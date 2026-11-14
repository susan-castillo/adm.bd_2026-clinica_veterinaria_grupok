/*
INFORMACION PARA DIMENSIONAMIENTO - db_veterinaria
Ejecutar DESPUES de cargar los datos masivos y SIN los indices ix_* de la seccion 3
(o rotular cada corrida: "sin ix_*" / "con ix_*"). Solo lectura: no modifica nada.
El backup NO esta en este archivo (ver README_Restore.md).
*/
USE db_veterinaria;
GO

-- 0) Entorno
SELECT
    SERVERPROPERTY('ProductVersion')      AS version_sqlserver,
    SERVERPROPERTY('Edition')             AS edicion,
    d.collation_name                      AS collation_db,
    d.compatibility_level                 AS nivel_compatibilidad,
    d.recovery_model_desc                 AS modelo_recuperacion
FROM sys.databases d
WHERE d.name = DB_NAME();
GO

-- 1) Por tabla: filas, datos, LOB, indices, total y bytes por fila
SELECT s.name AS esquema, t.name AS tabla,
       SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.row_count END) AS filas,
       CAST(SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.used_page_count END) * 8 / 1024.0 AS DECIMAL(10,2)) AS datos_mb,
       CAST(SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.lob_used_page_count END) * 8 / 1024.0 AS DECIMAL(10,2)) AS de_los_cuales_lob_mb,
       CAST(ISNULL(SUM(CASE WHEN ps.index_id > 1 THEN ps.used_page_count END), 0) * 8 / 1024.0 AS DECIMAL(10,2)) AS indices_mb,
       CAST(SUM(ps.used_page_count) * 8 / 1024.0 AS DECIMAL(10,2)) AS total_mb,
       CAST(SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.used_page_count END) * 8192.0
            / NULLIF(SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.row_count END), 0) AS DECIMAL(10,1)) AS bytes_por_fila_datos,
       CAST(SUM(ps.used_page_count) * 8192.0
            / NULLIF(SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.row_count END), 0) AS DECIMAL(10,1)) AS bytes_por_fila_total
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.dm_db_partition_stats ps ON ps.object_id = t.object_id
GROUP BY s.name, t.name
ORDER BY total_mb DESC;
GO

-- 1b) Total de la base (datos + indices)
SELECT
    CAST(SUM(CASE WHEN index_id IN (0,1) THEN used_page_count END) * 8 / 1024.0 AS DECIMAL(10,2)) AS datos_mb,
    CAST(ISNULL(SUM(CASE WHEN index_id > 1 THEN used_page_count END), 0) * 8 / 1024.0 AS DECIMAL(10,2)) AS indices_mb,
    CAST(SUM(used_page_count) * 8 / 1024.0 AS DECIMAL(10,2)) AS total_usado_mb
FROM sys.dm_db_partition_stats
WHERE OBJECTPROPERTY(object_id, 'IsUserTable') = 1;
GO

-- 2) Archivos: asignado vs usado
SELECT name AS archivo, type_desc AS tipo,
       CAST(size * 8 / 1024.0 AS DECIMAL(10,2)) AS asignado_mb,
       CAST(FILEPROPERTY(name, 'SpaceUsed') * 8 / 1024.0 AS DECIMAL(10,2)) AS usado_mb,
       CASE WHEN is_percent_growth = 1 THEN CONCAT(growth, N' %')
            ELSE CONCAT(CAST(growth * 8 / 1024.0 AS DECIMAL(10,2)), N' MB') END AS crecimiento_automatico
FROM sys.database_files;
GO

-- 2b) Log de transacciones: tamaño y uso actual
SELECT CAST(total_log_size_in_bytes / 1048576.0 AS DECIMAL(10,2)) AS log_total_mb,
       CAST(used_log_space_in_bytes / 1048576.0 AS DECIMAL(10,2)) AS log_usado_mb,
       CAST(used_log_space_in_percent AS DECIMAL(5,2))            AS log_usado_pct
FROM sys.dm_db_log_space_usage;
GO

-- 3) Razones entre tablas (lo que permite escalar todo desde un solo numero)
SELECT
    CAST(1.0 * m.n / p.n  AS DECIMAL(8,2)) AS mascotas_por_propietario,
    CAST(1.0 * c.n / m.n  AS DECIMAL(8,2)) AS citas_por_mascota,
    CAST(100.0 * cc.n / c.n AS DECIMAL(5,2)) AS pct_citas_completadas,
    CAST(100.0 * d.n  / NULLIF(cc.n, 0) AS DECIMAL(5,2)) AS pct_completadas_con_diagnostico,
    CAST(100.0 * pr.n / NULLIF(d.n, 0)  AS DECIMAL(5,2)) AS pct_diagnosticos_con_procedimiento,
    CAST(100.0 * tr.n / NULLIF(d.n, 0)  AS DECIMAL(5,2)) AS pct_diagnosticos_con_tratamiento,
    CAST(1.0 * dt.n / NULLIF(tr.n, 0)   AS DECIMAL(8,2)) AS medicamentos_por_tratamiento,
    CAST(100.0 * f.n  / NULLIF(cc.n, 0) AS DECIMAL(5,2)) AS pct_completadas_facturadas,
    CAST(1.0 * df.n / NULLIF(f.n, 0)    AS DECIMAL(8,2)) AS lineas_por_factura
FROM (SELECT COUNT_BIG(*) n FROM pacientes.propietarios) p,
     (SELECT COUNT_BIG(*) n FROM pacientes.mascotas) m,
     (SELECT COUNT_BIG(*) n FROM clinica.citas) c,
     (SELECT COUNT_BIG(*) n FROM clinica.citas WHERE estado_c = N'Completada') cc,
     (SELECT COUNT_BIG(*) n FROM clinica.diagnosticos) d,
     (SELECT COUNT_BIG(*) n FROM clinica.procedimientos) pr,
     (SELECT COUNT_BIG(*) n FROM clinica.tratamiento) tr,
     (SELECT COUNT_BIG(*) n FROM clinica.detalles_tratamientos) dt,
     (SELECT COUNT_BIG(*) n FROM facturacion.facturas) f,
     (SELECT COUNT_BIG(*) n FROM facturacion.detalles_facturas) df;
GO

-- 4) Distribucion por estado
SELECT N'cita' AS entidad, estado_c AS estado, COUNT_BIG(*) AS n,
       CAST(100.0 * COUNT_BIG(*) / SUM(COUNT_BIG(*)) OVER () AS DECIMAL(5,2)) AS pct
FROM clinica.citas GROUP BY estado_c
UNION ALL
SELECT N'factura', estado_f, COUNT_BIG(*),
       CAST(100.0 * COUNT_BIG(*) / SUM(COUNT_BIG(*)) OVER () AS DECIMAL(5,2))
FROM facturacion.facturas GROUP BY estado_f;
GO

-- 5) Tasa de crecimiento: citas y facturacion por mes (meses ya transcurridos)
SELECT DATEFROMPARTS(YEAR(c.fecha_c), MONTH(c.fecha_c), 1) AS mes,
       COUNT_BIG(*)                                        AS citas,
       SUM(CASE WHEN c.estado_c = N'Completada' THEN 1 ELSE 0 END) AS citas_completadas,
       SUM(f.total_f)                                      AS facturado
FROM clinica.citas c
LEFT JOIN facturacion.facturas f ON f.id_cita = c.id_cita
WHERE c.fecha_c < SYSDATETIME()
GROUP BY DATEFROMPARTS(YEAR(c.fecha_c), MONTH(c.fecha_c), 1)
ORDER BY mes;
GO

-- 5b) Promedio mensual del ultimo año (base para proyectar)
SELECT CAST(COUNT_BIG(*) / 12.0 AS DECIMAL(10,1)) AS citas_por_mes_ultimo_anio
FROM clinica.citas
WHERE fecha_c >= DATEADD(YEAR, -1, SYSDATETIME()) AND fecha_c < SYSDATETIME();
GO

-- 6) Tamaño del ultimo backup (sin comprimir y comprimido)
SELECT TOP (3)
    backup_finish_date,
    CAST(backup_size / 1048576.0 AS DECIMAL(10,2))            AS sin_comprimir_mb,
    CAST(compressed_backup_size / 1048576.0 AS DECIMAL(10,2)) AS comprimido_mb,
    CAST(1.0 * backup_size / NULLIF(compressed_backup_size, 0) AS DECIMAL(6,2)) AS ratio
FROM msdb.dbo.backupset
WHERE database_name = N'db_veterinaria' AND type = 'D'
ORDER BY backup_finish_date DESC;
GO

-- EXTRA) Por tabla: filas, datos, índices y bytes por fila
SELECT s.name AS esquema, t.name AS tabla,
       SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.row_count END) AS filas,
       CAST(SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.used_page_count END) * 8 / 1024.0 AS DECIMAL(10,2)) AS datos_mb,
       CAST(ISNULL(SUM(CASE WHEN ps.index_id > 1 THEN ps.used_page_count END), 0) * 8 / 1024.0 AS DECIMAL(10,2)) AS indices_mb,
       CAST(SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.used_page_count END) * 8192.0
            / NULLIF(SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.row_count END), 0) AS DECIMAL(10,1)) AS bytes_por_fila
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.dm_db_partition_stats ps ON ps.object_id = t.object_id
GROUP BY s.name, t.name
ORDER BY datos_mb DESC;

-- EXTRA) Archivos de la base (tamaño asignado en disco)
SELECT name AS archivo, type_desc AS tipo,
       CAST(size * 8 / 1024.0 AS DECIMAL(10,2)) AS tamanio_mb
FROM sys.database_files;

-- EXTRA) Filas de cada esquema y tablas
USE db_veterinaria;
SELECT s.name AS esquema, t.name AS tabla,
       SUM(ps.row_count) AS filas
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.dm_db_partition_stats ps
  ON ps.object_id = t.object_id AND ps.index_id IN (0,1)
GROUP BY s.name, t.name
ORDER BY filas, s.name, t.name;

USE db_veterinaria;
SELECT
 (SELECT COUNT_BIG(*) FROM pacientes.propietarios) AS propietarios,
 (SELECT COUNT_BIG(*) FROM pacientes.mascotas)     AS mascotas,
 (SELECT COUNT_BIG(*) FROM clinica.citas)          AS citas,
 (SELECT COUNT_BIG(*) FROM facturacion.facturas)   AS facturas,
 (SELECT SUM(costo_c) FROM clinica.citas)          AS suma_costo_citas,
 (SELECT SUM(total_f) FROM facturacion.facturas)   AS suma_total_facturas;