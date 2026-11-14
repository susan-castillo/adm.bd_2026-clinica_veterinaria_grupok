# Restaurar los datos masivos (db_veterinaria)

Restaurar REEMPLAZA por completo tu `db_veterinaria` (datos, usuarios, roles, vistas, auditoría).
Después hay que volver a crear lo tuyo. No ejecutar DML_Original.sql ni DML_Updated.sql luego del restore.

## 1. Copiar el .bak al contenedor (terminal, parado en esta carpeta)
```bash
docker cp DataBase_UpdatedData.bak sqlserver:/var/opt/mssql/data/DataBase_UpdatedData.bak
docker exec -u root sqlserver chown mssql:mssql /var/opt/mssql/data/DataBase_UpdatedData.bak
```

## 2. Restaurar (VS Code / mssql, conectado a master)
```sql
USE master;
GO
IF DB_ID(N'db_veterinaria') IS NOT NULL
    ALTER DATABASE db_veterinaria SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
RESTORE DATABASE db_veterinaria
FROM DISK = N'/var/opt/mssql/data/DataBase_UpdatedData.bak'
WITH REPLACE, RECOVERY,
     MOVE N'db_veterinaria'     TO N'/var/opt/mssql/data/db_veterinaria.mdf',
     MOVE N'db_veterinaria_log' TO N'/var/opt/mssql/data/db_veterinaria_log.ldf',
     STATS = 10;
GO
ALTER DATABASE db_veterinaria SET MULTI_USER;
ALTER DATABASE db_veterinaria SET RECOVERY FULL;
GO
```

## 3. Verificar (deben salir los mismos números para todos)
```sql
USE db_veterinaria;
SELECT
 (SELECT COUNT_BIG(*) FROM pacientes.propietarios) AS propietarios,
 (SELECT COUNT_BIG(*) FROM pacientes.mascotas)     AS mascotas,
 (SELECT COUNT_BIG(*) FROM clinica.citas)          AS citas,
 (SELECT COUNT_BIG(*) FROM facturacion.facturas)   AS facturas,
 (SELECT SUM(costo_c) FROM clinica.citas)          AS suma_costo_citas,
 (SELECT SUM(total_f) FROM facturacion.facturas)   AS suma_total_facturas;
```
Resultado esperado: 
| propietarios | mascotas | citas  | facturas | suma_costo_citas | suma_total_facturas |
|--------------|----------|--------|----------|------------------|---------------------|
| 5020         | 20075    | 300050 | 178471   | 47284833.60      | 28110760.47         |