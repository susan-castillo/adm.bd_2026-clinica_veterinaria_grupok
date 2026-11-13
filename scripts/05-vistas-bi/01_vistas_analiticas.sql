USE db_veterinaria;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bi')
    BEGIN
        EXEC('CREATE SCHEMA bi');
    END
GO

-- ============================================================
-- VISTA 1: Tarjetas de KPIs Ejecutivos (Hecho Global)
-- ============================================================
-- MEDIDAS: Ingresos Totales, Citas Completadas, Mascotas Registradas, Ticket Promedio.
CREATE OR ALTER VIEW bi.v_kpis_empresariales AS
SELECT
    (SELECT ISNULL(SUM(total_f), 0) FROM facturacion.facturas WHERE estado_f = 'Pagada') AS Ingresos_Totales,
    (SELECT COUNT(id_cita) FROM clinica.citas WHERE estado_c = 'Completada') AS Citas_Completadas,
    (SELECT COUNT(id_mascota) FROM pacientes.mascotas) AS Total_Mascotas_Registradas,
    (SELECT ISNULL(AVG(costo_c), 0) FROM clinica.citas WHERE estado_c = 'Completada') AS Ticket_Promedio_Cita;
GO

-- ============================================================
-- VISTA 2: Facturación Mensual por Especialidad (Tendencia Temporal)
-- ============================================================
-- MEDIDAS: TotalFacturado, TotalCitasAtendidas.
-- DIMENSIONES: Especialidad, Año, MesNum, MesNombre.
CREATE OR ALTER VIEW bi.v_ingresos_por_especialidad AS
SELECT
    e.nombre_esp AS Especialidad,
    YEAR(f.fecha_emision_f) AS Anio,
    MONTH(f.fecha_emision_f) AS MesNum,
    DATENAME(MONTH, f.fecha_emision_f) AS MesNombre,
    SUM(df.subtotal_df) AS TotalFacturado,
    COUNT(DISTINCT c.id_cita) AS TotalCitasAtendidas
FROM facturacion.facturas f
         INNER JOIN facturacion.detalles_facturas df ON f.id_factura = df.id_factura
         INNER JOIN clinica.citas c ON f.id_cita = c.id_cita
         INNER JOIN personal.veterinario v ON c.id_veterinario = v.id_veterinario
         INNER JOIN personal.especialidades e ON v.id_especialidad = e.id_especialidad
WHERE f.estado_f = 'Pagada'
GROUP BY e.nombre_esp, YEAR(f.fecha_emision_f), MONTH(f.fecha_emision_f), DATENAME(MONTH, f.fecha_emision_f);
GO

-- ============================================================
-- VISTA 3: Demografía de Pacientes (Dimensión Mascota/Especie)
-- ============================================================
-- MEDIDAS: CantidadMascotas, PesoPromedio.
-- DIMENSIONES: Especie, Raza, Sexo.
CREATE OR ALTER VIEW bi.v_demografia_mascotas AS
SELECT
    esp.nombre_e AS Especie,
    r.nombre_r AS Raza,
    m.sexo_m AS Sexo,
    COUNT(m.id_mascota) AS CantidadMascotas,
    AVG(m.peso_m) AS PesoPromedio
FROM pacientes.mascotas m
         INNER JOIN pacientes.razas r ON m.id_raza = r.id_raza
         INNER JOIN pacientes.especies esp ON r.id_especie = esp.id_especie
GROUP BY esp.nombre_e, r.nombre_r, m.sexo_m;
GO

-- ============================================================
-- VISTA 4: Desempeño y Productividad por Veterinario
-- ============================================================
-- MEDIDAS: CitasAtendidas, TotalGenerado, CostoPromedioCita.
-- DIMENSIONES: NombreVeterinario, Especialidad.
CREATE OR ALTER VIEW bi.v_desempenio_veterinarios AS
SELECT
    v.nombre_v + ' ' + v.apellido_v AS NombreVeterinario,
    e.nombre_esp AS Especialidad,
    COUNT(DISTINCT c.id_cita) AS CitasAtendidas,
    ISNULL(SUM(df.subtotal_df), 0) AS TotalGenerado,
    ISNULL(AVG(c.costo_c), 0) AS CostoPromedioCita
FROM personal.veterinario v
         INNER JOIN personal.especialidades e ON v.id_especialidad = e.id_especialidad
         LEFT JOIN clinica.citas c ON v.id_veterinario = c.id_veterinario
         LEFT JOIN facturacion.facturas f ON c.id_cita = f.id_cita AND f.estado_f = 'Pagada'
         LEFT JOIN facturacion.detalles_facturas df ON f.id_factura = df.id_factura
GROUP BY v.nombre_v, v.apellido_v, e.nombre_esp;
GO

-- ============================================================
-- VISTA 5: Consumo y Rotación de Medicamentos en Farmacia
-- ============================================================
-- MEDIDAS: UnidadesVendidas, IngresosMedicamento, StockActual.
-- DIMENSIONES: Medicamento, Presentacion, Laboratorio.
CREATE OR ALTER VIEW bi.v_rotacion_farmacia AS
SELECT
    m.nombre_m AS Medicamento,
    m.presentacion_m AS Presentacion,
    m.laboratorio_m AS Laboratorio,
    m.stock_m AS StockActual,
    ISNULL(SUM(df.cantidad_df), 0) AS UnidadesVendidas,
    ISNULL(SUM(df.subtotal_df), 0) AS IngresosMedicamento
FROM farmacia.medicamentos m
         LEFT JOIN facturacion.detalles_facturas df ON m.id_medicamento = df.id_medicamento
GROUP BY m.nombre_m, m.presentacion_m, m.laboratorio_m, m.stock_m;
GO

-- ============================================================
-- VISTA 6: Estado Operativo de Citas
-- ============================================================
-- MEDIDAS: TotalCitas, PorcentajeDelTotal.
-- DIMENSIONES: EstadoCita (Programada, En curso, Completada, Cancelada).
CREATE OR ALTER VIEW bi.v_estado_citas AS
SELECT
    c.estado_c AS EstadoCita,
    COUNT(c.id_cita) AS TotalCitas,
    CAST(COUNT(c.id_cita) * 100.0 / (SELECT COUNT(*) FROM clinica.citas) AS DECIMAL(5,2)) AS PorcentajeDelTotal
FROM clinica.citas c
GROUP BY c.estado_c;
GO