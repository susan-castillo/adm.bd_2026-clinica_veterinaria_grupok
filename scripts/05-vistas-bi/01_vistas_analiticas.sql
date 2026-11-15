USE db_veterinaria;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bi')
    BEGIN
        EXEC('CREATE SCHEMA bi');
    END
GO

-- VISTA 1: tarjetas de KPIs ejecutivos (Global)
-- ============================================================
-- MEDIDAS: Ingresos Totales, Citas Completadas, Mascotas Registradas, Ticket Promedio.
CREATE OR ALTER VIEW bi.v_kpis_empresariales AS
SELECT
    (SELECT ISNULL(SUM(total_f), 0) FROM facturacion.facturas WHERE estado_f = 'Pagada') AS Ingresos_Totales,
    (SELECT COUNT(id_cita) FROM clinica.citas WHERE estado_c = 'Completada') AS Citas_Completadas,
    (SELECT COUNT(id_mascota) FROM pacientes.mascotas) AS Total_Mascotas_Registradas,
    (SELECT ISNULL(AVG(costo_c), 0) FROM clinica.citas WHERE estado_c = 'Completada') AS Ticket_Promedio_Cita;
GO

-- VISTA 2: Facturación mensual por especialidad
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

-- VISTA 3: Demografía de pacientes
-- ============================================================
-- MEDIDAS: CantidadMascotas, PesoPromedio.
-- DIMENSIONES: Anio, MesNum, MesNombre, Especialidad, Especie, Raza, Sexo.
CREATE OR ALTER VIEW bi.v_demografia_mascotas AS
SELECT
    YEAR(f.fecha_emision_f)            AS Anio,
    MONTH(f.fecha_emision_f)           AS MesNum,
    DATENAME(MONTH, f.fecha_emision_f) AS MesNombre,
    e.nombre_esp                       AS Especialidad,
    esp.nombre_e                       AS Especie,
    r.nombre_r                         AS Raza,
    m.sexo_m                           AS Sexo,
    COUNT(DISTINCT m.id_mascota)       AS CantidadMascotas,
    AVG(m.peso_m)                      AS PesoPromedio
FROM pacientes.mascotas m
         INNER JOIN pacientes.razas r          ON m.id_raza = r.id_raza
         INNER JOIN pacientes.especies esp     ON r.id_especie = esp.id_especie
         INNER JOIN clinica.citas c            ON m.id_mascota = c.id_mascota
         INNER JOIN personal.veterinario v     ON c.id_veterinario = v.id_veterinario
         INNER JOIN personal.especialidades e  ON v.id_especialidad = e.id_especialidad
         INNER JOIN facturacion.facturas f     ON c.id_cita = f.id_cita AND f.estado_f = 'Pagada'
WHERE f.fecha_emision_f IS NOT NULL
GROUP BY
    YEAR(f.fecha_emision_f),
    MONTH(f.fecha_emision_f),
    DATENAME(MONTH, f.fecha_emision_f),
    e.nombre_esp,
    esp.nombre_e,
    r.nombre_r,
    m.sexo_m;
GO

-- VISTA 4: desempeño y productividad por veterinario (dinámica por tiempo)
-- ============================================================
-- MEDIDAS: CitasAtendidas, TotalGenerado, CostoPromedioCita.
-- DIMENSIONES: Anio, MesNum, MesNombre, NombreVeterinario, Especialidad.
CREATE OR ALTER VIEW bi.v_desempenio_veterinarios AS
SELECT
    YEAR(f.fecha_emision_f)            AS Anio,
    MONTH(f.fecha_emision_f)           AS MesNum,
    DATENAME(MONTH, f.fecha_emision_f) AS MesNombre,
    v.nombre_v + ' ' + v.apellido_v    AS NombreVeterinario,
    e.nombre_esp                       AS Especialidad,
    COUNT(DISTINCT c.id_cita)          AS CitasAtendidas,
    ISNULL(SUM(df.subtotal_df), 0)     AS TotalGenerado,
    ISNULL(AVG(c.costo_c), 0)          AS CostoPromedioCita
FROM personal.veterinario v
         INNER JOIN personal.especialidades e       ON v.id_especialidad = e.id_especialidad
         INNER JOIN clinica.citas c                 ON v.id_veterinario = c.id_veterinario
         INNER JOIN facturacion.facturas f          ON c.id_cita = f.id_cita AND f.estado_f = 'Pagada'
         INNER JOIN facturacion.detalles_facturas df ON f.id_factura = df.id_factura
WHERE f.fecha_emision_f IS NOT NULL
GROUP BY
    YEAR(f.fecha_emision_f),
    MONTH(f.fecha_emision_f),
    DATENAME(MONTH, f.fecha_emision_f),
    v.nombre_v,
    v.apellido_v,
    e.nombre_esp;
GO

-- VISTA 5: Consumo y rotación de medicamentos en farmacia
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

-- VISTA 6: Estado de citas
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


-- BLOQUE DE COMPROBACIÓN
-- ==============================================================================

-- 1. Comprobación de tarjetas KPI superiores (Ingresos, Citas y Ticket Promedio)
SELECT
    SUM(TotalFacturado) AS Ingresos_Totales_Nov2026,
    SUM(TotalCitasAtendidas) AS Total_Citas_Nov2026,
    CAST(SUM(TotalFacturado) / SUM(TotalCitasAtendidas) AS DECIMAL(10,2)) AS Ticket_Promedio_Nov2026
FROM bi.v_ingresos_por_especialidad
WHERE Anio = 2026 AND MesNum = 11;

-- 2. Comprobación de gráfico 1: Porcentaje de ingresos por especialidad
SELECT
    Especialidad,
    TotalFacturado,
    CAST(TotalFacturado * 100.0 / SUM(TotalFacturado) OVER() AS DECIMAL(5,2)) AS Porcentaje_Participacion
FROM bi.v_ingresos_por_especialidad
WHERE Anio = 2026 AND MesNum = 11
ORDER BY TotalFacturado DESC;

-- 3. Comprobación de gráfico 2 (Treemap): Top 7 especies de mascotas atendidas
SELECT TOP 7
    Especie,
    SUM(CantidadMascotas) AS Total_Mascotas_Especie
FROM bi.v_demografia_mascotas
WHERE Anio = 2026 AND MesNum = 11
GROUP BY Especie
ORDER BY Total_Mascotas_Especie DESC;

-- 4. Comprobación de gráfico 3 (Matriz): Ranking de veterinarios
SELECT
    DENSE_RANK() OVER (ORDER BY SUM(TotalGenerado) DESC) AS Posicion,
    NombreVeterinario,
    Especialidad,
    SUM(CitasAtendidas) AS Citas_Atendidas,
    SUM(TotalGenerado) AS Total_Generado
FROM bi.v_desempenio_veterinarios
WHERE Anio = 2026 AND MesNum = 11
GROUP BY NombreVeterinario, Especialidad
ORDER BY Posicion ASC;

-- 5. Comprobación de gráfico 4 (Tabla): Stock actual en farmacia
SELECT TOP 10
    Medicamento,
    StockActual AS Unidades_Disponibles,
    CASE
        WHEN StockActual < 15 THEN 'Critico (Rojo)'
        WHEN StockActual < 50 THEN 'Moderado (Amarillo)'
        ELSE 'Optimo (Verde)'
        END AS Estado_Alerta
FROM bi.v_rotacion_farmacia
ORDER BY StockActual ASC;
GO