/*
SECCION 3 - Indices (non-clustered) para C1, C2 y C3
Se ejecuta ENTRE las dos mediciones de Consultas.sql.
Es re-ejecutable: primero deja la base "sin indice" y luego crea los propios.
*/
USE db_veterinaria;
GO

-- ============================================================
-- 0. REINICIAR A "SIN INDICE" (tambien sirve para volver al baseline)
-- ============================================================
DROP INDEX IF EXISTS ix_citas_estado_fecha         ON clinica.citas;
DROP INDEX IF EXISTS ix_citas_estado_mascota_fecha ON clinica.citas;
DROP INDEX IF EXISTS ix_facturas_estado_fecha      ON facturacion.facturas;
GO

-- ============================================================
-- 1. INDICES PROPIOS (crear una sola vez por medicion)
-- ============================================================

-- C1: estado_c (igualdad) + fecha_c (rango). INCLUDE cubre la consulta
--     y evita volver a la tabla (reemplaza el Clustered Index Scan).
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
-- 2. CANDIDATOS ADICIONALES (probar de UNO en uno)
-- Flujo: descomentar un candidato, correr Consultas.sql, anotar lecturas y CPU,
-- luego borrarlo con su DROP y pasar al siguiente. Solo se documentan los que
-- bajan de forma clara las lecturas logicas o el CPU; si ninguno mejora, se
-- justifica en el informe por que uno solo por consulta basta.
-- ============================================================

-- Candidato A (C1): llave por veterinario primero
CREATE NONCLUSTERED INDEX ix_cand_citas_vet_estado_fecha
ON clinica.citas (id_veterinario, estado_c, fecha_c) INCLUDE (costo_c);
GO

--NO PRESENTÓ MEJORA, ASI QUE ELIMINAMOS Y PROBAMOS EL OTRO
DROP INDEX IF EXISTS ix_cand_citas_vet_estado_fecha ON clinica.citas;

-- Candidato B (C1): indice filtrado sobre Completada
CREATE NONCLUSTERED INDEX ix_cand_citas_comp_fecha
ON clinica.citas (fecha_c) INCLUDE (id_veterinario, costo_c)
WHERE estado_c = N'Completada';

--NO PRESENTÓ MEJORA, ASI QUE ELIMINAMOS Y PROBAMOS EL OTRO
DROP INDEX IF EXISTS ix_cand_citas_comp_fecha ON clinica.citas;

-- Candidato C (C2): indice filtrado sobre Completada
CREATE NONCLUSTERED INDEX ix_cand_citas_comp_mascota_fecha
ON clinica.citas (id_mascota, fecha_c)
WHERE estado_c = N'Completada';

--NO PRESENTÓ MEJORA, ASI QUE ELIMINAMOS Y PROBAMOS EL OTRO
DROP INDEX IF EXISTS ix_cand_citas_comp_mascota_fecha ON clinica.citas;

-- Candidato D (C3): indice filtrado sobre Pagada
CREATE NONCLUSTERED INDEX ix_cand_facturas_pagada_fecha
ON facturacion.facturas (fecha_emision_f) INCLUDE (total_f)
WHERE estado_f = N'Pagada';

--NO PRESENTÓ MEJORA, ASI QUE ELIMINAMOS Y ...ya no hay candidatos :D
DROP INDEX IF EXISTS ix_cand_facturas_pagada_fecha ON facturacion.facturas;

-- ============================================================
-- 3. VERIFICACION
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