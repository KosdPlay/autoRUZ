## Включаем отображение скрытых системных полей

```sql
CREATE EXTENSION pageinspect;

SELECT pg_relation_filepath('service.vehicles');
```


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


```sql
UPDATE service.vehicles
SET power_hp = 200
WHERE vin = 'TESTVIN1234567890';

SELECT vin, power_hp, xmin, xmax
FROM service.vehicles
WHERE vin = 'TESTVIN1234567890';
```

-- 2. t_infomask

SELECT 
    12::bit(16) AS binary,
    CASE WHEN (12 & 0x0008) != 0 THEN 'XMIN_COMMITTED ' ELSE '' END ||
    CASE WHEN (12 & 0x0010) != 0 THEN 'XMIN_COMMITTED(alt) ' ELSE '' END AS flags;

-- 3. Разные транзакции (на примере Repeatable read)

-- на всякий случай
ROLLBACK;

-- сессия 1
-- BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

UPDATE service.vehicles SET power_hp = 220 WHERE vehicle_id = 1;

SELECT ctid, xmin, xmax, brand, model, power_hp FROM service.vehicles WHERE vehicle_id = 1;

-- сессия 2
-- UPDATE service.vehicles SET power_hp = 210 WHERE vehicle_id = 1;

-- снова сессия 1
SELECT ctid, xmin, xmax, brand, model, power_hp FROM service.vehicles WHERE vehicle_id = 1;

COMMIT;

-- 4. Deadlock

-- сессия 1
BEGIN;
UPDATE service.vehicles SET power_hp = power_hp + 1 WHERE vehicle_id = 1;

-- сессия 2
BEGIN;
UPDATE service.vehicles SET power_hp = power_hp + 1 WHERE vehicle_id = 2;
UPDATE service.vehicles SET power_hp = power_hp - 1 WHERE vehicle_id = 1;

-- снова сессия 1
UPDATE service.vehicles SET power_hp = power_hp + 1 WHERE vehicle_id = 2;

-- 5. Блокировки
-- на уровне таблиц - изучили самостоятельно
-- на уровне строк:

-- FOR UPDATE vs ДРУГОЙ FOR UPDATE

-- сессия 1
BEGIN;
SELECT * FROM service.vehicles WHERE vehicle_id = 1 FOR UPDATE;
-- Удерживаем
SELECT pg_sleep(5);

-- сессия 2
SELECT * FROM service.vehicles WHERE vehicle_id = 1 FOR UPDATE;

-- снова сессия 1
COMMIT;

-- FOR UPDATE vs FOR SHARE

-- сессия 1
BEGIN;
SELECT * FROM service.vehicles WHERE vehicle_id = 1 FOR SHARE;
-- Удерживаем
SELECT pg_sleep(20);

-- сессия 2
UPDATE service.vehicles SET power_hp = power_hp + 1 WHERE vehicle_id = 1;

SELECT * FROM service.vehicles WHERE vehicle_id = 1 FOR SHARE;

-- снова сессия 1
COMMIT;

-- 6. Очистка

-- Статистика
SELECT 
    relname,
    n_live_tup,
    n_dead_tup,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE relname = 'vehicles';

-- Размер
SELECT 
    pg_size_pretty(pg_total_relation_size('service.vehicles')) AS total_size,
    pg_size_pretty(pg_relation_size('service.vehicles')) AS table_size;

VACUUM VERBOSE service.vehicles;

SELECT n_live_tup, n_dead_tup FROM pg_stat_user_tables WHERE relname = 'vehicles';

VACUUM FULL VERBOSE service.vehicles;