## Включаем отображение скрытых системных полей

```sql
CREATE EXTENSION pageinspect;

SELECT pg_relation_filepath('service.vehicles');
```
<img width="226" height="64" alt="Снимок экрана 2026-03-11 173849" src="https://github.com/user-attachments/assets/dd0388c5-44d2-4125-8b9a-e96d47771845" />


```sql
SELECT 
    ctid AS line_pointer,
    xmin AS t_xmin,
    xmax AS t_xmax,
    ctid AS t_ctid,
    xmax::text || ',' || xmin::text AS t_infomask_sample
FROM service.vehicles
LIMIT 50;
```

<img width="667" height="433" alt="Снимок экрана 2026-03-11 180905" src="https://github.com/user-attachments/assets/c962ca4e-9f69-434f-ab1a-384d3edbe494" />


## 1. Смоделировать обновление данных

```sql
INSERT INTO service.vehicles
(brand, model, year_of_manufacture, color, power_hp, state_code, vin)
VALUES 
('TestBrand','TestModel',2020,'black',150,'used','TESTVIN1234567890');

SELECT vin, power_hp, xmin, xmax
FROM service.vehicles
WHERE vin = 'TESTVIN1234567890';

```
<img width="487" height="63" alt="Снимок экрана 2026-03-11 181600" src="https://github.com/user-attachments/assets/1dfb740b-a67d-4bd7-948e-8771abf4748b" />


```sql
UPDATE service.vehicles
SET power_hp = 200
WHERE vin = 'TESTVIN1234567890';

SELECT vin, power_hp, xmin, xmax
FROM service.vehicles
WHERE vin = 'TESTVIN1234567890';
```
<img width="494" height="67" alt="Снимок экрана 2026-03-11 181628" src="https://github.com/user-attachments/assets/10feef97-cd32-41d9-a332-bdc2a86f9348" />

## 2. t_infomask
```sql
SELECT 
    12::bit(16) AS binary,
    CASE WHEN (12 & 8) != 0 THEN 'XMIN_COMMITTED ' ELSE '' END ||
    CASE WHEN (12 & 16) != 0 THEN 'XMIN_COMMITTED(alt) ' ELSE '' END AS flags;
```
<img width="238" height="60" alt="image" src="https://github.com/user-attachments/assets/6201d249-9711-4649-8d40-c12f700a128e" />

## 3. Разные транзакции (на примере Repeatable read)
```sql
-- на всякий случай
ROLLBACK;
```
```sql
-- сессия 1
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

UPDATE service.vehicles SET power_hp = 220 WHERE vehicle_id = 1;

SELECT ctid, xmin, xmax, brand, model, power_hp FROM service.vehicles WHERE vehicle_id = 1;
```
<img width="632" height="53" alt="image" src="https://github.com/user-attachments/assets/3b4c3fab-6bf0-4e64-b317-0bffb8471923" />

```sql
-- сессия 2
UPDATE service.vehicles SET power_hp = 210 WHERE vehicle_id = 1;
```

```sql
-- снова сессия 1
SELECT ctid, xmin, xmax, brand, model, power_hp FROM service.vehicles WHERE vehicle_id = 1;

COMMIT;
```
<img width="663" height="67" alt="Снимок экрана 2026-03-11 182441" src="https://github.com/user-attachments/assets/7c301980-804f-4a6c-8fd3-f1674269ae4c" />


## 4. Deadlock

```sql
-- сессия 1
BEGIN;
UPDATE service.vehicles SET power_hp = power_hp + 1 WHERE vehicle_id = 1;
```
```sql
-- сессия 2
BEGIN;
UPDATE service.vehicles SET power_hp = power_hp + 1 WHERE vehicle_id = 2;
UPDATE service.vehicles SET power_hp = power_hp - 1 WHERE vehicle_id = 1;
```
```sql
-- снова сессия 1
UPDATE service.vehicles SET power_hp = power_hp + 1 WHERE vehicle_id = 2;
```
<img width="568" height="174" alt="image" src="https://github.com/user-attachments/assets/ed532e4b-05a9-463c-9ada-2ed5a9bd4168" />


## 5. Блокировки

### на уровне строк:
### FOR UPDATE vs ДРУГОЙ FOR UPDATE
```sql
-- сессия 1
BEGIN;
SELECT * FROM service.vehicles WHERE vehicle_id = 1 FOR UPDATE;
-- Удерживаем
SELECT pg_sleep(5);
```

```sql
-- сессия 2
SELECT * FROM service.vehicles WHERE vehicle_id = 1 FOR UPDATE;
```
<img width="573" height="211" alt="image" src="https://github.com/user-attachments/assets/90701c2d-44e3-45f0-b46a-3c3e15e19da4" />

```sql
-- снова сессия 1
COMMIT;
```


## FOR UPDATE vs FOR SHARE

```sql
-- сессия 1
BEGIN;
SELECT * FROM service.vehicles WHERE vehicle_id = 1 FOR SHARE;
-- Удерживаем
SELECT pg_sleep(20);
```
<img width="1176" height="71" alt="image" src="https://github.com/user-attachments/assets/0a311ea4-63cc-407a-b0d0-064d66c151ca" />

```sql
-- сессия 2
UPDATE service.vehicles SET power_hp = power_hp + 1 WHERE vehicle_id = 1;

SELECT * FROM service.vehicles WHERE vehicle_id = 1 FOR SHARE;
```

<img width="672" height="88" alt="image" src="https://github.com/user-attachments/assets/c3946c77-a8a7-4611-8948-7830e8b2de52" />

```sql
-- снова сессия 1
COMMIT;
```

## 6. Очистка

### Статистика
```sql
SELECT 
    relname,
    n_live_tup,
    n_dead_tup,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE relname = 'vehicles';
```
<img width="738" height="84" alt="image" src="https://github.com/user-attachments/assets/ade9467c-953f-4bfd-ab5e-071f9fba3bac" />

### Размер

```sql
SELECT 
    pg_size_pretty(pg_total_relation_size('service.vehicles')) AS total_size,
    pg_size_pretty(pg_relation_size('service.vehicles')) AS table_size;
```
<img width="261" height="74" alt="image" src="https://github.com/user-attachments/assets/487b78a8-918a-4f7b-9457-ce4f9ab2da98" />
```sql
VACUUM VERBOSE service.vehicles;

SELECT n_live_tup, n_dead_tup FROM pg_stat_user_tables WHERE relname = 'vehicles';
```
<img width="284" height="65" alt="image" src="https://github.com/user-attachments/assets/c3370834-53f1-4ed8-a653-e915ac7da40a" />

```sql
VACUUM FULL VERBOSE service.vehicles;
```
<img width="261" height="74" alt="Снимок экрана 2026-03-11 183443" src="https://github.com/user-attachments/assets/dc860368-1f5f-4cf3-b74e-93e624840ab5" />
