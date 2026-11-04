USE [master];
GO

-- 1. Iniciar desde 0: Restaurar el último FULL
RESTORE DATABASE [db_veterinaria]
FROM DISK = N'/backup/db_veterinaria/FULL/TU_ULTIMO_FULL.bak'
WITH NORECOVERY, REPLACE, STATS = 10;
GO

-- 2. Restaurar el último DIFF basado en ese FULL
RESTORE DATABASE [db_veterinaria]
FROM DISK = N'/backup/db_veterinaria/DIFF/TU_ULTIMO_DIFF.bak'
WITH NORECOVERY, STATS = 10;
GO

-- 3. Restaurar TODOS los LOGs generados después del DIFF, en estricto orden cronológico
-- (Aplica el primer log que le sigue al DIFF)
RESTORE LOG [db_veterinaria]
FROM DISK = N'/backup/db_veterinaria/LOG/TU_LOG_INTERMEDIO_1.trn'
WITH NORECOVERY;
GO

-- (Aplica el siguiente log, repite esto por cada archivo hasta llegar al último)
RESTORE LOG [db_veterinaria]
FROM DISK = N'/backup/db_veterinaria/LOG/TU_LOG_INTERMEDIO_2.trn'
WITH NORECOVERY;
GO

-- (Aplica el último log de la cadena)
RESTORE LOG [db_veterinaria]
FROM DISK = N'/backup/db_veterinaria/LOG/TU_ULTIMO_LOG.trn'
WITH NORECOVERY;
GO

-- 4. Poner la base de datos en línea
RESTORE DATABASE [db_veterinaria] WITH RECOVERY;
GO