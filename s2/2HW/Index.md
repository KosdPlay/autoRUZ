DROP INDEX IF EXISTS service.idx_vehicles_brand_btree;
DROP INDEX IF EXISTS service.idx_vehicles_year_btree;
DROP INDEX IF EXISTS service.idx_ads_price_btree;
DROP INDEX IF EXISTS service.idx_users_email_btree;
DROP INDEX IF EXISTS service.idx_vehicles_state_btree;

DROP INDEX IF EXISTS service.idx_vehicles_brand_hash;
DROP INDEX IF EXISTS service.idx_vehicles_state_hash;
DROP INDEX IF EXISTS service.idx_users_email_hash;

DROP INDEX IF EXISTS service.idx_vehicles_brand_year_btree;

ANALYZE service.vehicles;
ANALYZE service.ads;
ANALYZE service.users;


-- ============================================================================
-- 1. ТЕСТИРОВАНИЕ БЕЗ ИНДЕКСОВ
-- ============================================================================

-- Запрос 1: Оператор = (равенство)
EXPLAIN SELECT * FROM service.vehicles WHERE brand = 'Toyota';
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE brand = 'Toyota';
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE brand = 'Toyota';

-- Запрос 2: Оператор > (больше)
EXPLAIN SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;

-- Запрос 3: Оператор < (меньше)
EXPLAIN SELECT * FROM service.ads WHERE price < 500000;
EXPLAIN (ANALYZE) SELECT * FROM service.ads WHERE price < 500000;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.ads WHERE price < 500000;

-- Запрос 4: Оператор LIKE 'prefix%' (префикс)
EXPLAIN SELECT * FROM service.users WHERE email LIKE 'user1%';
EXPLAIN (ANALYZE) SELECT * FROM service.users WHERE email LIKE 'user1%';
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.users WHERE email LIKE 'user1%';

-- Запрос 5: Оператор IN (множество значений)
EXPLAIN SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');


-- ============================================================================
-- 2. СОЗДАНИЕ B-TREE ИНДЕКСОВ И ТЕСТИРОВАНИЕ
-- ============================================================================
CREATE INDEX idx_vehicles_brand_btree ON service.vehicles USING btree (brand);
CREATE INDEX idx_vehicles_year_btree ON service.vehicles USING btree (year_of_manufacture);
CREATE INDEX idx_ads_price_btree ON service.ads USING btree (price);
CREATE INDEX idx_users_email_btree ON service.users USING btree (email);
CREATE INDEX idx_vehicles_state_btree ON service.vehicles USING btree (state_code);

ANALYZE service.vehicles;
ANALYZE service.ads;
ANALYZE service.users;

-- Запрос 1: = с B-tree
EXPLAIN SELECT * FROM service.vehicles WHERE brand = 'Toyota';
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE brand = 'Toyota';
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE brand = 'Toyota';

-- Запрос 2: > с B-tree
EXPLAIN SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;

-- Запрос 3: < с B-tree
EXPLAIN SELECT * FROM service.ads WHERE price < 500000;
EXPLAIN (ANALYZE) SELECT * FROM service.ads WHERE price < 500000;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.ads WHERE price < 500000;

-- Запрос 4: LIKE 'prefix%' с B-tree
EXPLAIN SELECT * FROM service.users WHERE email LIKE 'user1%';
EXPLAIN (ANALYZE) SELECT * FROM service.users WHERE email LIKE 'user1%';
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.users WHERE email LIKE 'user1%';

-- Запрос 5: IN с B-tree
EXPLAIN SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');


-- ============================================================================
-- 3. СОЗДАНИЕ HASH ИНДЕКСОВ И ТЕСТИРОВАНИЕ
-- ============================================================================
CREATE INDEX idx_vehicles_brand_hash ON service.vehicles USING hash (brand);
CREATE INDEX idx_vehicles_state_hash ON service.vehicles USING hash (state_code);
CREATE INDEX idx_users_email_hash ON service.users USING hash (email);

ANALYZE service.vehicles;
ANALYZE service.users;

-- Запрос 1: = с Hash
EXPLAIN SELECT * FROM service.vehicles WHERE brand = 'Toyota';
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE brand = 'Toyota';
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE brand = 'Toyota';

-- Запрос 5: IN с Hash
EXPLAIN SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE state_code IN ('new', 'used');

-- Дополнительно: email = с Hash
EXPLAIN SELECT * FROM service.users WHERE email = 'user12345@mail.com';
EXPLAIN (ANALYZE) SELECT * FROM service.users WHERE email = 'user12345@mail.com';
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.users WHERE email = 'user12345@mail.com';


-- ============================================================================
-- 4. СОСТАВНОЙ ИНДЕКС (COMPOSITE INDEX)
-- ============================================================================
CREATE INDEX idx_vehicles_brand_year_btree ON service.vehicles USING btree (brand, year_of_manufacture);

ANALYZE service.vehicles;

-- Запрос: использует обе колонки составного индекса
EXPLAIN SELECT * FROM service.vehicles WHERE brand = 'Toyota' AND year_of_manufacture > 2020;
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE brand = 'Toyota' AND year_of_manufacture > 2020;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE brand = 'Toyota' AND year_of_manufacture > 2020;

-- Запрос: использует только вторую колонку (неэффективно)
EXPLAIN SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
EXPLAIN (ANALYZE) SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM service.vehicles WHERE year_of_manufacture > 2020;