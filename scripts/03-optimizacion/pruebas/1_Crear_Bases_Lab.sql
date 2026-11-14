/*
LABORATORIO (Seccion 3): crea las dos bases de demostracion.
  db_vet_lab_sin_indices : solo el .bak (linea base)
  db_vet_lab_con_indices : .bak + los 3 indices filtrados del diseño final
Este script NO toca db_veterinaria (nunca la nombra).
Requisitos: .bak ya copiado al contenedor (README_Restore.md, paso 1)
            y conexion a master con el usuario sa.
Se puede re-ejecutar: reemplaza las dos bases de laboratorio.
*/
USE master;
GO

-- ============================================================
-- 1. db_vet_lab_sin_indices
-- ============================================================
IF DB_ID(N'db_vet_lab_sin_indices') IS NOT NULL
    ALTER DATABASE db_vet_lab_sin_indices SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
RESTORE DATABASE db_vet_lab_sin_indices
FROM DISK = N'/var/opt/mssql/data/DataBase_UpdatedData.bak'
WITH REPLACE, RECOVERY,
     MOVE N'db_veterinaria'     TO N'/var/opt/mssql/data/db_vet_lab_sin_indices.mdf',
     MOVE N'db_veterinaria_log' TO N'/var/opt/mssql/data/db_vet_lab_sin_indices_log.ldf',
     STATS = 10;
GO
ALTER DATABASE db_vet_lab_sin_indices SET MULTI_USER;
ALTER DATABASE db_vet_lab_sin_indices SET RECOVERY FULL;
GO

-- ============================================================
-- 2. db_vet_lab_con_indices (restauracion)
-- ============================================================
IF DB_ID(N'db_vet_lab_con_indices') IS NOT NULL
    ALTER DATABASE db_vet_lab_con_indices SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
RESTORE DATABASE db_vet_lab_con_indices
FROM DISK = N'/var/opt/mssql/data/DataBase_UpdatedData.bak'
WITH REPLACE, RECOVERY,
     MOVE N'db_veterinaria'     TO N'/var/opt/mssql/data/db_vet_lab_con_indices.mdf',
     MOVE N'db_veterinaria_log' TO N'/var/opt/mssql/data/db_vet_lab_con_indices_log.ldf',
     STATS = 10;
GO
ALTER DATABASE db_vet_lab_con_indices SET MULTI_USER;
ALTER DATABASE db_vet_lab_con_indices SET RECOVERY FULL;
GO

-- ============================================================
-- 3. db_vet_lab_con_indices: diseño final (identico a 2_Indices.sql, seccion 2)
-- ============================================================
USE db_vet_lab_con_indices;
GO
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
GO

-- C1
CREATE NONCLUSTERED INDEX ix_citas_comp_fecha
ON clinica.citas (fecha_c) INCLUDE (id_veterinario, costo_c)
WHERE estado_c = N'Completada';
GO

-- C2
CREATE NONCLUSTERED INDEX ix_citas_comp_mascota_fecha
ON clinica.citas (id_mascota, fecha_c)
WHERE estado_c = N'Completada';
GO

-- C3
CREATE NONCLUSTERED INDEX ix_facturas_pagada_fecha
ON facturacion.facturas (fecha_emision_f) INCLUDE (total_f)
WHERE estado_f = N'Pagada';
GO

-- ============================================================
-- 4. Estadisticas parejas en las dos bases
-- ============================================================
USE db_vet_lab_sin_indices;
GO
UPDATE STATISTICS clinica.citas        WITH FULLSCAN;
UPDATE STATISTICS facturacion.facturas WITH FULLSCAN;
UPDATE STATISTICS pacientes.mascotas   WITH FULLSCAN;
UPDATE STATISTICS personal.veterinario WITH FULLSCAN;
GO
USE db_vet_lab_con_indices;
GO
UPDATE STATISTICS clinica.citas        WITH FULLSCAN;
UPDATE STATISTICS facturacion.facturas WITH FULLSCAN;
UPDATE STATISTICS pacientes.mascotas   WITH FULLSCAN;
UPDATE STATISTICS personal.veterinario WITH FULLSCAN;
GO

-- ============================================================
-- 5. VERIFICACION
-- ============================================================
USE master;
GO

-- 5.1 Datos (README_Restore.md): deben dar OK en las dos bases
SELECT base, propietarios, mascotas, citas, facturas, suma_costo_citas, suma_total_facturas,
       CASE WHEN propietarios = 5882 AND mascotas = 10000 AND citas = 100000
             AND facturas = 76283 AND suma_costo_citas = 2452858.00
             AND suma_total_facturas = 4430201.90
            THEN N'OK' ELSE N'REVISAR' END AS verificacion
FROM (
    SELECT N'db_vet_lab_sin_indices' AS base,
        (SELECT COUNT_BIG(*) FROM db_vet_lab_sin_indices.pacientes.propietarios) AS propietarios,
        (SELECT COUNT_BIG(*) FROM db_vet_lab_sin_indices.pacientes.mascotas)     AS mascotas,
        (SELECT COUNT_BIG(*) FROM db_vet_lab_sin_indices.clinica.citas)          AS citas,
        (SELECT COUNT_BIG(*) FROM db_vet_lab_sin_indices.facturacion.facturas)   AS facturas,
        (SELECT SUM(costo_c)  FROM db_vet_lab_sin_indices.clinica.citas)         AS suma_costo_citas,
        (SELECT SUM(total_f)  FROM db_vet_lab_sin_indices.facturacion.facturas)  AS suma_total_facturas
    UNION ALL
    SELECT N'db_vet_lab_con_indices',
        (SELECT COUNT_BIG(*) FROM db_vet_lab_con_indices.pacientes.propietarios),
        (SELECT COUNT_BIG(*) FROM db_vet_lab_con_indices.pacientes.mascotas),
        (SELECT COUNT_BIG(*) FROM db_vet_lab_con_indices.clinica.citas),
        (SELECT COUNT_BIG(*) FROM db_vet_lab_con_indices.facturacion.facturas),
        (SELECT SUM(costo_c)  FROM db_vet_lab_con_indices.clinica.citas),
        (SELECT SUM(total_f)  FROM db_vet_lab_con_indices.facturacion.facturas)
) t;
GO

-- 5.2 Cantidad de indices ix_*: esperado 0 (sin indices) y 3 (con indices)
SELECT N'db_vet_lab_sin_indices' AS base, COUNT(*) AS indices_ix
FROM db_vet_lab_sin_indices.sys.indexes i JOIN db_vet_lab_sin_indices.sys.objects o ON o.object_id = i.object_id AND o.type = N'U' WHERE i.name LIKE N'ix[_]%'
UNION ALL
SELECT N'db_vet_lab_con_indices', COUNT(*)
FROM db_vet_lab_con_indices.sys.indexes i JOIN db_vet_lab_con_indices.sys.objects o ON o.object_id = i.object_id AND o.type = N'U' WHERE i.name LIKE N'ix[_]%';
GO

-- 5.3 Tamaño de los indices (esperado en medicion conjunta: 3.43 / 2.69 / 1.75 MB, total 7.87)
USE db_vet_lab_con_indices;
GO
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
