USE db_veterinaria;

-- 1) Por tabla: filas, datos, índices y bytes por fila
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

-- 2) Archivos de la base (tamaño asignado en disco)
SELECT name AS archivo, type_desc AS tipo,
       CAST(size * 8 / 1024.0 AS DECIMAL(10,2)) AS tamanio_mb
FROM sys.database_files;

-- 3) Filas de cada esquema y tablas
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

USE master;
GO
BACKUP DATABASE db_veterinaria
TO DISK = N'/var/opt/mssql/data/DataBase_UpdatedData.bak'
WITH COPY_ONLY, COMPRESSION, INIT, STATS = 10;
GO