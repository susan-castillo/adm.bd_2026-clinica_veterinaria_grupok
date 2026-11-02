-- ============================================================
-- SCRIPT DDL - Sistema de Gestión Veterinaria
-- Versión mejorada con validaciones de integridad
-- Versión T-SQL (SQL Server 2017+), migrada desde PostgreSQL
-- ============================================================
-- Notas de la migración:
--  * Texto: VARCHAR(n) -> NVARCHAR(n), TEXT -> NVARCHAR(MAX).
--  * TIMESTAMP -> DATETIME2 (en SQL Server TIMESTAMP es otro tipo: rowversion).
--  * ON DELETE RESTRICT -> NO ACTION (equivalente; SQL Server no tiene RESTRICT).
--  * ON UPDATE CASCADE -> NO ACTION: los ids son IDENTITY (nunca se actualizan) y, además,
--    SQL Server rechaza (error 1785) los múltiples caminos en cascada, p. ej.
--    citas -> detalles_facturas y citas -> facturas -> detalles_facturas.
--  * UNIQUE sobre columnas opcionales -> índice único filtrado (WHERE col IS NOT NULL),
--    porque un UNIQUE de SQL Server solo admite un NULL y PostgreSQL admite varios.
--  * CHECK con NOW()/CURRENT_DATE -> GETDATE().
--  * id_detalle_* llevan DEFAULT 0: el trigger INSTEAD OF los reemplaza, pero así el INSERT puede omitirlos.
-- ============================================================

-- 1. Cambiar el contexto a la base de datos master para no bloquearla tú mismo
-- USE master;
-- GO

-- 2. Cambiar la base de datos a SINGLE_USER expulsando todas las conexiones activas inmediatamente
-- ALTER DATABASE db_veterinaria 
-- SET SINGLE_USER 
-- WITH ROLLBACK IMMEDIATE;
-- GO

-- 3. Eliminar la base de datos
-- DROP DATABASE db_veterinaria;
-- GO

CREATE DATABASE db_veterinaria;
GO
USE db_veterinaria;
GO

-- ============================================================
-- 1. TABLA: especies
-- ============================================================
CREATE TABLE especies (
    id_especie        BIGINT         IDENTITY(1,1) NOT NULL,
    nombre_e          NVARCHAR(100)  NOT NULL,
    descripcion_e     NVARCHAR(MAX)  NOT NULL,
    CONSTRAINT pk_especies PRIMARY KEY (id_especie),
    CONSTRAINT uq_especie_nombre UNIQUE (nombre_e)
);

-- ============================================================
-- 2. TABLA: razas
-- ============================================================
CREATE TABLE razas (
    id_raza           BIGINT         IDENTITY(1,1) NOT NULL,
    id_especie        BIGINT         NOT NULL,
    nombre_r          NVARCHAR(100)  NOT NULL,
    CONSTRAINT pk_razas PRIMARY KEY (id_raza),
    CONSTRAINT fk_razas_especie
        FOREIGN KEY (id_especie) REFERENCES especies (id_especie)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT uq_raza_por_especie UNIQUE (id_especie, nombre_r)
);

-- ============================================================
-- 3. TABLA: propietarios
-- ============================================================
CREATE TABLE propietarios (
    id_propietario          BIGINT         IDENTITY(1,1) NOT NULL,
    dui_p                   NVARCHAR(20)   NOT NULL,
    nombre_p                NVARCHAR(100)  NOT NULL,
    apellido_p              NVARCHAR(100)  NOT NULL,
    genero_p                NVARCHAR(10),
    telefono_p              NVARCHAR(20)   NOT NULL,
    telefono_secundario_p   NVARCHAR(20)   NOT NULL,
    correo_p                NVARCHAR(150),
    direccion_p             NVARCHAR(MAX),
    CONSTRAINT pk_propietarios PRIMARY KEY (id_propietario),
    CONSTRAINT uq_propietarios_dui UNIQUE (dui_p),
    CONSTRAINT uq_propietarios_telefono UNIQUE (telefono_p),
    CONSTRAINT chk_genero_p CHECK (genero_p IN ('M', 'F', 'Otro')),
    CONSTRAINT chk_correo_p CHECK (correo_p IS NULL OR correo_p LIKE '%@%.%'),
    CONSTRAINT chk_dui_p CHECK (LEN(TRIM(dui_p)) > 0),
    CONSTRAINT chk_telefonos_distintos CHECK (telefono_p <> telefono_secundario_p)
);
-- UNIQUE opcional: permite varios NULL, como en PostgreSQL
CREATE UNIQUE INDEX uq_propietarios_correo ON propietarios (correo_p) WHERE correo_p IS NOT NULL;

-- ============================================================
-- 4. TABLA: mascotas
-- ============================================================
CREATE TABLE mascotas (
    id_mascota        BIGINT            IDENTITY(1,1) NOT NULL,
    id_propietario    BIGINT            NOT NULL,
    id_raza           BIGINT            NOT NULL,
    nombre_m          NVARCHAR(100)     NOT NULL,
    fecha_nacimiento  DATE,
    sexo_m            NVARCHAR(10),
    peso_m            DECIMAL(6,2),
    tamanio_m         NVARCHAR(50),
    CONSTRAINT pk_mascotas PRIMARY KEY (id_mascota),
    CONSTRAINT fk_mascotas_propietario
        FOREIGN KEY (id_propietario) REFERENCES propietarios (id_propietario)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_mascotas_raza
        FOREIGN KEY (id_raza) REFERENCES razas (id_raza)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT chk_sexo_m CHECK (sexo_m IN ('Macho', 'Hembra')),
    CONSTRAINT chk_peso_m CHECK (peso_m IS NULL OR peso_m > 0),
    CONSTRAINT chk_fecha_nacimiento CHECK (fecha_nacimiento IS NULL OR fecha_nacimiento <= CAST(GETDATE() AS DATE)),
    CONSTRAINT chk_nombre_mascota CHECK (LEN(TRIM(nombre_m)) > 0)
);

-- ============================================================
-- 5. TABLA: especialidades
-- ============================================================
CREATE TABLE especialidades (
    id_especialidad   BIGINT         IDENTITY(1,1) NOT NULL,
    nombre_esp        NVARCHAR(150)  NOT NULL,
    descripcion_esp   NVARCHAR(MAX),
    CONSTRAINT pk_especialidades PRIMARY KEY (id_especialidad),
    CONSTRAINT uq_especialidad_nombre UNIQUE (nombre_esp)
);

-- ============================================================
-- 6. TABLA: veterinario
-- ============================================================
CREATE TABLE veterinario (
    id_veterinario    BIGINT         IDENTITY(1,1) NOT NULL,
    id_especialidad   BIGINT         NOT NULL,
    nombre_v          NVARCHAR(100)  NOT NULL,
    apellido_v        NVARCHAR(100)  NOT NULL,
    telefono_v        NVARCHAR(20),
    correo_v          NVARCHAR(150),
    CONSTRAINT pk_veterinario PRIMARY KEY (id_veterinario),
    CONSTRAINT fk_veterinario_especialidad
        FOREIGN KEY (id_especialidad) REFERENCES especialidades (id_especialidad)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT chk_correo_v CHECK (correo_v IS NULL OR correo_v LIKE '%@%.%'),
    CONSTRAINT chk_nombre_v CHECK (LEN(TRIM(nombre_v)) > 0),
    CONSTRAINT chk_apellido_v CHECK (LEN(TRIM(apellido_v)) > 0)
);
-- UNIQUE opcionales: permiten varios NULL, como en PostgreSQL
CREATE UNIQUE INDEX uq_veterinario_telefono ON veterinario (telefono_v) WHERE telefono_v IS NOT NULL;
CREATE UNIQUE INDEX uq_veterinario_correo   ON veterinario (correo_v)   WHERE correo_v IS NOT NULL;

-- ============================================================
-- 7. TABLA: citas
-- ============================================================
CREATE TABLE citas (
    id_cita           BIGINT         IDENTITY(1,1) NOT NULL,
    id_mascota        BIGINT         NOT NULL,
    id_veterinario    BIGINT         NOT NULL,
    fecha_c           DATETIME2      NOT NULL,
    motivo_c          NVARCHAR(MAX),
    estado_c          NVARCHAR(20)   NOT NULL CONSTRAINT df_citas_estado_c DEFAULT 'Programada',
    costo_c           DECIMAL(10,2),
    CONSTRAINT pk_citas PRIMARY KEY (id_cita),
    CONSTRAINT fk_citas_mascota
        FOREIGN KEY (id_mascota) REFERENCES mascotas (id_mascota)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_citas_veterinario
        FOREIGN KEY (id_veterinario) REFERENCES veterinario (id_veterinario)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT chk_estado_c
        CHECK (estado_c IN ('Programada', 'En curso', 'Completada', 'Cancelada')),
    CONSTRAINT chk_costo_c CHECK (costo_c IS NULL OR costo_c >= 0),
    CONSTRAINT chk_fecha_cita_programada
        CHECK (estado_c <> 'Programada' OR fecha_c >= DATEADD(HOUR, -1, GETDATE()))
);

-- ============================================================
-- 8. TABLA: diagnosticos
-- ============================================================
CREATE TABLE diagnosticos (
    id_diagnostico    BIGINT            IDENTITY(1,1) NOT NULL,
    id_cita           BIGINT            NOT NULL,
    descripcion_d     NVARCHAR(MAX)     NOT NULL,
    observaciones_d   NVARCHAR(MAX),
    fecha_d           DATE,
    CONSTRAINT pk_diagnosticos PRIMARY KEY (id_diagnostico),
    CONSTRAINT uq_diagnosticos_cita UNIQUE (id_cita),
    CONSTRAINT fk_diagnosticos_cita
        FOREIGN KEY (id_cita) REFERENCES citas (id_cita)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT chk_fecha_diagnostico
        CHECK (fecha_d IS NULL OR fecha_d <= CAST(GETDATE() AS DATE)),
    CONSTRAINT chk_descripcion_diagnostico
        CHECK (LEN(TRIM(descripcion_d)) > 0)
);

-- ============================================================
-- 9. TABLA: procedimientos
-- ============================================================
CREATE TABLE procedimientos (
    id_procedimiento   BIGINT           IDENTITY(1,1) NOT NULL,
    id_diagnostico    BIGINT           NOT NULL,
    nombre_p          NVARCHAR(100),
    descripcion_p     NVARCHAR(MAX),
    costo_p           DECIMAL(10,2),
    CONSTRAINT pk_procedimientos PRIMARY KEY (id_procedimiento),
    CONSTRAINT fk_procedimientos_diagnostico
        FOREIGN KEY (id_diagnostico)
        REFERENCES diagnosticos (id_diagnostico)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT chk_costo_p CHECK (costo_p IS NULL OR costo_p >= 0),
    CONSTRAINT chk_nombre_procedimiento
        CHECK (nombre_p IS NULL OR LEN(TRIM(nombre_p)) > 0)
);

-- ============================================================
-- 10. TABLA: tratamiento
-- ============================================================
CREATE TABLE tratamiento (
    id_tratamiento      BIGINT           IDENTITY(1,1) NOT NULL,
    id_diagnostico      BIGINT           NOT NULL,
    fecha_inicio        DATE,
    fecha_fin           DATE,
    descripcion_t       NVARCHAR(MAX),
    indicaciones_t      NVARCHAR(MAX),
    CONSTRAINT pk_tratamiento PRIMARY KEY (id_tratamiento),
    CONSTRAINT fk_tratamiento_diagnostico
        FOREIGN KEY (id_diagnostico)
        REFERENCES diagnosticos (id_diagnostico)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT chk_fechas_tratamiento
        CHECK (fecha_inicio IS NULL OR fecha_fin IS NULL OR fecha_inicio <= fecha_fin),
    CONSTRAINT chk_fecha_inicio_minima
        CHECK (fecha_inicio IS NULL OR fecha_inicio >= '2000-01-01'),
    CONSTRAINT chk_fecha_fin_requiere_inicio
        CHECK (fecha_fin IS NULL OR fecha_inicio IS NOT NULL)
);

-- ============================================================
-- 11. TABLA: medicamentos
-- ============================================================
CREATE TABLE medicamentos (
    id_medicamento    BIGINT            IDENTITY(1,1) NOT NULL,
    nombre_m          NVARCHAR(150)     NOT NULL,
    presentacion_m    NVARCHAR(100),
    laboratorio_m     NVARCHAR(150),
    precio_m          DECIMAL(10,2)     NOT NULL CONSTRAINT df_medicamentos_precio_m DEFAULT 0,
    stock_m           INT               NOT NULL CONSTRAINT df_medicamentos_stock_m DEFAULT 0,
    CONSTRAINT pk_medicamentos PRIMARY KEY (id_medicamento),
    CONSTRAINT chk_precio_m CHECK (precio_m >= 0),
    CONSTRAINT chk_stock_m CHECK (stock_m >= 0),
    -- Nota: en SQL Server (nombre_m, NULL) solo puede existir una vez; en PostgreSQL podía repetirse
    CONSTRAINT uq_medicamento_nombre_presentacion
        UNIQUE (nombre_m, presentacion_m),
    CONSTRAINT chk_nombre_medicamento
        CHECK (LEN(TRIM(nombre_m)) > 0)
);

-- ============================================================
-- 12. TABLA: detalles_tratamientos (ENTIDAD DÉBIL)
-- ============================================================
CREATE TABLE detalles_tratamientos (
    id_detalle_tratamiento  BIGINT       NOT NULL CONSTRAINT df_dt_id_detalle DEFAULT 0, -- Controlado por trigger (INSTEAD OF)
    id_tratamiento          BIGINT       NOT NULL,
    id_medicamento          BIGINT       NOT NULL,
    dosis_dt                NVARCHAR(100),
    frecuencia_dt           NVARCHAR(100),
    duracion_dias_dt        INT,
    CONSTRAINT pk_detalles_tratamientos PRIMARY KEY (id_tratamiento, id_detalle_tratamiento),
    CONSTRAINT fk_dt_tratamiento
        FOREIGN KEY (id_tratamiento)
        REFERENCES tratamiento (id_tratamiento)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT fk_dt_medicamento
        FOREIGN KEY (id_medicamento)
        REFERENCES medicamentos (id_medicamento)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT chk_duracion
        CHECK (duracion_dias_dt IS NULL OR duracion_dias_dt > 0),
    CONSTRAINT uq_medicamento_por_tratamiento
        UNIQUE (id_tratamiento, id_medicamento),
    CONSTRAINT chk_duracion_maxima
        CHECK (duracion_dias_dt IS NULL OR duracion_dias_dt <= 365)
);

-- ============================================================
-- 13. TABLA: facturas
-- ============================================================
CREATE TABLE facturas (
    id_factura        BIGINT         IDENTITY(1,1) NOT NULL,
    id_cita           BIGINT,
    fecha_emision_f   DATE           NOT NULL,
    estado_f          NVARCHAR(50)   CONSTRAINT df_facturas_estado_f DEFAULT 'Pendiente',
    total_f           DECIMAL(10,2)  CONSTRAINT df_facturas_total_f DEFAULT 0,
    CONSTRAINT pk_facturas PRIMARY KEY (id_factura),
    CONSTRAINT fk_facturas_cita
        FOREIGN KEY (id_cita)
        REFERENCES citas (id_cita)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT chk_estado_f
        CHECK (estado_f IN ('Pendiente', 'Pagada', 'Anulada', 'Cancelada')),
    CONSTRAINT chk_total_f
        CHECK (total_f >= 0),
    CONSTRAINT chk_fecha_emision_f
        CHECK (fecha_emision_f <= CAST(GETDATE() AS DATE)),
    CONSTRAINT chk_factura_pagada_con_total
        CHECK (estado_f <> 'Pagada' OR total_f > 0)
);
-- UNIQUE opcional: permite varios NULL, como en PostgreSQL
CREATE UNIQUE INDEX uq_facturas_cita ON facturas (id_cita) WHERE id_cita IS NOT NULL;

-- ============================================================
-- 14. TABLA: detalles_facturas (ENTIDAD DÉBIL)
-- ============================================================
CREATE TABLE detalles_facturas (
    id_detalle_factura  BIGINT           NOT NULL CONSTRAINT df_df_id_detalle DEFAULT 0, -- Controlado por trigger (INSTEAD OF)
    id_factura          BIGINT           NOT NULL,
    id_cita             BIGINT           NULL,
    id_medicamento      BIGINT           NULL,
    id_tratamiento      BIGINT           NULL,
    id_procedimiento    BIGINT           NULL,
    descripcion_df      NVARCHAR(MAX)    NOT NULL,
    cantidad_df         BIGINT           NOT NULL CONSTRAINT df_detalles_facturas_cantidad DEFAULT 1,
    precio_unit_df      DECIMAL(10,2)    NOT NULL CONSTRAINT df_detalles_facturas_precio DEFAULT 0,
    subtotal_df         AS (CAST(cantidad_df * precio_unit_df AS DECIMAL(10,2))) PERSISTED,
    CONSTRAINT pk_detalles_facturas PRIMARY KEY (id_factura, id_detalle_factura),
    CONSTRAINT fk_df_factura
        FOREIGN KEY (id_factura)
        REFERENCES facturas (id_factura)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT fk_df_cita
        FOREIGN KEY (id_cita)
        REFERENCES citas (id_cita)
        ON UPDATE NO ACTION ON DELETE SET NULL,
    CONSTRAINT fk_df_medicamento
        FOREIGN KEY (id_medicamento)
        REFERENCES medicamentos (id_medicamento)
        ON UPDATE NO ACTION ON DELETE SET NULL,
    CONSTRAINT fk_df_tratamiento
        FOREIGN KEY (id_tratamiento)
        REFERENCES tratamiento (id_tratamiento)
        ON UPDATE NO ACTION ON DELETE SET NULL,
    CONSTRAINT fk_df_procedimiento
        FOREIGN KEY (id_procedimiento)
        REFERENCES procedimientos (id_procedimiento)
        ON UPDATE NO ACTION ON DELETE SET NULL,
    CONSTRAINT chk_cantidad_df
        CHECK (cantidad_df > 0),
    CONSTRAINT chk_precio_unit_df
        CHECK (precio_unit_df >= 0),
    CONSTRAINT chk_descripcion_df
        CHECK (LEN(TRIM(descripcion_df)) > 0),
    -- Exactamente uno de los campos de referencia debe estar poblado
    CONSTRAINT chk_un_solo_item CHECK (
        (id_cita IS NOT NULL AND id_medicamento IS NULL AND id_tratamiento IS NULL AND id_procedimiento IS NULL) OR
        (id_cita IS NULL AND id_medicamento IS NOT NULL AND id_tratamiento IS NOT NULL AND id_procedimiento IS NULL) OR
        (id_cita IS NULL AND id_medicamento IS NULL AND id_tratamiento IS NULL AND id_procedimiento IS NOT NULL)
    )
);
