/*
SECCION 3: Consultas analiticas, indices y planes de ejecucion
Base: db_veterinaria (restaurada desde DataBase_UpdatedData.bak). Activar "Actual Plan" en VS Code.

Flujo por consulta (C1, C2, C3):
  1. Estado "sin indice": ejecutar el bloque y guardar Messages + plan real.
  2. Crear los indices y repetir EXACTAMENTE el mismo bloque.
Los DBCC son solo para pruebas locales: no ejecutarlos en una instancia compartida.
*/

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- ESTADO "SIN INDICE"
DROP INDEX IF EXISTS ix_citas_estado_fecha         ON clinica.citas;
DROP INDEX IF EXISTS ix_citas_estado_mascota_fecha ON clinica.citas;
DROP INDEX IF EXISTS ix_facturas_estado_fecha      ON facturacion.facturas;
GO

-- ============================================================
-- CONSULTAS (cada bloque limpia cache antes de medir)
-- ============================================================

-- C1: Productividad y ranking de veterinarios por especialidad (ultimo año)
-- Ventanas: RANK(), SUM(COUNT(*)) OVER (PARTITION BY especialidad)
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
GO

SELECT
    esp.nombre_esp                                   AS especialidad,
    CONCAT(v.nombre_v, N' ', v.apellido_v)           AS veterinario,
    COUNT(*)                                         AS citas_completadas,
    SUM(c.costo_c)                                   AS ingresos_generados,
    CAST(AVG(c.costo_c) AS DECIMAL(10,2))            AS costo_promedio,
    RANK() OVER (PARTITION BY esp.id_especialidad
                 ORDER BY COUNT(*) DESC)             AS ranking_en_especialidad,
    CAST(100.0 * COUNT(*)
         / SUM(COUNT(*)) OVER (PARTITION BY esp.id_especialidad)
         AS DECIMAL(5,2))                            AS pct_de_la_especialidad
FROM clinica.citas c
JOIN personal.veterinario    v   ON v.id_veterinario    = c.id_veterinario
JOIN personal.especialidades esp ON esp.id_especialidad = v.id_especialidad
WHERE c.estado_c = N'Completada'
  AND c.fecha_c >= DATEADD(YEAR, -1, SYSDATETIME())
GROUP BY esp.id_especialidad, esp.nombre_esp,
         v.id_veterinario, v.nombre_v, v.apellido_v
ORDER BY esp.nombre_esp, ranking_en_especialidad;
GO

-- C2: Frecuencia de visitas y dias entre visitas por mascota (TOP 20)
-- Ventana: LAG() sobre la visita anterior de cada mascota
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
GO

WITH visitas AS (
    SELECT
        c.id_mascota,
        c.fecha_c,
        LAG(c.fecha_c) OVER (PARTITION BY c.id_mascota
                             ORDER BY c.fecha_c)     AS visita_anterior
    FROM clinica.citas c
    WHERE c.estado_c = N'Completada'
),
resumen AS (
    SELECT
        v.id_mascota,
        COUNT(*)                                                 AS total_visitas,
        MAX(v.fecha_c)                                           AS ultima_visita,
        CAST(AVG(DATEDIFF(DAY, v.visita_anterior, v.fecha_c) * 1.0)
             AS DECIMAL(10,2))                                   AS dias_promedio_entre_visitas,
        MAX(DATEDIFF(DAY, v.visita_anterior, v.fecha_c))         AS max_dias_entre_visitas
    FROM visitas v
    GROUP BY v.id_mascota
)
SELECT TOP (20)
    m.nombre_m                                                   AS mascota,
    r.total_visitas,
    r.dias_promedio_entre_visitas,
    r.max_dias_entre_visitas,
    r.ultima_visita,
    DATEDIFF(DAY, r.ultima_visita, SYSDATETIME())                AS dias_desde_ultima_visita
FROM resumen r
JOIN pacientes.mascotas m ON m.id_mascota = r.id_mascota
ORDER BY r.total_visitas DESC, m.id_mascota;
GO

-- C3: Facturacion mensual acumulada y promedio movil (solo facturas Pagada)
-- Ventanas: SUM() OVER acumulado, AVG() OVER movil, LAG()
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
GO

WITH mensual AS (
    SELECT
        DATEFROMPARTS(YEAR(f.fecha_emision_f),
                      MONTH(f.fecha_emision_f), 1)               AS mes,
        COUNT(*)                                                 AS facturas_emitidas,
        SUM(f.total_f)                                           AS total_mes
    FROM facturacion.facturas f
    WHERE f.estado_f = N'Pagada'
    GROUP BY DATEFROMPARTS(YEAR(f.fecha_emision_f),
                           MONTH(f.fecha_emision_f), 1)
)
SELECT
    mes,
    facturas_emitidas,
    total_mes,
    SUM(total_mes) OVER (ORDER BY mes
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)        AS facturacion_acumulada,
    CAST(AVG(total_mes) OVER (ORDER BY mes
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
         AS DECIMAL(12,2))                                       AS promedio_movil_3_meses,
    CAST(100.0 * (total_mes - LAG(total_mes) OVER (ORDER BY mes))
         / NULLIF(LAG(total_mes) OVER (ORDER BY mes), 0)
         AS DECIMAL(7,2))                                        AS variacion_pct_mes_anterior
FROM mensual
ORDER BY mes;
GO

-- ============================================================
-- INDICES PROPIOS (crear una sola vez)
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
-- CANDIDATOS ADICIONALES
-- Se agregan aqui uno a uno. Solo se conservan (y documentan)
-- los que bajan de forma clara lecturas logicas o CPU.
-- ============================================================


-- ============================================================
-- VERIFICACION
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
WHERE i.name LIKE 'ix[_]%'
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
WHERE i.name LIKE 'ix[_]%'
GROUP BY i.object_id, i.name
ORDER BY tamanio_mb DESC;
GO