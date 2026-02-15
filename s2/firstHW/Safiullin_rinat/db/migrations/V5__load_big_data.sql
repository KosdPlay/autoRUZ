-- users 250k
INSERT INTO service.users(full_name, email, phone_number, registration_date, profile_json)
SELECT
  'User ' || gs,
  'user' || gs || '@mail.test',
  CASE WHEN random() < 0.12 THEN NULL ELSE '+7' || lpad((trunc(random()*1e10))::bigint::text, 10, '0') END,
  now() - (trunc(random()*3650)::int || ' days')::interval,
  jsonb_build_object(
    'marketing', (random() < 0.5),
    'lang', (ARRAY['ru','en','tt'])[1 + (random()*2)::int],
    'score', trunc(random()*1000)
  )
FROM generate_series(1, 250000) gs;

-- sellers ~50k (каждый 5-й пользователь)
INSERT INTO service.sellers(user_id, seller_type, created_at)
SELECT
  u.user_id,
  CASE WHEN random() < 0.8 THEN 'individual' ELSE 'company' END,
  u.registration_date + (trunc(random()*180)::int || ' days')::interval
FROM service.users u
WHERE u.user_id % 5 = 0;

-- vehicles 250k
INSERT INTO service.vehicles(
  brand, model, year_of_manufacture, color, body_type_id, transmission_id, fuel_type_id,
  power_hp, state_code, vin, features, mileage_range
)
SELECT
  (ARRAY['Toyota','Kia','BMW','Lada','Hyundai','VW','Audi'])[1 + (random()*6)::int],
  'Model_' || (1 + (random()*40)::int),
  1990 + (random()*35)::int,
  CASE WHEN random() < 0.10 THEN NULL ELSE (ARRAY['black','white','red','blue','silver'])[1 + (random()*4)::int] END,
  (SELECT id FROM service.body_types ORDER BY id LIMIT 1 OFFSET (random()*3)::int),
  (SELECT id FROM service.transmissions ORDER BY id LIMIT 1 OFFSET (random()*2)::int),
  (SELECT id FROM service.fuel_types ORDER BY id LIMIT 1 OFFSET (random()*3)::int),
  70 + (random()*350)::int,
  (ARRAY['new','used','damaged'])[1 + (random()*2)::int],
  lpad(gs::text, 17, 'V'),
  ARRAY[
    (ARRAY['abs','esp','heated_seats','camera','autopilot'])[1 + (random()*4)::int],
    (ARRAY['cruise','parktronic','bluetooth','led','alarm'])[1 + (random()*4)::int]
  ],
  int4range((random()*50000)::int, (50000 + random()*250000)::int, '[]')
FROM generate_series(1, 250000) gs;

-- ads 250k, перекос: 70% объявлений у ~10% sellers
WITH sellers_ranked AS (
  SELECT seller_id, ntile(10) OVER (ORDER BY seller_id) AS decile
  FROM service.sellers
),
pick AS (
  SELECT
    gs AS n,
    CASE
      WHEN random() < 0.70 THEN (SELECT seller_id FROM sellers_ranked WHERE decile=1 ORDER BY random() LIMIT 1)
      ELSE (SELECT seller_id FROM service.sellers ORDER BY random() LIMIT 1)
    END AS seller_id,
    (SELECT vehicle_id FROM service.vehicles ORDER BY random() LIMIT 1) AS vehicle_id
  FROM generate_series(1, 250000) gs
)
INSERT INTO service.ads(
  seller_id, vehicle_id, header_text, description, price, publication_date, status_id, geo_point, search_tsv
)
SELECT
  p.seller_id,
  p.vehicle_id,
  'Selling car #' || p.n,
  CASE WHEN random() < 0.15 THEN NULL ELSE
    'Good condition. ' ||
    (ARRAY['One owner','Service book','No accidents','Urgent sale','Trade possible','New tires','Low mileage'])[1 + (random()*6)::int]
  END,
  (random()*3000000)::int,
  now() - (trunc(random()*365)::int || ' days')::interval,
  (SELECT id FROM service.ad_statuses ORDER BY id LIMIT 1 OFFSET (random()*2)::int),
  CASE WHEN random() < 0.10 THEN NULL ELSE point(55 + random()*10, 37 + random()*10) END,
  to_tsvector('simple', ('Selling car #' || p.n) || ' ' || coalesce(
    CASE WHEN random() < 0.15 THEN NULL ELSE 'Good condition and nice price' END, ''
  ))
FROM pick p;

-- mileage_log 250k
INSERT INTO service.mileage_log(vehicle_id, recorded_at, mileage_km)
SELECT
  (SELECT vehicle_id FROM service.vehicles ORDER BY random() LIMIT 1),
  now() - (trunc(random()*720)::int || ' days')::interval,
  (random()*350000)::int
FROM generate_series(1, 250000);

ANALYZE;