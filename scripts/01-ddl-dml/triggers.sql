-- 02. TRIGGERS: ejecutar después del DDL y antes del DML.
-- Crea o actualiza los ocho triggers; no carga ni elimina registros.
USE db_veterinaria;
GO
CREATE OR ALTER TRIGGER clinica.tr_antes_insertar_detalle_tratamiento
ON clinica.detalles_tratamientos INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO clinica.detalles_tratamientos (id_detalle_tratamiento, id_tratamiento, id_medicamento, dosis_dt, frecuencia_dt, duracion_dias_dt)
    SELECT COALESCE(mx.max_id, 0) + ROW_NUMBER() OVER
           (PARTITION BY i.id_tratamiento ORDER BY i.id_detalle_tratamiento),
           i.id_tratamiento, i.id_medicamento, i.dosis_dt, i.frecuencia_dt, i.duracion_dias_dt
    FROM inserted AS i
    OUTER APPLY (
        SELECT MAX(d.id_detalle_tratamiento) AS max_id
        FROM clinica.detalles_tratamientos AS d WITH (UPDLOCK, HOLDLOCK)
        WHERE d.id_tratamiento = i.id_tratamiento
    ) AS mx;
END;
GO

CREATE OR ALTER TRIGGER facturacion.tr_antes_insertar_detalle_factura
ON facturacion.detalles_facturas INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO facturacion.detalles_facturas (id_detalle_factura, id_factura, id_cita, id_medicamento, id_tratamiento, id_procedimiento, descripcion_df, cantidad_df, precio_unit_df)
    SELECT COALESCE(mx.max_id, 0) + ROW_NUMBER() OVER
           (PARTITION BY i.id_factura ORDER BY i.id_detalle_factura),
           i.id_factura, i.id_cita, i.id_medicamento, i.id_tratamiento, i.id_procedimiento, i.descripcion_df, i.cantidad_df, i.precio_unit_df
    FROM inserted AS i
    OUTER APPLY (
        SELECT MAX(d.id_detalle_factura) AS max_id
        FROM facturacion.detalles_facturas AS d WITH (UPDLOCK, HOLDLOCK)
        WHERE d.id_factura = i.id_factura
    ) AS mx;
END;
GO

CREATE OR ALTER TRIGGER facturacion.tr_acumular_total_factura
ON facturacion.detalles_facturas AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    ;WITH afectadas AS (
        SELECT id_factura FROM inserted UNION SELECT id_factura FROM deleted
    )
    UPDATE f SET total_f = COALESCE((SELECT SUM(d.subtotal_df)
        FROM facturacion.detalles_facturas d WHERE d.id_factura=f.id_factura),0)
    FROM facturacion.facturas f JOIN afectadas a ON a.id_factura=f.id_factura;
END;
GO

CREATE OR ALTER TRIGGER facturacion.tr_actualizar_inventario_farmacia
ON facturacion.detalles_facturas AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @delta TABLE (id_medicamento bigint PRIMARY KEY, delta bigint NOT NULL);
    INSERT INTO @delta
    SELECT id_medicamento, SUM(delta) FROM (
        SELECT id_medicamento, cantidad_df AS delta FROM inserted WHERE id_medicamento IS NOT NULL
        UNION ALL
        SELECT id_medicamento, -cantidad_df FROM deleted WHERE id_medicamento IS NOT NULL
    ) x GROUP BY id_medicamento HAVING SUM(delta) <> 0;
    DECLARE @esperados int = (SELECT COUNT(*) FROM @delta);
    UPDATE m WITH (UPDLOCK, HOLDLOCK)
    SET stock_m = CAST(CAST(m.stock_m AS bigint) - d.delta AS int)
    FROM farmacia.medicamentos m JOIN @delta d ON d.id_medicamento=m.id_medicamento
    WHERE CAST(m.stock_m AS bigint)-d.delta BETWEEN 0 AND 2147483647;
    IF @@ROWCOUNT <> @esperados
        THROW 51020, N'Medicamento inexistente o stock fuera de rango. Se revierte la operación.', 1;
END;
GO

CREATE OR ALTER TRIGGER pacientes.tr_validar_fecha_nacimiento_mascota
ON pacientes.mascotas
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted WHERE fecha_nacimiento IS NOT NULL AND fecha_nacimiento > CAST(GETDATE() AS date))
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50030, N'La fecha de nacimiento de la mascota no puede ser futura.', 1;
    END;
END;
GO

CREATE OR ALTER TRIGGER clinica.tr_validar_fecha_cita
ON clinica.citas
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted WHERE estado_c = N'Programada' AND fecha_c < DATEADD(HOUR,-1,GETDATE()))
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50031, N'Una cita Programada no puede tener fecha en el pasado.', 1;
    END;
END;
GO

CREATE OR ALTER TRIGGER clinica.tr_validar_fecha_diagnostico
ON clinica.diagnosticos
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted WHERE fecha_d IS NOT NULL AND fecha_d > CAST(GETDATE() AS date))
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50032, N'La fecha del diagnóstico no puede ser futura.', 1;
    END;
END;
GO

CREATE OR ALTER TRIGGER facturacion.tr_validar_fecha_emision_factura
ON facturacion.facturas
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted WHERE fecha_emision_f > CAST(GETDATE() AS date))
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50033, N'La fecha de emisión de la factura no puede ser futura.', 1;
    END;
END;
GO

ENABLE TRIGGER clinica.tr_antes_insertar_detalle_tratamiento ON clinica.detalles_tratamientos;
ENABLE TRIGGER facturacion.tr_antes_insertar_detalle_factura ON facturacion.detalles_facturas;
ENABLE TRIGGER facturacion.tr_acumular_total_factura ON facturacion.detalles_facturas;
ENABLE TRIGGER facturacion.tr_actualizar_inventario_farmacia ON facturacion.detalles_facturas;
ENABLE TRIGGER pacientes.tr_validar_fecha_nacimiento_mascota ON pacientes.mascotas;
ENABLE TRIGGER clinica.tr_validar_fecha_cita ON clinica.citas;
ENABLE TRIGGER clinica.tr_validar_fecha_diagnostico ON clinica.diagnosticos;
ENABLE TRIGGER facturacion.tr_validar_fecha_emision_factura ON facturacion.facturas;
GO
