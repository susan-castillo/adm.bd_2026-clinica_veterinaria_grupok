-- ============================================================
-- SCRIPT DDL - Sistema de Gestión Veterinaria
-- Versión T-SQL (SQL Server 2017+), migrada desde PostgreSQL
-- Versión corregida: compila y se ejecuta sin errores
-- ============================================================

-- PARA ELIMINAR LA BASE DE DATOS (opcional, descomentar si se requiere)
-- USE master;
-- GO
-- ALTER DATABASE db_veterinaria SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
-- GO
-- DROP DATABASE db_veterinaria;
-- GO

CREATE DATABASE db_veterinaria;
GO
USE db_veterinaria;
GO


-- ESQUEMAS

CREATE SCHEMA pacientes   AUTHORIZATION dbo; GO
CREATE SCHEMA personal    AUTHORIZATION dbo; GO
CREATE SCHEMA clinica     AUTHORIZATION dbo; GO
CREATE SCHEMA farmacia    AUTHORIZATION dbo; GO
CREATE SCHEMA facturacion AUTHORIZATION dbo; GO

-- 1. especies

CREATE TABLE pacientes.especies (
    id_especie        BIGINT         IDENTITY(1,1) NOT NULL,
    nombre_e          NVARCHAR(100)  NOT NULL,
    descripcion_e     NVARCHAR(MAX)  NOT NULL,
    CONSTRAINT pk_especies PRIMARY KEY (id_especie),
    CONSTRAINT uq_especie_nombre UNIQUE (nombre_e)
);


-- 2. razas
CREATE TABLE pacientes.razas (
    id_raza           BIGINT         IDENTITY(1,1) NOT NULL,
    id_especie        BIGINT         NOT NULL,
    nombre_r          NVARCHAR(100)  NOT NULL,
    CONSTRAINT pk_razas PRIMARY KEY (id_raza),
    CONSTRAINT fk_razas_especie
        FOREIGN KEY (id_especie) REFERENCES pacientes.especies (id_especie)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT uq_raza_por_especie UNIQUE (id_especie, nombre_r)
);


-- 3. propietarios

CREATE TABLE pacientes.propietarios (
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
    CONSTRAINT chk_genero_p CHECK (genero_p IS NULL OR genero_p IN ('M', 'F', 'Otro')),
    CONSTRAINT chk_correo_p CHECK (correo_p IS NULL OR correo_p LIKE '%@%.%'),
    CONSTRAINT chk_dui_p CHECK (LEN(TRIM(dui_p)) > 0),
    CONSTRAINT chk_telefonos_distintos CHECK (telefono_p <> telefono_secundario_p)
);
CREATE UNIQUE INDEX uq_propietarios_correo
    ON pacientes.propietarios (correo_p) WHERE correo_p IS NOT NULL;
GO


-- 4. mascotas
CREATE TABLE pacientes.mascotas (
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
        FOREIGN KEY (id_propietario) REFERENCES pacientes.propietarios (id_propietario)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_mascotas_raza
        FOREIGN KEY (id_raza) REFERENCES pacientes.razas (id_raza)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT chk_sexo_m CHECK (sexo_m IS NULL OR sexo_m IN ('Macho', 'Hembra')),
    CONSTRAINT chk_peso_m CHECK (peso_m IS NULL OR peso_m > 0),
    CONSTRAINT chk_nombre_mascota CHECK (LEN(TRIM(nombre_m)) > 0)
);
GO


-- 5. especialidades

CREATE TABLE personal.especialidades (
    id_especialidad   BIGINT         IDENTITY(1,1) NOT NULL,
    nombre_esp        NVARCHAR(150)  NOT NULL,
    descripcion_esp   NVARCHAR(MAX),
    CONSTRAINT pk_especialidades PRIMARY KEY (id_especialidad),
    CONSTRAINT uq_especialidad_nombre UNIQUE (nombre_esp)
);


-- 6. veterinario

CREATE TABLE personal.veterinario (
    id_veterinario    BIGINT         IDENTITY(1,1) NOT NULL,
    id_especialidad   BIGINT         NOT NULL,
    nombre_v          NVARCHAR(100)  NOT NULL,
    apellido_v        NVARCHAR(100)  NOT NULL,
    telefono_v        NVARCHAR(20),
    correo_v          NVARCHAR(150),
    CONSTRAINT pk_veterinario PRIMARY KEY (id_veterinario),
    CONSTRAINT fk_veterinario_especialidad
        FOREIGN KEY (id_especialidad) REFERENCES personal.especialidades (id_especialidad)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT chk_correo_v CHECK (correo_v IS NULL OR correo_v LIKE '%@%.%'),
    CONSTRAINT chk_nombre_v CHECK (LEN(TRIM(nombre_v)) > 0),
    CONSTRAINT chk_apellido_v CHECK (LEN(TRIM(apellido_v)) > 0)
);
CREATE UNIQUE INDEX uq_veterinario_telefono ON personal.veterinario (telefono_v) WHERE telefono_v IS NOT NULL;
CREATE UNIQUE INDEX uq_veterinario_correo   ON personal.veterinario (correo_v)   WHERE correo_v IS NOT NULL;
GO


-- 7. citas
-- ✅ FIX: se quitó GETDATE() del CHECK. Se valida por trigger AFTER.

CREATE TABLE clinica.citas (
    id_cita           BIGINT         IDENTITY(1,1) NOT NULL,
    id_mascota        BIGINT         NOT NULL,
    id_veterinario    BIGINT         NOT NULL,
    fecha_c           DATETIME2      NOT NULL,
    motivo_c          NVARCHAR(MAX),
    estado_c          NVARCHAR(20)   NOT NULL CONSTRAINT df_citas_estado_c DEFAULT 'Programada',
    costo_c           DECIMAL(10,2),
    CONSTRAINT pk_citas PRIMARY KEY (id_cita),
    CONSTRAINT fk_citas_mascota
        FOREIGN KEY (id_mascota) REFERENCES pacientes.mascotas (id_mascota)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_citas_veterinario
        FOREIGN KEY (id_veterinario) REFERENCES personal.veterinario (id_veterinario)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT chk_estado_c
        CHECK (estado_c IN ('Programada', 'En curso', 'Completada', 'Cancelada')),
    CONSTRAINT chk_costo_c CHECK (costo_c IS NULL OR costo_c >= 0)
);
GO


-- 8. diagnosticos


CREATE TABLE clinica.diagnosticos (
    id_diagnostico    BIGINT            IDENTITY(1,1) NOT NULL,
    id_cita           BIGINT            NOT NULL,
    descripcion_d     NVARCHAR(MAX)     NOT NULL,
    observaciones_d   NVARCHAR(MAX),
    fecha_d           DATE,
    CONSTRAINT pk_diagnosticos PRIMARY KEY (id_diagnostico),
    CONSTRAINT uq_diagnosticos_cita UNIQUE (id_cita),
    CONSTRAINT fk_diagnosticos_cita
        FOREIGN KEY (id_cita) REFERENCES clinica.citas (id_cita)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT chk_descripcion_diagnostico
        CHECK (LEN(TRIM(descripcion_d)) > 0)
);
GO


-- 9. procedimientos

CREATE TABLE clinica.procedimientos (
    id_procedimiento   BIGINT           IDENTITY(1,1) NOT NULL,
    id_diagnostico     BIGINT           NOT NULL,
    nombre_p           NVARCHAR(100),
    descripcion_p      NVARCHAR(MAX),
    costo_p            DECIMAL(10,2),
    CONSTRAINT pk_procedimientos PRIMARY KEY (id_procedimiento),
    CONSTRAINT fk_procedimientos_diagnostico
        FOREIGN KEY (id_diagnostico)
        REFERENCES clinica.diagnosticos (id_diagnostico)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT chk_costo_p CHECK (costo_p IS NULL OR costo_p >= 0),
    CONSTRAINT chk_nombre_procedimiento
        CHECK (nombre_p IS NULL OR LEN(TRIM(nombre_p)) > 0)
);

-- 10. tratamiento

CREATE TABLE clinica.tratamiento (
    id_tratamiento      BIGINT           IDENTITY(1,1) NOT NULL,
    id_diagnostico      BIGINT           NOT NULL,
    fecha_inicio        DATE,
    fecha_fin           DATE,
    descripcion_t       NVARCHAR(MAX),
    indicaciones_t      NVARCHAR(MAX),
    CONSTRAINT pk_tratamiento PRIMARY KEY (id_tratamiento),
    CONSTRAINT fk_tratamiento_diagnostico
        FOREIGN KEY (id_diagnostico)
        REFERENCES clinica.diagnosticos (id_diagnostico)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT chk_fechas_tratamiento
        CHECK (fecha_inicio IS NULL OR fecha_fin IS NULL OR fecha_inicio <= fecha_fin),
    CONSTRAINT chk_fecha_inicio_minima
        CHECK (fecha_inicio IS NULL OR fecha_inicio >= '2000-01-01'),
    CONSTRAINT chk_fecha_fin_requiere_inicio
        CHECK (fecha_fin IS NULL OR fecha_inicio IS NOT NULL)
);
GO


-- 11. medicamentos

CREATE TABLE farmacia.medicamentos (
    id_medicamento    BIGINT            IDENTITY(1,1) NOT NULL,
    nombre_m          NVARCHAR(150)     NOT NULL,
    presentacion_m    NVARCHAR(100),
    laboratorio_m     NVARCHAR(150),
    precio_m          DECIMAL(10,2)     NOT NULL CONSTRAINT df_medicamentos_precio_m DEFAULT 0,
    stock_m           INT               NOT NULL CONSTRAINT df_medicamentos_stock_m DEFAULT 0,
    CONSTRAINT pk_medicamentos PRIMARY KEY (id_medicamento),
    CONSTRAINT chk_precio_m CHECK (precio_m >= 0),
    CONSTRAINT chk_stock_m CHECK (stock_m >= 0),
    CONSTRAINT chk_nombre_medicamento
        CHECK (LEN(TRIM(nombre_m)) > 0)
);
-- Unicidad (nombre_m, presentacion_m) permitiendo varios NULL en presentacion_m
CREATE UNIQUE INDEX uq_medicamento_nombre_presentacion
    ON farmacia.medicamentos (nombre_m, presentacion_m)
    WHERE presentacion_m IS NOT NULL;
CREATE UNIQUE INDEX uq_medicamento_nombre_sin_presentacion
    ON farmacia.medicamentos (nombre_m)
    WHERE presentacion_m IS NULL;
GO


-- 12. detalles_tratamientos (ENTIDAD DÉBIL)
CREATE TABLE clinica.detalles_tratamientos (
    id_detalle_tratamiento  BIGINT       NOT NULL CONSTRAINT df_dt_id_detalle DEFAULT 0,
    id_tratamiento          BIGINT       NOT NULL,
    id_medicamento          BIGINT       NOT NULL,
    dosis_dt                NVARCHAR(100),
    frecuencia_dt           NVARCHAR(100),
    duracion_dias_dt        INT,
    CONSTRAINT pk_detalles_tratamientos PRIMARY KEY (id_tratamiento, id_detalle_tratamiento),
    CONSTRAINT fk_dt_tratamiento
        FOREIGN KEY (id_tratamiento)
        REFERENCES clinica.tratamiento (id_tratamiento)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT fk_dt_medicamento
        FOREIGN KEY (id_medicamento)
        REFERENCES farmacia.medicamentos (id_medicamento)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT chk_duracion
        CHECK (duracion_dias_dt IS NULL OR duracion_dias_dt > 0),
    CONSTRAINT uq_medicamento_por_tratamiento
        UNIQUE (id_tratamiento, id_medicamento),
    CONSTRAINT chk_duracion_maxima
        CHECK (duracion_dias_dt IS NULL OR duracion_dias_dt <= 365)
);
GO


-- 13. facturas

CREATE TABLE facturacion.facturas (
    id_factura        BIGINT         IDENTITY(1,1) NOT NULL,
    id_cita           BIGINT,
    fecha_emision_f   DATE           NOT NULL,
    estado_f          NVARCHAR(50)   CONSTRAINT df_facturas_estado_f DEFAULT 'Pendiente',
    total_f           DECIMAL(10,2)  CONSTRAINT df_facturas_total_f DEFAULT 0,
    CONSTRAINT pk_facturas PRIMARY KEY (id_factura),
    CONSTRAINT fk_facturas_cita
        FOREIGN KEY (id_cita)
        REFERENCES clinica.citas (id_cita)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT chk_estado_f
        CHECK (estado_f IN ('Pendiente', 'Pagada', 'Anulada', 'Cancelada')),
    CONSTRAINT chk_total_f
        CHECK (total_f >= 0),
    CONSTRAINT chk_factura_pagada_con_total
        CHECK (estado_f <> 'Pagada' OR total_f > 0)
);
CREATE UNIQUE INDEX uq_facturas_cita
    ON facturacion.facturas (id_cita) WHERE id_cita IS NOT NULL;
GO

-- ============================================================
-- 14. detalles_facturas (ENTIDAD DÉBIL)
-- ✅ FIX 1: chk_un_solo_item corregido (permite exactamente UNA referencia,
--          o bien la combinación medicamento+tratamiento que indica tu lógica).
-- ✅ FIX 2: ON DELETE SET NULL cambia a NO ACTION para no violar chk_un_solo_item.
-- ============================================================
CREATE TABLE facturacion.detalles_facturas (
    id_detalle_factura  BIGINT           NOT NULL CONSTRAINT df_df_id_detalle DEFAULT 0,
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
        REFERENCES facturacion.facturas (id_factura)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT fk_df_cita
        FOREIGN KEY (id_cita)
        REFERENCES clinica.citas (id_cita)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_df_medicamento
        FOREIGN KEY (id_medicamento)
        REFERENCES farmacia.medicamentos (id_medicamento)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_df_tratamiento
        FOREIGN KEY (id_tratamiento)
        REFERENCES clinica.tratamiento (id_tratamiento)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_df_procedimiento
        FOREIGN KEY (id_procedimiento)
        REFERENCES clinica.procedimientos (id_procedimiento)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT chk_cantidad_df
        CHECK (cantidad_df > 0),
    CONSTRAINT chk_precio_unit_df
        CHECK (precio_unit_df >= 0),
    CONSTRAINT chk_descripcion_df
        CHECK (LEN(TRIM(descripcion_df)) > 0),
    -- Exactamente una referencia (cita, procedimiento) o el par medicamento+tratamiento
    CONSTRAINT chk_un_solo_item CHECK (
        (id_cita         IS NOT NULL AND id_medicamento IS NULL     AND id_tratamiento IS NULL     AND id_procedimiento IS NULL)
     OR (id_cita         IS NULL     AND id_medicamento IS NOT NULL AND id_tratamiento IS NOT NULL AND id_procedimiento IS NULL)
     OR (id_cita         IS NULL     AND id_medicamento IS NULL     AND id_tratamiento IS NULL     AND id_procedimiento IS NOT NULL)
    )
);
GO