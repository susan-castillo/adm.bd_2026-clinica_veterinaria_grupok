USE [master];
GO


-- SCRIPT DE RESTAURACIÓN
-- Base de datos: db_veterinaria

-- 1. Restaurar el último respaldo COMPLETO (FULL)
RESTORE DATABASE [db_veterinaria]
FROM DISK = N'/backup/db_veterinaria/FULL/db_veterinaria_FULL_20261106_143009.bak' --cambiar por mas reciente
WITH NORECOVERY, REPLACE, STATS = 10;
GO

-- 2. Restaurar el último respaldo DIFERENCIAL (DIFF) posterior al FULL
RESTORE DATABASE [db_veterinaria]
FROM DISK = N'/backup/db_veterinaria/DIFF/db_veterinaria_DIFF_20261106_143033.bak' -- cambiar por mas reciente
WITH NORECOVERY, STATS = 10;
GO

-- 3. Restaurar únicamente el respaldo de LOG más reciente
RESTORE LOG [db_veterinaria]
FROM DISK = N'/backup/db_veterinaria/LOG/db_veterinaria_LOG_20261106_143057.trn' -- cambiar por mas reciente
WITH NORECOVERY;
GO

-- 4. Poner la base de datos en línea (RECOVERY) para que sea operable
RESTORE DATABASE [db_veterinaria] WITH RECOVERY;
GO

-- ============================================================
-- VERIFICACIONES POST-RESTAURACIÓN
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