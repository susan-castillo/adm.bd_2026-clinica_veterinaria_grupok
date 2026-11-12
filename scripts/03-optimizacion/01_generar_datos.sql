-- ============================================================
-- GENERACIÓN MASIVA DE DATOS - SOLO PARA PRUEBAS DE RENDIMIENTO
-- Sección 3: Consultas optimizadas e índices | Autora: Adriana
-- ============================================================
-- PROPÓSITO: agregar ~325,000 filas sintéticas (propietarios, mascotas,
--   citas, facturas) para que los índices muestren diferencias medibles.
--
-- ⚠ NO EJECUTAR EN db_veterinaria ⚠
--   Solo para veterinaria_perf, una COPIA de db_veterinaria hecha con
--   BACKUP ... COPY_ONLY y RESTORE ... WITH MOVE.
--   Ejecutarlo en db_veterinaria llenaría con datos falsos la base que
--   usan seguridad, auditoría, respaldos y Power BI.
--
-- NO ejecutar dos veces (duplica datos). Para repetirlo, restaurar de
-- nuevo la copia limpia. Tarda de 1 a 3 minutos.
-- ============================================================
USE master;
GO
ALTER DATABASE veterinaria_perf SET RECOVERY SIMPLE;
GO
USE veterinaria_perf;
GO
SET NOCOUNT ON;
GO

-- 1) PROPIETARIOS (+5,000)
;WITH n AS (
    SELECT TOP (5000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO pacientes.propietarios (dui_p, nombre_p, apellido_p, genero_p, telefono_p, telefono_secundario_p)
SELECT CONCAT(N'PERF-', i), CONCAT(N'Propietario', i), N'Prueba',
       CASE WHEN i % 2 = 0 THEN N'M' ELSE N'F' END,
       CONCAT(N'T-', i), CONCAT(N'S-', i)
FROM n;
GO

-- 2) MASCOTAS (+20,000)
DECLARE @maxProp BIGINT = (SELECT MAX(id_propietario) FROM pacientes.propietarios);
DECLARE @maxRaza BIGINT = (SELECT MAX(id_raza) FROM pacientes.razas);

SELECT TOP (20000)
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i,
    1 + ABS(CHECKSUM(NEWID()) % @maxProp) AS id_propietario,
    1 + ABS(CHECKSUM(NEWID()) % @maxRaza) AS id_raza,
    ABS(CHECKSUM(NEWID()) % 5475) AS dias,
    ABS(CHECKSUM(NEWID()) % 2)    AS sexo,
    ABS(CHECKSUM(NEWID()) % 4000) AS peso
INTO #gen_m
FROM sys.all_objects a CROSS JOIN sys.all_objects b;

INSERT INTO pacientes.mascotas (id_propietario, id_raza, nombre_m, fecha_nacimiento, sexo_m, peso_m)
SELECT id_propietario, id_raza, CONCAT(N'Mascota', i),
       DATEADD(DAY, -dias, CAST(GETDATE() AS DATE)),
       CASE WHEN sexo = 0 THEN N'Macho' ELSE N'Hembra' END,
       CAST(1 + peso / 100.0 AS DECIMAL(6,2))
FROM #gen_m;

DROP TABLE #gen_m;
GO

-- 3) CITAS (+300,000, últimos 3 años)
DECLARE @maxMasc BIGINT = (SELECT MAX(id_mascota)    FROM pacientes.mascotas);
DECLARE @maxVet  BIGINT = (SELECT MAX(id_veterinario) FROM personal.veterinario);

SELECT TOP (300000)
    1 + ABS(CHECKSUM(NEWID()) % @maxMasc) AS id_mascota,
    1 + ABS(CHECKSUM(NEWID()) % @maxVet)  AS id_veterinario,
    ABS(CHECKSUM(NEWID()) % 94608000)     AS seg,
    ABS(CHECKSUM(NEWID()) % 100)          AS r_estado,
    ABS(CHECKSUM(NEWID()) % 5)            AS r_motivo,
    ABS(CHECKSUM(NEWID()) % 28500)        AS r_costo
INTO #gen_c
FROM sys.all_objects a CROSS JOIN sys.all_objects b CROSS JOIN sys.all_objects c;

INSERT INTO clinica.citas (id_mascota, id_veterinario, fecha_c, motivo_c, estado_c, costo_c)
SELECT id_mascota, id_veterinario,
       DATEADD(SECOND, -seg, SYSDATETIME()),
       CHOOSE(r_motivo + 1, N'Consulta general', N'Vacunación', N'Control', N'Emergencia', N'Cirugía'),
       CASE WHEN r_estado < 85 THEN N'Completada' ELSE N'Cancelada' END,
       CAST(15 + r_costo / 100.0 AS DECIMAL(10,2))
FROM #gen_c;

DROP TABLE #gen_c;
GO

-- 4) FACTURAS (~70% de las citas completadas nuevas)
INSERT INTO facturacion.facturas (id_cita, fecha_emision_f, estado_f, total_f)
SELECT c.id_cita, CAST(c.fecha_c AS DATE),
       CASE (c.id_cita / 7) % 10 WHEN 8 THEN N'Pendiente' WHEN 9 THEN N'Anulada' ELSE N'Pagada' END,
       c.costo_c
FROM clinica.citas c
WHERE c.estado_c = N'Completada' AND c.id_cita > 50 AND c.id_cita % 100 < 70;
GO

-- 5) CONTEO FINAL
SELECT s.name AS esquema, t.name AS tabla, SUM(p.rows) AS filas
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;
GO