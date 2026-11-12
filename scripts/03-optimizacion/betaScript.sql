USE master;
GO

BACKUP DATABASE db_veterinaria
TO DISK = '/var/opt/mssql/data/db_veterinaria_base.bak'
WITH INIT, COPY_ONLY;
GO

RESTORE DATABASE veterinaria_perf
FROM DISK = '/var/opt/mssql/data/db_veterinaria_base.bak'
WITH MOVE 'db_veterinaria'     TO '/var/opt/mssql/data/veterinaria_perf.mdf',
     MOVE 'db_veterinaria_log' TO '/var/opt/mssql/data/veterinaria_perf_log.ldf',
     REPLACE;
GO

SELECT name FROM sys.databases WHERE name IN ('db_veterinaria','veterinaria_perf');