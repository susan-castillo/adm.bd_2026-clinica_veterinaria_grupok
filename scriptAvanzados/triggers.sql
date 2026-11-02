-- TRIGGERS
-- Versión T-SQL (SQL Server 2017+), migrada desde PostgreSQL
-- ============================================================
-- Notas:
--  * SQL Server no tiene BEFORE INSERT ni FOR EACH ROW. Los triggers "BEFORE" pasan a
--    INSTEAD OF INSERT (el trigger hace el INSERT) y todos trabajan sobre el conjunto
--    de filas `inserted`, por lo que soportan inserciones de varias filas.
--  * Cuando el INSTEAD OF hace su propio INSERT sobre la misma tabla, ese INSERT no vuelve
--    a disparar el INSTEAD OF, pero sí dispara los triggers AFTER (total y stock).
--  * Cada CREATE va seguido de GO porque debe ser la primera sentencia del lote.

USE db_veterinaria;
GO

--TRIGGERS PARA EL CONTROL DE ENTIDADES DÉBILES
-- ============================================================
-- 1. Automatización para DETALLES_FACTURAS
-- Busca el último número de renglón de esta factura y le suma 1. Si es el primero, inicia en 1.
-- El id que venga en el INSERT se ignora (igual que en el original); solo se usa para
-- conservar el orden relativo de las filas del mismo INSERT.
CREATE OR ALTER TRIGGER dbo.tr_antes_insertar_detalle_factura
ON dbo.detalles_facturas
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.detalles_facturas
        (id_detalle_factura, id_factura, id_cita, id_medicamento, id_tratamiento, id_procedimiento,
         descripcion_df, cantidad_df, precio_unit_df)
    SELECT
        COALESCE(mx.max_id, 0)
            + ROW_NUMBER() OVER (PARTITION BY i.id_factura ORDER BY i.id_detalle_factura),
        i.id_factura, i.id_cita, i.id_medicamento, i.id_tratamiento, i.id_procedimiento,
        i.descripcion_df, i.cantidad_df, i.precio_unit_df
    FROM inserted i
    LEFT JOIN (
        -- UPDLOCK/HOLDLOCK evita que dos inserciones simultáneas calculen el mismo número
        SELECT id_factura, MAX(id_detalle_factura) AS max_id
        FROM dbo.detalles_facturas WITH (UPDLOCK, HOLDLOCK)
        GROUP BY id_factura
    ) mx ON mx.id_factura = i.id_factura;
END;
GO

-- ===================================================================================

-- 2. Automatización para DETALLES_TRATAMIENTOS
-- Busca el último número de renglón de este tratamiento y le suma 1. Si es el primero, inicia en 1.
CREATE OR ALTER TRIGGER dbo.tr_antes_insertar_detalle_tratamiento
ON dbo.detalles_tratamientos
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.detalles_tratamientos
        (id_detalle_tratamiento, id_tratamiento, id_medicamento, dosis_dt, frecuencia_dt, duracion_dias_dt)
    SELECT
        COALESCE(mx.max_id, 0)
            + ROW_NUMBER() OVER (PARTITION BY i.id_tratamiento ORDER BY i.id_detalle_tratamiento),
        i.id_tratamiento, i.id_medicamento, i.dosis_dt, i.frecuencia_dt, i.duracion_dias_dt
    FROM inserted i
    LEFT JOIN (
        SELECT id_tratamiento, MAX(id_detalle_tratamiento) AS max_id
        FROM dbo.detalles_tratamientos WITH (UPDLOCK, HOLDLOCK)
        GROUP BY id_tratamiento
    ) mx ON mx.id_tratamiento = i.id_tratamiento;
END;
GO

-- ===================================================================================
-- TRIGGERS PARA EL CONTROL DEL TOTALIZADOR DE LA FACTURA

-- 3. Actualiza el totalizador de la factura
-- Sumamos el subtotal generado en el detalle al total acumulado de la factura
-- (AFTER: necesitamos que subtotal_df ya esté calculado)
CREATE OR ALTER TRIGGER dbo.tr_acumular_total_factura
ON dbo.detalles_facturas
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE f
    SET f.total_f = f.total_f + s.suma_subtotal
    FROM dbo.facturas f
    JOIN (
        SELECT id_factura, SUM(subtotal_df) AS suma_subtotal
        FROM inserted
        GROUP BY id_factura
    ) s ON s.id_factura = f.id_factura;
END;
GO

-- ===================================================================================
-- TRIGGERS PARA EL CONTROL DEL INVENTARIO DE MEDICAMENTOS

-- 4. Reduce el stock del medicamento vendido en la factura
-- (AFTER para actuar después de validar los CHECKS)
CREATE OR ALTER TRIGGER dbo.tr_actualizar_inventario_farmacia
ON dbo.detalles_facturas
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @msg NVARCHAR(2048);

    -- Solo actuamos sobre los renglones de la factura que corresponden a un medicamento.
    -- Se agrupa por medicamento para validar el total pedido en el INSERT (varias filas).
    DECLARE @pedido TABLE (id_medicamento BIGINT PRIMARY KEY, solicitado BIGINT NOT NULL);

    INSERT INTO @pedido (id_medicamento, solicitado)
    SELECT id_medicamento, SUM(cantidad_df)
    FROM inserted
    WHERE id_medicamento IS NOT NULL
    GROUP BY id_medicamento;

    -- 1-2. Validar si hay suficiente existencia
    SELECT TOP (1)
        @msg = CONCAT(N'Error de Inventario: No hay suficiente stock para el medicamento solicitado. Disponible: ',
                      m.stock_m, N', Solicitado: ', p.solicitado)
    FROM @pedido p
    JOIN dbo.medicamentos m ON m.id_medicamento = p.id_medicamento
    WHERE m.stock_m < p.solicitado
    ORDER BY p.id_medicamento;

    IF @msg IS NOT NULL
    BEGIN
        -- En un trigger hay que deshacer la transacción explícitamente para anular el INSERT
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50020, @msg, 1;
    END;

    -- 3. Si hay stock, restar las unidades del inventario
    UPDATE m
    SET m.stock_m = m.stock_m - p.solicitado
    FROM dbo.medicamentos m
    JOIN @pedido p ON p.id_medicamento = m.id_medicamento;
END;
GO
