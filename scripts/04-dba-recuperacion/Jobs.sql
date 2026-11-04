-
-- JOBS DE RESPALDO - SQL Server Agent
-- Base de datos: db_veterinaria (Fast Paws)
-- Requisitos: SQL Server Agent habilitado (en Docker: MSSQL_AGENT_ENABLED=true),

-- carpetas FULL / DIFF / LOG creadas en el docker: (en poweshell usa el comando)
--docker exec -u root NOMBRE_DEL_CONTENEDOR bash -c 'mkdir -p /backup/db_veterinaria/FULL /backup/db_veterinaria/DIFF /backup/db_veterinaria/LOG && chown -R mssql:root /backup/db_veterinaria && chmod -R 770 /backup/db_veterinaria'.

-- Orden de ejecución: 0) preparación, 1) job FULL, 2) job DIFF, 3) job LOG.


-- 0. PREPARACIÓN (ejecutar una sola vez)
USE [master];
GO
ALTER DATABASE [db_veterinaria] SET RECOVERY FULL;      -- necesario para respaldar el log y restaurar a un punto en el tiempo
ALTER DATABASE [db_veterinaria] SET PAGE_VERIFY CHECKSUM;
GO

-- Tamaño inicial de archivos según el dimensionamiento (año 3 + margen ≈ 18 MB -> 32 MB datos y 32 MB log)
USE [db_veterinaria];
GO
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql += N'ALTER DATABASE [db_veterinaria] MODIFY FILE (NAME = N''' + name
             + N''', SIZE = 32MB, FILEGROWTH = 16MB);' + CHAR(10)
FROM sys.database_files
WHERE type_desc IN (N'ROWS', N'LOG') AND size * 8 / 1024 < 32;   -- size está en páginas de 8 KB
EXEC sys.sp_executesql @sql;
GO

-- ------------------------------------------------------------
-- JOB: FastPaws - Backup FULL semanal
-- Horario: Domingo 01:00

USE [msdb];
GO

DECLARE @job_name SYSNAME       = N'FastPaws - Backup FULL semanal';
DECLARE @dir      NVARCHAR(260) = N'/backup/db_veterinaria/FULL/';

DECLARE @cmd1 NVARCHAR(MAX) = REPLACE(N'DECLARE @db   SYSNAME       = N''db_veterinaria'';
DECLARE @dir  NVARCHAR(260) = N''{{DIR}}'';
DECLARE @ts   CHAR(15)      = CONVERT(CHAR(8), GETDATE(), 112) + ''_'' + REPLACE(CONVERT(CHAR(8), GETDATE(), 108), '':'', '''');
DECLARE @file NVARCHAR(400) = @dir + @db + N''_FULL_'' + @ts + N''.bak'';

BACKUP DATABASE @db
TO DISK = @file
WITH COMPRESSION, CHECKSUM, INIT, STATS = 10,
     NAME = N''db_veterinaria - Full semanal'';', N'{{DIR}}', @dir);
DECLARE @cmd2 NVARCHAR(MAX) = N'DECLARE @db   SYSNAME = N''db_veterinaria'';
DECLARE @file NVARCHAR(400);

SELECT TOP (1) @file = bmf.physical_device_name
FROM msdb.dbo.backupset AS bs
JOIN msdb.dbo.backupmediafamily AS bmf ON bmf.media_set_id = bs.media_set_id
WHERE bs.database_name = @db AND bs.type = ''D''
ORDER BY bs.backup_finish_date DESC;

RESTORE VERIFYONLY FROM DISK = @file WITH CHECKSUM;';

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @job_name)
    EXEC msdb.dbo.sp_delete_job @job_name = @job_name, @delete_unused_schedule = 1;

EXEC msdb.dbo.sp_add_job
    @job_name = @job_name,
    @enabled = 1,
    @description = N'Respaldo completo semanal de db_veterinaria (domingo 01:00). Paso 1: BACKUP DATABASE. Paso 2: RESTORE VERIFYONLY.',
    @category_name = N'Database Maintenance',
    @notify_level_eventlog = 2;          -- registrar en el log de eventos si falla

EXEC msdb.dbo.sp_add_jobstep
    @job_name = @job_name, @step_id = 1,
    @step_name = N'1. Respaldo FULL',
    @subsystem = N'TSQL', @database_name = N'master',
    @command = @cmd1,
    @on_success_action = 3,              -- ir al siguiente paso
    @on_fail_action = 2;                 -- terminar el job con error

EXEC msdb.dbo.sp_add_jobstep
    @job_name = @job_name, @step_id = 2,
    @step_name = N'2. Verificar respaldo (VERIFYONLY)',
    @subsystem = N'TSQL', @database_name = N'master',
    @command = @cmd2,
    @on_success_action = 1,              -- terminar con éxito
    @on_fail_action = 2;

EXEC msdb.dbo.sp_add_jobschedule
    @job_name = @job_name,
    @name = N'Domingo 01:00',
    @enabled = 1,
    @freq_type = 8,                      -- 8 = semanal
    @freq_interval = 1,                 -- 1 = domingo
    @freq_subday_type = 1,                 -- 1 = a la hora indicada
    @freq_subday_interval = 0,
    @freq_recurrence_factor = 1,
    @active_start_time = 10000;                -- HHMMSS

EXEC msdb.dbo.sp_add_jobserver @job_name = @job_name, @server_name = N'(LOCAL)';
GO

-- ------------------------------------------------------------
-- JOB: FastPaws - Backup DIFERENCIAL diario
-- Horario: Lunes a sábado 01:00

USE [msdb];
GO

DECLARE @job_name SYSNAME       = N'FastPaws - Backup DIFERENCIAL diario';
DECLARE @dir      NVARCHAR(260) = N'/backup/db_veterinaria/DIFF/';

DECLARE @cmd1 NVARCHAR(MAX) = REPLACE(N'DECLARE @db   SYSNAME       = N''db_veterinaria'';
DECLARE @dir  NVARCHAR(260) = N''{{DIR}}'';
DECLARE @ts   CHAR(15)      = CONVERT(CHAR(8), GETDATE(), 112) + ''_'' + REPLACE(CONVERT(CHAR(8), GETDATE(), 108), '':'', '''');
DECLARE @file NVARCHAR(400) = @dir + @db + N''_DIFF_'' + @ts + N''.bak'';

BACKUP DATABASE @db
TO DISK = @file
WITH DIFFERENTIAL, COMPRESSION, CHECKSUM, INIT, STATS = 10,
     NAME = N''db_veterinaria - Diferencial diario'';', N'{{DIR}}', @dir);
DECLARE @cmd2 NVARCHAR(MAX) = N'DECLARE @db   SYSNAME = N''db_veterinaria'';
DECLARE @file NVARCHAR(400);

SELECT TOP (1) @file = bmf.physical_device_name
FROM msdb.dbo.backupset AS bs
JOIN msdb.dbo.backupmediafamily AS bmf ON bmf.media_set_id = bs.media_set_id
WHERE bs.database_name = @db AND bs.type = ''I''
ORDER BY bs.backup_finish_date DESC;

RESTORE VERIFYONLY FROM DISK = @file WITH CHECKSUM;';

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @job_name)
    EXEC msdb.dbo.sp_delete_job @job_name = @job_name, @delete_unused_schedule = 1;

EXEC msdb.dbo.sp_add_job
    @job_name = @job_name,
    @enabled = 1,
    @description = N'Respaldo diferencial diario de db_veterinaria (lunes a sábado 01:00). Paso 1: BACKUP DATABASE WITH DIFFERENTIAL. Paso 2: RESTORE VERIFYONLY.',
    @category_name = N'Database Maintenance',
    @notify_level_eventlog = 2;          -- registrar en el log de eventos si falla

EXEC msdb.dbo.sp_add_jobstep
    @job_name = @job_name, @step_id = 1,
    @step_name = N'1. Respaldo DIFF',
    @subsystem = N'TSQL', @database_name = N'master',
    @command = @cmd1,
    @on_success_action = 3,              -- ir al siguiente paso
    @on_fail_action = 2;                 -- terminar el job con error

EXEC msdb.dbo.sp_add_jobstep
    @job_name = @job_name, @step_id = 2,
    @step_name = N'2. Verificar respaldo (VERIFYONLY)',
    @subsystem = N'TSQL', @database_name = N'master',
    @command = @cmd2,
    @on_success_action = 1,              -- terminar con éxito
    @on_fail_action = 2;

EXEC msdb.dbo.sp_add_jobschedule
    @job_name = @job_name,
    @name = N'Lunes a sábado 01:00',
    @enabled = 1,
    @freq_type = 8,                      -- 8 = semanal
    @freq_interval = 126,                 -- 126 = lunes a sábado (2+4+8+16+32+64)
    @freq_subday_type = 1,                 -- 1 = a la hora indicada
    @freq_subday_interval = 0,
    @freq_recurrence_factor = 1,
    @active_start_time = 10000;                -- HHMMSS

EXEC msdb.dbo.sp_add_jobserver @job_name = @job_name, @server_name = N'(LOCAL)';
GO

-- ------------------------------------------------------------
-- JOB: FastPaws - Backup LOG 15 min
-- Horario: Cada 15 minutos

USE [msdb];
GO

DECLARE @job_name SYSNAME       = N'FastPaws - Backup LOG 15 min';
-- Carpeta de destino (debe existir y tener permisos de escritura para la cuenta de SQL Server).
-- Docker/Linux: N'/backup/db_veterinaria/LOG/'   |   Windows: N'D:\Backups\db_veterinaria\LOG\'
DECLARE @dir      NVARCHAR(260) = N'/backup/db_veterinaria/LOG/';

DECLARE @cmd1 NVARCHAR(MAX) = REPLACE(N'DECLARE @db   SYSNAME       = N''db_veterinaria'';
DECLARE @dir  NVARCHAR(260) = N''{{DIR}}'';
DECLARE @ts   CHAR(15)      = CONVERT(CHAR(8), GETDATE(), 112) + ''_'' + REPLACE(CONVERT(CHAR(8), GETDATE(), 108), '':'', '''');
DECLARE @file NVARCHAR(400) = @dir + @db + N''_LOG_'' + @ts + N''.trn'';

BACKUP LOG @db
TO DISK = @file
WITH COMPRESSION, CHECKSUM, INIT,
     NAME = N''db_veterinaria - Log de transacciones'';', N'{{DIR}}', @dir);
DECLARE @cmd2 NVARCHAR(MAX) = N'DECLARE @db   SYSNAME = N''db_veterinaria'';
DECLARE @file NVARCHAR(400);

SELECT TOP (1) @file = bmf.physical_device_name
FROM msdb.dbo.backupset AS bs
JOIN msdb.dbo.backupmediafamily AS bmf ON bmf.media_set_id = bs.media_set_id
WHERE bs.database_name = @db AND bs.type = ''L''
ORDER BY bs.backup_finish_date DESC;

RESTORE VERIFYONLY FROM DISK = @file WITH CHECKSUM;';

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @job_name)
    EXEC msdb.dbo.sp_delete_job @job_name = @job_name, @delete_unused_schedule = 1;

EXEC msdb.dbo.sp_add_job
    @job_name = @job_name,
    @enabled = 1,
    @description = N'Respaldo del log de transacciones de db_veterinaria cada 15 minutos, todos los días. Paso 1: BACKUP LOG. Paso 2: RESTORE VERIFYONLY.',
    @category_name = N'Database Maintenance',
    @notify_level_eventlog = 2;          -- registrar en el log de eventos si falla

EXEC msdb.dbo.sp_add_jobstep
    @job_name = @job_name, @step_id = 1,
    @step_name = N'1. Respaldo LOG',
    @subsystem = N'TSQL', @database_name = N'master',
    @command = @cmd1,
    @on_success_action = 3,              -- ir al siguiente paso
    @on_fail_action = 2;                 -- terminar el job con error

EXEC msdb.dbo.sp_add_jobstep
    @job_name = @job_name, @step_id = 2,
    @step_name = N'2. Verificar respaldo (VERIFYONLY)',
    @subsystem = N'TSQL', @database_name = N'master',
    @command = @cmd2,
    @on_success_action = 1,              -- terminar con éxito
    @on_fail_action = 2;

EXEC msdb.dbo.sp_add_jobschedule
    @job_name = @job_name,
    @name = N'Cada 15 minutos',
    @enabled = 1,
    @freq_type = 4,                      -- 4 = diario
    @freq_interval = 1,                 -- cada 1 día
    @freq_subday_type = 4,                 -- 4 = en minutos
    @freq_subday_interval = 15,
    @freq_recurrence_factor = 1,
    @active_start_time = 0,                -- HHMMSS
    @active_end_time = 235959;                  -- HHMMSS

EXEC msdb.dbo.sp_add_jobserver @job_name = @job_name, @server_name = N'(LOCAL)';
GO

