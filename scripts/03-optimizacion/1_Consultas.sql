/*
SECCION 3 - Consultas analiticas (C1, C2, C3)
Base: db_veterinaria (restaurada desde DataBase_UpdatedData.bak).

ESTE ARCHIVO NO CREA NI BORRA INDICES. Se ejecuta dos veces, identico:
  1. Sin indice  -> estado inicial (Messages dice "ESTADO: SIN INDICE").
  2. Corre Indices.sql, y vuelve a ejecutar este archivo (dice "ESTADO: CON INDICE").
*/

-- ============================================================
-- 0. PREPARACION
-- ============================================================
USE db_veterinaria;
GO
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- 0.1 Estado actual (debe coincidir con lo que quieres medir)
IF EXISTS (SELECT 1 FROM sys.indexes
           WHERE name LIKE 'ix[_]%' AND OBJECTPROPERTY(object_id, 'IsUserTable') = 1)
    PRINT N'>>> ESTADO: CON INDICE';
ELSE
    PRINT N'>>> ESTADO: SIN INDICE';
GO
SELECT OBJECT_SCHEMA_NAME(object_id) AS esquema, OBJECT_NAME(object_id) AS tabla, name AS indice
FROM sys.indexes
WHERE name LIKE 'ix[_]%' AND OBJECTPROPERTY(object_id, 'IsUserTable') = 1
ORDER BY esquema, tabla, indice;
GO

-- 0.2 Estadisticas parejas (evita que el "con indice" gane por estadisticas frescas)
UPDATE STATISTICS clinica.citas        WITH FULLSCAN;
UPDATE STATISTICS facturacion.facturas WITH FULLSCAN;
UPDATE STATISTICS pacientes.mascotas   WITH FULLSCAN;
UPDATE STATISTICS personal.veterinario WITH FULLSCAN;
GO

-- ============================================================
-- C1: Productividad y ranking de veterinarios por especialidad (ultimo año)
-- Ventanas: RANK(), SUM(COUNT(*)) OVER (PARTITION BY especialidad)
-- ============================================================
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
GO

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
JOIN personal.veterinario    v   ON v.id_veterinario    = c.id_veterinario
JOIN personal.especialidades esp ON esp.id_especialidad = v.id_especialidad
WHERE c.estado_c = N'Completada'
  AND c.fecha_c >= DATEADD(YEAR, -1, SYSDATETIME())
GROUP BY esp.id_especialidad, esp.nombre_esp,
         v.id_veterinario, v.nombre_v, v.apellido_v
ORDER BY esp.nombre_esp, ranking_en_especialidad;
GO

-- ============================================================
-- C2: Frecuencia de visitas y dias entre visitas por mascota (TOP 20)
-- Ventana: LAG() sobre la visita anterior de cada mascota
-- ============================================================
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
GO

WITH visitas AS (
    SELECT
        c.id_mascota,
        c.fecha_c,
        LAG(c.fecha_c) OVER (PARTITION BY c.id_mascota
                             ORDER BY c.fecha_c)     AS visita_anterior
    FROM clinica.citas c
    WHERE c.estado_c = N'Completada'
),
resumen AS (
    SELECT
        v.id_mascota,
        COUNT(*)                                                 AS total_visitas,
        MAX(v.fecha_c)                                           AS ultima_visita,
        CAST(AVG(DATEDIFF(DAY, v.visita_anterior, v.fecha_c) * 1.0)
             AS DECIMAL(10,2))                                   AS dias_promedio_entre_visitas,
        MAX(DATEDIFF(DAY, v.visita_anterior, v.fecha_c))         AS max_dias_entre_visitas
    FROM visitas v
    GROUP BY v.id_mascota
)
SELECT TOP (20)
    m.nombre_m                                                   AS mascota,
    r.total_visitas,
    r.dias_promedio_entre_visitas,
    r.max_dias_entre_visitas,
    r.ultima_visita,
    DATEDIFF(DAY, r.ultima_visita, SYSDATETIME())                AS dias_desde_ultima_visita
FROM resumen r
JOIN pacientes.mascotas m ON m.id_mascota = r.id_mascota
ORDER BY r.total_visitas DESC, m.id_mascota;
GO

-- ============================================================
-- C3: Facturacion mensual acumulada y promedio movil (solo facturas Pagada)
-- Ventanas: SUM() OVER acumulado, AVG() OVER movil, LAG()
-- ============================================================
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
GO

WITH mensual AS (
    SELECT
        DATEFROMPARTS(YEAR(f.fecha_emision_f),
                      MONTH(f.fecha_emision_f), 1)               AS mes,
        COUNT(*)                                                 AS facturas_emitidas,
        SUM(f.total_f)                                           AS total_mes
    FROM facturacion.facturas f
    WHERE f.estado_f = N'Pagada'
    GROUP BY DATEFROMPARTS(YEAR(f.fecha_emision_f),
                           MONTH(f.fecha_emision_f), 1)
)
SELECT
    mes,
    facturas_emitidas,
    total_mes,
    SUM(total_mes) OVER (ORDER BY mes
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)        AS facturacion_acumulada,
    CAST(AVG(total_mes) OVER (ORDER BY mes
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
         AS DECIMAL(12,2))                                       AS promedio_movil_3_meses,
    CAST(100.0 * (total_mes - LAG(total_mes) OVER (ORDER BY mes))
         / NULLIF(LAG(total_mes) OVER (ORDER BY mes), 0)
         AS DECIMAL(7,2))                                        AS variacion_pct_mes_anterior
FROM mensual
ORDER BY mes;
GO