/*
DEMO EN VIVO: probar un indice inicial o descartado, y dejar la base como estaba.
Cada seccion se corre por separado (seleccionar y ejecutar). Despues, ejecutar
3_Consultas_Lab.sql (o la consulta que se quiera ver) con "Actual Plan" activo.

BASE POR DEFECTO: db_vet_lab_sin_indices (escenario limpio, igual al de las mediciones).
Para hacerlo en db_veterinaria, cambiar la linea USE SOLO si el equipo lo autoriza.
La LIMPIEZA (seccion 7) borra unicamente los indices de esta demo (6 nombres);
nunca borra los 3 indices del diseño final.
NO ejecutar la demo en db_vet_lab_con_indices: con el filtrado presente el optimizador
puede elegir otro indice y el resultado deja de ser comparable.
*/
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
