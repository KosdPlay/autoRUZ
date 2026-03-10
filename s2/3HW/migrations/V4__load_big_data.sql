-- ============================================
-- Справочники (без изменений)
-- ============================================
INSERT INTO service.body_types(code, name) VALUES
  ('sedan','Sedan'),
  ('hatchback','Hatchback'),
  ('suv','SUV'),
  ('coupe','Coupe'),
  ('truck','Truck'),
  ('van','Van')
ON CONFLICT DO NOTHING;

INSERT INTO service.transmissions(code, name) VALUES
  ('manual','Manual'),
  ('automatic','Automatic'),
  ('cvt','CVT')
ON CONFLICT DO NOTHING;

INSERT INTO service.fuel_types(code, name) VALUES
  ('petrol','Petrol'),
  ('diesel','Diesel'),
  ('electric','Electric'),
  ('hybrid','Hybrid')
ON CONFLICT DO NOTHING;

INSERT INTO service.ad_statuses(code, name) VALUES
  ('active','Active'),
  ('sold','Sold'),
  ('blocked','Blocked'),
  ('draft','Draft')
ON CONFLICT DO NOTHING;

INSERT INTO service.moderator_roles(code, name) VALUES
  ('supervisor','Supervisor'),
  ('editor','Editor'),
  ('viewer','Viewer')
ON CONFLICT DO NOTHING;

-- ============================================
-- Генерация пользователей и продавцов
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
FROM generate_series(1, 250000) gs;

SELECT setval(pg_get_serial_sequence('service.users','user_id'), 250000, true);

INSERT INTO service.sellers(seller_id, user_id, seller_type, created_at)
SELECT
  gs,
  gs,
  CASE WHEN random() < 0.85 THEN 'individual' ELSE 'company' END,
  now() - (floor(random()*365)::int || ' days')::interval
FROM generate_series(1, 250000) gs;

SELECT setval(pg_get_serial_sequence('service.sellers','seller_id'), 250000, true);

-- ============================================
-- Генерация транспортных средств
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
FROM generate_series(1, 250000) gs;

SELECT setval(pg_get_serial_sequence('service.vehicles','vehicle_id'), 250000, true);

-- ============================================
-- Генерация объявлений (только исходные колонки)
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
    WHEN random() < 0.70 THEN 1 + floor(random()*25000)::int
    ELSE 25001 + floor(random()*225000)::int
  END,
  1 + floor(random()*250000)::int,
  'Selling car #' || gs,
  CASE WHEN random() < 0.10 THEN NULL
       ELSE 'Great condition ' || md5(gs::text)
  END,
  (100000 + floor(random()*4900000))::int,
  now() - (floor(random()*365)::int || ' days')::interval,
  (SELECT id FROM st, stcnt WHERE rn = (gs % stcnt.c) + 1)
FROM generate_series(1, 250000) gs;

SELECT setval(pg_get_serial_sequence('service.ads','ad_id'), 250000, true);

-- ============================================
-- Опционально: генерация связанных данных
-- ============================================
-- Пример для ad_photos (если нужно)
INSERT INTO service.ad_photos(ad_id, url, is_primary)
SELECT
  1 + floor(random()*250000)::int,
  'https://example.com/img/' || gs || '.jpg',
  random() < 0.2
FROM generate_series(1, 500000) gs;

-- Пример для favourites
INSERT INTO service.favourites(user_id, ad_id, added_at)
SELECT
  1 + floor(random()*250000)::int,
  1 + floor(random()*250000)::int,
  now() - (floor(random()*365)::int || ' days')::interval
FROM generate_series(1, 100000) gs
ON CONFLICT (user_id, ad_id) DO NOTHING;

-- Пример для feedbacks
INSERT INTO service.feedbacks(user_id, seller_id, ad_id, text, rating, publication_date)
SELECT
  CASE WHEN random() < 0.9 THEN 1 + floor(random()*250000)::int ELSE NULL END,
  1 + floor(random()*250000)::int,
  1 + floor(random()*250000)::int,
  'Feedback text ' || gs,
  round((random()*5)::numeric, 2),
  now() - (floor(random()*365)::int || ' days')::interval
FROM generate_series(1, 50000) gs
ON CONFLICT (user_id, seller_id, ad_id) DO NOTHING;