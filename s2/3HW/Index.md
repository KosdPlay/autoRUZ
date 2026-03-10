# Gin
## Запрос 1 — поиск слова в description

Доп колонка
```sql
ALTER TABLE service.ads ADD COLUMN tags text[];
```

### Без индекса
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.ads
WHERE to_tsvector('english', description) @@ to_tsquery('great');
```

<img width="700" height="249" alt="Снимок экрана 2026-03-10 223445" src="https://github.com/user-attachments/assets/444c85ef-d3c1-44a5-a2c2-9b107b89726c" />
### С индексом
```sql
CREATE INDEX idx_ads_description_gin ON service.ads USING gin(to_tsvector('english', description));
ANALYZE service.ads;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.ads
WHERE to_tsvector('english', description) @@ to_tsquery('great');
```

<img width="843" height="325" alt="Снимок экрана 2026-03-10 223742" src="https://github.com/user-attachments/assets/5939dba5-d0ec-4b70-8135-33bc29ee5baf" />

## Запрос 2 — поиск нескольких слов

### Без индекса
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.ads
WHERE to_tsvector('english', description) @@ to_tsquery('great & condition');
```

<img width="708" height="220" alt="Снимок экрана 2026-03-10 223512" src="https://github.com/user-attachments/assets/8851303b-5568-4870-85d4-e445ffccd115" />

### С индексом
```sql
CREATE INDEX idx_ads_description_gin ON service.ads USING gin(to_tsvector('english', description));
ANALYZE service.ads;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.ads
WHERE to_tsvector('english', description) @@ to_tsquery('great & condition');
```
<img width="849" height="329" alt="Снимок экрана 2026-03-10 223758" src="https://github.com/user-attachments/assets/00c25943-02a8-4054-ba9b-6c42172f1f13" />



## Запрос 3 — поиск по массиву тегов (оператор @>)

### Без индекса
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.ads
WHERE tags @> ARRAY['sale'];
```

<img width="658" height="195" alt="Снимок экрана 2026-03-10 231408" src="https://github.com/user-attachments/assets/261761cc-e211-48a3-a836-fcd5edf2ce78" />


### С индексом
```sql
CREATE INDEX idx_ads_tags_gin ON service.ads USING gin(tags);
ANALYZE service.ads;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.ads
WHERE tags @> ARRAY['sale'];
```

<img width="795" height="242" alt="Снимок экрана 2026-03-10 231513" src="https://github.com/user-attachments/assets/789ef11a-79fe-4f80-8cc0-8b5307456e69" />


## Запрос 4 — поиск с несколькими тегами

### Без индекса
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.ads
WHERE tags @> ARRAY['sale','cheap'];
```

<img width="670" height="160" alt="Снимок экрана 2026-03-10 231425" src="https://github.com/user-attachments/assets/de23511a-0bff-466f-8002-eeb7223b7a56" />



### С индексом
```sql
CREATE INDEX idx_ads_tags_gin ON service.ads USING gin(tags);
ANALYZE service.ads;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.ads
WHERE tags @> ARRAY['sale','cheap'];
```

<img width="800" height="252" alt="Снимок экрана 2026-03-10 231525" src="https://github.com/user-attachments/assets/baa51fc3-f903-4217-90ba-c1acbcf8b213" />



## Запрос 5 — поиск с отрицанием

### Без индекса
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.ads
WHERE NOT (tags @> ARRAY['used']);
```


<img width="674" height="156" alt="Снимок экрана 2026-03-10 231438" src="https://github.com/user-attachments/assets/b608ff88-f1c2-4d34-95bd-32b58bece582" />


### С индексом
```sql
CREATE INDEX idx_ads_tags_gin ON service.ads USING gin(tags);
ANALYZE service.ads;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.ads
WHERE NOT (tags @> ARRAY['used']);
```

<img width="793" height="149" alt="Снимок экрана 2026-03-10 231553" src="https://github.com/user-attachments/assets/ef89a88b-a997-4cee-9706-77a737f7790b" />



# GiST
## Запрос 1 — поиск по бренду (=)

### Без индекса
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.vehicles
WHERE brand='Toyota';
```
<img width="795" height="195" alt="Снимок экрана 2026-03-10 235604" src="https://github.com/user-attachments/assets/f76f45e7-0ca1-4bc3-9614-4440dbc187cc" />


### С индексом
```sql
CREATE INDEX idx_vehicles_brand_gist ON service.vehicles USING gist(brand);
ANALYZE service.vehicles;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.vehicles
WHERE brand='Toyota';
```

<img width="793" height="245" alt="Снимок экрана 2026-03-10 235727" src="https://github.com/user-attachments/assets/c6ffb436-14b7-4c52-b0a2-55b7bd91387c" />


## Запрос 2 — поиск по году выпуска (>)

### Без индекса
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.vehicles
WHERE year_of_manufacture > 2020;

```

<img width="793" height="142" alt="Снимок экрана 2026-03-10 235816" src="https://github.com/user-attachments/assets/fbdb2353-26ef-4a5a-ad83-ba094d474778" />



### С индексом
```sql
CREATE INDEX idx_vehicles_year_gist ON service.vehicles USING gist(year_of_manufacture);
ANALYZE service.vehicles;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.vehicles
WHERE year_of_manufacture > 2020;
```

<img width="786" height="246" alt="Снимок экрана 2026-03-10 235845" src="https://github.com/user-attachments/assets/f9527291-8eef-494f-b99d-745289d1f7b7" />


## Запрос 3 — поиск по цвету с LIKE (gist_trgm_ops)

### Без индекса
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.vehicles
WHERE color LIKE 'bl%';
```

<img width="659" height="150" alt="Снимок экрана 2026-03-10 235924" src="https://github.com/user-attachments/assets/d89a2563-6368-4744-93ee-43b3b0145b99" />



### С индексом
```sql
CREATE INDEX idx_vehicles_color_gist ON service.vehicles USING gist(color gist_trgm_ops);
ANALYZE service.vehicles;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.vehicles
WHERE color LIKE 'bl%';
```

<img width="662" height="200" alt="Снимок экрана 2026-03-10 235955" src="https://github.com/user-attachments/assets/8844d796-7ccc-4645-a730-6cf677a8b6fb" />



## Запрос 4 — полнотекстовый поиск GiST (альтернатива GIN)

### Без индекса
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.ads
WHERE to_tsvector('english', description) @@ to_tsquery('great');
```


<img width="705" height="267" alt="Снимок экрана 2026-03-11 000436" src="https://github.com/user-attachments/assets/7840b593-99e2-4a9f-a8e7-85ad8d4911a7" />



### С индексом
```sql
CREATE INDEX idx_ads_description_gist ON service.ads USING gist(to_tsvector('english', description));
ANALYZE service.ads;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.ads
WHERE to_tsvector('english', description) @@ to_tsquery('great');
```


<img width="840" height="178" alt="Снимок экрана 2026-03-11 000554" src="https://github.com/user-attachments/assets/3d599b9f-eb6a-4e66-add1-a86976259995" />



## Запрос 5 — Диапазон цен

```sql
ALTER TABLE service.ads 
ADD COLUMN price_range int4range GENERATED ALWAYS AS (int4range(price, price+1,'[]')) STORED;
```


### Без индекса
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.ads
WHERE price_range && int4range(100000,500000,'[]');
```


<img width="699" height="244" alt="Снимок экрана 2026-03-11 002546" src="https://github.com/user-attachments/assets/396fa4b5-7ee2-481b-8c23-49aa1acd7271" />



### С индексом
```sql
CREATE INDEX idx_ads_price_gist ON service.ads USING gist(price_range);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.ads
WHERE price_range && int4range(100000,500000,'[]');
```

<img width="795" height="254" alt="Снимок экрана 2026-03-11 002617" src="https://github.com/user-attachments/assets/1121e436-d79d-4bd3-af48-1803b94b6847" />


# Join

## JOIN-запрос 1 — ads + vehicles (по vehicle_id)

### Без индекса
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT a.ad_id, v.brand, v.model, a.price
FROM service.ads a
JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
WHERE v.brand='Toyota';
```
<img width="769" height="422" alt="image" src="https://github.com/user-attachments/assets/81b9c5e6-80b3-4ab6-99e8-dd8bf7bdeeb4" />

### С индексом
```sql
CREATE INDEX idx_ads_vehicle_id ON service.ads(vehicle_id);
CREATE INDEX idx_vehicles_vehicle_id ON service.vehicles(vehicle_id);
CREATE INDEX idx_vehicles_brand ON service.vehicles(brand);
ANALYZE service.ads;
ANALYZE service.vehicles;

EXPLAIN (ANALYZE, BUFFERS)
SELECT a.ad_id, v.brand, v.model, a.price
FROM service.ads a
JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
WHERE v.brand='Toyota';
```

<img width="809" height="405" alt="Снимок экрана 2026-03-11 010502" src="https://github.com/user-attachments/assets/a860da0a-2bc8-401c-8b79-b9e089f25427" />



## JOIN-запрос 2 — ads + sellers + users

### Без индекса
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT a.ad_id, u.full_name, s.seller_type, a.price
FROM service.ads a
JOIN service.sellers s ON a.seller_id = s.seller_id
JOIN service.users u ON s.user_id = u.user_id
WHERE s.seller_type='company';
```
<img width="815" height="576" alt="Снимок экрана 2026-03-11 010639" src="https://github.com/user-attachments/assets/4c0027bc-2e91-48db-badd-c8ec678634c1" />


### С индексом
```sql
CREATE INDEX idx_ads_seller_id ON service.ads(seller_id);
CREATE INDEX idx_sellers_seller_id ON service.sellers(seller_id);
CREATE INDEX idx_sellers_user_id ON service.sellers(user_id);
CREATE INDEX idx_users_user_id ON service.users(user_id);
ANALYZE service.ads;
ANALYZE service.sellers;
ANALYZE service.users;

EXPLAIN (ANALYZE, BUFFERS)
SELECT a.ad_id, u.full_name, s.seller_type, a.price
FROM service.ads a
JOIN service.sellers s ON a.seller_id = s.seller_id
JOIN service.users u ON s.user_id = u.user_id
WHERE s.seller_type='company';
```
<img width="793" height="577" alt="Снимок экрана 2026-03-11 010756" src="https://github.com/user-attachments/assets/7b1d079f-1bb0-4b01-a4fe-104cc66d20db" />


## JOIN-запрос 3 — feedbacks + sellers + ads

### Без индекса
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT f.feedback_id, s.seller_id, a.ad_id, f.rating
FROM service.feedbacks f
JOIN service.sellers s ON f.seller_id = s.seller_id
JOIN service.ads a ON f.ad_id = a.ad_id
WHERE f.rating>4;
```

<img width="814" height="542" alt="Снимок экрана 2026-03-11 010954" src="https://github.com/user-attachments/assets/f3cd1845-45b9-44cc-9e6b-7d2e98dc22fa" />


### С индексом
```sql
CREATE INDEX idx_feedbacks_seller_id ON service.feedbacks(seller_id);
CREATE INDEX idx_feedbacks_ad_id ON service.feedbacks(ad_id);
CREATE INDEX idx_sellers_seller_id ON service.sellers(seller_id);
CREATE INDEX idx_ads_ad_id ON service.ads(ad_id);
ANALYZE service.feedbacks;
ANALYZE service.sellers;
ANALYZE service.ads;

EXPLAIN (ANALYZE, BUFFERS)
SELECT f.feedback_id, s.seller_id, a.ad_id, f.rating
FROM service.feedbacks f
JOIN service.sellers s ON f.seller_id = s.seller_id
JOIN service.ads a ON f.ad_id = a.ad_id
WHERE f.rating>4;
```

<img width="780" height="525" alt="Снимок экрана 2026-03-11 011118" src="https://github.com/user-attachments/assets/cd7ae814-f2cc-4a44-bd59-bdc4bf13715d" />


## JOIN-запрос 4 — favourites + users + ads

### Без индекса
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT f.user_id, u.full_name, a.ad_id, a.price
FROM service.favourites f
JOIN service.users u ON f.user_id = u.user_id
JOIN service.ads a ON f.ad_id = a.ad_id
WHERE a.price<200000;
```
<img width="774" height="529" alt="image" src="https://github.com/user-attachments/assets/f0bde25a-63d4-4891-a524-55fa6d65ddd2" />


### С индексом
```sql
CREATE INDEX idx_favourites_user_id ON service.favourites(user_id);
CREATE INDEX idx_favourites_ad_id ON service.favourites(ad_id);
CREATE INDEX idx_users_user_id ON service.users(user_id);
CREATE INDEX idx_ads_ad_id ON service.ads(ad_id);
ANALYZE service.favourites;
ANALYZE service.users;
ANALYZE service.ads;

EXPLAIN (ANALYZE, BUFFERS)
SELECT f.user_id, u.full_name, a.ad_id, a.price
FROM service.favourites f
JOIN service.users u ON f.user_id = u.user_id
JOIN service.ads a ON f.ad_id = a.ad_id
WHERE a.price<200000;
```
<img width="824" height="461" alt="image" src="https://github.com/user-attachments/assets/d0a5cc2e-4a2a-4ff0-9eca-ef5af963474c" />


## JOIN-запрос 5 — ownerships + vehicles + users

### Без индекса
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.ownership_id, u.full_name, v.brand, v.model
FROM service.ownerships o
JOIN service.vehicles v ON o.vehicle_id = v.vehicle_id
JOIN service.users u ON o.owner_user_id = u.user_id
WHERE o.purchase_date > '2023-01-01';
```
<img width="677" height="249" alt="image" src="https://github.com/user-attachments/assets/7fa54ca7-55ff-4351-8bb8-99418e8c1e60" />


### С индексом
```sql
CREATE INDEX idx_ownerships_vehicle_id ON service.ownerships(vehicle_id);
CREATE INDEX idx_ownerships_owner_user_id ON service.ownerships(owner_user_id);
CREATE INDEX idx_vehicles_vehicle_id ON service.vehicles(vehicle_id);
CREATE INDEX idx_users_user_id ON service.users(user_id);
ANALYZE service.ownerships;
ANALYZE service.vehicles;
ANALYZE service.users;

EXPLAIN (ANALYZE, BUFFERS)
SELECT o.ownership_id, u.full_name, v.brand, v.model
FROM service.ownerships o
JOIN service.vehicles v ON o.vehicle_id = v.vehicle_id
JOIN service.users u ON o.owner_user_id = u.user_id
WHERE o.purchase_date > '2023-01-01';
```
<img width="670" height="272" alt="image" src="https://github.com/user-attachments/assets/db3b94c2-1c56-447d-aaa6-73d8b67f5652" />


