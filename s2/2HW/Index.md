## 1. ТЕСТИРОВАНИЕ БЕЗ ИНДЕКСОВ

# Запрос 1: Оператор = (равенство)
```sql
EXPLAIN SELECT * FROM service.vehicles WHERE brand = 'Toyota';
```
<img width="537" height="71" alt="Снимок экрана 2026-02-28 105152" src="https://github.com/user-attachments/assets/9fcc2a2c-67e5-42eb-a352-5ab180268dbc" />

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE brand = 'Toyota';
```
<img width="533" height="128" alt="Снимок экрана 2026-02-28 105212" src="https://github.com/user-attachments/assets/a0abbbbb-3775-45d2-b55b-1cd493148029" />

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE brand = 'Toyota';
```
<img width="539" height="150" alt="Снимок экрана 2026-02-28 105456" src="https://github.com/user-attachments/assets/55d83061-5cbc-4dce-bb4d-fc450e750ce9" />

# Запрос 2: Оператор > (больше)
```sql
EXPLAIN SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
```
![Uploading Снимок экрана 2026-02-28 105517.png…]()

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
```
![Uploading Снимок экрана 2026-02-28 105538.png…]()

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
```
![Uploading Снимок экрана 2026-02-28 105603.png…]()

# Запрос 3: Оператор < (меньше)

```sql
EXPLAIN SELECT * FROM service.ads WHERE price < 500000;
```
![Uploading Снимок экрана 2026-02-28 105621.png…]()

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.ads WHERE price < 500000;
```
![Uploading Снимок экрана 2026-02-28 105639.png…]()

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.ads WHERE price < 500000;
```
![Uploading Снимок экрана 2026-02-28 105657.png…]()

# Запрос 4: Оператор LIKE 'prefix%' (префикс)
```sql
EXPLAIN SELECT * FROM service.users WHERE email LIKE 'user1%';
```
![Uploading Снимок экрана 2026-02-28 110018.png…]()

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.users WHERE email LIKE 'user1%';
```
![Uploading Снимок экрана 2026-02-28 110036.png…]()

```
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.users WHERE email LIKE 'user1%';
```
![Uploading Снимок экрана 2026-02-28 110057.png…]()

# Запрос 5: Оператор IN (множество значений)
```sql
EXPLAIN SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
```

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
```

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
```


## 2. СОЗДАНИЕ B-TREE ИНДЕКСОВ И ТЕСТИРОВАНИЕ
```sql
CREATE INDEX idx_vehicles_brand_btree ON service.vehicles USING btree (brand);
CREATE INDEX idx_vehicles_year_btree ON service.vehicles USING btree (year_of_manufacture);
CREATE INDEX idx_ads_price_btree ON service.ads USING btree (price);
CREATE INDEX idx_users_email_btree ON service.users USING btree (email);
CREATE INDEX idx_vehicles_state_btree ON service.vehicles USING btree (state_code);

ANALYZE service.vehicles;
ANALYZE service.ads;
ANALYZE service.users;
```

# Запрос 1: = с B-tree
```sql
EXPLAIN SELECT * FROM service.vehicles WHERE brand = 'Toyota';
```

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE brand = 'Toyota';
```

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE brand = 'Toyota';
```

# Запрос 2: > с B-tree
```sql
EXPLAIN SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
```

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
```

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
```

# Запрос 3: < с B-tree
```sql
EXPLAIN SELECT * FROM service.ads WHERE price < 500000;
```

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.ads WHERE price < 500000;
```

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.ads WHERE price < 500000;
```

# Запрос 4: LIKE 'prefix%' с B-tree
```sql
EXPLAIN SELECT * FROM service.users WHERE email LIKE 'user1%';
```

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.users WHERE email LIKE 'user1%';
```

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.users WHERE email LIKE 'user1%';
```

# Запрос 5: IN с B-tree
```sql
EXPLAIN SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
```

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
```

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
```


# 3. СОЗДАНИЕ HASH ИНДЕКСОВ И ТЕСТИРОВАНИЕ
```sql
CREATE INDEX idx_vehicles_brand_hash ON service.vehicles USING hash (brand);
CREATE INDEX idx_vehicles_state_hash ON service.vehicles USING hash (state_code);
CREATE INDEX idx_users_email_hash ON service.users USING hash (email);

ANALYZE service.vehicles;
ANALYZE service.users;
```

# Запрос 1: = с Hash
```sql
EXPLAIN SELECT * FROM service.vehicles WHERE brand = 'Toyota';
```

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE brand = 'Toyota';
```

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE brand = 'Toyota';
```

# Запрос 5: IN с Hash
```sql
EXPLAIN SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
```

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
```

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
```

# Дополнительно: email = с Hash
```sql
EXPLAIN SELECT * FROM service.users WHERE email = 'user12345@mail.com';
```

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.users WHERE email = 'user12345@mail.com';
```

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.users WHERE email = 'user12345@mail.com';
```


## 4. СОСТАВНОЙ ИНДЕКС (COMPOSITE INDEX)
```sql
CREATE INDEX idx_vehicles_brand_year_btree ON service.vehicles USING btree (brand, year_of_manufacture);

ANALYZE service.vehicles;
```

# Запрос: использует обе колонки составного индекса
```sql
EXPLAIN SELECT * FROM service.vehicles WHERE brand = 'Toyota' AND year_of_manufacture > 2020;
```

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE brand = 'Toyota' AND year_of_manufacture > 2020;
```

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE brand = 'Toyota' AND year_of_manufacture > 2020;
```

-- Запрос: использует только вторую колонку (неэффективно)
EXPLAIN SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
