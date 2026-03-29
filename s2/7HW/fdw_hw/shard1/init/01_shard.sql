CREATE SCHEMA shard;
CREATE TABLE shard.listings (
    id         INTEGER PRIMARY KEY,
    seller_id  INTEGER NOT NULL,
    title      TEXT NOT NULL
);

-- Шард 1: «левые» id (условное разбиение для демо)
INSERT INTO shard.listings (id, seller_id, title) VALUES
    (1, 101, 'Listing 1 (shard1)'),
    (3, 303, 'Listing 3 (shard1)'),
    (5, 505, 'Listing 5 (shard1)');
