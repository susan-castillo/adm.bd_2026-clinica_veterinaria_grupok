/*
-- SECCION 3: Consultas analiticas, indices y planes de ejecucion
-- ============================================================
--  Conectar a veterinaria_perf y activar "Actual Plan" en VS Code.
--  borrar todos los indices (estado "sin indice").
--  por cada consulta (1, 2 y 3), ejecutar su bloque completo
--     Guardar:
--       - Messages 
--       - Plan real 
--  crear los indices (una sola vez).
--  repetir las MISMAS consultas. Guardar:
--       - Messages  
--       - Plan real 
-- NO ejecutar en db_veterinaria: la limpieza de cache es solo para pruebas.
*/

USE veterinaria_perf;
GO

-- Activa lecturas logicas (IO) y tiempos (TIME) para toda la sesion.
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO


-- ESTADO "SIN INDICE"
-- Borra los indices del equipo y los propios. Quedan solo PK y UNIQUE.
DROP INDEX IF EXISTS IX_mascotas_propietario        ON pacientes.mascotas;
DROP INDEX IF EXISTS IX_mascotas_raza               ON pacientes.mascotas;
DROP INDEX IF EXISTS IX_veterinario_especialidad    ON personal.veterinario;
DROP INDEX IF EXISTS IX_citas_mascota               ON clinica.citas;
DROP INDEX IF EXISTS IX_citas_veterinario           ON clinica.citas;
DROP INDEX IF EXISTS IX_citas_fecha                 ON clinica.citas;
DROP INDEX IF EXISTS IX_procedimientos_diagnostico  ON clinica.procedimientos;
DROP INDEX IF EXISTS IX_tratamiento_diagnostico     ON clinica.tratamiento;
DROP INDEX IF EXISTS IX_dt_medicamento              ON clinica.detalles_tratamientos;
DROP INDEX IF EXISTS IX_df_cita                     ON facturacion.detalles_facturas;
DROP INDEX IF EXISTS IX_df_medicamento              ON facturacion.detalles_facturas;
DROP INDEX IF EXISTS IX_df_tratamiento              ON facturacion.detalles_facturas;
DROP INDEX IF EXISTS IX_df_procedimiento            ON facturacion.detalles_facturas;

-- Indices propios (uno por consulta)
DROP INDEX IF EXISTS ix_citas_estado_fecha          ON clinica.citas;
DROP INDEX IF EXISTS ix_citas_estado_mascota_fecha  ON clinica.citas;
DROP INDEX IF EXISTS ix_facturas_estado_fecha       ON facturacion.facturas;
GO

-- CONSULTAS (se ejecutan antes y despues de crear indices)
-- Cada bloque: limpia cache para una medicion justa y luego ejecuta.

-- ------------------------------------------------------------
-- CONSULTA 1: Productividad y ranking de veterinarios por especialidad
-- Ventanas: RANK() y SUM(COUNT(*)) OVER (PARTITION BY especialidad).
-- ------------------------------------------------------------
CHECKPOINT;
DBCC DROPCLEANBUFFERS;   -- vacia cache de datos
DBCC FREEPROCCACHE;      -- vacia cache de planes
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

-- ------------------------------------------------------------
-- CONSULTA 2: Frecuencia de visitas y dias transcurridos por mascota
-- Ventana: LAG() para obtener la visita anterior de cada mascota.
-- ------------------------------------------------------------
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
GO

WITH visitas AS (
    -- Cada visita completada junto con la fecha de la visita anterior
    SELECT
        c.id_mascota,
        c.fecha_c,
        LAG(c.fecha_c) OVER (PARTITION BY c.id_mascota
                             ORDER BY c.fecha_c)     AS visita_anterior
    FROM clinica.citas c
    WHERE c.estado_c = N'Completada'
),
resumen AS (
    -- Una fila por mascota: frecuencia y dias entre visitas
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

-- ------------------------------------------------------------
-- CONSULTA 3: Facturacion acumulada y promedio movil mensual
-- Ventanas: SUM() OVER acumulado, AVG() OVER movil, LAG().
-- ------------------------------------------------------------
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
GO

WITH mensual AS (
    -- Total de facturas pagadas por mes
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
-- CREAR INDICES (una sola vez)
-- ============================================================

-- 3.1 Indices del equipo sobre llaves foraneas (con esquema).
--     Aceleran uniones y filtros por FK en todo el modelo.
CREATE INDEX IX_mascotas_propietario       ON pacientes.mascotas (id_propietario);
CREATE INDEX IX_mascotas_raza              ON pacientes.mascotas (id_raza);
CREATE INDEX IX_veterinario_especialidad   ON personal.veterinario (id_especialidad);
CREATE INDEX IX_citas_mascota              ON clinica.citas (id_mascota);
CREATE INDEX IX_citas_veterinario          ON clinica.citas (id_veterinario);
CREATE INDEX IX_citas_fecha                ON clinica.citas (fecha_c);
CREATE INDEX IX_procedimientos_diagnostico ON clinica.procedimientos (id_diagnostico);
CREATE INDEX IX_tratamiento_diagnostico    ON clinica.tratamiento (id_diagnostico);
CREATE INDEX IX_dt_medicamento             ON clinica.detalles_tratamientos (id_medicamento);
-- Filtrados: solo indexan filas con valor (ahorran espacio).
CREATE INDEX IX_df_cita          ON facturacion.detalles_facturas (id_cita)          WHERE id_cita IS NOT NULL;
CREATE INDEX IX_df_medicamento   ON facturacion.detalles_facturas (id_medicamento)   WHERE id_medicamento IS NOT NULL;
CREATE INDEX IX_df_tratamiento   ON facturacion.detalles_facturas (id_tratamiento)   WHERE id_tratamiento IS NOT NULL;
CREATE INDEX IX_df_procedimiento ON facturacion.detalles_facturas (id_procedimiento) WHERE id_procedimiento IS NOT NULL;
GO

-- 3.2 Indice propio CONSULTA 1
--     estado_c (igualdad) + fecha_c (rango); INCLUDE cubre la consulta
--     y evita volver a la tabla. Reemplaza el Clustered Index Scan.
CREATE NONCLUSTERED INDEX ix_citas_estado_fecha
ON clinica.citas (estado_c, fecha_c)
INCLUDE (id_veterinario, costo_c);
GO

-- 3.3 Indice propio CONSULTA 2
--     Deja las citas completadas ya ordenadas por mascota y fecha:
--     LAG() no necesita el Sort que hay sin indice.
CREATE NONCLUSTERED INDEX ix_citas_estado_mascota_fecha
ON clinica.citas (estado_c, id_mascota, fecha_c);
GO

-- 3.4 Indice propio CONSULTA 3
--     estado_f (igualdad) + fecha_emision_f (orden por mes);
--     INCLUDE total_f hace que el indice cubra la consulta.
CREATE NONCLUSTERED INDEX ix_facturas_estado_fecha
ON facturacion.facturas (estado_f, fecha_emision_f)
INCLUDE (total_f);
GO

-- Verificar todos los indices creados (propios y del equipo)
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
WHERE i.name LIKE 'ix[_]%'   -- IX_ y ix_ (propios y del equipo)
GROUP BY i.object_id, i.name, i.type_desc, i.filter_definition
ORDER BY esquema, tabla, indice;
GO

-- Espacio ocupado por cada indice, en MB
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