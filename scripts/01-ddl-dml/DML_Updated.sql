/*
DML_Updated.sql: GENERADOR DE DATOS MASIVOS (solo documentacion, NO ejecutar)

Para tener los datos, restaurar el .bak
(ver README_Restore.md). Ejecutarlo de nuevo daria datos distintos (NEWID) y duplicaria filas.
*/

-- Ejecutar antes 02_Triggers_Veterinaria.sql. Este archivo no crea ni modifica triggers.
USE db_veterinaria;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @RecrearDatos bit = 1;
IF @@TRANCOUNT <> 0
    THROW 51000, N'Ejecute este archivo fuera de otra transacción.', 1;
-- Verificar dependencias antes de borrar o insertar datos.
IF (SELECT COUNT(*) FROM sys.triggers WHERE is_disabled=0 AND object_id IN (
    OBJECT_ID(N'clinica.tr_antes_insertar_detalle_tratamiento'),
    OBJECT_ID(N'facturacion.tr_antes_insertar_detalle_factura'),
    OBJECT_ID(N'facturacion.tr_acumular_total_factura'),
    OBJECT_ID(N'facturacion.tr_actualizar_inventario_farmacia'),
    OBJECT_ID(N'pacientes.tr_validar_fecha_nacimiento_mascota'),
    OBJECT_ID(N'clinica.tr_validar_fecha_cita'),
    OBJECT_ID(N'clinica.tr_validar_fecha_diagnostico'),
    OBJECT_ID(N'facturacion.tr_validar_fecha_emision_factura')
)) <> 8
    THROW 51006, N'Primero ejecute completo 02_Triggers_Veterinaria.sql.', 1;
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE is_disabled=1)
 OR EXISTS (SELECT 1 FROM sys.check_constraints WHERE is_disabled=1)
    THROW 51007, N'Hay restricciones deshabilitadas. Reactívelas y valide los datos antes de cargar.', 1;
BEGIN TRY
BEGIN TRANSACTION;
IF @RecrearDatos = 0 AND (
EXISTS (SELECT 1 FROM facturacion.detalles_facturas) OR
EXISTS (SELECT 1 FROM facturacion.facturas) OR
EXISTS (SELECT 1 FROM clinica.detalles_tratamientos) OR
EXISTS (SELECT 1 FROM clinica.tratamiento) OR
EXISTS (SELECT 1 FROM clinica.procedimientos) OR
EXISTS (SELECT 1 FROM clinica.diagnosticos) OR
EXISTS (SELECT 1 FROM clinica.citas) OR
EXISTS (SELECT 1 FROM pacientes.mascotas) OR
EXISTS (SELECT 1 FROM pacientes.propietarios) OR
EXISTS (SELECT 1 FROM personal.veterinario) OR
EXISTS (SELECT 1 FROM personal.especialidades) OR
EXISTS (SELECT 1 FROM pacientes.razas) OR
EXISTS (SELECT 1 FROM pacientes.especies) OR
EXISTS (SELECT 1 FROM farmacia.medicamentos))
    THROW 51001, N'La base contiene datos. La carga se ha cancelado sin borrarlos.', 1;
IF @RecrearDatos = 1
BEGIN
    -- Evita que al retirar detalles una factura Pagada quede temporalmente en cero.
    UPDATE facturacion.facturas SET estado_f = N'Pendiente' WHERE estado_f = N'Pagada';
    DELETE FROM facturacion.detalles_facturas;
    DELETE FROM facturacion.facturas;
    DELETE FROM clinica.detalles_tratamientos;
    DELETE FROM clinica.tratamiento;
    DELETE FROM clinica.procedimientos;
    DELETE FROM clinica.diagnosticos;
    DELETE FROM clinica.citas;
    DELETE FROM pacientes.mascotas;
    DELETE FROM pacientes.propietarios;
    DELETE FROM personal.veterinario;
    DELETE FROM personal.especialidades;
    DELETE FROM pacientes.razas;
    DELETE FROM pacientes.especies;
    DELETE FROM farmacia.medicamentos;
END;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID(N'facturacion.facturas') AND last_value IS NULL)
    DBCC CHECKIDENT ('facturacion.facturas', RESEED, 1) WITH NO_INFOMSGS;
ELSE
    DBCC CHECKIDENT ('facturacion.facturas', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID(N'clinica.tratamiento') AND last_value IS NULL)
    DBCC CHECKIDENT ('clinica.tratamiento', RESEED, 1) WITH NO_INFOMSGS;
ELSE
    DBCC CHECKIDENT ('clinica.tratamiento', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID(N'clinica.procedimientos') AND last_value IS NULL)
    DBCC CHECKIDENT ('clinica.procedimientos', RESEED, 1) WITH NO_INFOMSGS;
ELSE
    DBCC CHECKIDENT ('clinica.procedimientos', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID(N'clinica.diagnosticos') AND last_value IS NULL)
    DBCC CHECKIDENT ('clinica.diagnosticos', RESEED, 1) WITH NO_INFOMSGS;
ELSE
    DBCC CHECKIDENT ('clinica.diagnosticos', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID(N'clinica.citas') AND last_value IS NULL)
    DBCC CHECKIDENT ('clinica.citas', RESEED, 1) WITH NO_INFOMSGS;
ELSE
    DBCC CHECKIDENT ('clinica.citas', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID(N'pacientes.mascotas') AND last_value IS NULL)
    DBCC CHECKIDENT ('pacientes.mascotas', RESEED, 1) WITH NO_INFOMSGS;
ELSE
    DBCC CHECKIDENT ('pacientes.mascotas', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID(N'pacientes.propietarios') AND last_value IS NULL)
    DBCC CHECKIDENT ('pacientes.propietarios', RESEED, 1) WITH NO_INFOMSGS;
ELSE
    DBCC CHECKIDENT ('pacientes.propietarios', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID(N'personal.veterinario') AND last_value IS NULL)
    DBCC CHECKIDENT ('personal.veterinario', RESEED, 1) WITH NO_INFOMSGS;
ELSE
    DBCC CHECKIDENT ('personal.veterinario', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID(N'personal.especialidades') AND last_value IS NULL)
    DBCC CHECKIDENT ('personal.especialidades', RESEED, 1) WITH NO_INFOMSGS;
ELSE
    DBCC CHECKIDENT ('personal.especialidades', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID(N'pacientes.razas') AND last_value IS NULL)
    DBCC CHECKIDENT ('pacientes.razas', RESEED, 1) WITH NO_INFOMSGS;
ELSE
    DBCC CHECKIDENT ('pacientes.razas', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID(N'pacientes.especies') AND last_value IS NULL)
    DBCC CHECKIDENT ('pacientes.especies', RESEED, 1) WITH NO_INFOMSGS;
ELSE
    DBCC CHECKIDENT ('pacientes.especies', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID(N'farmacia.medicamentos') AND last_value IS NULL)
    DBCC CHECKIDENT ('farmacia.medicamentos', RESEED, 1) WITH NO_INFOMSGS;
ELSE
    DBCC CHECKIDENT ('farmacia.medicamentos', RESEED, 0) WITH NO_INFOMSGS;
-- 1° INSERT: especies (17)
-- ============================================================
INSERT INTO pacientes.especies (nombre_e, descripcion_e)
VALUES ('Can', N'Mamífero doméstico de la familia Canidae, comúnmente conocido como perro.'),
       ('Felino', N'Mamífero de la familia Felidae, incluye gatos domésticos y felinos salvajes.'),
       ('Ave', 'Animal vertebrado de sangre caliente con plumas, pico y alas.'),
       ('Conejo', N'Mamífero herbívoro de orejas largas, comúnmente criado como mascota.'),
       ('Reptil', N'Animal vertebrado de sangre fría con escamas, incluye lagartijas y serpientes.'),
       ('Pez', N'Animal acuático de sangre fría con aletas y branquias.'),
       ('Roedor', N'Mamífero caracterizado por sus incisivos prominentes, incluye hámster y cobaya.'),
       (N'Hurón', N'Mamífero carnívoro domesticado de la familia Mustelidae.'),
       ('Anfibio', 'Animal vertebrado que puede vivir en agua y tierra, como ranas y salamandras.'),
       (N'Équido', N'Mamífero ungulado de la familia Equidae, incluye caballos, burros y ponis.'),
       ('Porcino', N'Mamífero omnívoro doméstico de la familia Suidae, comúnmente conocido como cerdo.'),
       ('Ovejas', N'Mamífero rumiante de la familia Bovidae, comúnmente conocido como oveja.'),
       ('Caprino', N'Mamífero rumiante doméstico de la familia Bovidae, comúnmente conocido como cabra.'),
       ('Ave de corral', N'Aves criadas principalmente para la producción de huevos y carne.'),
       ('Primate', N'Orden de mamíferos que incluye monos y simios, de alta inteligencia.'),
       ('Marsupial', N'Mamífero que da a luz crías inmaduras y las desarrolla en una bolsa ventral.'),
       (N'Arácnido', N'Artrópodo de ocho patas, incluye arañas y escorpiones.');

-- ============================================================
-- 2° INSERT: razas (61)
-- ============================================================
INSERT INTO pacientes.razas (id_especie, nombre_r)
VALUES 
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Can'), 'Labrador Retriever'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Can'), N'Pastor Alemán'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Can'), 'Chihuahua'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Can'), 'Golden Retriever'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Can'), N'Bulldog Francés'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Felino'), N'Siamés'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Felino'), 'Persa'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Felino'), N'Bengalí'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Felino'), 'Maine Coon'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Felino'), 'Angora'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Ave'), 'Loro'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Ave'), 'Canario'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Ave'), N'Cacatúa'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Ave'), 'Periquito'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Ave'), 'Agapornis'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Roedor'), N'Hámster Sirio'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Roedor'), 'Cobaya'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Roedor'), 'Chinchilla'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Roedor'), 'Rata Fancy'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Roedor'), 'Jerbo'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Conejo'), N'Holandés'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Conejo'), 'Angora'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Conejo'), 'Rex'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Conejo'), 'Lionhead'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Conejo'), 'Mini Lop'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Reptil'), N'Dragón Barbudo'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Reptil'), 'Gecko Leopardo'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Reptil'), 'Iguana Verde'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Pez'), 'Betta'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Pez'), 'Goldfish'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Pez'), 'Guppy'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = N'Hurón'), N'Hurón Estándar'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = N'Hurón'), N'Hurón Angora'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = N'Hurón'), N'Hurón Albino'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Anfibio'), 'Axolotl'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Anfibio'), 'Rana Africana'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Anfibio'), 'Salamandra Tigre'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = N'Équido'), N'Caballo Árabe'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = N'Équido'), 'Poni Shetland'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = N'Équido'), 'Burro Andaluz'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Porcino'), 'Cerdo Vietnamita'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Porcino'), 'Duroc'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Porcino'), 'Landrace'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Ovejas'), 'Merino'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Ovejas'), 'Suffolk'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Ovejas'), 'Dorper'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Caprino'), 'Boer'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Caprino'), 'Nubia'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Caprino'), 'Saanen'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Ave de corral'), 'Gallina Leghorn'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Ave de corral'), N'Pato Pekín'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Ave de corral'), 'Pavo Real'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Primate'), N'Tití Común'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Primate'), 'Mono Ardilla'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Primate'), 'Lémur'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Marsupial'), N'Zarigüeya'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Marsupial'), 'Canguro Enano'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = 'Marsupial'), 'Equidna'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = N'Arácnido'), N'Tarántula Rosa'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = N'Arácnido'), N'Escorpión Emperador'),
((SELECT id_especie FROM pacientes.especies WHERE nombre_e = N'Arácnido'), N'Tarántula Patas Rojas');

-- ============================================================
-- 3° INSERT: propietarios (20) - Con captura de IDs para escalabilidad
-- ============================================================
IF OBJECT_ID('tempdb..#TempPropietarios') IS NOT NULL DROP TABLE #TempPropietarios;
CREATE TABLE #TempPropietarios (
    RowID INT IDENTITY(1,1),
    id_propietario INT
);

INSERT INTO pacientes.propietarios (dui_p, nombre_p, apellido_p, genero_p, telefono_p, telefono_secundario_p, correo_p, direccion_p)
OUTPUT INSERTED.id_propietario INTO #TempPropietarios(id_propietario)
VALUES ('01234567-8', 'Adriana', N'Mejía', 'F', '7123-4567', '2234-5678', 'adriana.mejia@gmail.com', N'Colonia Escalón, San Salvador'),
       ('02345678-9', 'Susan', 'Castillo', 'F', '7234-5678', '2345-6789', 'susan.castillo@gmail.com', N'Reparto Los Héroes, San Salvador'),
       ('03456789-0', 'Francisco', N'NoSé', 'M', '7345-6789', '2456-7890', 'francisco.nose@gmail.com', 'Colonia San Benito, San Salvador'),
       ('04567890-1', 'Daniel', 'Echegoyen', 'M', '7456-7890', '2567-8901', 'daniel.echegoyen@gmail.com', N'Urbanización Madre Selva, Antiguo Cuscatlán'),
       ('05678901-2', 'Luis', N'Rodríguez', 'M', '7567-8901', '2678-9012', 'luis.rodriguez@gmail.com', 'Colonia Miramonte, San Salvador'),
       ('06789012-3', 'Laura', N'Pérez', 'F', '7678-9012', '2789-0123', 'laura.perez@gmail.com', N'Residencial Santa Elena, Antiguo Cuscatlán'),
       ('07890123-4', 'Roberto', 'Flores', 'M', '7789-0123', '2890-1234', 'roberto.flores@hotmail.com', 'Colonia Jardines de Guadalupe, San Salvador'),
       ('08901234-5', N'Sofía', N'Chávez', 'F', '7890-1234', '2901-2345', 'sofia.chavez@gmail.com', 'Colonia Maquilishuat, San Salvador'),
       ('09012345-6', 'Diego', N'Ramírez', 'M', '7901-2345', '2012-3456', 'diego.ramirez@gmail.com', N'Urbanización California, Santa Tecla'),
       ('00123456-7', 'Valentina', 'Cruz', 'F', '7012-3456', '2123-4567', 'valentina.cruz@yahoo.com', N'Colonia América, San Salvador'),
       ('11234567-8', 'Miguel', 'Castillo', 'M', '7523-4567', '2334-5678', 'miguel.castillo@gmail.com', 'Reparto Shafick, San Salvador'),
       ('12345678-9', 'Isabella', 'Morales', 'F', '7634-5678', '2445-6789', 'isabella.morales@gmail.com', 'Colonia Universitaria, San Salvador'),
       ('13456789-0', N'Andrés', N'Jiménez', 'M', '7745-6789', '2556-7890', 'andres.jimenez@hotmail.com', 'Residencial Las Colinas, Santa Tecla'),
       ('14567890-1', 'Camila', 'Torres', 'F', '7856-7890', '2667-8901', 'camila.torres@gmail.com', N'Colonia Lomas de San Francisco, Antiguo Cuscatlán'),
       ('15678901-2', 'Fernando', 'Aguilar', 'M', '7967-8901', '2778-9012', 'fernando.aguilar@gmail.com', N'Colonia Centroamérica, San Salvador'),
       ('16789012-3', 'Valeria', N'Vásquez', 'F', '7078-9012', '2889-0123', 'valeria.vasquez@yahoo.com', N'Urbanización Siena, Antiguo Cuscatlán'),
       ('17890123-4', 'Ricardo', 'Mendoza', 'M', '7189-0123', '2990-1234', 'ricardo.mendoza@gmail.com', N'Colonia La Sultana, Antiguo Cuscatlán'),
       ('18901234-5', 'Gabriela', 'Rivas', 'F', '7290-1234', '2101-2345', 'gabriela.rivas@gmail.com', N'Reparto Cucumacayán, San Salvador'),
       ('19012345-6', 'Alejandro', 'Molina', 'M', '7391-2345', '2212-3456', 'alejandro.molina@hotmail.com', N'Colonia Médica, San Salvador'),
       ('10123456-7', 'Daniela', 'Ortiz', 'F', '7492-3456', '2323-4567', 'daniela.ortiz@gmail.com', N'Colonia Escalón, San Salvador');

IF OBJECT_ID('tempdb..#TempRazas') IS NOT NULL DROP TABLE #TempRazas;
CREATE TABLE #TempRazas (nombre_r NVARCHAR(100), id_raza INT);
INSERT INTO #TempRazas (nombre_r, id_raza)
SELECT nombre_r, id_raza FROM pacientes.razas;

-- ============================================================
-- 4° INSERT: mascotas (71) - Escalable con asignación modular rotativa
-- ============================================================
IF OBJECT_ID('tempdb..#MascotasNuevas') IS NOT NULL DROP TABLE #MascotasNuevas;
CREATE TABLE #MascotasNuevas (
    Secuencia INT IDENTITY(1,1),
    nombre_r NVARCHAR(100),
    nombre_m NVARCHAR(100),
    fecha_nacimiento DATE,
    sexo_m VARCHAR(10),
    peso_m DECIMAL(5,2),
    tamanio_m VARCHAR(20)
);

INSERT INTO #MascotasNuevas (nombre_r, nombre_m, fecha_nacimiento, sexo_m, peso_m, tamanio_m)
VALUES
('Labrador Retriever', 'Max', '2021-03-15', 'Macho', 30.5, 'Grande'),
('Labrador Retriever', 'Luna', '2020-07-22', 'Hembra', 28.0, 'Grande'),
(N'Pastor Alemán', 'Rex', '2019-11-10', 'Macho', 35.0, 'Grande'),
(N'Pastor Alemán', 'Nala', '2022-01-05', 'Hembra', 29.5, 'Grande'),
('Chihuahua', 'Tiny', '2023-05-18', 'Macho', 2.1, N'Pequeño'),
('Chihuahua', 'Bella', '2022-09-30', 'Hembra', 1.8, N'Pequeño'),
('Golden Retriever', 'Buddy', '2021-06-12', 'Macho', 32.0, 'Grande'),
('Golden Retriever', 'Daisy', '2020-12-01', 'Hembra', 27.5, 'Grande'),
(N'Bulldog Francés', 'Gordo', '2022-04-20', 'Macho', 12.0, 'Mediano'),
(N'Bulldog Francés', 'Coco', '2023-02-14', 'Hembra', 10.5, 'Mediano'),
(N'Siamés', 'Milo', '2021-08-03', 'Macho', 4.5, 'Mediano'),
(N'Siamés', 'Nube', '2022-11-25', 'Hembra', 3.8, 'Mediano'),
('Persa', 'Pelusa', '2020-03-17', 'Hembra', 4.2, 'Mediano'),
('Persa', 'Simon', '2019-07-09', 'Macho', 5.0, 'Mediano'),
(N'Bengalí', 'Tigre', '2022-06-01', 'Macho', 5.5, 'Mediano'),
(N'Bengalí', 'Mia', '2023-01-19', 'Hembra', 4.0, 'Mediano'),
('Maine Coon', 'Gigante', '2020-09-14', 'Macho', 8.5, 'Grande'),
('Maine Coon', 'Reina', '2021-12-30', 'Hembra', 6.5, 'Grande'),
('Angora', 'Blanca', '2022-03-08', 'Hembra', 3.5, 'Mediano'),
('Angora', 'Fluffy', '2021-10-22', 'Macho', 4.0, 'Mediano'),
('Loro', 'Paco', '2018-05-11', 'Macho', 0.40, N'Pequeño'),
('Loro', 'Verde', '2019-08-23', 'Hembra', 0.30, N'Pequeño'),
('Canario', 'Sol', '2022-02-14', 'Macho', 0.02, N'Pequeño'),
('Canario', 'Pio', '2023-04-01', 'Hembra', 0.02, N'Pequeño'),
(N'Cacatúa', 'Nieve', '2020-11-05', 'Hembra', 0.35, N'Pequeño'),
(N'Cacatúa', 'Rocky', '2019-03-28', 'Macho', 0.40, N'Pequeño'),
('Periquito', 'Azul', '2023-06-10', 'Macho', 0.03, N'Pequeño'),
('Periquito', 'Verdecito', '2022-08-15', 'Hembra', 0.03, N'Pequeño'),
('Agapornis', 'Amor', '2022-01-30', 'Hembra', 0.05, N'Pequeño'),
('Agapornis', 'Pico', '2021-07-17', 'Macho', 0.05, N'Pequeño'),
(N'Hámster Sirio', 'Bolita', '2023-03-12', 'Macho', 0.15, N'Pequeño'),
(N'Hámster Sirio', 'Canela', '2022-10-05', 'Hembra', 0.13, N'Pequeño'),
('Cobaya', 'Manchas', '2021-05-20', 'Macho', 1.10, N'Pequeño'),
('Cobaya', 'Trebol', '2022-07-14', 'Hembra', 0.90, N'Pequeño'),
('Chinchilla', 'Gris', '2020-04-08', 'Macho', 0.60, N'Pequeño'),
('Chinchilla', 'Suave', '2021-09-19', 'Hembra', 0.50, N'Pequeño'),
('Rata Fancy', 'Raton', '2023-01-25', 'Macho', 0.35, N'Pequeño'),
('Rata Fancy', 'Noche', '2022-06-30', 'Hembra', 0.28, N'Pequeño'),
('Jerbo', 'Salto', '2023-05-03', 'Macho', 0.08, N'Pequeño'),
('Jerbo', 'Arena', '2022-11-11', 'Hembra', 0.07, N'Pequeño'),
(N'Holandés', 'Dutch', '2021-02-18', 'Macho', 2.0, N'Pequeño'),
(N'Holandés', 'Mochi', '2022-04-27', 'Hembra', 1.8, N'Pequeño'),
('Angora', 'Algodon', '2020-08-09', 'Macho', 3.5, 'Mediano'),
('Angora', 'Lana', '2021-11-14', 'Hembra', 3.2, 'Mediano'),
('Rex', 'Terciopelo', '2022-07-21', 'Macho', 4.0, 'Mediano'),
('Rex', 'Suavecito', '2023-03-05', 'Hembra', 3.5, 'Mediano'),
('Lionhead', 'Melena', '2022-09-16', 'Macho', 1.8, N'Pequeño'),
('Lionhead', 'Leon', '2021-04-02', 'Hembra', 1.6, N'Pequeño'),
('Mini Lop', 'Orejon', '2023-02-28', 'Macho', 2.2, N'Pequeño'),
('Mini Lop', 'Floppy', '2022-06-13', 'Hembra', 2.0, N'Pequeño'),
(N'Dragón Barbudo', 'Spike', '2021-01-15', 'Macho', 0.45, 'Mediano'),
('Gecko Leopardo', 'Spot', '2022-03-22', 'Hembra', 0.07, N'Pequeño'),
('Iguana Verde', 'Verde', '2020-06-30', 'Macho', 3.50, 'Grande'),
('Betta', 'Escarlata', '2023-01-10', 'Macho', 0.01, N'Pequeño'),
('Goldfish', 'Naranja', '2022-05-18', 'Hembra', 0.05, N'Pequeño'),
('Guppy', 'Colores', '2023-04-05', 'Macho', 0.01, N'Pequeño'),
(N'Hurón Estándar', 'Bandido', '2021-09-07', 'Macho', 1.2, N'Pequeño'),
(N'Hurón Angora', 'Pelin', '2022-12-19', 'Hembra', 0.9, N'Pequeño'),
(N'Hurón Albino', 'Blanco', '2023-02-01', 'Macho', 1.0, N'Pequeño'),
('Axolotl', 'Axo', '2022-08-14', 'Macho', 0.3, N'Pequeño'),
('Rana Africana', 'Croac', '2021-11-28', 'Hembra', 0.08, N'Pequeño'),
('Salamandra Tigre', 'Tigresa', '2020-07-03', 'Hembra', 0.12, N'Pequeño'),
(N'Caballo Árabe', 'Trueno', '2018-03-25', 'Macho', 450, 'Grande'),
('Poni Shetland', 'Pony', '2019-10-11', 'Hembra', 180, 'Mediano'),
('Burro Andaluz', 'Burrito', '2017-06-16', 'Macho', 200, 'Mediano'),
('Cerdo Vietnamita', 'Chanchito', '2021-04-14', 'Macho', 45, 'Mediano'),
('Duroc', 'Rosado', '2020-01-22', 'Hembra', 120, 'Grande'),
('Landrace', 'Oink', '2019-08-30', 'Macho', 150, 'Grande'),
('Merino', 'Lana', '2020-11-17', 'Hembra', 55, 'Mediano'),
('Suffolk', 'Negrita', '2021-03-04', 'Hembra', 70, 'Mediano'),
('Dorper', 'Borrego', '2022-07-09', 'Macho', 65, 'Mediano');

DECLARE @TP INT = (SELECT COUNT(*) FROM #TempPropietarios);

SET IDENTITY_INSERT pacientes.mascotas ON;
INSERT INTO pacientes.mascotas (id_mascota, id_propietario, id_raza, nombre_m, fecha_nacimiento, sexo_m, peso_m, tamanio_m)
SELECT 
    mn.Secuencia,
    (SELECT id_propietario FROM #TempPropietarios WHERE id_propietario = ((mn.Secuencia - 1) % @TP) + 1),
    r.id_raza,
    mn.nombre_m,
    mn.fecha_nacimiento,
    mn.sexo_m,
    mn.peso_m,
    mn.tamanio_m
FROM #MascotasNuevas mn
INNER JOIN #TempRazas r ON mn.nombre_r = r.nombre_r
INNER JOIN pacientes.razas rr ON rr.id_raza = r.id_raza
INNER JOIN pacientes.especies ee ON ee.id_especie = rr.id_especie
WHERE mn.nombre_r <> N'Angora'
   OR (mn.nombre_m IN (N'Blanca', N'Fluffy') AND ee.nombre_e = N'Felino')
   OR (mn.nombre_m IN (N'Algodon', N'Lana') AND ee.nombre_e = N'Conejo');

SET IDENTITY_INSERT pacientes.mascotas OFF;
DROP TABLE #MascotasNuevas;
DROP TABLE #TempRazas;
DROP TABLE #TempPropietarios;

-- ============================================================
-- 5° INSERT: especialidades (20)
-- ============================================================
INSERT INTO personal.especialidades (nombre_esp, descripcion_esp)
VALUES ('Medicina General Veterinaria', N'Atención médica integral para animales domésticos.'),
       (N'Cirugía Veterinaria', N'Procedimientos quirúrgicos preventivos y correctivos.'),
       (N'Dermatología Veterinaria', N'Diagnóstico y tratamiento de enfermedades de la piel.'),
       (N'Odontología Veterinaria', N'Prevención y tratamiento de enfermedades dentales.'),
       (N'Cardiología Veterinaria', N'Diagnóstico y tratamiento de enfermedades cardiovasculares.'),
       (N'Neurología Veterinaria', N'Atención de trastornos del sistema nervioso.'),
       (N'Oftalmología Veterinaria', N'Diagnóstico y tratamiento de enfermedades oculares.'),
       (N'Oncología Veterinaria', N'Diagnóstico y tratamiento del cáncer en animales.'),
       (N'Traumatología Veterinaria', N'Tratamiento de fracturas y lesiones musculoesqueléticas.'),
       ('Ortopedia Veterinaria', N'Corrección y tratamiento de problemas óseos y articulares.'),
       ('Medicina Interna Veterinaria', N'Diagnóstico y tratamiento de enfermedades complejas.'),
       (N'Nutrición Veterinaria', 'Planes alimenticios y control nutricional.'),
       (N'Etología Veterinaria', 'Estudio y tratamiento de problemas de comportamiento animal.'),
       (N'Anestesiología Veterinaria', N'Administración y monitoreo de anestesia.'),
       ('Medicina Preventiva', N'Vacunación, desparasitación y control sanitario.'),
       ('Reproducción Animal', 'Manejo reproductivo y fertilidad animal.'),
       (N'Medicina de Animales Exóticos', N'Atención de reptiles, aves y pequeños mamíferos.'),
       ('Urgencias Veterinarias', N'Atención de emergencias médicas y quirúrgicas.'),
       ('Diagnóstico por Imágenes', N'Radiografías, ecografías y otros estudios diagnósticos.'),
       ('Fisioterapia y Rehabilitación', N'Recuperación funcional tras lesiones o cirugías.');

-- ============================================================
-- 6° INSERT: veterinario (40)
-- ============================================================
INSERT INTO personal.veterinario (id_especialidad, nombre_v, apellido_v, telefono_v, correo_v)
VALUES ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = 'Medicina General Veterinaria'), 'Carlos', N'Martínez', '7000-0001', 'carlos.martinez@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = 'Medicina General Veterinaria'), 'Laura', 'Torres', '7000-0002', 'laura.torres@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Cirugía Veterinaria'), 'Ana', N'López', '7000-0003', 'ana.lopez@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Cirugía Veterinaria'), 'Javier', 'Castillo', '7000-0004', 'javier.castillo@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Dermatología Veterinaria'), 'Jorge', N'Ramírez', '7000-0005', 'jorge.ramirez@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Dermatología Veterinaria'), 'Daniela', 'Romero', '7000-0006', 'daniela.romero@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Odontología Veterinaria'), N'Sofía', 'Castro', '7000-0007', 'sofia.castro@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Odontología Veterinaria'), N'Andrés', 'Flores', '7000-0008', 'andres.flores@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Cardiología Veterinaria'), 'Ricardo', 'Mendoza', '7000-0009', 'ricardo.mendoza@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Cardiología Veterinaria'), 'Patricia', 'Vega', '7000-0010', 'patricia.vega@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Neurología Veterinaria'), 'Miguel', 'Herrera', '7000-0011', 'miguel.herrera@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Neurología Veterinaria'), 'Valeria', 'Reyes', '7000-0012', 'valeria.reyes@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Oftalmología Veterinaria'), 'Diego', 'Silva', '7000-0013', 'diego.silva@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Oftalmología Veterinaria'), N'María', 'Campos', '7000-0014', 'maria.campos@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Oncología Veterinaria'), 'Fernando', 'Vega', '7000-0015', 'fernando.vega@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Oncología Veterinaria'), 'Gabriela', 'Morales', '7000-0016', 'gabriela.morales@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Traumatología Veterinaria'), 'Eduardo', 'Cruz', '7000-0017', 'eduardo.cruz@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Traumatología Veterinaria'), 'Andrea', 'Navarro', '7000-0018', 'andrea.navarro@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = 'Ortopedia Veterinaria'), 'Luis', N'Pérez', '7000-0019', 'luis.perez@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = 'Ortopedia Veterinaria'), 'Karen', 'Rivas', '7000-0020', 'karen.rivas@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = 'Medicina Interna Veterinaria'), N'Óscar', 'Ruiz', '7000-0021', 'oscar.ruiz@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = 'Medicina Interna Veterinaria'), N'Lucía', N'Benítez', '7000-0022', 'lucia.benitez@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Nutrición Veterinaria'), 'Roberto', 'Aguilar', '7000-0023', 'roberto.aguilar@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Nutrición Veterinaria'), 'Paula', N'Gómez', '7000-0024', 'paula.gomez@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Etología Veterinaria'), N'Tomás', 'Molina', '7000-0025', 'tomas.molina@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Etología Veterinaria'), 'Camila', 'Ortiz', '7000-0026', 'camila.ortiz@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Anestesiología Veterinaria'), N'Raúl', 'Fuentes', '7000-0027', 'raul.fuentes@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Anestesiología Veterinaria'), 'Natalia', 'Arias', '7000-0028', 'natalia.arias@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = 'Medicina Preventiva'), N'Héctor', 'Salazar', '7000-0029', 'hector.salazar@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = 'Medicina Preventiva'), 'Elena', N'Mejía', '7000-0030', 'elena.mejia@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Reproducción Animal'), 'Samuel', 'Castillo', '7000-0031', 'samuel.castillo@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Reproducción Animal'), N'Verónica', 'Lara', '7000-0032', 'veronica.lara@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Medicina de Animales Exóticos'), 'Esteban', 'Santos', '7000-0033', 'esteban.santos@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Medicina de Animales Exóticos'), 'Tatiana', 'Rojas', '7000-0034', 'tatiana.rojas@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = 'Urgencias Veterinarias'), N'Iván', N'Peña', '7000-0035', 'ivan.pena@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = 'Urgencias Veterinarias'), N'Mónica', 'Vargas', '7000-0036', 'monica.vargas@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Diagnóstico por Imágenes'), 'Roberto', N'León', '7000-0037', 'roberto.leon@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Diagnóstico por Imágenes'), 'Melissa', 'Pineda', '7000-0038', 'melissa.pineda@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Fisioterapia y Rehabilitación'), 'Cristian', N'Durán', '7000-0039', 'cristian.duran@veterinaria.com'),
       ((SELECT id_especialidad FROM personal.especialidades WHERE nombre_esp = N'Fisioterapia y Rehabilitación'), 'Alejandra', 'Escobar', '7000-0040', 'alejandra.escobar@veterinaria.com');

-- ============================================================
-- 7° INSERT: medicamentos (30)
-- ============================================================
INSERT INTO farmacia.medicamentos (nombre_m, presentacion_m, laboratorio_m, precio_m, stock_m)
VALUES ('Epiotic Complete', N'Suspensión ótica 125ml', 'Virbac', 18.50, 25),
       ('Synulox Tablets', N'Blíster 10 tabletas 250mg', 'Zoetis', 14.25, 40),
       ('Metonil Jarabe', 'Frasco 30ml', 'Calox', 8.00, 30),
       ('Bravecto Perros', 'Tableta masticable 20-40kg', 'MSD', 38.00, 15),
       ('Simparica Trio', 'Tableta masticable 5-10kg', 'Zoetis', 22.00, 20),
       ('Doxitabs', N'Blíster 10 tabletas 100mg', 'Veterina', 9.50, 50),
       ('Tobramicina Gotas', 'Frasco gotero ophthalmic', 'Laboratorios', 7.50, 25),
       (N'Meloxicam Solución', 'Frasco gotas 10ml 0.5%', 'Drag Pharma', 11.20, 35),
       ('Enrofloxacina', N'Blíster 10 tabletas 150mg', 'Calox', 12.00, 45),
       ('Fortekor 5mg', 'Caja 28 tabletas', 'Elanco', 29.50, 12),
       (N'Malaseb Champú', 'Frasco 250ml', 'Dermavet', 24.00, 18),
       ('Drontal Plus', 'Tableta individual', 'Elanco', 4.50, 100),
       ('NexGard Spectra', 'Tableta masticable 2-3.5kg', 'Boehringer', 19.75, 22),
       ('Clindamicina', N'Caja 16 cápsulas 150mg', 'Drag Pharma', 13.10, 30),
       ('Ketosteril Vet', 'Caja 100 tabletas', 'Fresenius', 55.00, 8),
       ('Prednisolona 5mg', N'Blíster 10 tabletas', 'Calox', 4.20, 60),
       ('Cranberry Urinary', 'Frasco 60 tabletas mastic', 'Nutri-Vet', 21.50, 14),
       ('Tramadol Gotas', 'Frasco gotero 20ml', 'Drag Pharma', 13.40, 28),
       ('Amoxicilina + AC', N'Frasco suspensión 60ml', 'Zoetis', 16.50, 35),
       ('Canisulta', N'Ungüento dérmico 15g', 'Veterina', 9.00, 40),
       ('Cerenia', 'Caja 4 tabletas 24mg', 'Zoetis', 27.50, 18),
       ('Apoquel', 'Caja 20 tabletas 16mg', 'Zoetis', 48.00, 12),
       (N'Aureomicina Oftálmica', 'Tubo 3.5g', 'Pfizer', 11.50, 25),
       ('Baytril', N'Blíster 10 tabletas 50mg', 'Elanco', 18.75, 30),
       ('Omeprazol Vet', N'Caja 14 cápsulas 20mg', 'Calox', 9.80, 40),
       ('Lactato de Ringer', 'Bolsa 500ml', 'Baxter', 6.50, 60),
       ('Atopica', N'Caja 15 cápsulas 50mg', 'Elanco', 62.00, 10),
       ('Rimadyl', N'Blíster 14 tabletas 50mg', 'Zoetis', 26.00, 22),
       ('Metronidazol Vet', 'Caja 20 tabletas 250mg', 'Drag Pharma', 14.50, 35),
       (N'Mupirocina Ungüento', 'Tubo 15g', 'Calox', 8.90, 28);

-- ============================================================
-- 8° INSERT: citas (50)
-- ============================================================
INSERT INTO clinica.citas (id_mascota, id_veterinario, fecha_c, motivo_c, estado_c, costo_c)
VALUES 
       (1, 1, '2025-01-10 09:00:00', 'Consulta general', 'Completada', 20.00),
       (2, 2, '2025-01-15 10:30:00', N'Vacunación anual', 'Completada', 25.00),
       (3, 3, '2025-01-20 14:00:00', 'Control de peso', 'Completada', 18.00),
       (4, 4, '2025-01-25 11:00:00', N'Desparasitación', 'Completada', 15.00),
       (5, 5, '2025-02-01 09:30:00', 'Chequeo preventivo', 'Completada', 22.00),
       (6, 6, '2025-02-05 15:00:00', N'Consulta dermatológica', 'Completada', 30.00),
       (7, 7, '2025-02-10 10:00:00', 'Control de crecimiento', 'Completada', 20.00),
       (8, 8, '2025-02-15 13:30:00', N'Revisión general', 'Completada', 20.00),
       (9, 9, '2025-02-20 08:00:00', 'Problema respiratorio', 'Completada', 35.00),
       (10, 10, '2025-02-25 16:00:00', 'Control nutricional', 'Completada', 25.00),
       (11, 11, '2025-03-02 09:00:00', N'Vacunación de refuerzo', 'Completada', 25.00),
       (12, 12, '2025-03-06 11:00:00', 'Consulta general', 'Completada', 20.00),
       (13, 13, '2025-03-10 14:00:00', N'Revisión ocular', 'Completada', 30.00),
       (14, 14, '2025-03-15 10:30:00', 'Control postoperatorio', 'Completada', 40.00),
       (15, 15, '2025-03-20 15:30:00', 'Chequeo preventivo', 'Completada', 22.00),
       (16, 16, '2025-03-25 09:15:00', N'Evaluación cardiológica', 'Completada', 45.00),
       (17, 17, '2025-04-01 13:00:00', N'Revisión de rutina', 'Completada', 20.00),
       (18, 18, '2025-04-05 11:45:00', 'Control de peso', 'Completada', 18.00),
       (19, 19, '2025-04-10 10:00:00', 'Consulta por alergia', 'Completada', 35.00),
       (20, 20, '2025-04-15 16:30:00', N'Desparasitación', 'Completada', 15.00),
       (21, 21, '2025-04-20 09:00:00', N'Vacunación anual', 'Completada', 25.00),
       (22, 22, '2025-04-25 14:30:00', 'Consulta general', 'Completada', 20.00),
       (23, 23, '2025-05-01 10:15:00', 'Chequeo preventivo', 'Completada', 22.00),
       (24, 24, '2025-05-05 15:00:00', 'Problema digestivo', 'Completada', 32.00),
       (25, 25, '2025-05-10 09:45:00', 'Control de crecimiento', 'Completada', 20.00),
       (26, 26, '2025-05-15 11:30:00', N'Consulta dermatológica', 'Completada', 30.00),
       (27, 27, '2025-05-20 13:00:00', N'Revisión general', 'Completada', 20.00),
       (28, 28, '2025-05-25 16:00:00', 'Control nutricional', 'Completada', 25.00),
       (29, 29, '2025-06-01 08:30:00', N'Evaluación médica', 'Completada', 28.00),
       (30, 30, '2025-06-05 14:00:00', 'Consulta preventiva', 'Completada', 20.00),
       (31, 31, '2025-06-10 10:00:00', N'Vacunación anual', 'Completada', 25.00),
       (32, 32, '2025-06-15 15:30:00', 'Control de peso', 'Completada', 18.00),
       (33, 33, '2025-06-20 09:15:00', 'Chequeo preventivo', 'Completada', 22.00),
       (34, 34, '2025-06-25 11:45:00', 'Consulta general', 'Completada', 20.00),
       (35, 35, '2025-06-28 14:30:00', N'Revisión post tratamiento', 'Completada', 30.00),
       (36, 1, '2026-06-01 09:00:00', 'Tratamiento en seguimiento', 'En curso', 35.00),
       (37, 2, '2026-06-02 11:00:00', N'Recuperación postoperatoria', 'En curso', 50.00),
       (38, 3, '2026-06-03 15:00:00', 'Control especializado', 'En curso', 40.00),
       (39, 4, '2026-06-04 10:00:00', N'Evaluación médica continua', 'En curso', 30.00),
       (40, 5, '2026-06-05 13:00:00', N'Monitoreo clínico', 'En curso', 28.00),
       (41, 6, '2025-07-10 09:00:00', 'Cita cancelada por propietario', 'Cancelada', 0.00),
       (42, 7, '2025-08-15 11:00:00', N'Cancelación por emergencia', 'Cancelada', 0.00),
       (43, 8, '2025-09-05 14:00:00', N'Reprogramación solicitada', 'Cancelada', 0.00),
       (44, 9, '2025-10-20 10:30:00', 'Ausencia del propietario', 'Cancelada', 0.00),
       (45, 10, '2025-11-12 15:00:00', N'Cancelación administrativa', 'Cancelada', 0.00),
       (46, 11, DATEADD(DAY, 2, GETDATE()), N'Vacunación programada', 'Programada', 25.00),
       (47, 12, DATEADD(DAY, 5, GETDATE()), 'Chequeo preventivo programado', 'Programada', 20.00),
       (48, 13, DATEADD(DAY, 8, GETDATE()), 'Control de peso programado', 'Programada', 18.00),
       (49, 14, DATEADD(DAY, 10, GETDATE()), 'Consulta de seguimiento', 'Programada', 30.00),
       (50, 15, DATEADD(DAY, 17, GETDATE()), N'Evaluación médica programada', 'Programada', 22.00);

-- ============================================================
-- 9° INSERT: diagnósticos (40)
-- ============================================================
INSERT INTO clinica.diagnosticos (id_cita, descripcion_d, observaciones_d, fecha_d)
VALUES 
       (1, 'Otitis externa bilateral', N'Presencia de ácaros y secreción de mal olor.', '2025-01-10'),
       (2, N'Paciente sano para vacunación', N'Sin hallazgos clínicos anormales.', '2025-01-15'),
       (3, 'Obesidad grado I', N'Se recomienda estrictamente cambio a dieta metabólica.', '2025-01-20'),
       (4, 'Gastroenteritis bacteriana', N'Presenta deshidratación leve del 5%.', '2025-01-25'),
       (5, 'Chequeo de rutina conforme', N'Mascota activa con buena condición corporal.', '2025-02-01'),
       (6, N'Dermatitis alérgica por pulga (DAPP)', N'Lesiones alopécicas en la zona lumbosacra.', '2025-02-05'),
       (7, 'Control de cachorro en desarrollo', N'Dentición decidua completa y sana.', '2025-02-10'),
       (8, 'Revisión general preventiva', 'Linfonodos normales, mucosas rosadas.', '2025-02-15'),
       (9, N'Infección respiratoria felina (Calicivirus)', N'Úlceras linguales leves y estornudos.', '2025-02-20'),
       (10, 'Control nutricional avanzado', 'Monitoreo de porcentaje de grasa corporal.', '2025-02-25'),
       (11, N'Refuerzo de vacuna quíntuple', N'Paciente apto para inmunización.', '2025-03-02'),
       (12, 'Conjuntivitis bacteriana severa', N'Secreción purulenta en ojo izquierdo.', '2025-03-06'),
       (13, 'Ulcera corneal superficial', 'Ojo derecho afectado por rascado violento.', '2025-03-10'),
       (14, N'Fractura de fémur izquierdo', 'Traumatismo por atropellamiento vial.', '2025-03-15'),
       (15, N'Evaluación geriátrica preventiva', 'Monitoreo de articulaciones por edad.', '2025-03-20'),
       (16, N'Soplo cardíaco grado II/VI', N'Cardiomiopatía hipertrófica en fase inicial.', '2025-03-25'),
       (17, N'Revisión periódica clínica', 'Sin alteraciones aparentes en sistemas.', '2025-04-01'),
       (18, 'Control de peso semestral', N'Evolución favorable en pérdida de peso.', '2025-04-05'),
       (19, 'Dermatitis por Malassezia', N'Infección micótica secundaria en pliegues.', '2025-04-10'),
       (20, 'Desparasitación cuatrimestral', 'Tratamiento preventivo antiparasitario.', '2025-04-15'),
       (21, N'Infección respiratoria felina (Calicivirus)', N'Estornudos frecuentes y secreción nasal serosa bilateral.', '2026-06-14'),
       (22, 'Bronquitis aguda canina', 'Tos productiva persistente con sibilancias leves al auscultarse.',  '2026-06-10'),
       (23, 'Traqueobronquitis infecciosa (Tos de las perreras)','Tos seca en accesos, sin fiebre asociada al momento del examen.', '2026-06-01'),
       (24, N'Dermatitis alérgica por pulga (DAPP)', N'Lesiones eritematosas en región inguinal y base de la cola.', '2026-06-08'),
       (25, 'Dermatitis por Malassezia', N'Infección micótica con prurito intenso en pliegues cutáneos.', '2026-06-09'),
       (26, N'Sarna sarcóptica', N'Infestación moderada con costras en pabellones auriculares.', '2026-06-02'),
       (27, N'Paciente apto para vacunación anual', N'Sin hallazgos clínicos anormales previos a la inmunización.', '2026-06-08'),
       (28, 'Refuerzo de vacuna polivalente canina', N'Titer bajo detectado en control previo; revacunación indicada.', '2026-06-14'),
       (29, 'Gastroenteritis aguda', N'Vómitos y diarrea de 48 horas de evolución, hidratación conservada.','2026-06-12'),
       (30, N'Colitis crónica reagudizada', 'Heces con moco y sangre fresca; dieta blanda estricta indicada.', '2026-06-11'),
       (31, 'Mascota en buen estado general.', 'Continuar con controles preventivos cada 6 meses.', '2026-06-15'),
       (32, N'Esquema de vacunación completado.', N'Aplicar próxima vacuna según calendario.', '2026-06-15'),
       (33, 'Leve sobrepeso detectado.', 'Dieta balanceada y ejercicio diario durante 30 minutos.', '2026-06-16'),
       (34, 'Gastroenteritis leve.', N'Dieta blanda y medicación durante 5 días.', '2026-06-16'),
       (35, N'Dermatitis alérgica.', N'Aplicar crema dermatológica y evitar alérgenos.', '2026-06-16'),
       (36, N'Recuperación favorable después de cirugía.', N'Reposo y revisión en 7 días.', '2026-06-17'),
       (37, N'Cicatrización adecuada.', N'Retirar puntos en la próxima consulta.', '2026-06-17'),
       (38, N'Sin hallazgos clínicos importantes.', 'Mantener controles preventivos.', '2026-06-17'),
       (39, N'Infección respiratoria leve.', N'Antibióticos y reposo por una semana.', '2026-06-18'),
       (40, 'Estado nutricional aceptable.', 'Mantener dieta recomendada y seguimiento mensual.', '2026-06-18');

-- ============================================================
-- 10° INSERT: procedimientos (40)
-- ============================================================
INSERT INTO clinica.procedimientos (id_diagnostico, nombre_p, descripcion_p, costo_p)
VALUES
    (1,  N'Limpieza ótica profunda', N'Lavado clínico de conducto auditivo externo.', 15.00),
    (2,  N'Revisión física pre-vacunación', N'Exploración de ganglios y temperatura.', 10.00),
    (4,  'Fluidoterapia ambulatoria', N'Administración de solución Hartman intravenosa.', 25.00),
    (5,  'Hemograma completo de control', N'Evaluación de rutina de células sanguíneas.', 15.00),
    (6,  N'Raspado de piel superficial', N'Toma de muestra para descarte de ectoparásitos.', 10.00),
    (7,  N'Coprológico por flotación', N'Examen de descarte de parásitos gastrointestinales.', 10.00),
    (8,  N'Limpieza dental preventiva básica', N'Eliminación manual de placa dental incipiente.', 20.00),
    (9,  N'Prueba rápida Triple Felina', 'Descarte de Leucemia, SIDA y Panleucopenia.', 35.00),
    (10, N'Medición de presión arterial', 'Monitoreo preventivo cardiovascular.', 15.00),
    (11, N'Inyección subcutánea terapéutica', N'Aplicación clínica controlada.', 5.00),
    (12, 'Limpieza ocular con suero', N'Lavado antiséptico de sacos conjuntivales.', 8.00),
    (13, N'Prueba de Fluoresceína', N'Tinción ocular para evaluar extensión de úlcera.', 8.00),
    (14, N'Radiografía digital', N'Dos proyecciones ortogonales de fémur izquierdo.', 40.00),
    (14, N'Cirugía Ortopédica - Osteosíntesis', N'Fijación de fémur mediante placa y tornillos.', 350.00),
    (15, N'Perfil geriátrico bioquímico', N'Análisis de funcionamiento renal y hepático.', 35.00),
    (16, 'Ecocardiograma Doppler', N'Evaluación dimensional y flujo de cámaras cardíacas.', 65.00),
    (17, 'Examen general de orina', 'Toma de muestra y lectura de Sedimento.', 12.00),
    (18, N'Medición de glucosa en sangre', N'Monitoreo rápido con glucómetro portátil.', 6.00),
    (19, N'Citología de piel', N'Tinción e identificación microscópica de levaduras.', 12.00),
    (20, N'Aplicación de spot-on clínico', N'Colocación profesional de antiparasitario.', 5.00),
    (21, N'Prueba rápida Triple Felina', 'Descarte de Leucemia, SIDA y Panleucopenia en felino con cuadro respiratorio.', 35.00),
    (22, N'Radiografía de tórax', N'Dos proyecciones para evaluación de campo pulmonar.', 30.00),
    (23, N'Auscultación cardiopulmonar ampliada', N'Evaluación de ruidos pulmonares con estetoscopio digital.', 12.00),
    (24, N'Raspado de piel superficial', N'Toma de muestra para identificación de ectoparásitos.', 10.00),
    (25, N'Citología de piel', N'Tinción e identificación microscópica de levaduras y cocos.', 12.00),
    (26, N'Prueba de alergia intradérmica', N'Evaluación de hipersensibilidad cutánea por sospecha de sarna.', 45.00),
    (27, N'Revisión física pre-vacunación', N'Exploración de ganglios, temperatura y mucosas.', 10.00),
    (28, N'Inyección subcutánea terapéutica', N'Aplicación clínica controlada de vacuna polivalente.', 5.00),
    (29, N'Coprológico por flotación', N'Examen de descarte de parásitos gastrointestinales.', 10.00),
    (30, N'Ecografía abdominal', N'Evaluación de intestino grueso y colon por imagen.', 40.00),
    (31, N'Consulta clínica preventiva', N'Evaluación física general para confirmar el buen estado de salud.', 18.00),
    (32, N'Aplicación de vacuna séxtuple', N'Administración del refuerzo correspondiente según el esquema de vacunación.', 30.00),
    (33, N'Evaluación nutricional', N'Análisis del peso corporal y elaboración de un plan alimenticio.', 20.00),
    (34, 'Fluidoterapia intravenosa', N'Administración de líquidos y electrolitos para corregir la deshidratación.', 35.00),
    (35, N'Baño dermatológico medicado', N'Tratamiento tópico con champú especializado para dermatitis alérgica.', 25.00),
    (36, N'Control postquirúrgico', N'Revisión de la evolución de la herida y del proceso de recuperación.', 22.00),
    (37, 'Retiro de suturas', N'Extracción de puntos de la herida quirúrgica y limpieza de la zona.', 15.00),
    (38, N'Desparasitación preventiva', N'Aplicación de antiparasitario interno y externo.', 18.00),
    (39, N'Nebulización', N'Terapia respiratoria para facilitar la eliminación de secreciones.', 20.00),
    (40, 'Control nutricional', N'Seguimiento del plan alimenticio y evaluación del estado corporal.', 18.00);

-- ============================================================
-- 11° INSERT: tratamiento (40)
-- ============================================================
INSERT INTO clinica.tratamiento (id_diagnostico, fecha_inicio, fecha_fin, descripcion_t, indicaciones_t)
VALUES 
       (1, '2025-01-10', '2025-01-17', 'Tratamiento Otitis infecciosa', 'Limpieza diaria previa a las gotas.'),
       (2, '2025-01-15', '2025-01-18', 'Monitoreo post-vacunal inmediato', N'Reportar decaimiento o fiebre al médico.'),
       (3, '2025-01-20', '2025-04-20', N'Plan nutricional metabólico', N'Pesar ración exacta indicada por la mañana.'),
       (4, '2025-01-25', '2025-01-30', 'Esquema de soporte digestivo', N'Dieta blanda líquida en porciones pequeñas.'),
       (5, '2025-02-01', '2025-02-08', N'Suplementación vitamínica general', N'Mezclar con el alimento húmedo diariamente.'),
       (6, '2025-02-05', '2025-03-05', N'Control ectoparásitos y DAPP', 'Aplicar pipeta y evitar contacto con pulgas.'),
       (7, '2025-02-10', '2025-02-15', 'Esquema preventivo de crecimiento', 'Monitorear consistencia de las heces.'),
       (8, '2025-02-15', '2025-02-22', 'Higiene dental oral preventiva', N'Aplicar gel antiséptico dental por las noches.'),
       (9, '2025-02-20', '2025-02-27', N'Soporte antiviral y sintomático', N'Mantener en ambiente cálido y asear nariz.'),
       (10, '2025-02-25', '2025-03-25', N'Esquema dietético para control graso', 'Prohibido dar premios o comida casera.'),
       (11, '2025-03-02', '2025-03-05', N'Manejo preventivo inmunológico', N'Evitar paseos públicos por las próximas 48h.'),
       (12, '2025-03-06', '2025-03-13', N'Terapia oftálmica antibacteriana', 'Aplicar colirio rigurosamente en horarios.'),
       (13, '2025-03-10', '2025-03-20', N'Manejo biológico de úlcera corneal', 'Uso obligatorio de collar isabelino 24/7.'),
       (14, '2025-03-16', '2025-04-16', N'Manejo analgésico postoperatorio', N'Reposo absoluto en jaula o espacio pequeño.'),
       (15, '2025-03-20', '2025-04-20', N'Condroprotección geriátrica articular', N'Suministrar tableta masticable por las mañanas.'),
       (16, '2025-03-25', '2025-09-25', N'Terapia cardíaca de mantenimiento', 'Evitar emociones fuertes y ejercicio extremo.'),
       (17, '2025-04-01', '2025-04-08', 'Tratamiento preventivo urinario', N'Aumentar el consumo de agua colocando más fuentes.'),
       (18, '2025-04-05', '2025-04-12', 'Control glucémico preventivo', N'Mantener horarios fijos para la alimentación.'),
       (19, '2025-04-10', '2025-04-24', N'Tratamiento antimicótico tópico', N'Baños terapéuticos dejando actuar el champú.'),
       (20, '2025-04-15', '2025-04-18', 'Plan antiparasitario de amplio espectro', N'Verificar la eliminación de parásitos en cajas.'),
       (21, '2026-06-18', '2026-06-25', N'Soporte antiviral y mucolítico felino', N'Mantener en ambiente cálido y limpiar secreción nasal.'),
       (22, '2026-06-19', '2026-06-26', 'Terapia broncodilatadora ambulatoria', N'Evitar exposición a humo, polvo y ambientes fríos.'),
       (23, '2026-06-20', '2026-06-27', N'Manejo sintomático de traqueobronquitis', N'Reposo y aislamiento de otros perros por 7 días.'),
       (24, '2026-06-18', '2026-07-18', N'Control ectoparásitos y DAPP', 'Aplicar pipeta y evitar contacto con pulgas del entorno.'),
       (25, '2026-06-19', '2026-07-03', N'Tratamiento antimicótico tópico intensivo', N'Baños terapéuticos dejando actuar el champú 10 minutos.'),
       (26, '2026-06-20', '2026-07-20', 'Terapia antiparasitaria y antiinflamatoria', N'Tratar también el ambiente del hogar con acaricida.'),
       (27, '2026-06-18', '2026-06-21', 'Monitoreo post-vacunal inmediato', N'Reportar decaimiento, fiebre o vómito al médico.'),
       (28, '2026-06-19', '2026-06-22', 'Refuerzo inmunológico post-vacunación', N'Evitar paseos públicos por las próximas 48 horas.'),
       (29, '2026-06-20', '2026-06-27', 'Esquema de soporte digestivo agudo', N'Dieta blanda en porciones pequeñas cada 4 horas.'),
       (30, '2026-06-21', '2026-07-05', N'Manejo de colitis crónica reagudizada', 'Prohibido dar comida casera o premios fuera de dieta.'),
       (31, '2026-06-15', '2026-06-20', N'Seguimiento preventivo sin medicación específica.', N'Mantener una alimentación balanceada y asistir al control en seis meses.'),
       (32, '2026-06-15', '2026-06-16', N'Observación posterior a la aplicación de la vacuna.', 'Vigilar posibles reacciones adversas durante las siguientes 24 horas.'),
       (33, '2026-06-16', '2026-07-16', N'Plan de reducción de peso mediante dieta controlada.', 'Disminuir las porciones de alimento y realizar ejercicio diariamente.'),
       (34, '2026-06-16', '2026-06-21', 'Tratamiento para gastroenteritis con medicamentos y dieta blanda.', N'Mantener hidratación constante y administrar los medicamentos según indicación.'),
       (35, '2026-06-16', '2026-06-30', N'Tratamiento para dermatitis alérgica.', N'Aplicar crema tópica dos veces al día y evitar el contacto con alérgenos.'),
       (36, '2026-06-17', '2026-06-24', N'Recuperación postoperatoria con control de la herida.', N'Mantener reposo, evitar esfuerzos y administrar analgésicos prescritos.'),
       (37, '2026-06-17', '2026-06-24', N'Seguimiento del proceso de cicatrización.', 'Mantener la herida limpia y asistir al retiro de suturas en la fecha indicada.'),
       (38, '2026-06-17', '2026-06-18', N'Control preventivo sin necesidad de tratamiento farmacológico.', 'Continuar con los controles veterinarios de rutina.'),
       (39, '2026-06-18', '2026-06-25', N'Tratamiento para infección respiratoria leve.', N'Administrar antibióticos completos y evitar la exposición al frío.'),
       (40, '2026-06-18', '2026-07-18', 'Seguimiento nutricional y control del peso corporal.', N'Mantener la dieta recomendada y realizar actividad física moderada.');

-- ============================================================
-- 12° INSERT: detalles_tratamientos (40)
-- ============================================================
INSERT INTO clinica.detalles_tratamientos (id_detalle_tratamiento, id_tratamiento, id_medicamento, dosis_dt, frecuencia_dt, duracion_dias_dt)
VALUES 
       (1, 1, 1, N'5 gotas por oído afectado', 'Cada 12 horas', 7),
       (2, 1, 19, N'1.5 ml vía oral', 'Cada 12 horas', 7),
       (1, 2, 19, N'2.0 ml vía oral', 'Cada 12 horas', 5),
       (2, 2, 3, N'1.0 ml vía oral', 'Cada 8 horas', 3),
       (1, 3, 4, '1 tableta masticable total', N'Dosis única', 1),
       (1, 4, 6, N'1/2 tableta vía oral', 'Cada 12 horas', 7),
       (1, 5, 7, '2 gotas en ojo izquierdo', 'Cada 6 horas', 7),
       (1, 6, 7, '1 gota en ojo derecho', 'Cada 4 horas', 10),
       (2, 6, 8, N'6 gotas vía oral', 'Cada 24 horas', 5),
       (1, 7, 8, N'12 gotas vía oral', 'Cada 24 horas', 5),
       (2, 7, 14, N'1 cápsula vía oral', 'Cada 12 horas', 10),
       (1, 8, 10, N'1/2 tableta vía oral', 'Cada 24 horas', 180),
       (1, 9, 11, N'Baño completo dos por semana', N'Cada 3 días', 14),
       (1, 10, 12, N'1 tableta y media vía oral', N'Dosis única', 1),
       (1, 11, 5, '1 tableta masticable total', N'Dosis única', 1),
       (1, 12, 14, N'1/2 cápsula vía oral', 'Cada 12 horas', 7),
       (1, 13, 15, N'1/4 tableta vía oral', 'Cada 24 horas', 180),
       (1, 14, 17, '1 tableta triturada en comida', 'Cada 12 horas', 7),
       (1, 15, 5, '1 tableta masticable total', N'Dosis única', 1),
       (1, 16, 19, N'1.0 ml suspensión vía oral', 'Cada 12 horas', 10),
       (1, 21, 2,  N'5 ml jarabe vía oral', 'Cada 12 horas', 7), 
       (1, 22, 9,  N'1 tableta vía oral', 'Cada 12 horas', 7),    
       (2, 22, 8,  N'8 gotas vía oral', 'Cada 24 horas', 5),    
       (1, 23, 3,  N'1.5 ml vía oral', 'Cada 12 horas', 7),    
       (1, 24, 4,  '1 tableta masticable total', N'Dosis única', 1),  
       (1, 25, 11, N'Baño completo dos veces por semana', N'Cada 3 días', 14),  
       (1, 26, 16, N'1/2 tableta vía oral', 'Cada 24 horas', 14),  
       (1, 27, 5,  '1 tableta masticable total', N'Dosis única', 1), 
       (1, 28, 19, N'1.0 ml suspensión vía oral', 'Cada 12 horas', 7),    
       (1, 29, 7,  N'1 tableta vía oral', 'Cada 24 horas', 7),
       (1, 31, 21, N'1 tableta vía oral', 'Cada 24 horas', 5),
       (1, 32, 22, N'1/2 tableta vía oral', 'Cada 24 horas', 14),
       (1, 33, 30, N'Aplicar una capa fina sobre la lesión', 'Cada 12 horas', 10),
       (1, 34, 29, N'1 tableta vía oral', 'Cada 12 horas', 7),
       (1, 35, 27, N'1 cápsula vía oral', 'Cada 24 horas', 21),
       (1, 36, 28, N'1 tableta vía oral', 'Cada 12 horas', 7),
       (1, 37, 26, '1 dosis intravenosa', 'Cada 24 horas', 3),
       (1, 38, 23, '2 gotas en el ojo afectado', 'Cada 8 horas', 7),
       (1, 39, 24, N'1 tableta vía oral', 'Cada 24 horas', 10),
       (1, 40, 25, N'1 cápsula vía oral', 'Cada 24 horas', 14);

-- ============================================================

-- Alinear fechas de los expedientes con la cita; mantener la duración del plan.
UPDATE c SET fecha_c = CAST(d.fecha_d AS datetime2), motivo_c = d.descripcion_d,
    estado_c = N'Completada'
FROM clinica.citas c JOIN clinica.diagnosticos d ON d.id_cita=c.id_cita;
UPDATE t SET fecha_fin=DATEADD(DAY,DATEDIFF(DAY,t.fecha_inicio,t.fecha_fin),d.fecha_d),
    fecha_inicio=d.fecha_d
FROM clinica.tratamiento t JOIN clinica.diagnosticos d ON d.id_diagnostico=t.id_diagnostico;

-- 21 citas futuras adicionales: completan las 71 citas iniciales
-- implícitas en la proyección del documento (2071 - 2000).
-- Sin diagnóstico ni factura mientras permanezcan programadas.
;WITH adicionales AS (
    SELECT n FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),
        (11),(12),(13),(14),(15),(16),(17),(18),(19),(20),(21)) v(n)
)
INSERT INTO clinica.citas
    (id_mascota,id_veterinario,fecha_c,motivo_c,estado_c,costo_c)
SELECT 50+n, n, DATEADD(DAY,30+n,CAST(CAST(GETDATE() AS date) AS datetime2)),
       N'Control preventivo programado', N'Programada', 20.00
FROM adicionales;

-- Guardar stock inicial para comprobar que cada unidad se descuenta una sola vez.
SELECT id_medicamento, stock_m INTO #StockInicial FROM farmacia.medicamentos;

-- 13. Facturar 30 de las 40 citas completadas; las otras 10 quedan sin facturar.
-- Primero Pendiente y total cero; el trigger calcula el importe.
INSERT INTO facturacion.facturas (id_cita, fecha_emision_f, estado_f, total_f)
SELECT id_cita, CAST(fecha_c AS date), N'Pendiente', 0
FROM clinica.citas WHERE estado_c=N'Completada' AND id_cita BETWEEN 1 AND 30;

-- 14. Exactamente 50 líneas: 30 consultas, 10 procedimientos y 10 medicamentos.
-- Solo se incluyen servicios y medicamentos del expediente de cada factura.
-- Los demás procedimientos/medicamentos permanecen sin facturar en esta muestra.
;WITH procedimientos_a_facturar AS (
    SELECT TOP (10) p.id_procedimiento
    FROM clinica.procedimientos p
    JOIN clinica.diagnosticos d ON d.id_diagnostico=p.id_diagnostico
    JOIN facturacion.facturas f ON f.id_cita=d.id_cita
    ORDER BY p.id_procedimiento
), medicamentos_a_facturar AS (
    SELECT TOP (10) dt.id_tratamiento, dt.id_detalle_tratamiento
    FROM clinica.detalles_tratamientos dt
    JOIN clinica.tratamiento t ON t.id_tratamiento=dt.id_tratamiento
    JOIN clinica.diagnosticos d ON d.id_diagnostico=t.id_diagnostico
    JOIN facturacion.facturas f ON f.id_cita=d.id_cita
    ORDER BY dt.id_tratamiento, dt.id_detalle_tratamiento
), items AS (
    SELECT f.id_factura, c.id_cita, CAST(NULL AS bigint) AS id_medicamento,
        CAST(NULL AS bigint) AS id_tratamiento, CAST(NULL AS bigint) AS id_procedimiento,
        CONCAT(N'Consulta: ',c.motivo_c) AS descripcion_df,
        CAST(1 AS bigint) AS cantidad_df, c.costo_c AS precio_unit_df,
        1 AS tipo, c.id_cita AS orden
    FROM facturacion.facturas f JOIN clinica.citas c ON c.id_cita=f.id_cita
    UNION ALL
    SELECT f.id_factura, NULL, NULL, NULL, p.id_procedimiento,
        CONCAT(N'Procedimiento: ',p.nombre_p), 1, p.costo_p, 2, p.id_procedimiento
    FROM facturacion.facturas f
    JOIN clinica.diagnosticos d ON d.id_cita=f.id_cita
    JOIN clinica.procedimientos p ON p.id_diagnostico=d.id_diagnostico
    JOIN procedimientos_a_facturar pf ON pf.id_procedimiento=p.id_procedimiento
    UNION ALL
    SELECT f.id_factura, NULL, m.id_medicamento, t.id_tratamiento, NULL,
        CONCAT(N'Medicamento: ',m.nombre_m,N' - ',m.presentacion_m), 1, m.precio_m,
        3, dt.id_detalle_tratamiento
    FROM facturacion.facturas f
    JOIN clinica.diagnosticos d ON d.id_cita=f.id_cita
    JOIN clinica.tratamiento t ON t.id_diagnostico=d.id_diagnostico
    JOIN clinica.detalles_tratamientos dt ON dt.id_tratamiento=t.id_tratamiento
    JOIN farmacia.medicamentos m ON m.id_medicamento=dt.id_medicamento
    JOIN medicamentos_a_facturar mf ON mf.id_tratamiento=dt.id_tratamiento
        AND mf.id_detalle_tratamiento=dt.id_detalle_tratamiento
)
INSERT INTO facturacion.detalles_facturas
    (id_detalle_factura,id_factura,id_cita,id_medicamento,id_tratamiento,
     id_procedimiento,descripcion_df,cantidad_df,precio_unit_df)
SELECT ROW_NUMBER() OVER(PARTITION BY id_factura ORDER BY tipo,orden,id_tratamiento,id_medicamento),
    id_factura,id_cita,id_medicamento,id_tratamiento,id_procedimiento,
    descripcion_df,cantidad_df,precio_unit_df
FROM items;

-- El trigger ya calculó los totales; ahora es válido marcar algunas como pagadas.
UPDATE facturacion.facturas SET estado_f=N'Pagada'
WHERE id_cita % 2 = 0 AND total_f > 0;

-- Comprobaciones automáticas: ante cualquier discrepancia se revierte toda la carga.
IF EXISTS (SELECT 1 FROM clinica.detalles_tratamientos WHERE id_detalle_tratamiento<=0)
 OR EXISTS (SELECT 1 FROM facturacion.detalles_facturas WHERE id_detalle_factura<=0)
    THROW 51002,N'Numeración de detalles inválida.',1;
IF EXISTS (
    SELECT 1 FROM facturacion.facturas f
    OUTER APPLY (SELECT SUM(subtotal_df) total FROM facturacion.detalles_facturas d
                 WHERE d.id_factura=f.id_factura) s
    WHERE f.total_f<>COALESCE(s.total,0)
) THROW 51003,N'Total de factura inconsistente.',1;
IF EXISTS (
    SELECT 1 FROM farmacia.medicamentos m JOIN #StockInicial s ON s.id_medicamento=m.id_medicamento
    OUTER APPLY (SELECT SUM(cantidad_df) vendidas FROM facturacion.detalles_facturas d
                 WHERE d.id_medicamento=m.id_medicamento) v
    WHERE m.stock_m<>s.stock_m-COALESCE(v.vendidas,0)
) THROW 51004,N'Descuento de inventario inconsistente.',1;
IF EXISTS (
    SELECT 1 FROM facturacion.detalles_facturas df
    JOIN facturacion.facturas f ON f.id_factura=df.id_factura
    LEFT JOIN clinica.procedimientos p ON p.id_procedimiento=df.id_procedimiento
    LEFT JOIN clinica.tratamiento t ON t.id_tratamiento=df.id_tratamiento
    LEFT JOIN clinica.diagnosticos dp ON dp.id_diagnostico=p.id_diagnostico
    LEFT JOIN clinica.diagnosticos dt ON dt.id_diagnostico=t.id_diagnostico
    WHERE (df.id_cita IS NOT NULL AND df.id_cita<>f.id_cita)
       OR (df.id_procedimiento IS NOT NULL AND dp.id_cita<>f.id_cita)
       OR (df.id_tratamiento IS NOT NULL AND dt.id_cita<>f.id_cita)
       OR (df.id_medicamento IS NOT NULL AND NOT EXISTS (
           SELECT 1 FROM clinica.detalles_tratamientos r
           WHERE r.id_tratamiento=df.id_tratamiento AND r.id_medicamento=df.id_medicamento))
) THROW 51005,N'Un detalle no corresponde al expediente facturado.',1;
-- Validar exactamente las cantidades iniciales del documento.
IF (SELECT COUNT_BIG(*) FROM pacientes.especies) <> 17
 OR (SELECT COUNT_BIG(*) FROM pacientes.razas) <> 61
 OR (SELECT COUNT_BIG(*) FROM pacientes.propietarios) <> 20
 OR (SELECT COUNT_BIG(*) FROM pacientes.mascotas) <> 71
 OR (SELECT COUNT_BIG(*) FROM personal.especialidades) <> 20
 OR (SELECT COUNT_BIG(*) FROM personal.veterinario) <> 40
 OR (SELECT COUNT_BIG(*) FROM farmacia.medicamentos) <> 30
 OR (SELECT COUNT_BIG(*) FROM clinica.citas) <> 71
 OR (SELECT COUNT_BIG(*) FROM clinica.diagnosticos) <> 40
 OR (SELECT COUNT_BIG(*) FROM clinica.procedimientos) <> 40
 OR (SELECT COUNT_BIG(*) FROM clinica.tratamiento) <> 40
 OR (SELECT COUNT_BIG(*) FROM clinica.detalles_tratamientos) <> 40
 OR (SELECT COUNT_BIG(*) FROM facturacion.facturas) <> 30
 OR (SELECT COUNT_BIG(*) FROM facturacion.detalles_facturas) <> 50
    THROW 51008, N'Los conteos no coinciden con la base inicial del documento.', 1;
DROP TABLE #StockInicial;
COMMIT TRANSACTION;
PRINT N'Carga completada: relaciones, totales e inventario verificados.';
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    SET IDENTITY_INSERT pacientes.mascotas OFF;
    THROW;
END CATCH;

-- Conteos de salida.
SELECT N'farmacia.medicamentos' AS tabla, COUNT_BIG(*) AS registros FROM farmacia.medicamentos
UNION ALL
SELECT N'pacientes.especies' AS tabla, COUNT_BIG(*) AS registros FROM pacientes.especies
UNION ALL
SELECT N'pacientes.razas' AS tabla, COUNT_BIG(*) AS registros FROM pacientes.razas
UNION ALL
SELECT N'personal.especialidades' AS tabla, COUNT_BIG(*) AS registros FROM personal.especialidades
UNION ALL
SELECT N'personal.veterinario' AS tabla, COUNT_BIG(*) AS registros FROM personal.veterinario
UNION ALL
SELECT N'pacientes.propietarios' AS tabla, COUNT_BIG(*) AS registros FROM pacientes.propietarios
UNION ALL
SELECT N'pacientes.mascotas' AS tabla, COUNT_BIG(*) AS registros FROM pacientes.mascotas
UNION ALL
SELECT N'clinica.citas' AS tabla, COUNT_BIG(*) AS registros FROM clinica.citas
UNION ALL
SELECT N'clinica.diagnosticos' AS tabla, COUNT_BIG(*) AS registros FROM clinica.diagnosticos
UNION ALL
SELECT N'clinica.procedimientos' AS tabla, COUNT_BIG(*) AS registros FROM clinica.procedimientos
UNION ALL
SELECT N'clinica.tratamiento' AS tabla, COUNT_BIG(*) AS registros FROM clinica.tratamiento
UNION ALL
SELECT N'clinica.detalles_tratamientos' AS tabla, COUNT_BIG(*) AS registros FROM clinica.detalles_tratamientos
UNION ALL
SELECT N'facturacion.facturas' AS tabla, COUNT_BIG(*) AS registros FROM facturacion.facturas
UNION ALL
SELECT N'facturacion.detalles_facturas' AS tabla, COUNT_BIG(*) AS registros FROM facturacion.detalles_facturas;
GO
-- ============================================================================
-- BLOQUE MASIVO (se anexa DESPUES del ultimo GO de DML_Original.sql)
-- DML_Updated.sql = DML_Original.sql + este bloque.
--
-- Requisitos: DDL y Triggers ya ejecutados; GENERATE_SERIES (SQL Server 2022+).
-- Todo es DETERMINISTA (hash SHA2_256 sobre ids + semilla, sin NEWID): regenerar da la misma forma.
-- Fechas relativas a hoy: citas en los ultimos 3 años, con mas densidad reciente
-- (clinica en crecimiento, util para C3).
--
-- Proporciones (N = @N_CITAS = total de citas, incluidas las 71 originales):
--   mascotas        = N / 10          (~10 citas por mascota; sirve para C2)
--   propietarios    = mascotas / 1.7
--   citas nuevas    : 85% Completada, 15% Cancelada
--   diagnosticos    : 1 por cita Completada
--   procedimientos  : 60% de los diagnosticos
--   tratamiento     : 70% de los diagnosticos
--   detalles_trat.  : 1 a 2 por tratamiento (50% llevan 2)
--   facturas        : 90% de las citas Completadas nuevas (80% Pagada, 12% Pendiente, 8% Anulada)
--   detalles_fact.  : linea de consulta + procedimientos + medicamentos (~2.6 por factura)
-- ============================================================================
USE db_veterinaria;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0
    THROW 51100, N'Ejecute este bloque fuera de otra transaccion.', 1;

-- ---------------------------------------------------------------- PARAMETROS
DECLARE @N_CITAS int = 100000;                       -- unico numero que hay que tocar para escalar
DECLARE @N_MASC  int = @N_CITAS / 10;
DECLARE @N_PROP  int = CAST(@N_MASC / 1.7 AS int);
DECLARE @hoy     date = CAST(SYSDATETIME() AS date);

DECLARE @p0 int = (SELECT COALESCE(MAX(id_propietario),0) FROM pacientes.propietarios);
DECLARE @m0 int = (SELECT COALESCE(MAX(id_mascota),0)     FROM pacientes.mascotas);
DECLARE @c0 int = (SELECT COALESCE(MAX(id_cita),0)        FROM clinica.citas);
DECLARE @f0 bigint = (SELECT COALESCE(MAX(id_factura),0)  FROM facturacion.facturas);
DECLARE @n_vet int = (SELECT COUNT(*) FROM personal.veterinario);

-- ---------------------------------------------------------------- PRECONDICIONES
-- La base debe venir del DML original (ids contiguos, catalogos completos).
IF (SELECT COUNT_BIG(*) FROM pacientes.propietarios) <> @p0
 OR (SELECT COUNT_BIG(*) FROM pacientes.mascotas)    <> @m0
 OR (SELECT COUNT_BIG(*) FROM clinica.citas)         <> @c0
 OR (SELECT COUNT_BIG(*) FROM personal.veterinario)  <> (SELECT MAX(id_veterinario) FROM personal.veterinario)
    THROW 51101, N'Los ids no son contiguos. Ejecute primero el DML original completo sobre una base limpia.', 1;
IF (SELECT COUNT_BIG(*) FROM pacientes.razas) <> 61
 OR (SELECT COUNT_BIG(*) FROM farmacia.medicamentos) <> 30
 OR @n_vet <> 40
    THROW 51102, N'Catalogos (razas, medicamentos, veterinarios) distintos a los del DML original.', 1;
IF (SELECT COUNT_BIG(*) FROM pacientes.razas r JOIN pacientes.especies e ON e.id_especie=r.id_especie
    WHERE (r.id_raza BETWEEN 1 AND 5 AND e.nombre_e<>N'Can') OR (r.id_raza BETWEEN 6 AND 10 AND e.nombre_e<>N'Felino')) <> 0
    THROW 51103, N'El orden de razas no coincide (1-5 Can, 6-10 Felino).', 1;
IF @N_MASC <= @m0 OR @N_PROP <= @p0 OR @N_CITAS <= @c0
    THROW 51104, N'@N_CITAS es demasiado pequeño para la base existente.', 1;

BEGIN TRY

-- ---------------------------------------------------------------- CATALOGOS TEMPORALES
CREATE TABLE #cat (
    idx int PRIMARY KEY,
    motivo  nvarchar(100) COLLATE DATABASE_DEFAULT, costo decimal(10,2),
    diag    nvarchar(200) COLLATE DATABASE_DEFAULT, obs   nvarchar(300) COLLATE DATABASE_DEFAULT,
    proc_n  nvarchar(100) COLLATE DATABASE_DEFAULT, proc_d nvarchar(300) COLLATE DATABASE_DEFAULT, proc_c decimal(10,2),
    trat    nvarchar(200) COLLATE DATABASE_DEFAULT, ind   nvarchar(300) COLLATE DATABASE_DEFAULT,
    med1 bigint, med2 bigint,
    d1 nvarchar(100) COLLATE DATABASE_DEFAULT, f1 nvarchar(100) COLLATE DATABASE_DEFAULT, n1 int,
    d2 nvarchar(100) COLLATE DATABASE_DEFAULT, f2 nvarchar(100) COLLATE DATABASE_DEFAULT, n2 int);

INSERT INTO #cat VALUES
(1, N'Consulta general', 20, N'Paciente clínicamente sano', N'Sin hallazgos relevantes; continuar controles preventivos.',
    N'Examen físico completo', N'Auscultación, palpación y toma de signos vitales.', 10,
    N'Seguimiento preventivo', N'Mantener alimentación balanceada y control en seis meses.',
    12, 5, N'1 tableta vía oral', N'Dosis única', 1, N'1 tableta masticable total', N'Dosis única', 1),
(2, N'Vacunación anual', 25, N'Paciente apto para vacunación anual', N'Sin hallazgos previos a la inmunización.',
    N'Aplicación de vacuna polivalente', N'Inyección subcutánea según esquema anual.', 15,
    N'Monitoreo post-vacunal', N'Reportar decaimiento, fiebre o vómito en las siguientes 48 horas.',
    12, 3, N'1 tableta vía oral', N'Dosis única', 1, N'1.0 ml vía oral', N'Cada 8 horas', 3),
(3, N'Desparasitación', 15, N'Parasitosis intestinal leve', N'Huevos de parásitos detectados en examen coprológico.',
    N'Coprológico por flotación', N'Examen de descarte de parásitos gastrointestinales.', 10,
    N'Plan antiparasitario', N'Repetir dosis a los 15 días y verificar las heces.',
    12, 13, N'1 tableta vía oral', N'Dosis única', 1, N'1 tableta masticable total', N'Dosis única', 1),
(4, N'Control de peso', 18, N'Sobrepeso leve', N'Se recomienda dieta balanceada y ejercicio diario.',
    N'Evaluación nutricional', N'Análisis de condición corporal y plan alimenticio.', 20,
    N'Plan de reducción de peso', N'Pesar la ración y evitar premios fuera de la dieta.',
    17, 8, N'1 tableta masticable por la mañana', N'Cada 24 horas', 30, N'6 gotas vía oral', N'Cada 24 horas', 5),
(5, N'Chequeo preventivo', 22, N'Chequeo de rutina conforme', N'Buena condición corporal y mucosas normales.',
    N'Hemograma completo de control', N'Evaluación de rutina de células sanguíneas.', 15,
    N'Suplementación general', N'Mezclar con el alimento húmedo diariamente.',
    5, 12, N'1 tableta masticable total', N'Dosis única', 1, N'1 tableta vía oral', N'Dosis única', 1),
(6, N'Consulta dermatológica', 30, N'Dermatitis alérgica', N'Lesiones eritematosas y prurito en región inguinal.',
    N'Raspado de piel superficial', N'Toma de muestra para descartar ectoparásitos.', 10,
    N'Control de dermatitis y ectoparásitos', N'Baños medicados y evitar contacto con alérgenos.',
    11, 20, N'Baño completo dos veces por semana', N'Cada 3 días', 14, N'Aplicar una capa fina sobre la lesión', N'Cada 12 horas', 10),
(7, N'Problema digestivo', 32, N'Gastroenteritis aguda', N'Vómitos y diarrea con hidratación conservada.',
    N'Fluidoterapia ambulatoria', N'Administración intravenosa de solución Hartman.', 25,
    N'Soporte digestivo agudo', N'Dieta blanda en porciones pequeñas cada 4 horas.',
    29, 25, N'1 tableta vía oral', N'Cada 12 horas', 7, N'1 cápsula vía oral', N'Cada 24 horas', 10),
(8, N'Revisión ocular', 30, N'Conjuntivitis bacteriana', N'Secreción purulenta ocular.',
    N'Prueba de fluoresceína', N'Tinción ocular para descartar úlcera corneal.', 8,
    N'Terapia oftálmica antibacteriana', N'Aplicar el colirio en los horarios indicados.',
    7, 23, N'2 gotas en el ojo afectado', N'Cada 6 horas', 7, N'Aplicar tira de ungüento en el ojo', N'Cada 12 horas', 7),
(9, N'Control postoperatorio', 40, N'Recuperación favorable tras cirugía', N'Cicatrización adecuada; retirar puntos en la próxima consulta.',
    N'Control postquirúrgico', N'Revisión de la herida y retiro de suturas.', 22,
    N'Manejo analgésico postoperatorio', N'Reposo, evitar esfuerzos y mantener la herida limpia.',
    28, 19, N'1/2 tableta vía oral', N'Cada 12 horas', 7, N'1.0 ml suspensión vía oral', N'Cada 12 horas', 7),
(10, N'Evaluación cardiológica', 45, N'Soplo cardíaco grado II/VI', N'Cardiomiopatía en fase inicial; controles periódicos.',
    N'Ecocardiograma Doppler', N'Evaluación de cámaras cardíacas y flujo sanguíneo.', 65,
    N'Terapia cardíaca de mantenimiento', N'Evitar ejercicio extremo y emociones fuertes.',
    10, 16, N'1/2 tableta vía oral', N'Cada 24 horas', 30, N'1/4 tableta vía oral', N'Cada 24 horas', 14),
(11, N'Consulta por alergia', 35, N'Dermatitis alérgica por pulga (DAPP)', N'Lesiones alopécicas en la zona lumbosacra.',
    N'Citología de piel', N'Identificación microscópica de levaduras y parásitos.', 12,
    N'Control de ectoparásitos y alergia', N'Tratar también el ambiente del hogar.',
    22, 13, N'1 tableta vía oral', N'Cada 24 horas', 14, N'1 tableta masticable total', N'Dosis única', 1),
(12, N'Problema respiratorio', 35, N'Infección respiratoria leve', N'Estornudos y secreción nasal serosa.',
    N'Nebulización', N'Terapia respiratoria para eliminar secreciones.', 20,
    N'Soporte antibiótico respiratorio', N'Completar los antibióticos y evitar la exposición al frío.',
    24, 19, N'1 tableta vía oral', N'Cada 24 horas', 10, N'1.0 ml suspensión vía oral', N'Cada 12 horas', 10);

CREATE TABLE #nom (idx int PRIMARY KEY, nombre varchar(30) COLLATE DATABASE_DEFAULT, genero varchar(1) COLLATE DATABASE_DEFAULT);
INSERT INTO #nom VALUES
(1,'Maria','F'),(2,'Ana','F'),(3,'Carmen','F'),(4,'Lucia','F'),(5,'Patricia','F'),(6,'Rosa','F'),
(7,'Elena','F'),(8,'Sandra','F'),(9,'Claudia','F'),(10,'Karla','F'),(11,'Monica','F'),(12,'Beatriz','F'),
(13,'Jose','M'),(14,'Juan','M'),(15,'Carlos','M'),(16,'Luis','M'),(17,'Miguel','M'),(18,'Pedro','M'),
(19,'Jorge','M'),(20,'Mario','M'),(21,'Oscar','M'),(22,'Rafael','M'),(23,'Hector','M'),(24,'Manuel','M');

CREATE TABLE #ape (idx int PRIMARY KEY, apellido varchar(30) COLLATE DATABASE_DEFAULT);
INSERT INTO #ape VALUES
(1,'Hernandez'),(2,'Martinez'),(3,'Lopez'),(4,'Gonzalez'),(5,'Rodriguez'),(6,'Perez'),(7,'Sanchez'),(8,'Ramirez'),
(9,'Flores'),(10,'Gomez'),(11,'Diaz'),(12,'Reyes'),(13,'Morales'),(14,'Cruz'),(15,'Ortiz'),(16,'Gutierrez'),
(17,'Chavez'),(18,'Ramos'),(19,'Mendoza'),(20,'Ruiz'),(21,'Alvarado'),(22,'Guevara'),(23,'Serrano'),(24,'Menendez');

CREATE TABLE #col (idx int PRIMARY KEY, dir nvarchar(120) COLLATE DATABASE_DEFAULT);
INSERT INTO #col VALUES
(1,N'Colonia Escalón, San Salvador'),(2,N'Colonia San Benito, San Salvador'),(3,N'Colonia Miramonte, San Salvador'),
(4,N'Residencial Santa Elena, Antiguo Cuscatlán'),(5,N'Urbanización California, Santa Tecla'),(6,N'Colonia Médica, San Salvador'),
(7,N'Reparto Los Héroes, San Salvador'),(8,N'Colonia Centroamérica, San Salvador'),(9,N'Ciudad Merliot, Antiguo Cuscatlán'),
(10,N'Colonia Layco, San Salvador'),(11,N'Residencial Las Colinas, Santa Tecla'),(12,N'Colonia Flor Blanca, San Salvador');

CREATE TABLE #pn (idx int PRIMARY KEY, nombre nvarchar(50) COLLATE DATABASE_DEFAULT);
INSERT INTO #pn VALUES
(1,N'Max'),(2,N'Luna'),(3,N'Rocky'),(4,N'Nala'),(5,N'Toby'),(6,N'Lola'),(7,N'Simba'),(8,N'Mia'),(9,N'Coco'),(10,N'Bella'),
(11,N'Thor'),(12,N'Kira'),(13,N'Duke'),(14,N'Maya'),(15,N'Rex'),(16,N'Lucky'),(17,N'Nina'),(18,N'Zeus'),(19,N'Chispa'),(20,N'Canela'),
(21,N'Bruno'),(22,N'Mora'),(23,N'Pelusa'),(24,N'Tigre'),(25,N'Milo'),(26,N'Kiara'),(27,N'Rufo'),(28,N'Perla'),(29,N'Oso'),(30,N'Frida');

-- ---------------------------------------------------------------- 1. PROPIETARIOS
BEGIN TRANSACTION;
INSERT INTO pacientes.propietarios
    (dui_p, nombre_p, apellido_p, genero_p, telefono_p, telefono_secundario_p, correo_p, direccion_p)
SELECT
    RIGHT('00000000' + CAST(30000000 + g.n AS varchar(8)), 8) + '-' + CAST(g.n % 10 AS varchar(1)),
    nm.nombre, ap.apellido, nm.genero,
    STUFF(CAST(78000000 + g.n AS varchar(8)), 5, 0, '-'),
    STUFF(CAST(22000000 + g.n AS varchar(8)), 5, 0, '-'),
    LOWER(CONCAT(nm.nombre, '.', ap.apellido, g.n, '@',
         CASE g.n % 4 WHEN 0 THEN 'gmail.com' WHEN 1 THEN 'hotmail.com' WHEN 2 THEN 'yahoo.com' ELSE 'outlook.com' END)),
    co.dir
FROM (SELECT CAST(value AS int) AS n FROM GENERATE_SERIES(1, @N_PROP - @p0)) g
JOIN #nom nm ON nm.idx = 1 + (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(g.n, ':', 1)), 1, 4) AS int) & 2147483647) % 24
JOIN #ape ap ON ap.idx = 1 + (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(g.n, ':', 2)), 1, 4) AS int) & 2147483647) % 24
JOIN #col co ON co.idx = 1 + (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(g.n, ':', 3)), 1, 4) AS int) & 2147483647) % 12
ORDER BY g.n;
COMMIT;

-- ---------------------------------------------------------------- 2. MASCOTAS
-- 55% perros, 30% gatos, 15% otras especies. Fecha de nacimiento anterior a 3.3 años
-- para que toda cita (ultimos 3 años) ocurra despues del nacimiento.
BEGIN TRANSACTION;
INSERT INTO pacientes.mascotas
    (id_propietario, id_raza, nombre_m, fecha_nacimiento, sexo_m, peso_m, tamanio_m)
SELECT
    ((@m0 + g.n - 1) % @N_PROP) + 1,
    r.id_raza,
    mn.nombre,
    DATEADD(DAY, -(1200 + (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(g.n, ':', 24)), 1, 4) AS int) & 2147483647) % 4300), @hoy),
    CASE (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(g.n, ':', 25)), 1, 4) AS int) & 2147483647) % 2 WHEN 0 THEN N'Macho' ELSE N'Hembra' END,
    w.peso,
    CASE WHEN gr.grp = 3 THEN N'Pequeño'
         WHEN gr.grp = 2 THEN CASE WHEN w.peso >= 5.5 THEN N'Grande' ELSE N'Mediano' END
         WHEN w.peso < 8  THEN N'Pequeño'
         WHEN w.peso < 20 THEN N'Mediano'
         ELSE N'Grande' END
FROM (SELECT CAST(value AS int) AS n FROM GENERATE_SERIES(1, @N_MASC - @m0)) g
CROSS APPLY (SELECT u = (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(g.n, ':', 21)), 1, 4) AS int) & 2147483647) % 100,
                    v = (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(g.n, ':', 22)), 1, 4) AS int) & 2147483647),
                    x = (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(g.n, ':', 23)), 1, 4) AS int) & 2147483647)) h
CROSS APPLY (SELECT grp = CASE WHEN h.u < 55 THEN 1 WHEN h.u < 85 THEN 2 ELSE 3 END) gr
CROSS APPLY (SELECT id_raza = CASE gr.grp WHEN 1 THEN 1 + h.v % 5
                                          WHEN 2 THEN 6 + h.v % 5
                                          ELSE 11 + h.v % 51 END) r
CROSS APPLY (SELECT peso = CAST(CASE gr.grp WHEN 1 THEN 2   + (h.x % 3800) / 100.0
                                            WHEN 2 THEN 2.5 + (h.x % 450)  / 100.0
                                            ELSE 0.05 + (h.x % 300) / 100.0 END AS decimal(6,2))) w
JOIN #pn mn ON mn.idx = 1 + (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(g.n, ':', 26)), 1, 4) AS int) & 2147483647) % 30
ORDER BY g.n;
COMMIT;

-- ---------------------------------------------------------------- 3. CITAS
-- Ids cronologicos (INSERT ... ORDER BY fecha). Mascotas y veterinarios con sesgo suave
-- (algunos mas activos) para que rankings y TOP de C1/C2 no sean uniformes.
BEGIN TRANSACTION;
;WITH g AS (
    SELECT CAST(value AS int) AS n FROM GENERATE_SERIES(1, @N_CITAS - @c0)
), h AS (
    SELECT n,
        u1 = (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(n, ':', 31)), 1, 4) AS int) & 2147483647) % 10000 / 10000e0,
        u2 = (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(n, ':', 32)), 1, 4) AS int) & 2147483647) % 10000 / 10000e0,
        u3 = (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(n, ':', 34)), 1, 4) AS int) & 2147483647) % 10000 / 10000e0,
        r_slot = (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(n, ':', 35)), 1, 4) AS int) & 2147483647) % 20,
        r_est  = (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(n, ':', 36)), 1, 4) AS int) & 2147483647) % 100,
        r_mot  = (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(n, ':', 33)), 1, 4) AS int) & 2147483647) % 12 + 1,
        r_can  = (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(n, ':', 37)), 1, 4) AS int) & 2147483647) % 4 + 1
    FROM g
), s AS (
    SELECT h.n,
        id_mascota     = 1 + CAST(@N_MASC * POWER(h.u1, 1.2e0) AS int),
        id_veterinario = 1 + CAST(@n_vet  * POWER(h.u2, 1.4e0) AS int),
        fecha_c = DATEADD(MINUTE, 480 + 30 * h.r_slot,
                    CAST(DATEADD(DAY, -(1 + CAST(1094 * POWER(h.u3, 1.25e0) AS int)), @hoy) AS datetime2)),
        completada = CASE WHEN h.r_est < 85 THEN 1 ELSE 0 END,
        h.r_mot, h.r_can
    FROM h
)
INSERT INTO clinica.citas (id_mascota, id_veterinario, fecha_c, motivo_c, estado_c, costo_c)
SELECT s.id_mascota, s.id_veterinario, s.fecha_c,
       CASE WHEN s.completada = 1 THEN k.motivo
            ELSE CHOOSE(s.r_can, N'Cita cancelada por el propietario', N'Ausencia del propietario',
                                 N'Reprogramación solicitada', N'Cancelación por emergencia') END,
       CASE WHEN s.completada = 1 THEN N'Completada' ELSE N'Cancelada' END,
       CASE WHEN s.completada = 1 THEN k.costo ELSE CAST(0 AS decimal(10,2)) END
FROM s JOIN #cat k ON k.idx = s.r_mot
ORDER BY s.fecha_c, s.n;
COMMIT;

-- ---------------------------------------------------------------- 4. DIAGNOSTICOS (1 por cita Completada)
BEGIN TRANSACTION;
INSERT INTO clinica.diagnosticos (id_cita, descripcion_d, observaciones_d, fecha_d)
SELECT c.id_cita, k.diag, k.obs, CAST(c.fecha_c AS date)
FROM clinica.citas c
JOIN #cat k ON k.motivo = c.motivo_c
WHERE c.id_cita > @c0 AND c.estado_c = N'Completada'
ORDER BY c.id_cita;
COMMIT;

-- ---------------------------------------------------------------- 5. PROCEDIMIENTOS (60%)
BEGIN TRANSACTION;
INSERT INTO clinica.procedimientos (id_diagnostico, nombre_p, descripcion_p, costo_p)
SELECT d.id_diagnostico, k.proc_n, k.proc_d, k.proc_c
FROM clinica.diagnosticos d
JOIN clinica.citas c ON c.id_cita = d.id_cita
JOIN #cat k ON k.motivo = c.motivo_c
WHERE d.id_cita > @c0
  AND (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(d.id_diagnostico, ':', 41)), 1, 4) AS int) & 2147483647) % 10 < 6
ORDER BY d.id_diagnostico;
COMMIT;

-- ---------------------------------------------------------------- 6. TRATAMIENTO (70%)
BEGIN TRANSACTION;
INSERT INTO clinica.tratamiento (id_diagnostico, fecha_inicio, fecha_fin, descripcion_t, indicaciones_t)
SELECT d.id_diagnostico, d.fecha_d,
       DATEADD(DAY, 3 + (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(d.id_diagnostico, ':', 43)), 1, 4) AS int) & 2147483647) % 25, d.fecha_d),
       k.trat, k.ind
FROM clinica.diagnosticos d
JOIN clinica.citas c ON c.id_cita = d.id_cita
JOIN #cat k ON k.motivo = c.motivo_c
WHERE d.id_cita > @c0
  AND (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(d.id_diagnostico, ':', 42)), 1, 4) AS int) & 2147483647) % 10 < 7
ORDER BY d.id_diagnostico;
COMMIT;

-- ---------------------------------------------------------------- 7. DETALLES_TRATAMIENTOS (1 a 2 por tratamiento)
-- El trigger INSTEAD OF renumera por tratamiento; aqui solo se da el orden (1, 2).
BEGIN TRANSACTION;
INSERT INTO clinica.detalles_tratamientos
    (id_detalle_tratamiento, id_tratamiento, id_medicamento, dosis_dt, frecuencia_dt, duracion_dias_dt)
SELECT 1, t.id_tratamiento, k.med1, k.d1, k.f1, k.n1
FROM clinica.tratamiento t
JOIN clinica.diagnosticos d ON d.id_diagnostico = t.id_diagnostico
JOIN clinica.citas c ON c.id_cita = d.id_cita
JOIN #cat k ON k.motivo = c.motivo_c
WHERE d.id_cita > @c0
UNION ALL
SELECT 2, t.id_tratamiento, k.med2, k.d2, k.f2, k.n2
FROM clinica.tratamiento t
JOIN clinica.diagnosticos d ON d.id_diagnostico = t.id_diagnostico
JOIN clinica.citas c ON c.id_cita = d.id_cita
JOIN #cat k ON k.motivo = c.motivo_c
WHERE d.id_cita > @c0
  AND (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(t.id_tratamiento, ':', 52)), 1, 4) AS int) & 2147483647) % 2 = 0;
COMMIT;

-- ---------------------------------------------------------------- 8. STOCK + FACTURAS
-- El trigger de inventario rechaza stock < 0: se sube el stock antes de facturar.
-- La demanda crece con N; el medicamento mas usado (id 12) gasta ~16% de N.
-- Con N/2 sobra margen (N = 100,000 -> +50,000 unidades por medicamento).
UPDATE farmacia.medicamentos SET stock_m = stock_m + @N_CITAS / 2;
SELECT id_medicamento, stock_m INTO #Stock2 FROM farmacia.medicamentos;

BEGIN TRANSACTION;
INSERT INTO facturacion.facturas (id_cita, fecha_emision_f, estado_f, total_f)
SELECT c.id_cita, CAST(c.fecha_c AS date), N'Pendiente', 0
FROM clinica.citas c
WHERE c.id_cita > @c0
  AND c.estado_c = N'Completada'
  AND (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(c.id_cita, ':', 61)), 1, 4) AS int) & 2147483647) % 10 < 9
ORDER BY c.id_cita;
COMMIT;

-- ---------------------------------------------------------------- 9. DETALLES_FACTURAS (por lotes de facturas)
-- Los triggers calculan total_f y descuentan inventario.
DECLARE @lote int = 20000;
DECLARE @desde bigint = @f0 + 1;
DECLARE @hasta bigint;
DECLARE @fmax  bigint = (SELECT MAX(id_factura) FROM facturacion.facturas);

WHILE @desde <= @fmax
BEGIN
    SET @hasta = @desde + @lote - 1;
    BEGIN TRANSACTION;
    ;WITH items AS (
        SELECT f.id_factura, c.id_cita, CAST(NULL AS bigint) AS id_medicamento,
               CAST(NULL AS bigint) AS id_tratamiento, CAST(NULL AS bigint) AS id_procedimiento,
               CONCAT(N'Consulta: ', c.motivo_c) AS descripcion_df,
               CAST(1 AS bigint) AS cantidad_df, c.costo_c AS precio_unit_df,
               1 AS tipo, CAST(0 AS bigint) AS orden
        FROM facturacion.facturas f
        JOIN clinica.citas c ON c.id_cita = f.id_cita
        WHERE f.id_factura BETWEEN @desde AND @hasta
        UNION ALL
        SELECT f.id_factura, NULL, NULL, NULL, p.id_procedimiento,
               CONCAT(N'Procedimiento: ', p.nombre_p), 1, p.costo_p, 2, p.id_procedimiento
        FROM facturacion.facturas f
        JOIN clinica.diagnosticos d ON d.id_cita = f.id_cita
        JOIN clinica.procedimientos p ON p.id_diagnostico = d.id_diagnostico
        WHERE f.id_factura BETWEEN @desde AND @hasta
        UNION ALL
        SELECT f.id_factura, NULL, m.id_medicamento, t.id_tratamiento, NULL,
               CONCAT(N'Medicamento: ', m.nombre_m, N' - ', m.presentacion_m), 1, m.precio_m,
               3, dt.id_detalle_tratamiento
        FROM facturacion.facturas f
        JOIN clinica.diagnosticos d ON d.id_cita = f.id_cita
        JOIN clinica.tratamiento t ON t.id_diagnostico = d.id_diagnostico
        JOIN clinica.detalles_tratamientos dt ON dt.id_tratamiento = t.id_tratamiento
        JOIN farmacia.medicamentos m ON m.id_medicamento = dt.id_medicamento
        WHERE f.id_factura BETWEEN @desde AND @hasta
    )
    INSERT INTO facturacion.detalles_facturas
        (id_detalle_factura, id_factura, id_cita, id_medicamento, id_tratamiento,
         id_procedimiento, descripcion_df, cantidad_df, precio_unit_df)
    SELECT ROW_NUMBER() OVER (PARTITION BY id_factura ORDER BY tipo, orden),
           id_factura, id_cita, id_medicamento, id_tratamiento, id_procedimiento,
           descripcion_df, cantidad_df, precio_unit_df
    FROM items;
    COMMIT;
    SET @desde = @hasta + 1;
END;

-- ---------------------------------------------------------------- 10. ESTADO DE FACTURAS
-- Ya tienen total > 0 (lo calculo el trigger), por eso se permite Pagada.
BEGIN TRANSACTION;
UPDATE facturacion.facturas
SET estado_f = CASE
        WHEN (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(id_factura, ':', 71)), 1, 4) AS int) & 2147483647) % 100 < 80 THEN N'Pagada'
        WHEN (CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(id_factura, ':', 71)), 1, 4) AS int) & 2147483647) % 100 < 92 THEN N'Pendiente'
        ELSE N'Anulada' END
WHERE id_factura > @f0;
COMMIT;

-- ---------------------------------------------------------------- VALIDACIONES
IF (SELECT COUNT_BIG(*) FROM pacientes.propietarios) <> @N_PROP
 OR (SELECT COUNT_BIG(*) FROM pacientes.mascotas)    <> @N_MASC
 OR (SELECT COUNT_BIG(*) FROM clinica.citas)         <> @N_CITAS
    THROW 51105, N'Conteos de propietarios, mascotas o citas distintos a los esperados.', 1;

IF EXISTS (SELECT 1 FROM clinica.citas c
           WHERE c.id_cita > @c0 AND c.estado_c = N'Completada'
             AND NOT EXISTS (SELECT 1 FROM clinica.diagnosticos d WHERE d.id_cita = c.id_cita))
    THROW 51106, N'Hay citas Completadas sin diagnostico.', 1;

IF EXISTS (SELECT 1 FROM clinica.detalles_tratamientos WHERE id_detalle_tratamiento <= 0)
 OR EXISTS (SELECT 1 FROM facturacion.detalles_facturas WHERE id_detalle_factura <= 0)
    THROW 51107, N'Numeracion de detalles invalida.', 1;

IF EXISTS (
    SELECT 1 FROM facturacion.facturas f
    OUTER APPLY (SELECT SUM(subtotal_df) total FROM facturacion.detalles_facturas d
                 WHERE d.id_factura = f.id_factura) s
    WHERE f.total_f <> COALESCE(s.total, 0))
    THROW 51108, N'Total de factura inconsistente.', 1;

IF EXISTS (
    SELECT 1 FROM farmacia.medicamentos m
    JOIN #Stock2 s ON s.id_medicamento = m.id_medicamento
    OUTER APPLY (SELECT SUM(cantidad_df) vendidas FROM facturacion.detalles_facturas d
                 WHERE d.id_medicamento = m.id_medicamento AND d.id_factura > @f0) v
    WHERE m.stock_m <> s.stock_m - COALESCE(v.vendidas, 0))
    THROW 51109, N'Descuento de inventario inconsistente.', 1;

IF EXISTS (SELECT 1 FROM facturacion.facturas f
           WHERE f.id_factura > @f0
             AND (SELECT COUNT(*) FROM facturacion.detalles_facturas d
                  WHERE d.id_factura = f.id_factura AND d.id_cita = f.id_cita) <> 1)
    THROW 51110, N'Cada factura nueva debe tener exactamente una linea de consulta.', 1;

DROP TABLE #Stock2;
DROP TABLE #cat; DROP TABLE #nom; DROP TABLE #ape; DROP TABLE #col; DROP TABLE #pn;
PRINT N'Carga masiva completada y verificada.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

-- ---------------------------------------------------------------- RESUMEN
SELECT N'pacientes.especies' AS tabla, COUNT_BIG(*) AS registros FROM pacientes.especies
UNION ALL SELECT N'pacientes.razas',              COUNT_BIG(*) FROM pacientes.razas
UNION ALL SELECT N'pacientes.propietarios',       COUNT_BIG(*) FROM pacientes.propietarios
UNION ALL SELECT N'pacientes.mascotas',           COUNT_BIG(*) FROM pacientes.mascotas
UNION ALL SELECT N'personal.especialidades',      COUNT_BIG(*) FROM personal.especialidades
UNION ALL SELECT N'personal.veterinario',         COUNT_BIG(*) FROM personal.veterinario
UNION ALL SELECT N'farmacia.medicamentos',        COUNT_BIG(*) FROM farmacia.medicamentos
UNION ALL SELECT N'clinica.citas',                COUNT_BIG(*) FROM clinica.citas
UNION ALL SELECT N'clinica.diagnosticos',         COUNT_BIG(*) FROM clinica.diagnosticos
UNION ALL SELECT N'clinica.procedimientos',       COUNT_BIG(*) FROM clinica.procedimientos
UNION ALL SELECT N'clinica.tratamiento',          COUNT_BIG(*) FROM clinica.tratamiento
UNION ALL SELECT N'clinica.detalles_tratamientos',COUNT_BIG(*) FROM clinica.detalles_tratamientos
UNION ALL SELECT N'facturacion.facturas',         COUNT_BIG(*) FROM facturacion.facturas
UNION ALL SELECT N'facturacion.detalles_facturas',COUNT_BIG(*) FROM facturacion.detalles_facturas;

SELECT estado_c AS estado_cita, COUNT_BIG(*) AS n,
       CAST(100.0 * COUNT_BIG(*) / SUM(COUNT_BIG(*)) OVER () AS decimal(5,2)) AS pct
FROM clinica.citas GROUP BY estado_c;

SELECT estado_f AS estado_factura, COUNT_BIG(*) AS n,
       CAST(100.0 * COUNT_BIG(*) / SUM(COUNT_BIG(*)) OVER () AS decimal(5,2)) AS pct
FROM facturacion.facturas GROUP BY estado_f;
GO