-- Массовая загрузка по образцу firstHW/migrations/V4__load_big_data.sql.
-- Справочники уже в V2 — здесь только генерация фактов и наполнение секций из V3.

-- ============================================
-- Пользователи и продавцы (объём под 1M объявлений)
-- ============================================
INSERT INTO service.users(user_id, full_name, email, phone_number, registration_date)
SELECT
  gs,
  'User ' || gs,
  'user' || gs || '@mail.com',
  CASE WHEN random() < 0.15 THEN NULL
       ELSE '+' || (10000000000 + floor(random()*89999999999))::bigint::text
  END,
  now() - (floor(random()*365)::int || ' days')::interval
FROM generate_series(1, 300000) gs;

SELECT setval(pg_get_serial_sequence('service.users', 'user_id'), 300000, true);

INSERT INTO service.sellers(seller_id, user_id, seller_type, created_at)
SELECT
  gs,
  gs,
  CASE WHEN random() < 0.85 THEN 'individual' ELSE 'company' END,
  now() - (floor(random()*365)::int || ' days')::interval
FROM generate_series(1, 300000) gs;

SELECT setval(pg_get_serial_sequence('service.sellers', 'seller_id'), 300000, true);

-- ============================================
-- Транспортные средства — 1 000 000 строк
-- ============================================
WITH
  bt AS (SELECT id, row_number() OVER (ORDER BY id) rn FROM service.body_types),
  tr AS (SELECT id, row_number() OVER (ORDER BY id) rn FROM service.transmissions),
  ft AS (SELECT id, row_number() OVER (ORDER BY id) rn FROM service.fuel_types),
  btcnt AS (SELECT count(*)::int c FROM service.body_types),
  trcnt AS (SELECT count(*)::int c FROM service.transmissions),
  ftcnt AS (SELECT count(*)::int c FROM service.fuel_types)
INSERT INTO service.vehicles(
  vehicle_id, brand, model, year_of_manufacture, color,
  body_type_id, transmission_id, fuel_type_id,
  power_hp, state_code, vin
)
SELECT
  gs,
  (ARRAY['Toyota','BMW','Mercedes','Audi','Kia','Hyundai','VW','Skoda','Renault','Nissan','Ford','Lada'])[1+floor(random()*12)::int],
  'Model-' || (1+floor(random()*50)::int),
  (1990 + floor(random()*36))::int,
  CASE WHEN random() < 0.10 THEN NULL
       ELSE (ARRAY['black','white','silver','red','blue'])[1+floor(random()*5)::int]
  END,
  (SELECT id FROM bt, btcnt WHERE rn = (gs % btcnt.c) + 1),
  (SELECT id FROM tr, trcnt WHERE rn = (gs % trcnt.c) + 1),
  (SELECT id FROM ft, ftcnt WHERE rn = (gs % ftcnt.c) + 1),
  (70 + floor(random()*300))::int,
  (ARRAY['new','used','damaged'])[1+floor(random()*3)::int],
  upper(substring(md5(gs::text), 1, 17))
FROM generate_series(1, 1000000) gs;

SELECT setval(pg_get_serial_sequence('service.vehicles', 'vehicle_id'), 1000000, true);

-- ============================================
-- Объявления — 1 000 000 строк
-- ============================================
WITH
  st AS (SELECT id, row_number() OVER (ORDER BY id) rn FROM service.ad_statuses),
  stcnt AS (SELECT count(*)::int c FROM service.ad_statuses)
INSERT INTO service.ads(
  ad_id, seller_id, vehicle_id, header_text, description, price,
  publication_date, status_id
)
SELECT
  gs,
  CASE
    WHEN random() < 0.70 THEN 1 + floor(random()*30000)::int
    ELSE 30001 + floor(random()*270000)::int
  END,
  1 + floor(random()*1000000)::int,
  'Selling car #' || gs,
  CASE WHEN random() < 0.10 THEN NULL
       ELSE 'Great condition ' || md5(gs::text)
  END,
  (100000 + floor(random()*4900000))::int,
  now() - (floor(random()*365)::int || ' days')::interval,
  (SELECT id FROM st, stcnt WHERE rn = (gs % stcnt.c) + 1)
FROM generate_series(1, 1000000) gs;

SELECT setval(pg_get_serial_sequence('service.ads', 'ad_id'), 1000000, true);

-- ============================================
-- Связанные данные (масштаб под 1M ads)
-- ============================================
INSERT INTO service.ad_photos(ad_id, url, is_primary)
SELECT
  1 + floor(random()*1000000)::int,
  'https://example.com/img/' || gs || '.jpg',
  random() < 0.2
FROM generate_series(1, 500000) gs;

INSERT INTO service.favourites(user_id, ad_id, added_at)
SELECT
  1 + floor(random()*300000)::int,
  1 + floor(random()*1000000)::int,
  now() - (floor(random()*365)::int || ' days')::interval
FROM generate_series(1, 200000) gs
ON CONFLICT (user_id, ad_id) DO NOTHING;

INSERT INTO service.feedbacks(user_id, seller_id, ad_id, text, rating, publication_date)
SELECT
  CASE WHEN random() < 0.9 THEN 1 + floor(random()*300000)::int ELSE NULL END,
  1 + floor(random()*300000)::int,
  1 + floor(random()*1000000)::int,
  'Feedback text ' || gs,
  round((random()*5)::numeric, 2),
  now() - (floor(random()*365)::int || ' days')::interval
FROM generate_series(1, 100000) gs
ON CONFLICT (user_id, seller_id, ad_id) DO NOTHING;

-- ============================================
-- Секционированные таблицы из V3
-- ============================================
INSERT INTO service.mileage_partitioned (vehicle_id, recorded_at, mileage_km)
SELECT
  1 + ((gs::bigint * 7919) % 1000000)::int,
  TIMESTAMP '2024-01-01' + ((gs % 1095) * interval '1 day'),
  (gs % 300000)
FROM generate_series(1, 1000000) gs;

INSERT INTO service.contracts_partitioned (seller_id, amount, status)
SELECT
  1 + floor(random()*300000)::int,
  (random()*50000)::int,
  (ARRAY['active','closed','pending'])[1 + floor(random()*3)::int]
FROM generate_series(1, 300000) gs;

INSERT INTO service.ads_partitioned (seller_id, header_text)
SELECT
  1 + ((gs * 7) % 300000),
  'Partitioned ad ' || gs
FROM generate_series(1, 1000000) gs;

ANALYZE service.mileage_partitioned;
ANALYZE service.contracts_partitioned;
ANALYZE service.ads_partitioned;
