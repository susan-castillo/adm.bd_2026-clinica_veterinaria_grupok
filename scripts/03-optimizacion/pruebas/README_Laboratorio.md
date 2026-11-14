# Laboratorio de la Sección 3 (optimización de consultas e índices)

## Para qué existe
Reproducir en vivo las condiciones exactas de las mediciones del informe, sin capturar
planes y sin factores externos (auditorías, roles, etc.).

## Los tres escenarios
| Base | Contenido | Uso |
|---|---|---|
| db_veterinaria | Base principal del equipo (la manejan ellos) | Solo para demos autorizadas; este laboratorio no la toca |
| db_vet_lab_sin_indices | Solo el .bak (DataBase_UpdatedData.bak) | Línea base limpia; también donde se prueban índices descartados o iniciales |
| db_vet_lab_con_indices | .bak + 3 índices filtrados finales | Comparación con el diseño utilizado |

## Archivos
- 1_Crear_Bases_Lab.sql: restaura las dos bases, crea los 3 índices en la "con índices", actualiza estadísticas y verifica.
- 2_Demo_Descartados_Iniciales.sql: crea y borra índices iniciales o descartados para una demo en vivo.
- 3_Consultas_Lab.sql: copia de 1_Consultas.sql sin la línea USE (se ejecuta en la base conectada).

## Cómo se usa
1. Tener el .bak en el contenedor (README_Restore.md, paso 1).
2. Conectarse a master con sa y ejecutar 1_Crear_Bases_Lab.sql.
3. Conectarse a cada base de laboratorio y ejecutar 3_Consultas_Lab.sql con Actual Plan activo.
4. Para probar un índice inicial o descartado: 2_Demo_Descartados_Iniciales.sql en db_vet_lab_sin_indices y luego la LIMPIEZA.

## Lecturas lógicas esperadas (del informe)
    C1: 1,861 sin índices / 424 con índices (puede variar unas páginas por SYSDATETIME())
    C2: 2,124 sin índices / 376 con índices
    C3: 561 sin índices / 208 con índices
Si difieren, se reportan ambas cifras; no se ajusta ninguna.

## Decisiones
- Dos bases separadas de db_veterinaria para que auditorías, roles o cambios del equipo no alteren los planes.
- La base con índices lleva solo los 3 filtrados finales. Los iniciales y descartados se prueban bajo demanda.
- El script de creación nunca nombra db_veterinaria.
- Las mediciones del informe se hicieron en db_veterinaria recién restaurada; estas bases las reproducen.

## Advertencias
- DBCC DROPCLEANBUFFERS y FREEPROCCACHE (en 3_Consultas_Lab.sql) afectan a toda la instancia: usar solo en un contenedor local.
- Con un rol limitado, esos DBCC normalmente no se pueden ejecutar y ver el plan real requiere el permiso SHOWPLAN. Preparar la corrida fría con sa y ejecutar las consultas con el rol.
