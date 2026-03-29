-- Выполнить на роутере после запуска шардов: psql -f /setup/setup_fdw.sql
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

DROP SERVER IF EXISTS shard1 CASCADE;
DROP SERVER IF EXISTS shard2 CASCADE;

CREATE SERVER shard1 FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'fdw_shard1', dbname 'shard_db', port '5432');

CREATE SERVER shard2 FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'fdw_shard2', dbname 'shard_db', port '5432');

CREATE USER MAPPING FOR postgres SERVER shard1
    OPTIONS (user 'postgres', password 'postgres');

CREATE USER MAPPING FOR postgres SERVER shard2
    OPTIONS (user 'postgres', password 'postgres');

CREATE SCHEMA IF NOT EXISTS shard_fdw;

IMPORT FOREIGN SCHEMA shard
    LIMIT TO (listings)
    FROM SERVER shard1 INTO shard_fdw;

-- Вторая схема: listings со shard2 (имя таблицы конфликтует — отдельное имя)
CREATE FOREIGN TABLE shard_fdw.listings_s2 (
    id         INTEGER NOT NULL,
    seller_id  INTEGER NOT NULL,
    title      TEXT NOT NULL
) SERVER shard2 OPTIONS (schema_name 'shard', table_name 'listings');

-- «Глобальное» представление: все строки со всех шардов
CREATE OR REPLACE VIEW shard_fdw.all_listings AS
SELECT id, seller_id, title, 'shard1'::text AS shard FROM shard_fdw.listings
UNION ALL
SELECT id, seller_id, title, 'shard2'::text AS shard FROM shard_fdw.listings_s2;

ANALYZE shard_fdw.listings;
ANALYZE shard_fdw.listings_s2;
