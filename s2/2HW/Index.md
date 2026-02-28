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

<img width="489" height="80" alt="Снимок экрана 2026-02-28 105517" src="https://github.com/user-attachments/assets/32143504-0016-4c47-b7a3-f91c2eaf8bc0" />

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
```
<img width="491" height="121" alt="Снимок экрана 2026-02-28 105538" src="https://github.com/user-attachments/assets/df6fc0e6-1149-4450-986c-a5a9b2b34a7e" />


```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
```

<img width="489" height="151" alt="Снимок экрана 2026-02-28 105603" src="https://github.com/user-attachments/assets/16aabcea-78dd-4a67-8b2f-4cc9e3ebbeac" />

# Запрос 3: Оператор < (меньше)

```sql
EXPLAIN SELECT * FROM service.ads WHERE price < 500000;
```

<img width="496" height="79" alt="Снимок экрана 2026-02-28 105621" src="https://github.com/user-attachments/assets/567431ec-e872-4afb-8247-72775085454b" />

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.ads WHERE price < 500000;
```

<img width="535" height="137" alt="Снимок экрана 2026-02-28 105639" src="https://github.com/user-attachments/assets/133f8d0f-7b75-4142-96ae-5bd8e3893fa9" />

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.ads WHERE price < 500000;
```
<img width="496" height="146" alt="Снимок экрана 2026-02-28 105657" src="https://github.com/user-attachments/assets/27d1d2b0-6bb4-47f0-b475-f10f95175785" />

# Запрос 4: Оператор LIKE 'prefix%' (префикс)
```sql
EXPLAIN SELECT * FROM service.users WHERE email LIKE 'user1%';
```
<img width="673" height="77" alt="Снимок экрана 2026-02-28 110201" src="https://github.com/user-attachments/assets/ac2efaa7-893a-4a95-901a-4ba29ec398ff" />


```sql
EXPLAIN (ANALYZE) SELECT * FROM service.users WHERE email LIKE 'user1%';
```

<img width="688" height="138" alt="Снимок экрана 2026-02-28 110217" src="https://github.com/user-attachments/assets/bf2847ec-b1bd-41d0-a1b3-5649c54c166c" />

```
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.users WHERE email LIKE 'user1%';
```

<img width="678" height="155" alt="Снимок экрана 2026-02-28 110237" src="https://github.com/user-attachments/assets/eaf16008-cf36-4f01-8654-3b206615c022" />


# Запрос 5: Оператор IN (множество значений)
```sql
EXPLAIN SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
```
<img width="678" height="75" alt="Снимок экрана 2026-02-28 110257" src="https://github.com/user-attachments/assets/0638ef86-a6a2-4a04-b90e-ea97c7b33af9" />

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
```
<img width="676" height="131" alt="Снимок экрана 2026-02-28 110312" src="https://github.com/user-attachments/assets/0cbe79c2-9b3b-4c2e-a5c5-7be382232c4e" />


```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
```

<img width="674" height="147" alt="Снимок экрана 2026-02-28 110348" src="https://github.com/user-attachments/assets/39cd8702-dc10-4512-bd30-af6bc8216763" />


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

<img width="506" height="112" alt="Снимок экрана 2026-02-28 110832" src="https://github.com/user-attachments/assets/ab1f7468-d731-4661-910a-d18e346616c2" />

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE brand = 'Toyota';
```

<img width="782" height="173" alt="Снимок экрана 2026-02-28 110934" src="https://github.com/user-attachments/assets/f38bd099-e831-412e-b096-3d94e3abb4ce" />

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE brand = 'Toyota';
```

<img width="779" height="210" alt="Снимок экрана 2026-02-28 110955" src="https://github.com/user-attachments/assets/edbaca9c-2ffc-4f3c-88c6-4f128e4be882" />

# Запрос 2: > с B-tree
```sql
EXPLAIN SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
```

<img width="550" height="105" alt="Снимок экрана 2026-02-28 111026" src="https://github.com/user-attachments/assets/0ee8eb21-720f-4ffe-a657-408537a4f3f6" />

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
```

<img width="774" height="168" alt="Снимок экрана 2026-02-28 111045" src="https://github.com/user-attachments/assets/52c7cf75-e0a6-4741-ae48-a3fdc197527c" />

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
```
<img width="790" height="212" alt="Снимок экрана 2026-02-28 111153" src="https://github.com/user-attachments/assets/0a88b7d3-61b2-45a6-8f84-5aab2709f265" />


# Запрос 3: < с B-tree
```sql
EXPLAIN SELECT * FROM service.ads WHERE price < 500000;
```
<img width="781" height="121" alt="Снимок экрана 2026-02-28 111215" src="https://github.com/user-attachments/assets/b9cc3a8e-6a2a-453a-928c-fa5274ba6e04" />


```sql
EXPLAIN (ANALYZE) SELECT * FROM service.ads WHERE price < 500000;
```

<img width="784" height="172" alt="Снимок экрана 2026-02-28 111232" src="https://github.com/user-attachments/assets/6750cace-b5ba-4e38-a44a-6916c2cefb57" />

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.ads WHERE price < 500000;
```
<img width="786" height="207" alt="Снимок экрана 2026-02-28 111248" src="https://github.com/user-attachments/assets/97816ada-95f7-4f2f-9890-0ba2ae95d823" />


# Запрос 4: LIKE 'prefix%' с B-tree
```sql
EXPLAIN SELECT * FROM service.users WHERE email LIKE 'user1%';
```
<img width="791" height="71" alt="Снимок экрана 2026-02-28 111307" src="https://github.com/user-attachments/assets/0246d892-0cdc-4f18-8a91-e6d4d9ea10b6" />


```sql
EXPLAIN (ANALYZE) SELECT * FROM service.users WHERE email LIKE 'user1%';
```
<img width="608" height="143" alt="Снимок экрана 2026-02-28 111622" src="https://github.com/user-attachments/assets/94b5827e-5bfc-4a5f-bf18-78b63ece7195" />


```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.users WHERE email LIKE 'user1%';
```

<img width="610" height="147" alt="Снимок экрана 2026-02-28 111642" src="https://github.com/user-attachments/assets/71a089d0-b4e8-49f4-b000-7768136ee15d" />

# Запрос 5: IN с B-tree
```sql
EXPLAIN SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
```

<img width="611" height="55" alt="Снимок экрана 2026-02-28 111658" src="https://github.com/user-attachments/assets/b1b78641-0460-4124-af3b-7b4b0ec25515" />

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
```

<img width="597" height="115" alt="Снимок экрана 2026-02-28 111715" src="https://github.com/user-attachments/assets/15f9eff4-7b62-4bce-ac4b-28c55f4badcb" />

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
```

<img width="613" height="149" alt="Снимок экрана 2026-02-28 111731" src="https://github.com/user-attachments/assets/d5e3009f-42e0-452c-9007-2c1ac34a2e70" />


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
<img width="510" height="120" alt="Снимок экрана 2026-02-28 111851" src="https://github.com/user-attachments/assets/4abbe8cd-9d79-43b2-a2ee-392b8c921f3d" />


```sql
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE brand = 'Toyota';
```
<img width="514" height="166" alt="Снимок экрана 2026-02-28 111906" src="https://github.com/user-attachments/assets/266eb4ea-b684-4111-89f6-09e8ef58a8d1" />


```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE brand = 'Toyota';
```
<img width="515" height="209" alt="Снимок экрана 2026-02-28 111922" src="https://github.com/user-attachments/assets/8c0b7c96-4256-4c89-9355-0b4969c38321" />


# Запрос 5: IN с Hash
```sql
EXPLAIN SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
```
<img width="507" height="72" alt="Снимок экрана 2026-02-28 111942" src="https://github.com/user-attachments/assets/e665caeb-df7a-4868-a94b-4c424e4aa115" />

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
```
<img width="506" height="130" alt="Снимок экрана 2026-02-28 111959" src="https://github.com/user-attachments/assets/e33a3864-c752-4084-ae9a-15bb7cebc50a" />

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
```
<img width="503" height="150" alt="Снимок экрана 2026-02-28 112646" src="https://github.com/user-attachments/assets/fbd4f52e-fe24-4790-af6d-d42322b48f40" />

# Дополнительно: email = с Hash
```sql
EXPLAIN SELECT * FROM service.users WHERE email = 'user12345@mail.com';
```

<img width="514" height="88" alt="Снимок экрана 2026-02-28 112709" src="https://github.com/user-attachments/assets/ea5ddda0-2525-4de7-8563-35e3ea6d1a39" />

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.users WHERE email = 'user12345@mail.com';
```
<img width="509" height="108" alt="Снимок экрана 2026-02-28 112723" src="https://github.com/user-attachments/assets/fef1a38f-bfcd-4788-bf78-05895de5225a" />


```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.users WHERE email = 'user12345@mail.com';
```
<img width="509" height="139" alt="Снимок экрана 2026-02-28 112743" src="https://github.com/user-attachments/assets/4315be0f-2bd6-4bbc-81a0-dc6094000952" />



## 4. СОСТАВНОЙ ИНДЕКС (COMPOSITE INDEX)
```sql
CREATE INDEX idx_vehicles_brand_year_btree ON service.vehicles USING btree (brand, year_of_manufacture);

ANALYZE service.vehicles;
```

# Запрос: использует обе колонки составного индекса
```sql
EXPLAIN SELECT * FROM service.vehicles WHERE brand = 'Toyota' AND year_of_manufacture > 2020;
```
<img width="523" height="117" alt="Снимок экрана 2026-02-28 112849" src="https://github.com/user-attachments/assets/c0ac310b-c1bc-4d55-bc93-dbb84620dec3" />

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE brand = 'Toyota' AND year_of_manufacture > 2020;
```
<img width="776" height="158" alt="Снимок экрана 2026-02-28 112912" src="https://github.com/user-attachments/assets/b20a775e-6803-4db8-b1fa-1389a487c696" />

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE brand = 'Toyota' AND year_of_manufacture > 2020;
```
<img width="784" height="203" alt="Снимок экрана 2026-02-28 112934" src="https://github.com/user-attachments/assets/278f0bbf-7584-4a45-bf98-bd3a7b8a4087" />

-- Запрос: использует только вторую колонку (неэффективно)
```sql
EXPLAIN SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
```
<img width="533" height="112" alt="Снимок экрана 2026-02-28 113003" src="https://github.com/user-attachments/assets/181debd6-f607-47c3-8991-96ae1d105c2d" />

```sql
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
```
<img width="767" height="164" alt="Снимок экрана 2026-02-28 113018" src="https://github.com/user-attachments/assets/50caf9ae-507e-4e40-9bc7-f1cd3a668ba5" />

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
```
<img width="763" height="207" alt="Снимок экрана 2026-02-28 113043" src="https://github.com/user-attachments/assets/b2ba3e23-a583-47a6-9f87-53845efad89c" />

