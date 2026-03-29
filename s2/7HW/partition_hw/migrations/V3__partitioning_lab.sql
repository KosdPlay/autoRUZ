-- Секционированные таблицы для ДЗ: только DDL (данные — в V4__load_big_data.sql).

-- RANGE: пробег по дате записи (FK на service.vehicles — строки появятся после V4)
CREATE TABLE service.mileage_partitioned (
    mileage_id     BIGSERIAL,
    vehicle_id     INTEGER NOT NULL REFERENCES service.vehicles(vehicle_id) ON DELETE CASCADE,
    recorded_at    TIMESTAMP NOT NULL,
    mileage_km     INTEGER CHECK (mileage_km >= 0),
    PRIMARY KEY (mileage_id, recorded_at)
) PARTITION BY RANGE (recorded_at);

CREATE TABLE service.mileage_p2024 PARTITION OF service.mileage_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE service.mileage_p2025 PARTITION OF service.mileage_partitioned
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE service.mileage_p2026 PARTITION OF service.mileage_partitioned
    FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

CREATE INDEX idx_mileage_partitioned_recorded_at ON service.mileage_partitioned (recorded_at);

-- LIST: «контракты» по статусу
CREATE TABLE service.contracts_partitioned (
    contract_id BIGSERIAL,
    seller_id   INTEGER NOT NULL,
    amount      INTEGER NOT NULL CHECK (amount >= 0),
    status      VARCHAR(20) NOT NULL CHECK (status IN ('active', 'closed', 'pending')),
    PRIMARY KEY (contract_id, status)
) PARTITION BY LIST (status);

CREATE TABLE service.contracts_p_active PARTITION OF service.contracts_partitioned
    FOR VALUES IN ('active');

CREATE TABLE service.contracts_p_closed PARTITION OF service.contracts_partitioned
    FOR VALUES IN ('closed');

CREATE TABLE service.contracts_p_pending PARTITION OF service.contracts_partitioned
    FOR VALUES IN ('pending');

CREATE INDEX idx_contracts_partitioned_seller ON service.contracts_partitioned (seller_id);

-- HASH: по seller_id
CREATE TABLE service.ads_partitioned (
    ad_id       BIGSERIAL,
    seller_id   INTEGER NOT NULL,
    header_text VARCHAR(200) NOT NULL,
    PRIMARY KEY (ad_id, seller_id)
) PARTITION BY HASH (seller_id);

CREATE TABLE service.ads_hash_p0 PARTITION OF service.ads_partitioned
    FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE service.ads_hash_p1 PARTITION OF service.ads_partitioned
    FOR VALUES WITH (MODULUS 4, REMAINDER 1);

CREATE TABLE service.ads_hash_p2 PARTITION OF service.ads_partitioned
    FOR VALUES WITH (MODULUS 4, REMAINDER 2);

CREATE TABLE service.ads_hash_p3 PARTITION OF service.ads_partitioned
    FOR VALUES WITH (MODULUS 4, REMAINDER 3);

CREATE INDEX idx_ads_partitioned_seller ON service.ads_partitioned (seller_id);

-- Логическая репликация (publish_via_partition_root): тестовые INSERT — в разделе 3 файла Partitioning.md после CREATE SUBSCRIPTION.
CREATE TABLE service.logical_part_root (
    id           INTEGER NOT NULL,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payload      TEXT,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

CREATE TABLE service.logical_part_2025 PARTITION OF service.logical_part_root
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE service.logical_part_2026 PARTITION OF service.logical_part_root
    FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
