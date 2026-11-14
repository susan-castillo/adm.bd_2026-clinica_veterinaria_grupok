-- ROLES Y PRIVILEGIOS - VETERINARIA

-- 0. ROL PERSONALIZADO DE SERVIDOR: CREACION DE BASES
USE master;
GO
CREATE SERVER ROLE rol_creador_bases;
GO
GRANT CREATE ANY DATABASE TO rol_creador_bases;
GO

-- 1. Crear los esquemas (estan en el ddl).
USE db_veterinaria;
GO

-- 2. Crear los cinco roles.
CREATE ROLE rol_recepcion;
CREATE ROLE rol_veterinario;
CREATE ROLE rol_facturacion;
CREATE ROLE rol_inventario;
CREATE ROLE rol_reportes_bi;
GO

-- 2.1 Crear los tres roles de desarrollo.
CREATE ROLE rol_desarrollador;
CREATE ROLE rol_arquitecto_datos;
CREATE ROLE rol_desarrollador_bi;
GO

-- 2.2 Crear cuatro roles administrativos de base de datos.
-- El quinto, rol_creador_bases, se creo en master como rol de servidor.
CREATE ROLE rol_administrador_seguridad;
CREATE ROLE rol_operador_respaldos;
CREATE ROLE rol_operador_recuperacion;
CREATE ROLE rol_auditor_seguridad;
GO

-- 2.3 Crear rol de lectura para el profesor.
CREATE ROLE rol_profesor_lectura;
GO

-- 3. Crear usuarios de prueba y asignarlos a los roles.
-- WITHOUT LOGIN permite probar con EXECUTE AS USER; no permite iniciar sesion.
CREATE USER usuario_recepcion WITHOUT LOGIN;
ALTER ROLE rol_recepcion ADD MEMBER usuario_recepcion;

CREATE USER usuario_veterinario WITHOUT LOGIN;
ALTER ROLE rol_veterinario ADD MEMBER usuario_veterinario;

CREATE USER usuario_facturacion WITHOUT LOGIN;
ALTER ROLE rol_facturacion ADD MEMBER usuario_facturacion;

CREATE USER usuario_inventario WITHOUT LOGIN;
ALTER ROLE rol_inventario ADD MEMBER usuario_inventario;

CREATE USER usuario_reportes WITHOUT LOGIN;
ALTER ROLE rol_reportes_bi ADD MEMBER usuario_reportes;

GO

CREATE USER usuario_desarrollador WITHOUT LOGIN;
ALTER ROLE rol_desarrollador ADD MEMBER usuario_desarrollador;

CREATE USER usuario_arquitecto WITHOUT LOGIN;
ALTER ROLE rol_arquitecto_datos ADD MEMBER usuario_arquitecto;

CREATE USER usuario_desarrollador_bi WITHOUT LOGIN;
ALTER ROLE rol_desarrollador_bi ADD MEMBER usuario_desarrollador_bi;
GO


CREATE USER usuario_seguridad WITHOUT LOGIN;
ALTER ROLE rol_administrador_seguridad ADD MEMBER usuario_seguridad;

CREATE USER usuario_respaldos WITHOUT LOGIN;
ALTER ROLE rol_operador_respaldos ADD MEMBER usuario_respaldos;

CREATE USER usuario_recuperacion WITHOUT LOGIN;
ALTER ROLE rol_operador_recuperacion ADD MEMBER usuario_recuperacion;

CREATE USER usuario_auditor WITHOUT LOGIN;
ALTER ROLE rol_auditor_seguridad ADD MEMBER usuario_auditor;
GO


CREATE USER usuario_profesor WITHOUT LOGIN;
ALTER ROLE rol_profesor_lectura ADD MEMBER usuario_profesor;
GO


-- 4. Permisos de recepcion.
GRANT SELECT, INSERT, UPDATE ON pacientes.propietarios TO rol_recepcion;
GRANT SELECT, INSERT, UPDATE ON pacientes.mascotas TO rol_recepcion;
GRANT SELECT, INSERT, UPDATE ON clinica.citas TO rol_recepcion;
GRANT SELECT ON pacientes.especies TO rol_recepcion;
GRANT SELECT ON pacientes.razas TO rol_recepcion;
GRANT SELECT ON personal.veterinario TO rol_recepcion;
GRANT SELECT ON personal.especialidades TO rol_recepcion;
GO

-- 5. Permisos de veterinario.
GRANT SELECT ON pacientes.propietarios TO rol_veterinario;
GRANT SELECT ON pacientes.mascotas TO rol_veterinario;
GRANT SELECT ON pacientes.especies TO rol_veterinario;
GRANT SELECT ON pacientes.razas TO rol_veterinario;
GRANT SELECT ON personal.veterinario TO rol_veterinario;
GRANT SELECT ON personal.especialidades TO rol_veterinario;
GRANT SELECT ON clinica.citas TO rol_veterinario;
GRANT SELECT ON farmacia.medicamentos TO rol_veterinario;
GRANT UPDATE ON clinica.citas (estado_c) TO rol_veterinario;
GRANT SELECT, INSERT, UPDATE ON clinica.diagnosticos TO rol_veterinario;
GRANT SELECT, INSERT, UPDATE ON clinica.procedimientos TO rol_veterinario;
GRANT SELECT, INSERT, UPDATE ON clinica.tratamiento TO rol_veterinario;
GRANT SELECT, INSERT, UPDATE ON clinica.detalles_tratamientos TO rol_veterinario;
GO

-- 6. Permisos de facturacion.
GRANT SELECT ON pacientes.propietarios (id_propietario,dui_p,nombre_p,apellido_p,correo_p) TO rol_facturacion;
GRANT SELECT ON pacientes.mascotas (id_mascota,id_propietario,nombre_m) TO rol_facturacion;
GRANT SELECT ON clinica.citas (id_cita,id_mascota,fecha_c,estado_c,costo_c) TO rol_facturacion;
GRANT SELECT ON clinica.procedimientos (id_procedimiento,nombre_p,costo_p) TO rol_facturacion;
GRANT SELECT ON clinica.tratamiento (id_tratamiento) TO rol_facturacion;
GRANT SELECT ON farmacia.medicamentos (id_medicamento,nombre_m,presentacion_m,precio_m) TO rol_facturacion;
GRANT SELECT, INSERT, UPDATE ON facturacion.facturas TO rol_facturacion;
GRANT SELECT, INSERT, UPDATE ON facturacion.detalles_facturas TO rol_facturacion;
GO

-- 7. Permisos de inventario.
GRANT SELECT, INSERT, UPDATE ON farmacia.medicamentos TO rol_inventario;
GO

-- 7.1 Permisos de desarrollador: objetos de programacion y datos de prueba.
GRANT CREATE PROCEDURE, CREATE FUNCTION, CREATE VIEW TO rol_desarrollador;
GRANT SELECT ON clinica.diagnosticos TO rol_desarrollador;
GRANT SELECT ON clinica.tratamiento TO rol_desarrollador;
GRANT INSERT, UPDATE ON clinica.diagnosticos TO rol_desarrollador;
GRANT INSERT, UPDATE ON clinica.tratamiento TO rol_desarrollador;
GO

-- 7.2 Permisos de arquitecto: DDL sobre esquemas autorizados.
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION TO rol_arquitecto_datos;
GRANT ALTER ON SCHEMA::pacientes TO rol_arquitecto_datos;
GRANT ALTER ON SCHEMA::personal TO rol_arquitecto_datos;
GRANT ALTER ON SCHEMA::clinica TO rol_arquitecto_datos;
GRANT ALTER ON SCHEMA::farmacia TO rol_arquitecto_datos;
GRANT ALTER ON SCHEMA::facturacion TO rol_arquitecto_datos;
-- ALTER sobre esquema es potente: permite alterar/eliminar objetos del esquema.
-- CREATE SCHEMA y modificaciones globales requieren un proceso separado.
GO

-- 7.3 Permisos del desarrollador BI.
-- Requiere que el esquema bi exista (se crea si no existe).
IF SCHEMA_ID(N'bi') IS NULL EXEC(N'CREATE SCHEMA bi AUTHORIZATION dbo');
GO
GRANT CREATE VIEW TO rol_desarrollador_bi;
GRANT ALTER ON SCHEMA::bi TO rol_desarrollador_bi;
-- Solo lectura de origen a traves de vistas autorizadas.
-- Las vistas operativas concretas deben concederse explicitamente.
-- No se otorgan SELECT indiscriminados sobre tablas con datos sensibles.
GO

-- 7.4 Administrador de seguridad: usuarios, roles y membresias.
GRANT ALTER ANY USER TO rol_administrador_seguridad;
GRANT CREATE ROLE TO rol_administrador_seguridad;
GRANT ALTER ANY ROLE TO rol_administrador_seguridad;
-- No se concede CONTROL, db_owner ni GRANT general de permisos de datos.
-- Las concesiones de permisos sobre objetos requieren una cuenta autorizada
-- o un proceso separado con privilegios y revision especificos.
GO

-- 7.5 Operador de respaldos: FULL, DIFFERENTIAL y LOG cuando aplique.
GRANT BACKUP DATABASE TO rol_operador_respaldos;
GRANT BACKUP LOG TO rol_operador_respaldos;
GO

-- 7.6 Operador de recuperacion.
-- SQL Server NO tiene GRANT RESTORE DATABASE a nivel de base.
-- No se asignan privilegios peligrosos de db_owner o sysadmin.
-- El usuario solicita la restauracion y un administrador autorizado la
-- ejecuta con un procedimiento operativo supervisado.

-- 7.7 Auditor: lectura de auditorias mediante permisos especificos de servidor.
-- La consulta de archivos de auditoria se configura por separado, a nivel
-- de servidor, segun la version SQL Server y las politicas de acceso.
-- No se otorgan permisos de modificar ni desactivar auditorias.

-- 7.8 Profesor: SELECT sobre esquemas operativos y BI.
GRANT SELECT ON SCHEMA::pacientes TO rol_profesor_lectura;
GRANT SELECT ON SCHEMA::personal TO rol_profesor_lectura;
GRANT SELECT ON SCHEMA::clinica TO rol_profesor_lectura;
GRANT SELECT ON SCHEMA::farmacia TO rol_profesor_lectura;
GRANT SELECT ON SCHEMA::facturacion TO rol_profesor_lectura;
GRANT SELECT ON SCHEMA::bi TO rol_profesor_lectura;
GO



-- 8. Prohibir eliminaciones a los cinco roles.
DENY DELETE ON SCHEMA::pacientes
TO rol_recepcion, rol_veterinario, rol_facturacion, rol_inventario, rol_reportes_bi;
DENY DELETE ON SCHEMA::personal
TO rol_recepcion, rol_veterinario, rol_facturacion, rol_inventario, rol_reportes_bi;
DENY DELETE ON SCHEMA::clinica
TO rol_recepcion, rol_veterinario, rol_facturacion, rol_inventario, rol_reportes_bi;
DENY DELETE ON SCHEMA::farmacia
TO rol_recepcion, rol_veterinario, rol_facturacion, rol_inventario, rol_reportes_bi;
DENY DELETE ON SCHEMA::facturacion
TO rol_recepcion, rol_veterinario, rol_facturacion, rol_inventario, rol_reportes_bi;
GO

-- 8.1 Prohibir modificaciones de datos operativos al profesor.
DENY INSERT, UPDATE, DELETE ON SCHEMA::pacientes TO rol_profesor_lectura;
DENY INSERT, UPDATE, DELETE ON SCHEMA::personal TO rol_profesor_lectura;
DENY INSERT, UPDATE, DELETE ON SCHEMA::clinica TO rol_profesor_lectura;
DENY INSERT, UPDATE, DELETE ON SCHEMA::farmacia TO rol_profesor_lectura;
DENY INSERT, UPDATE, DELETE ON SCHEMA::facturacion TO rol_profesor_lectura;
GO


-- 9. Pruebas de suplantacion.
-- Las pruebas negativas deben mostrar un error de permisos.
-- Ejecutar cada prueba completa, incluido REVERT para regresar al administrador.
-- WHERE 1=0 comprueba permisos sin modificar filas.
-- Estas pruebas presuponen una base de laboratorio sin triggers con efectos externos.

-- recepcion: acceso permitido.
EXECUTE AS USER = 'usuario_recepcion';
GO
SELECT USER_NAME() AS usuario_actual;
SELECT TOP (5) * FROM pacientes.propietarios;
GO
REVERT;
GO

-- recepcion: acceso denegado.
EXECUTE AS USER = 'usuario_recepcion';
GO
SELECT USER_NAME() AS usuario_actual;
SELECT TOP (5) * FROM clinica.diagnosticos;
GO
REVERT;
GO

-- veterinario: acceso permitido.
EXECUTE AS USER = 'usuario_veterinario';
GO
SELECT USER_NAME() AS usuario_actual;
UPDATE clinica.citas SET estado_c=estado_c WHERE 1=0;
GO
REVERT;
GO

-- veterinario: acceso denegado.
EXECUTE AS USER = 'usuario_veterinario';
GO
SELECT USER_NAME() AS usuario_actual;
UPDATE clinica.citas SET costo_c=costo_c WHERE 1=0;
GO
REVERT;
GO

-- facturacion: acceso permitido.
EXECUTE AS USER = 'usuario_facturacion';
GO
SELECT USER_NAME() AS usuario_actual;
SELECT TOP (5) id_propietario,dui_p,nombre_p,apellido_p,correo_p FROM pacientes.propietarios;
GO
REVERT;
GO

-- facturacion: acceso denegado.
EXECUTE AS USER = 'usuario_facturacion';
GO
SELECT USER_NAME() AS usuario_actual;
DELETE FROM facturacion.facturas WHERE 1=0;
GO
REVERT;
GO

-- inventario: acceso permitido.
EXECUTE AS USER = 'usuario_inventario';
GO
SELECT USER_NAME() AS usuario_actual;
SELECT TOP (5) * FROM farmacia.medicamentos;
GO
REVERT;
GO

-- inventario: acceso denegado.
EXECUTE AS USER = 'usuario_inventario';
GO
SELECT USER_NAME() AS usuario_actual;
SELECT TOP (5) * FROM pacientes.propietarios;
GO
REVERT;
GO

-- reportes BI: acceso denegado.
EXECUTE AS USER = 'usuario_reportes';
GO
SELECT TOP (5) * FROM pacientes.propietarios;
GO
REVERT;
GO

-- desarrollador: permitido.
EXECUTE AS USER = 'usuario_desarrollador';
GO
SELECT USER_NAME() AS usuario_actual;
SELECT TOP (5) * FROM clinica.diagnosticos;
SELECT HAS_PERMS_BY_NAME('clinica.diagnosticos', 'OBJECT', 'UPDATE') AS puede_actualizar;
GO
REVERT;
GO

-- desarrollador: denegado.
EXECUTE AS USER = 'usuario_desarrollador';
GO
DELETE FROM clinica.diagnosticos WHERE 1=0;
GO
REVERT;
GO

-- arquitecto: permitido (permiso DDL, sin modificar objetos).
EXECUTE AS USER = 'usuario_arquitecto';
GO
SELECT HAS_PERMS_BY_NAME('clinica', 'SCHEMA', 'ALTER') AS puede_alterar_clinica;
GO
REVERT;
GO

-- arquitecto: denegado (sin permiso de lectura de datos).
EXECUTE AS USER = 'usuario_arquitecto';
GO
SELECT TOP (5) * FROM pacientes.propietarios;
GO
REVERT;
GO

-- desarrollador BI: permitido.
EXECUTE AS USER = 'usuario_desarrollador_bi';
GO
SELECT HAS_PERMS_BY_NAME('bi', 'SCHEMA', 'ALTER') AS puede_modificar_vistas_bi;
GO
REVERT;
GO

-- desarrollador BI: denegado.
EXECUTE AS USER = 'usuario_desarrollador_bi';
GO
UPDATE farmacia.medicamentos SET stock_m = stock_m WHERE 1=0;
GO
REVERT;
GO

-- administrador de seguridad: permitido.
EXECUTE AS USER = 'usuario_seguridad';
GO
SELECT HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'ALTER ANY USER') AS puede_gestionar_usuarios;
GO
REVERT;
GO

-- administrador de seguridad: denegado.
EXECUTE AS USER = 'usuario_seguridad';
GO
SELECT TOP (5) * FROM clinica.diagnosticos;
GO
REVERT;
GO

-- operador respaldos: permitido (comprobacion de permiso).
EXECUTE AS USER = 'usuario_respaldos';
GO
SELECT HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'BACKUP DATABASE') AS puede_hacer_backup;
GO
REVERT;
GO

-- operador respaldos: denegado.
EXECUTE AS USER = 'usuario_respaldos';
GO
SELECT TOP (5) * FROM clinica.diagnosticos;
GO
REVERT;
GO

-- operador recuperacion: puede consultar su identidad, pero NO posee
-- permiso RESTORE directo. La restauracion se tramita por administrador.
EXECUTE AS USER = 'usuario_recuperacion';
GO
SELECT USER_NAME() AS usuario_actual;
SELECT TOP (5) * FROM farmacia.medicamentos; -- denegado
GO
REVERT;
GO

-- auditor: usuario sin permisos sobre datos operativos.
EXECUTE AS USER = 'usuario_auditor';
GO
SELECT USER_NAME() AS usuario_actual;
SELECT TOP (5) * FROM facturacion.facturas; -- denegado
GO
REVERT;
GO

-- profesor: permitido.
EXECUTE AS USER = 'usuario_profesor';
GO
SELECT TOP (5) * FROM pacientes.mascotas;
GO
REVERT;
GO

-- profesor: denegado.
EXECUTE AS USER = 'usuario_profesor';
GO
UPDATE pacientes.mascotas SET nombre_m = nombre_m WHERE 1=0;
GO
REVERT;
GO