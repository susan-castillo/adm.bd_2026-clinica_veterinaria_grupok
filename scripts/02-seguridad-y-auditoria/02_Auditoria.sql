-- AUDITORIA - VETERINARIA

-- 1. verifixando que no se haya creado dible.
USE master;
GO

SELECT name
FROM sys.server_audits
WHERE name = 'Audit_Veterinaria_Facturacion';

/* 2. Preparar la carpeta EN WINDOWS, en el equipo donde corre SQL Server:
docker exec sqlserver-2025 mkdir -p /audit/Veterinaria
Y PARA VERIFICARLA 
docker exec sqlserver-2025 ls -ld /audit/Veterinaria
*/

-- 3. Crear la auditoria del servidor.
USE master;
GO
CREATE SERVER AUDIT Audit_Veterinaria_Facturacion
TO FILE (
    FILEPATH = N'/audit/Veterinaria/',
    MAXSIZE = 30 MB,
    MAX_ROLLOVER_FILES = 8
)
WITH (
    QUEUE_DELAY = 1000,
    ON_FAILURE = CONTINUE
);
GO


-- Activar la auditoria.
ALTER SERVER AUDIT Audit_Veterinaria_Facturacion
WITH (STATE = ON);
GO

-- Comprobar que status_desc sea STARTED antes de continuar.
SELECT name, status_desc, audit_file_path
FROM sys.dm_server_audit_status
WHERE name = 'Audit_Veterinaria_Facturacion';
GO

-- 4. Crear la especificacion de la base de datos.
USE db_veterinaria;
GO
CREATE DATABASE AUDIT SPECIFICATION AuditSpec_Veterinaria_Facturacion
FOR SERVER AUDIT Audit_Veterinaria_Facturacion
ADD (INSERT, UPDATE, DELETE ON OBJECT::facturacion.facturas BY public),
ADD (INSERT, UPDATE, DELETE ON OBJECT::facturacion.detalles_facturas BY public)
WITH (STATE = ON);
GO

-- Comprobar que is_state_enabled sea 1.
SELECT name, is_state_enabled
FROM sys.database_audit_specifications
WHERE name = 'AuditSpec_Veterinaria_Facturacion';
GO

-- 5. Generar eventos de prueba.
-- Requiere el usuario creado en 01_Roles_y_privilegios.sql.
-- Ejecutar cada prueba completa, incluido REVERT.
-- WHERE 1=0 prueba permisos sin modificar filas.

-- UPDATE permitido sobre facturas y detalles.
EXECUTE AS USER = 'usuario_facturacion';
GO
UPDATE facturacion.facturas
SET total_f = total_f
WHERE 1=0;

UPDATE facturacion.detalles_facturas
SET cantidad_df = cantidad_df
WHERE 1=0;
GO
REVERT;
GO

-- DELETE denegado: los errores de permisos son el resultado esperado.
EXECUTE AS USER = 'usuario_facturacion';
GO
DELETE FROM facturacion.facturas WHERE 1=0;
GO
DELETE FROM facturacion.detalles_facturas WHERE 1=0;
GO
REVERT;
GO

-- 6. Consultar los registros como administrador.
SELECT
    event_time,
    action_id,
    succeeded,
    server_principal_name,
    database_principal_name,
    database_name,
    schema_name,
    object_name,
    statement
FROM sys.fn_get_audit_file(
    N'/audit/Veterinaria/*.sqlaudit',
    DEFAULT,
    DEFAULT
)
WHERE database_name = DB_NAME()
ORDER BY event_time DESC;
GO

-- BY public incluye a todos los usuarios; no concede permisos.
-- En estos eventos, succeeded indica si paso la comprobacion de permisos,
-- no si se modificaron filas o hubo COMMIT. event_time esta en UTC.
-- INSERT se registrara cuando insertes una factura/detalle valido.
-- ON_FAILURE=CONTINUE permite continuar si falla la escritura del audit.
-- MAX_ROLLOVER_FILES rota archivos antiguos: guardar aparte las evidencias.
