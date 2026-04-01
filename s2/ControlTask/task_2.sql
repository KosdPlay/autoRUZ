-- Active: 1773576213453@@127.0.0.1@5432@postgres
-- Практическая контрольная работа.
-- Подготовка окружения.

DROP TABLE IF EXISTS shipment_stats CASCADE;
DROP TABLE IF EXISTS shipment_stats_src CASCADE;
DROP TABLE IF EXISTS booking_slots CASCADE;
DROP TABLE IF EXISTS warehouse_items CASCADE;
DROP TABLE IF EXISTS club_visits CASCADE;
DROP TABLE IF EXISTS club_members CASCADE;
DROP TABLE IF EXISTS store_checks CASCADE;

-- ----------------------------
-- Блок 1
-- ----------------------------
CREATE TABLE store_checks (
    id BIGSERIAL PRIMARY KEY,
    shop_id INTEGER NOT NULL,
    payment_type TEXT NOT NULL,
    total_sum NUMERIC(10,2) NOT NULL,
    sold_at TIMESTAMP NOT NULL,
    cashier_note TEXT
);

INSERT INTO store_checks (shop_id, payment_type, total_sum, sold_at, cashier_note)
SELECT
    ((g * 23) % 800) + 1,
    CASE
        WHEN g % 8 = 0 THEN 'cash'
        WHEN g % 3 = 0 THEN 'card'
        ELSE 'qr'
    END,
    ((g * 41) % 250000) / 100.0,
    TIMESTAMP '2025-01-01 00:00:00'
        + ((g % 75) || ' days')::interval
        + (((g * 19) % 86400) || ' seconds')::interval,
    'check-' || g
FROM generate_series(1, 70000) AS g;

INSERT INTO store_checks (shop_id, payment_type, total_sum, sold_at, cashier_note) VALUES
(77, 'card', 450.30, '2025-02-14 08:10:00', 'target-1'),
(77, 'cash', 180.00, '2025-02-14 11:45:00', 'target-2'),
(77, 'qr',   990.90, '2025-02-14 18:20:00', 'target-3'),
(77, 'card', 120.00, '2025-02-20 10:05:00', 'outside-range');

CREATE INDEX idx_store_checks_payment_type ON store_checks (payment_type);
CREATE INDEX idx_store_checks_total_sum_hash ON store_checks USING hash (total_sum);

-- ----------------------------
-- Блок 2
-- ----------------------------
CREATE TABLE club_members (
    id BIGSERIAL PRIMARY KEY,
    full_name TEXT NOT NULL,
    member_level TEXT NOT NULL,
    city_code TEXT NOT NULL
);

CREATE TABLE club_visits (
    id BIGSERIAL PRIMARY KEY,
    member_id BIGINT NOT NULL,
    spend NUMERIC(10,2) NOT NULL,
    visit_type TEXT NOT NULL,
    visit_at TIMESTAMP NOT NULL
);

INSERT INTO club_members (full_name, member_level, city_code)
SELECT
    'Member ' || g,
    CASE
        WHEN g % 15 = 0 THEN 'premium'
        WHEN g % 4 = 0 THEN 'plus'
        ELSE 'base'
    END,
    CASE
        WHEN g % 8 = 0 THEN 'KZN'
        WHEN g % 5 = 0 THEN 'MSK'
        ELSE 'NNV'
    END
FROM generate_series(1, 22000) AS g;

INSERT INTO club_visits (member_id, spend, visit_type, visit_at)
SELECT
    ((g * 17) % 22000) + 1,
    ((g * 13) % 150000) / 100.0,
    CASE
        WHEN g % 6 = 0 THEN 'gym'
        WHEN g % 5 = 0 THEN 'pool'
        ELSE 'group'
    END,
    TIMESTAMP '2025-01-01 00:00:00'
        + ((g % 90) || ' days')::interval
        + (((g * 43) % 86400) || ' seconds')::interval
FROM generate_series(1, 110000) AS g;

CREATE INDEX idx_club_visits_visit_at ON club_visits (visit_at);
CREATE INDEX idx_club_members_full_name ON club_members (full_name);

-- ----------------------------
-- Блок 3
-- ----------------------------
CREATE TABLE warehouse_items (
    id BIGSERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    stock INTEGER NOT NULL
);

INSERT INTO warehouse_items (title, stock) VALUES
('Cable', 40),
('Adapter', 25),
('Hub', 12);

-- ----------------------------
-- Блок 3b
-- ----------------------------
CREATE TABLE booking_slots (
    id BIGSERIAL PRIMARY KEY,
    room_code TEXT NOT NULL,
    reserved_count INTEGER NOT NULL
);

INSERT INTO booking_slots (room_code, reserved_count) VALUES
('A101', 1),
('B205', 3);

-- ----------------------------
-- Блок 4
-- ----------------------------
CREATE TABLE shipment_stats_src (
    region_code TEXT NOT NULL,
    shipped_on DATE NOT NULL,
    packages INTEGER NOT NULL,
    avg_weight NUMERIC(8,2)
);

INSERT INTO shipment_stats_src (region_code, shipped_on, packages, avg_weight)
SELECT
    'north',
    DATE '2025-02-01' + (g % 20),
    10 + (g % 150),
    ((g * 9) % 3000) / 100.0
FROM generate_series(1, 900) AS g;

INSERT INTO shipment_stats_src (region_code, shipped_on, packages, avg_weight)
SELECT
    'south',
    DATE '2025-02-01' + (g % 20),
    20 + (g % 170),
    ((g * 11) % 3500) / 100.0
FROM generate_series(1, 900) AS g;

INSERT INTO shipment_stats_src (region_code, shipped_on, packages, avg_weight)
SELECT
    'west',
    DATE '2025-02-01' + (g % 20),
    15 + (g % 160),
    ((g * 7) % 2800) / 100.0
FROM generate_series(1, 900) AS g;

INSERT INTO shipment_stats_src (region_code, shipped_on, packages, avg_weight)
SELECT
    'east',
    DATE '2025-02-01' + (g % 10),
    30 + (g % 90),
    ((g * 5) % 2200) / 100.0
FROM generate_series(1, 120) AS g;

ANALYZE;

SELECT 'booking_slots' AS table_name, count(*) AS rows_count FROM booking_slots
UNION ALL
SELECT 'club_members', count(*) FROM club_members
UNION ALL
SELECT 'club_visits', count(*) FROM club_visits
UNION ALL
SELECT 'shipment_stats_src', count(*) FROM shipment_stats_src
UNION ALL
SELECT 'store_checks', count(*) FROM store_checks
UNION ALL
SELECT 'warehouse_items', count(*) FROM warehouse_items
ORDER BY table_name;
