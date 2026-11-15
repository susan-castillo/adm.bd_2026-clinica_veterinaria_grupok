-- Cambiar el contexto a master para no autobloquear la base de datos
USE master;
GO

ALTER DATABASE db_veterinaria SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

-- Habilitar la contención parcial
ALTER DATABASE db_veterinaria SET CONTAINMENT = PARTIAL;
GO

-- Volver a habilitar el acceso multiusuario
ALTER DATABASE db_veterinaria SET MULTI_USER;
GO

USE db_veterinaria;
GO

-- 2. Dar permiso de lectura exclusiva sobre las vistas del esquema bi al rol de reportes
GRANT SELECT ON SCHEMA::bi TO rol_reportes_bi;
GO

-- Eliminar el usuario creado con WITHOUT LOGIN
DROP USER IF EXISTS usuario_reportes;
GO

-- Creación del usuario para Power bi con su contraseña
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usuario_reportes')
    BEGIN
        CREATE USER usuario_reportes WITH PASSWORD = 'Admin123!';
    END
GO

ALTER ROLE rol_reportes_bi ADD MEMBER usuario_reportes;
GO
