USE db_veterinaria;
GO


-- 1. DETALLES_FACTURAS: numeración por factura

CREATE OR ALTER TRIGGER facturacion.tr_antes_insertar_detalle_factura
ON facturacion.detalles_facturas
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO facturacion.detalles_facturas
        (id_detalle_factura, id_factura, id_cita, id_medicamento, id_tratamiento, id_procedimiento,
         descripcion_df, cantidad_df, precio_unit_df)
    SELECT
        COALESCE(mx.max_id, 0)
            + ROW_NUMBER() OVER (PARTITION BY i.id_factura ORDER BY i.id_detalle_factura),
        i.id_factura, i.id_cita, i.id_medicamento, i.id_tratamiento, i.id_procedimiento,
        i.descripcion_df, i.cantidad_df, i.precio_unit_df
    FROM inserted i
    LEFT JOIN (
        SELECT id_factura, MAX(id_detalle_factura) AS max_id
        FROM facturacion.detalles_facturas WITH (UPDLOCK, HOLDLOCK)
        GROUP BY id_factura
    ) mx ON mx.id_factura = i.id_factura;
END;
GO


-- 2. DETALLES_TRATAMIENTOS: numeración por tratamiento

CREATE OR ALTER TRIGGER clinica.tr_antes_insertar_detalle_tratamiento
ON clinica.detalles_tratamientos
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO clinica.detalles_tratamientos
        (id_detalle_tratamiento, id_tratamiento, id_medicamento, dosis_dt, frecuencia_dt, duracion_dias_dt)
    SELECT
        COALESCE(mx.max_id, 0)
            + ROW_NUMBER() OVER (PARTITION BY i.id_tratamiento ORDER BY i.id_detalle_tratamiento),
        i.id_tratamiento, i.id_medicamento, i.dosis_dt, i.frecuencia_dt, i.duracion_dias_dt
    FROM inserted i
    LEFT JOIN (
        SELECT id_tratamiento, MAX(id_detalle_tratamiento) AS max_id
        FROM clinica.detalles_tratamientos WITH (UPDLOCK, HOLDLOCK)
        GROUP BY id_tratamiento
    ) mx ON mx.id_tratamiento = i.id_tratamiento;
END;
GO


-- 3. TOTAL DE FACTURA
-- FIX: recalcula desde cero (no acumula) y soporta INSERT, UPDATE, DELETE.

CREATE OR ALTER TRIGGER facturacion.tr_acumular_total_factura
ON facturacion.detalles_facturas
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Facturas afectadas por cualquiera de las 3 operaciones
    ;WITH afectadas AS (
        SELECT id_factura FROM inserted
        UNION
        SELECT id_factura FROM deleted
    )
    UPDATE f
    SET f.total_f = ISNULL((
        SELECT SUM(d.subtotal_df)
        FROM facturacion.detalles_facturas d
        WHERE d.id_factura = f.id_factura
    ), 0)
    FROM facturacion.facturas f
    JOIN afectadas a ON a.id_factura = f.id_factura;
END;
GO


-- 4. INVENTARIO DE MEDICAMENTOS
-- FIX: soporta INSERT, UPDATE y DELETE (devuelve stock al eliminar,ajusta delta al actualizar).

CREATE OR ALTER TRIGGER facturacion.tr_actualizar_inventario_farmacia
ON facturacion.detalles_facturas
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @msg NVARCHAR(2048);

    -- Delta neto por medicamento:
    --   INSERT -> +cantidad (se consume)
    --   DELETE -> -cantidad (se devuelve)
    --   UPDATE -> (nueva cantidad) - (cantidad anterior)
    DECLARE @delta TABLE (id_medicamento BIGINT PRIMARY KEY, delta BIGINT NOT NULL);

    INSERT INTO @delta (id_medicamento, delta)
    SELECT id_medicamento, SUM(delta) FROM (
        SELECT id_medicamento,  cantidad_df AS delta FROM inserted WHERE id_medicamento IS NOT NULL
        UNION ALL
        SELECT id_medicamento, -cantidad_df AS delta FROM deleted  WHERE id_medicamento IS NOT NULL
    ) x
    GROUP BY id_medicamento
    HAVING SUM(delta) <> 0;

    -- Validación de stock (solo si se consume más de lo disponible)
    SELECT TOP (1)
        @msg = CONCAT(N'Error de Inventario: stock insuficiente para medicamento ', d.id_medicamento,
                      N'. Disponible: ', m.stock_m, N', requerido adicional: ', d.delta)
    FROM @delta d
    JOIN farmacia.medicamentos m ON m.id_medicamento = d.id_medicamento
    WHERE d.delta > 0 AND m.stock_m < d.delta
    ORDER BY d.id_medicamento;

    IF @msg IS NOT NULL
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50020, @msg, 1;
    END;

    -- Aplicar delta (positivo = consume, negativo = devuelve)
    UPDATE m
    SET m.stock_m = m.stock_m - d.delta
    FROM farmacia.medicamentos m
    JOIN @delta d ON d.id_medicamento = m.id_medicamento;
END;
GO

-- ============================================================
-- 5. VALIDACIONES DE FECHAS QUE ANTES ESTABAN EN CHECK
--FIX: se movieron aquí porque GETDATE() no es válido en CHECK.


-- 5.1 mascotas: fecha_nacimiento <= hoy
CREATE OR ALTER TRIGGER pacientes.tr_validar_fecha_nacimiento_mascota
ON pacientes.mascotas
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted
        WHERE fecha_nacimiento IS NOT NULL
          AND fecha_nacimiento > CAST(GETDATE() AS DATE)
    )
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50030, N'La fecha de nacimiento de la mascota no puede ser futura.', 1;
    END
END;
GO

-- 5.2 citas: si estado = 'Programada', la fecha no puede ser pasada (más de 1h)
CREATE OR ALTER TRIGGER clinica.tr_validar_fecha_cita
ON clinica.citas
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted
        WHERE estado_c = 'Programada'
          AND fecha_c < DATEADD(HOUR, -1, GETDATE())
    )
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50031, N'Una cita en estado Programada no puede tener fecha en el pasado.', 1;
    END
END;
GO

-- 5.3 diagnosticos: fecha_d <= hoy
CREATE OR ALTER TRIGGER clinica.tr_validar_fecha_diagnostico
ON clinica.diagnosticos
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted
        WHERE fecha_d IS NOT NULL AND fecha_d > CAST(GETDATE() AS DATE)
    )
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50032, N'La fecha del diagnóstico no puede ser futura.', 1;
    END
END;
GO

-- 5.4 facturas: fecha_emision_f <= hoy
CREATE OR ALTER TRIGGER facturacion.tr_validar_fecha_emision_factura
ON facturacion.facturas
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted
        WHERE fecha_emision_f > CAST(GETDATE() AS DATE)
    )
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50033, N'La fecha de emisión de la factura no puede ser futura.', 1;
    END
END;
GO