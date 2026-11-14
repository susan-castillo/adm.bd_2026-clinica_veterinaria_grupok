USE db_vet_lab_sin_indices;
GO

-- 0. Estado actual
SELECT DB_NAME() AS base;
SELECT OBJECT_SCHEMA_NAME(object_id) AS esquema, OBJECT_NAME(object_id) AS tabla, name AS indice
FROM sys.indexes
WHERE name LIKE 'ix[_]%' AND OBJECTPROPERTY(object_id, 'IsUserTable') = 1
ORDER BY esquema, tabla, indice;
GO

-- 1. C1 inicial
CREATE NONCLUSTERED INDEX ix_citas_estado_fecha
ON clinica.citas (estado_c, fecha_c)
INCLUDE (id_veterinario, costo_c);
GO

-- 2. C2 inicial
CREATE NONCLUSTERED INDEX ix_citas_estado_mascota_fecha
ON clinica.citas (estado_c, id_mascota, fecha_c);
GO

-- 3. C3 inicial
CREATE NONCLUSTERED INDEX ix_facturas_estado_fecha
ON facturacion.facturas (estado_f, fecha_emision_f)
INCLUDE (total_f);
GO

-- 4. C1 descartado: Candidato A (2a sugerencia de SQL Server)
CREATE NONCLUSTERED INDEX ix_cand_citas_vet_estado_fecha
ON clinica.citas (id_veterinario, estado_c, fecha_c) INCLUDE (costo_c);
GO

-- 5. C2 descartado: sugerencia de SQL Server
CREATE NONCLUSTERED INDEX ix_sug_citas_estado
ON clinica.citas (estado_c) INCLUDE (id_mascota, fecha_c);
GO

-- 6. C3 descartado: sugerencia de SQL Server
CREATE NONCLUSTERED INDEX ix_sug_facturas_estado
ON facturacion.facturas (estado_f) INCLUDE (fecha_emision_f, total_f);
GO

-- 7. LIMPIEZA: solo indices de esta demo
DROP INDEX IF EXISTS ix_citas_estado_fecha            ON clinica.citas;
DROP INDEX IF EXISTS ix_citas_estado_mascota_fecha    ON clinica.citas;
DROP INDEX IF EXISTS ix_facturas_estado_fecha         ON facturacion.facturas;
DROP INDEX IF EXISTS ix_cand_citas_vet_estado_fecha   ON clinica.citas;
DROP INDEX IF EXISTS ix_sug_citas_estado              ON clinica.citas;
DROP INDEX IF EXISTS ix_sug_facturas_estado           ON facturacion.facturas;
GO
