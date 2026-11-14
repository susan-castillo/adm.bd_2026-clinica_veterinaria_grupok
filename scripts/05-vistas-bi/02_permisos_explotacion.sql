-- 1. Cambiar el contexto a master para no autobloquear la base de datos
USE master;
GO

-- 2. Forzar el bloqueo exclusivo desconectando sesiones activas
ALTER DATABASE db_veterinaria SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

-- 3. Habilitar la contención parcial
ALTER DATABASE db_veterinaria SET CONTAINMENT = PARTIAL;
GO

-- 4. Volver a habilitar el acceso multiusuario
ALTER DATABASE db_veterinaria SET MULTI_USER;
GO

-- 5. Regresar al contexto de la base de datos de la veterinaria
USE db_veterinaria;
GO

-- 6. Otorgar permisos SELECT de lectura explícita sobre el esquema 'bi'
GRANT SELECT ON SCHEMA::bi TO rol_desarrollador_bi;
GO

-- Eliminar el usuario creado con WITHOUT LOGIN
DROP USER IF EXISTS usuario_powerbi;
GO

-- 7. Creación del usuario para Power BI con su contraseña
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usuario_powerbi')
    BEGIN
        CREATE USER usuario_powerbi WITH PASSWORD = 'Admin123!';
    END
GO
-- 8. Vinculación al rol de reportes/BI para que herede los permisos SELECT
ALTER ROLE rol_desarrollador_bi ADD MEMBER usuario_powerbi;
GO
