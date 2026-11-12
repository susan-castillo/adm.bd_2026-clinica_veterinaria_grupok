USE veterinaria_perf;
GO
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
GO
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO
-- CONSULTA 1: Productividad y ranking de veterinarios por especialidad (último año)
SELECT
    esp.nombre_esp                                   AS especialidad,
    CONCAT(v.nombre_v, N' ', v.apellido_v)           AS veterinario,
    COUNT(*)                                         AS citas_completadas,
    SUM(c.costo_c)                                   AS ingresos_generados,
    CAST(AVG(c.costo_c) AS DECIMAL(10,2))            AS costo_promedio,
    RANK() OVER (PARTITION BY esp.id_especialidad
                 ORDER BY COUNT(*) DESC)             AS ranking_en_especialidad,
    CAST(100.0 * COUNT(*)
         / SUM(COUNT(*)) OVER (PARTITION BY esp.id_especialidad)
         AS DECIMAL(5,2))                            AS pct_de_la_especialidad
FROM clinica.citas c
JOIN personal.veterinario    v   ON v.id_veterinario  = c.id_veterinario
JOIN personal.especialidades esp ON esp.id_especialidad = v.id_especialidad
WHERE c.estado_c = N'Completada'
  AND c.fecha_c >= DATEADD(YEAR, -1, SYSDATETIME())
GROUP BY esp.id_especialidad, esp.nombre_esp,
         v.id_veterinario, v.nombre_v, v.apellido_v
ORDER BY esp.nombre_esp, ranking_en_especialidad;
GO

-- ÍNDICE PARA LA CONSULTA 1
USE veterinaria_perf;
GO

DROP INDEX IF EXISTS ix_citas_estado_fecha ON clinica.citas;
GO

/*CREATE NONCLUSTERED INDEX ix_citas_estado_fecha
ON clinica.citas (estado_c, fecha_c)
INCLUDE (id_veterinario, costo_c);
GO*/