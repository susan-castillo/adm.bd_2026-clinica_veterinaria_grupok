-- ROLES Y PRIVILEGIOS - VETERINARIA
USE db_veterinaria;
GO

-- 1. Crear los esquemas (estan en el ddl).

-- 2. Mover las tablas de dbo a sus esquemas.
-- Actualizar las consultas de la aplicacion que todavia usen dbo.
ALTER SCHEMA pacientes TRANSFER dbo.propietarios;
ALTER SCHEMA pacientes TRANSFER dbo.mascotas;
ALTER SCHEMA pacientes TRANSFER dbo.especies;
ALTER SCHEMA pacientes TRANSFER dbo.razas;
ALTER SCHEMA personal TRANSFER dbo.veterinario;
ALTER SCHEMA personal TRANSFER dbo.especialidades;
ALTER SCHEMA clinica TRANSFER dbo.citas;
ALTER SCHEMA clinica TRANSFER dbo.diagnosticos;
ALTER SCHEMA clinica TRANSFER dbo.procedimientos;
ALTER SCHEMA clinica TRANSFER dbo.tratamiento;
ALTER SCHEMA clinica TRANSFER dbo.detalles_tratamientos;
ALTER SCHEMA farmacia TRANSFER dbo.medicamentos;
ALTER SCHEMA facturacion TRANSFER dbo.facturas;
ALTER SCHEMA facturacion TRANSFER dbo.detalles_facturas;
GO

-- 3. Crear los cinco roles.
CREATE ROLE rol_recepcion;
CREATE ROLE rol_veterinario;
CREATE ROLE rol_facturacion;
CREATE ROLE rol_inventario;
CREATE ROLE rol_reportes;
GO

-- 4. Crear usuarios de prueba y asignarlos a los roles.
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
ALTER ROLE rol_reportes ADD MEMBER usuario_reportes;

GO

-- 5. Permisos de recepcion.
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

-- 5. Permisos de facturacion.
GRANT SELECT ON pacientes.propietarios (id_propietario,dui_p,nombre_p,apellido_p,correo_p) TO rol_facturacion;
GRANT SELECT ON pacientes.mascotas (id_mascota,id_propietario,nombre_m) TO rol_facturacion;
GRANT SELECT ON clinica.citas (id_cita,id_mascota,fecha_c,estado_c,costo_c) TO rol_facturacion;
GRANT SELECT ON clinica.procedimientos (id_procedimiento,nombre_p,costo_p) TO rol_facturacion;
GRANT SELECT ON clinica.tratamiento (id_tratamiento) TO rol_facturacion;
GRANT SELECT ON farmacia.medicamentos (id_medicamento,nombre_m,presentacion_m,precio_m) TO rol_facturacion;
GRANT SELECT, INSERT, UPDATE ON facturacion.facturas TO rol_facturacion;
GRANT SELECT, INSERT, UPDATE ON facturacion.detalles_facturas TO rol_facturacion;
GO

-- 5. Permisos de inventario.
GRANT SELECT, INSERT, UPDATE ON farmacia.medicamentos TO rol_inventario;
GO

-- 6. Crear las vistas de reportes.


-- Permisos de reportes: solo lectura de las vistas que vaya a crear susan
GRANT SELECT ON clinica.v_reporte_citas TO rol_reportes;
GRANT SELECT ON facturacion.v_reporte_ingresos TO rol_reportes;
GRANT SELECT ON clinica.v_reporte_procedimientos TO rol_reportes;
GRANT SELECT ON farmacia.v_reporte_inventario TO rol_reportes;
GO

-- 7. Prohibir eliminaciones a los cinco roles.
DENY DELETE ON SCHEMA::pacientes
TO rol_recepcion, rol_veterinario, rol_facturacion, rol_inventario, rol_reportes;
DENY DELETE ON SCHEMA::personal
TO rol_recepcion, rol_veterinario, rol_facturacion, rol_inventario, rol_reportes;
DENY DELETE ON SCHEMA::clinica
TO rol_recepcion, rol_veterinario, rol_facturacion, rol_inventario, rol_reportes;
DENY DELETE ON SCHEMA::farmacia
TO rol_recepcion, rol_veterinario, rol_facturacion, rol_inventario, rol_reportes;
DENY DELETE ON SCHEMA::facturacion
TO rol_recepcion, rol_veterinario, rol_facturacion, rol_inventario, rol_reportes;
GO

-- 8. Pruebas de suplantacion.
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

-- reportes: acceso permitido.
EXECUTE AS USER = 'usuario_reportes';
GO
SELECT USER_NAME() AS usuario_actual;
SELECT TOP (5) * FROM clinica.v_reporte_citas;
GO
REVERT;
GO

-- reportes: acceso denegado.
EXECUTE AS USER = 'usuario_reportes';
GO
SELECT USER_NAME() AS usuario_actual;
SELECT TOP (5) * FROM clinica.citas;
GO
REVERT;
GO
