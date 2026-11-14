/*
SECCION 3 - Indices (non-clustered) para C1, C2 y C3
Se ejecuta ENTRE las mediciones de Consultas.sql. Cada seccion se corre por separado
(seleccionar y ejecutar):
  Sin indice      -> seccion 0
  Diseño inicial  -> seccion 0 + seccion 1
  Diseño final    -> seccion 0 + seccion 2
*/
USE db_veterinaria;
GO

-- ============================================================
-- 0. REINICIAR A "SIN INDICE"
-- ============================================================
DROP INDEX IF EXISTS ix_citas_estado_fecha         ON clinica.citas;
DROP INDEX IF EXISTS ix_citas_estado_mascota_fecha ON clinica.citas;
DROP INDEX IF EXISTS ix_citas_comp_fecha           ON clinica.citas;
DROP INDEX IF EXISTS ix_citas_comp_mascota_fecha   ON clinica.citas;
DROP INDEX IF EXISTS ix_facturas_estado_fecha      ON facturacion.facturas;
DROP INDEX IF EXISTS ix_facturas_pagada_fecha      ON facturacion.facturas;
-- Restos de las pruebas de candidatos
DROP INDEX IF EXISTS ix_cand_citas_vet_estado_fecha     ON clinica.citas;
DROP INDEX IF EXISTS ix_cand_citas_comp_fecha           ON clinica.citas;
DROP INDEX IF EXISTS ix_cand_citas_comp_mascota_fecha   ON clinica.citas;
DROP INDEX IF EXISTS ix_sug_citas_estado                ON clinica.citas;
DROP INDEX IF EXISTS ix_cand_facturas_pagada_fecha      ON facturacion.facturas;
DROP INDEX IF EXISTS ix_sug_facturas_estado             ON facturacion.facturas;
GO

-- ============================================================
-- 1. DISEÑO INICIAL (un indice por consulta)
-- ============================================================

-- C1: estado_c (igualdad) + fecha_c (rango). INCLUDE cubre la consulta
--     y evita volver a la tabla (reemplaza el Clustered Index Scan).
--     Coincide con la primera sugerencia de SQL Server.
CREATE NONCLUSTERED INDEX ix_citas_estado_fecha
ON clinica.citas (estado_c, fecha_c)
INCLUDE (id_veterinario, costo_c);
GO

-- C2: citas completadas ya ordenadas por mascota y fecha;
--     LAG() no necesita el Sort que aparece sin indice.
CREATE NONCLUSTERED INDEX ix_citas_estado_mascota_fecha
ON clinica.citas (estado_c, id_mascota, fecha_c);
GO

-- C3: estado_f (igualdad) + fecha_emision_f (orden por mes);
--     INCLUDE total_f hace que el indice cubra la consulta.
CREATE NONCLUSTERED INDEX ix_facturas_estado_fecha
ON facturacion.facturas (estado_f, fecha_emision_f)
INCLUDE (total_f);
GO

-- ============================================================
-- 2. DISEÑO FINAL (indices filtrados; reemplazan al inicial)
-- Mismo orden de llaves, pero solo guardan las filas que usa cada consulta
-- (estado fijo en el WHERE): indice mas angosto, menos paginas por leer.
-- Con el inicial presente el optimizador no los elige; hay que reemplazarlo.
-- Limite: solo sirven si la consulta escribe el estado como literal.
-- ============================================================

-- C1: lecturas en citas 279 -> 175; tamaño 6.13 -> 3.23 MB
CREATE NONCLUSTERED INDEX ix_citas_comp_fecha
ON clinica.citas (fecha_c) INCLUDE (id_veterinario, costo_c)
WHERE estado_c = N'Completada';
GO

-- C2: lecturas en citas 577 -> 329; tamaño 5.27 -> 2.70 MB
CREATE NONCLUSTERED INDEX ix_citas_comp_mascota_fecha
ON clinica.citas (id_mascota, fecha_c)
WHERE estado_c = N'Completada';
GO

-- C3: lecturas en facturas 324 -> 208; tamaño 3.21 -> 1.75 MB
CREATE NONCLUSTERED INDEX ix_facturas_pagada_fecha
ON facturacion.facturas (fecha_emision_f) INCLUDE (total_f)
WHERE estado_f = N'Pagada';
GO

-- ============================================================
-- 3. CANDIDATOS DESCARTADOS (documentacion, NO ejecutar)
-- ============================================================

-- A (C1, 2a sugerencia de SQL Server): llave por veterinario primero.
--   Stream Aggregate en vez de Hash Match, pero 40 Seeks: 656 lecturas vs 279.
-- CREATE NONCLUSTERED INDEX ix_cand_citas_vet_estado_fecha
-- ON clinica.citas (id_veterinario, estado_c, fecha_c) INCLUDE (costo_c);

-- Sugerencia de SQL Server para C2: vuelve el Sort del LAG() y el plan paralelo;
--   605 lecturas en citas y ~420 en mascotas (vs 577 y 48 con el inicial).
-- CREATE NONCLUSTERED INDEX ix_sug_citas_estado
-- ON clinica.citas (estado_c) INCLUDE (id_mascota, fecha_c);

-- Sugerencia de SQL Server para C3: 324 lecturas, igual que el inicial.
-- CREATE NONCLUSTERED INDEX ix_sug_facturas_estado
-- ON facturacion.facturas (estado_f) INCLUDE (fecha_emision_f, total_f);

-- ============================================================
-- 4. VERIFICACION
-- ============================================================

-- Indices creados (columnas clave, incluidas y filtro)
SELECT
    OBJECT_SCHEMA_NAME(i.object_id) AS esquema,
    OBJECT_NAME(i.object_id)        AS tabla,
    i.name                          AS indice,
    i.type_desc                     AS tipo,
    STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN c.name END, ', ')
        WITHIN GROUP (ORDER BY ic.key_ordinal) AS columnas_clave,
    STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN c.name END, ', ') AS columnas_incluidas,
    i.filter_definition             AS filtro
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns c        ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE i.name LIKE 'ix[_]%' AND OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
GROUP BY i.object_id, i.name, i.type_desc, i.filter_definition
ORDER BY esquema, tabla, indice;
GO

-- Espacio por indice (MB)
SELECT
    OBJECT_SCHEMA_NAME(i.object_id) AS esquema,
    OBJECT_NAME(i.object_id)        AS tabla,
    i.name                          AS indice,
    CAST(SUM(ps.used_page_count) * 8 / 1024.0 AS DECIMAL(10,2)) AS tamanio_mb
FROM sys.indexes i
JOIN sys.dm_db_partition_stats ps
  ON ps.object_id = i.object_id AND ps.index_id = i.index_id
WHERE i.name LIKE 'ix[_]%' AND OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
GROUP BY i.object_id, i.name
ORDER BY tamanio_mb DESC;
GO