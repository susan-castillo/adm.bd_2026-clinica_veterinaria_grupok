-- EVIDENCIA DE EJECUCIÓN DE LOS JOBS DE RESPALDO

USE [msdb];
GO

-- 1. Ejecutar los jobs manualmente, en este orden (DIFF y LOG necesitan un FULL previo)
EXEC msdb.dbo.sp_start_job @job_name = N'FastPaws - Backup FULL semanal';
WAITFOR DELAY '00:00:20';     -- aumentar si la base crece
EXEC msdb.dbo.sp_start_job @job_name = N'FastPaws - Backup DIFERENCIAL diario';
WAITFOR DELAY '00:00:20';
EXEC msdb.dbo.sp_start_job @job_name = N'FastPaws - Backup LOG 15 min';
WAITFOR DELAY '00:00:20';
  
SELECT j.name AS job,
       msdb.dbo.agent_datetime(h.run_date, h.run_time) AS inicio,
       STUFF(STUFF(RIGHT('000000' + CAST(h.run_duration AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':') AS duracion,
       CASE h.run_status WHEN 0 THEN 'Fallido' WHEN 1 THEN 'Exitoso' WHEN 2 THEN 'Reintento'
                         WHEN 3 THEN 'Cancelado' ELSE 'En progreso' END AS estado,
       h.message
FROM msdb.dbo.sysjobhistory AS h
JOIN msdb.dbo.sysjobs AS j ON j.job_id = h.job_id
WHERE j.name LIKE N'FastPaws%' AND h.step_id = 0
ORDER BY h.instance_id DESC;
GO


SELECT j.name AS job, h.step_id, h.step_name,
       msdb.dbo.agent_datetime(h.run_date, h.run_time) AS inicio,
       CASE h.run_status WHEN 0 THEN 'Fallido' WHEN 1 THEN 'Exitoso' ELSE 'Otro' END AS estado,
       h.message
FROM msdb.dbo.sysjobhistory AS h
JOIN msdb.dbo.sysjobs AS j ON j.job_id = h.job_id
WHERE j.name LIKE N'FastPaws%' AND h.step_id > 0
ORDER BY h.instance_id DESC;
GO

-- 4. CAPTURA 3: archivos generados (historial de respaldos de msdb)
SELECT TOP (20)
       bs.database_name,
       CASE bs.type WHEN 'D' THEN 'FULL' WHEN 'I' THEN 'DIFERENCIAL' WHEN 'L' THEN 'LOG' END AS tipo,
       bs.backup_start_date, bs.backup_finish_date,
       CAST(bs.backup_size / 1048576.0 AS DECIMAL(10,2)) AS size_mb,
       CAST(bs.compressed_backup_size / 1048576.0 AS DECIMAL(10,2)) AS comprimido_mb,
       bs.has_backup_checksums,
       bmf.physical_device_name AS archivo
FROM msdb.dbo.backupset AS bs
JOIN msdb.dbo.backupmediafamily AS bmf ON bmf.media_set_id = bs.media_set_id
WHERE bs.database_name = N'db_veterinaria'
ORDER BY bs.backup_finish_date DESC;
GO