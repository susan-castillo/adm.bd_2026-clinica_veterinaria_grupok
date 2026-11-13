USE [master];
GO


--TAIL-LOG BACKUP (hacer SIEMPRE antes de restaurar)
-- Base ONLINE y sana: la deja en estado RESTORING (nadie más escribe)
BACKUP LOG [db_veterinaria]
TO DISK = N'/backup/db_veterinaria/LOG/db_veterinaria_TAIL_20261112_120000.trn' --el nombre es editable
GO

-- Base DAÑADA (.mdf inaccesible): usa esta variante en lugar de la anterior
-- BACKUP LOG [db_veterinaria]
-- TO DISK = N'/backup/db_veterinaria/LOG/db_veterinaria_TAIL_20261112_120000.trn'
-- WITH NO_TRUNCATE, CONTINUE_AFTER_ERROR, INIT, STATS = 10;
-- GO


-- SCRIPT DE RESTAURACIÓN CASO A.
-- Base de datos: db_veterinaria

-- 1. Restaurar el último respaldo COMPLETO (FULL)
RESTORE DATABASE [db_veterinaria]
FROM DISK = N'/backup/db_veterinaria/FULL/db_veterinaria_FULL_20261104_211836.bak' --cambiar por mas reciente
WITH NORECOVERY, REPLACE, STATS = 10;
GO

-- 2. Restaurar el último respaldo DIFERENCIAL (DIFF) posterior al FULL
RESTORE DATABASE [db_veterinaria]
FROM DISK = N'/backup/db_veterinaria/DIFF/db_veterinaria_DIFF_20261104_220305.bak' -- cambiar por mas reciente
WITH NORECOVERY, STATS = 10;
GO

-- 3. Restaurar únicamente el respaldo de LOG más reciente
RESTORE LOG [db_veterinaria]
FROM DISK = N'/backup/db_veterinaria/LOG/db_veterinaria_LOG_20261104_220530.trn' -- cambiar por mas reciente
WITH NORECOVERY;
GO

-- NUEVO: 3.1 Restaurar el TAIL-LOG (último de la cadena, antes del RECOVERY)
-- Opcional: agrega STOPAT = '2026-11-12 11:59:00' para detenerte en un momento específico
RESTORE LOG [db_veterinaria]
FROM DISK = N'/backup/db_veterinaria/LOG/db_veterinaria_TAIL_20261112_120000.trn'
WITH NORECOVERY;
GO

-- 4. Poner la base de datos en línea (RECOVERY) para que sea operable
RESTORE DATABASE [db_veterinaria] WITH RECOVERY;
GO

-- ============================================================
-- SCRIPT DE RESTAURACIÓN - CASO B: 
-- Implementar backups (FULL -> DIFF -> LOG) en una base de 
-- datos vacía ya creada previamente llamada [db_copia].


-- 1. Restaurar el respaldo COMPLETO (FULL) en [db_copia]
create database db_copia
GO

RESTORE DATABASE [db_copia]
FROM DISK = N'/backup/db_veterinaria/FULL/db_veterinaria_FULL_20261111_002426.bak'
WITH NORECOVERY, REPLACE, STATS = 10,
     MOVE N'db_veterinaria'     TO N'/var/opt/mssql/data/db_copia.mdf',
     MOVE N'db_veterinaria_log' TO N'/var/opt/mssql/data/db_copia_log.ldf';
GO

-- 2. Restaurar el último respaldo DIFERENCIAL (DIFF) posterior al FULL en [db_copia]
RESTORE DATABASE [db_copia]
FROM DISK = N'/backup/db_veterinaria/DIFF/db_veterinaria_DIFF_20261111_002449.bak'
WITH NORECOVERY, STATS = 10;
GO

-- 3. Restaurar únicamente el respaldo de LOG más reciente en [db_copia]
RESTORE LOG [db_copia]
FROM DISK = N'/backup/db_veterinaria/LOG/db_veterinaria_LOG_20261111_004501.trn'
WITH NORECOVERY;
GO

-- NUEVO: 3.1 Restaurar el TAIL-LOG en [db_copia] (antes del RECOVERY)
RESTORE LOG [db_copia]
FROM DISK = N'/backup/db_veterinaria/LOG/db_veterinaria_TAIL_20261112_120000.trn' --debe coincidir con el creado al inicio.
WITH NORECOVERY;
GO

-- 4. Poner la base de datos en línea (RECOVERY) para que sea operable
RESTORE DATABASE [db_copia] WITH RECOVERY;
GO



-- ============================================================
-- VERIFICACIONES POST-RESTAURACIÓN (Aplicadas a [db_copia])
-- ============================================================

USE [db_copia];
GO

-- A. Verificar la integridad física y lógica de la base de datos
DBCC CHECKDB (N'db_copia') WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO

-- B. Verificar el conteo de registros de todas tus tablas organizadas por esquema
SELECT 'clinica.citas' AS tabla, COUNT(*) AS filas FROM clinica.citas
UNION ALL SELECT 'clinica.detalles_tratamientos', COUNT(*) FROM clinica.detalles_tratamientos
UNION ALL SELECT 'clinica.diagnosticos', COUNT(*) FROM clinica.diagnosticos
UNION ALL SELECT 'clinica.procedimientos', COUNT(*) FROM clinica.procedimientos
UNION ALL SELECT 'clinica.tratamiento', COUNT(*) FROM clinica.tratamiento
UNION ALL SELECT 'facturacion.detalles_facturas', COUNT(*) FROM facturacion.detalles_facturas
UNION ALL SELECT 'facturacion.facturas', COUNT(*) FROM facturacion.facturas
UNION ALL SELECT 'farmacia.medicamentos', COUNT(*) FROM farmacia.medicamentos
UNION ALL SELECT 'pacientes.especies', COUNT(*) FROM pacientes.especies
UNION ALL SELECT 'pacientes.mascotas', COUNT(*) FROM pacientes.mascotas
UNION ALL SELECT 'pacientes.propietarios', COUNT(*) FROM pacientes.propietarios
UNION ALL SELECT 'pacientes.razas', COUNT(*) FROM pacientes.razas
UNION ALL SELECT 'personal.especialidades', COUNT(*) FROM personal.especialidades
UNION ALL SELECT 'personal.veterinario', COUNT(*) FROM personal.veterinario;
GO

-- C. Comprobar que los triggers, funciones y procedimientos almacenados viajaron correctamente
SELECT name, type_desc 
FROM sys.objects 
WHERE type IN ('TR', 'FN', 'IF', 'P') 
ORDER BY type_desc, name;
GO

-- ============================================================
-- VERIFICACIONES POST-RESTAURACIÓN (BASE NORMAL)
-- ============================================================

USE [db_veterinaria];
GO

-- A. Verificar la integridad física y lógica de la base de datos
DBCC CHECKDB (N'db_veterinaria') WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO

-- B. Verificar el conteo de registros de todas tus tablas organizadas por esquema
SELECT 'clinica.citas' AS tabla, COUNT(*) AS filas FROM clinica.citas
UNION ALL SELECT 'clinica.detalles_tratamientos', COUNT(*) FROM clinica.detalles_tratamientos
UNION ALL SELECT 'clinica.diagnosticos', COUNT(*) FROM clinica.diagnosticos
UNION ALL SELECT 'clinica.procedimientos', COUNT(*) FROM clinica.procedimientos
UNION ALL SELECT 'clinica.tratamiento', COUNT(*) FROM clinica.tratamiento
UNION ALL SELECT 'facturacion.detalles_facturas', COUNT(*) FROM facturacion.detalles_facturas
UNION ALL SELECT 'facturacion.facturas', COUNT(*) FROM facturacion.facturas
UNION ALL SELECT 'farmacia.medicamentos', COUNT(*) FROM farmacia.medicamentos
UNION ALL SELECT 'pacientes.especies', COUNT(*) FROM pacientes.especies
UNION ALL SELECT 'pacientes.mascotas', COUNT(*) FROM pacientes.mascotas
UNION ALL SELECT 'pacientes.propietarios', COUNT(*) FROM pacientes.propietarios
UNION ALL SELECT 'pacientes.razas', COUNT(*) FROM pacientes.razas
UNION ALL SELECT 'personal.especialidades', COUNT(*) FROM personal.especialidades
UNION ALL SELECT 'personal.veterinario', COUNT(*) FROM personal.veterinario;
GO

-- C. Comprobar que los triggers, funciones y procedimientos almacenados viajaron correctamente
SELECT name, type_desc 
FROM sys.objects 
WHERE type IN ('TR', 'FN', 'IF', 'P') 
ORDER BY type_desc, name;
GO