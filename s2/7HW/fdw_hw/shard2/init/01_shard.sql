CREATE SCHEMA shard;
CREATE TABLE shard.listings (
    id         INTEGER PRIMARY KEY,
    seller_id  INTEGER NOT NULL,
    title      TEXT NOT NULL
);

INSERT INTO shard.listings (id, seller_id, title) VALUES
    (2, 202, 'Listing 2 (shard2)'),
    (4, 404, 'Listing 4 (shard2)'),
    (6, 606, 'Listing 6 (shard2)');
