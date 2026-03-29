## ДЗ 7: секционирование, репликация, postgres_fdw

СУБД: PostgreSQL 15.

---

## Часть 1. Секционирование и репликация

### Архитектура

**Physical streaming replication (WAL, async)**

```
[hw7_master] ──────► [hw7_replica]
```

**Logical replication (PUB/SUB)**

```
[hw7_master] (publisher) ──────► [hw7_logical_sub] (subscriber)
```

DDL на subscriber с publisher автоматически не реплицируется.

---

### Состав файлов в каталоге `partition_hw`

```
partition_hw/
  docker-compose.yml
  pg_hba_master.conf
  migrations/
    V1__init_schema.sql
    V2__seed_reference.sql
    V3__partitioning_lab.sql
    V4__load_big_data.sql
```

---

### `pg_hba_master.conf` (без BOM)

Файл сохраняется как UTF-8 **без BOM**.

```conf
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust

hostnossl replication   repl            0.0.0.0/0               md5
host    replication     repl            0.0.0.0/0               md5

hostnossl all           all             0.0.0.0/0               md5
host    all             all             0.0.0.0/0               md5
```

---

### `partition_hw/docker-compose.yml`

```yaml
services:
  hw7_master:
    image: postgres:15
    container_name: hw7_master
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: service_db
    ports:
      - "5544:5432"
    volumes:
      - hw7_pg_master_data:/var/lib/postgresql/data
      - ./pg_hba_master.conf:/etc/postgresql/pg_hba_master.conf:ro
    command: >
      postgres
      -c listen_addresses='*'
      -c hba_file=/etc/postgresql/pg_hba_master.conf
      -c wal_level=logical
      -c max_wal_senders=10
      -c max_replication_slots=10
      -c hot_standby=on
      -c wal_keep_size=512MB
      -c password_encryption=md5

  flyway_hw7_master:
    image: flyway/flyway:latest
    container_name: flyway_hw7_master
    depends_on:
      - hw7_master
    command: -url=jdbc:postgresql://hw7_master:5432/service_db -user=postgres -password=postgres -schemas=service migrate
    volumes:
      - ./migrations:/flyway/sql

  hw7_replica:
    image: postgres:15
    container_name: hw7_replica
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: service_db
    ports:
      - "5545:5432"
    volumes:
      - hw7_pg_replica_data:/var/lib/postgresql/data
    depends_on:
      - hw7_master

  hw7_logical_sub:
    image: postgres:15
    container_name: hw7_logical_sub
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: service_db
    ports:
      - "5546:5432"
    volumes:
      - hw7_pg_logical_data:/var/lib/postgresql/data
    command: >
      postgres
      -c listen_addresses='*'
      -c wal_level=logical
      -c max_wal_senders=10
      -c max_replication_slots=10

  flyway_hw7_logical:
    image: flyway/flyway:latest
    container_name: flyway_hw7_logical
    depends_on:
      - hw7_logical_sub
    command: -url=jdbc:postgresql://hw7_logical_sub:5432/service_db -user=postgres -password=postgres -schemas=service migrate
    volumes:
      - ./migrations:/flyway/sql

volumes:
  hw7_pg_master_data:
  hw7_pg_replica_data:
  hw7_pg_logical_data:
```

Порты с хоста: master **5544**, replica **5545**, logical subscriber **5546**.

---

### Запуск окружения (консоль)

Каталог: `7HW\partition_hw`.

### 1) Полный сброс

```bat
docker compose down -v
```

### 2) Поднять master и logical subscriber

```bat
docker compose up -d hw7_master hw7_logical_sub
```

### 3) Применить миграции на master и на logical subscriber

```bat
docker compose up -d flyway_hw7_master flyway_hw7_logical
```

Проверка master (порт 5544):

```bat
docker exec -it hw7_master psql -U postgres -d service_db -c "SELECT 1;"
```

---

## Настройка Physical streaming replication (консоль)

Каталог: `7HW\partition_hw`. Условие: шаги 1–3 выполнены, миграции на master применены.

### 4) Создать пользователя репликации на master

```bat
docker exec -it hw7_master psql -U postgres -d service_db -c "CREATE ROLE repl WITH REPLICATION LOGIN PASSWORD 'replpass';"
```

### 5) Создать physical replication slot на master

```bat
docker exec -it hw7_master psql -U postgres -d service_db -c "SELECT pg_create_physical_replication_slot('hw7_replica_slot');"
```

### 6) Создать том реплики (если отсутствует)

```bat
docker volume create partition_hw_hw7_pg_replica_data
```

Как в 6 ДЗ: том задаётся явно. При каталоге проекта `partition_hw` и имени Compose по умолчанию полное имя тома — `partition_hw_hw7_pg_replica_data`. Если в `docker volume ls` имя другое — использовать его в шаге 7 в параметре `-v`.

### 7) Выполнить basebackup для реплики

```bat
docker run --rm -it --network partition_hw_default -v partition_hw_hw7_pg_replica_data:/var/lib/postgresql/data postgres:15 bash -lc "rm -rf /var/lib/postgresql/data/* && PGPASSWORD=replpass pg_basebackup -h hw7_master -U repl -D /var/lib/postgresql/data -Fp -Xs -P -R && echo \"primary_slot_name = 'hw7_replica_slot'\" >> /var/lib/postgresql/data/postgresql.auto.conf"
```

### 8) Поднять physical standby

```bat
docker compose up -d hw7_replica
```

### 9) Статус physical replication (master)

```bat
docker exec -it hw7_master psql -U postgres -d service_db -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"
```

---

### Листинг `V3__partitioning_lab.sql` (совпадает с файлом миграции)

```sql
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

-- Логическая репликация (publish_via_partition_root): тестовые INSERT — в разделе 3 этого файла после CREATE SUBSCRIPTION.
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
```

---

### 1) Секционирование: RANGE, LIST, HASH

Таблицы создаются в `V3`, заполняются в `V4`.

- **RANGE** — `service.mileage_partitioned`, ключ `recorded_at`.
- **LIST** — `service.contracts_partitioned`, ключ `status`.
- **HASH** — `service.ads_partitioned`, ключ `seller_id`, четыре партиции (`MODULUS 4`).

Команды для планов:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.mileage_partitioned
WHERE recorded_at >= TIMESTAMP '2025-01-01'
  AND recorded_at < TIMESTAMP '2026-01-01';

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.mileage_partitioned;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.contracts_partitioned
WHERE status = 'active';

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.contracts_partitioned;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.ads_partitioned
WHERE seller_id = 7;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.ads_partitioned;
```

Выполнение — на **master** (`hw7_master`), база `service_db`, схема `service`. Итоговые формулировки для отчёта сверяются с фактическим текстом `EXPLAIN`.

**RANGE, запрос с диапазоном по дате (2025 год).**  
**a)** Partition pruning есть: в плане обычно один скан партиции `mileage_p2025`, без полного `Append` по всем годам.  
**b)** Участвует одна партиция.  
**c)** Часто используется индекс: **Index Scan** / **Bitmap Index Scan** по `idx_mileage_partitioned_recorded_at` на этой партиции.

**RANGE, запрос без условия на ключ.**  
**a)** Pruning нет.  
**b)** Три партиции, узел **Append** с тремя дочерними сканами.  
**c)** Обычно **Seq Scan** по каждой партиции.

**LIST, `status = 'active'`.**  
**a)** Pruning есть, остаётся `contracts_p_active`.  
**b)** Одна партиция.  
**c)** Часто **Seq Scan** по одной партиции; при добавлении селективного условия, например `seller_id = 1`, возможен **Index Scan** по `idx_contracts_partitioned_seller`:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM service.contracts_partitioned
WHERE status = 'active' AND seller_id = 1;
```

**LIST, полная выборка.**  
**a)** Pruning нет.  
**b)** Три партиции под **Append**.  
**c)** Обычно **Seq Scan** по каждой дочерней таблице.

**HASH, `seller_id = 7`.**  
**a)** Pruning есть, остаётся одна hash-партиция.  
**b)** Одна партиция.  
**c)** Обычно **Index Scan** / **Bitmap Index Scan** по `idx_ads_partitioned_seller`.

**HASH, полная выборка.**  
**a)** Pruning нет.  
**b)** Четыре партиции под **Append**.  
**c)** Обычно **Seq Scan** по каждой партиции.

**Как читать pruning и индекс в плане:** если под **Append** несколько дочерних сканов по именам партиций при отсутствии предиката по ключу секционирования — секции не отсекаются. Если при условии на ключ остался один дочерний скан одной партиции — pruning сработал. Наличие **Index Scan** / **Bitmap Index Scan** с нужным именем индекса означает использование индекса.

---

### 2) Секционирование и физическая репликация

**2.a) Наличие секционирования на реплике**

После запуска `hw7_replica` подключение к реплике: порт **5545**, БД `service_db`, пользователь `postgres`.

```bat
docker exec -it hw7_replica psql -U postgres -d service_db -c "\d+ service.mileage_partitioned"
```

```sql
SELECT c.relname, pg_get_expr(c.relpartbound, c.oid) AS bounds
FROM pg_class c
JOIN pg_inherits i ON i.inhrelid = c.oid
JOIN pg_class p ON p.oid = i.inhparent AND p.relname = 'mileage_partitioned'
ORDER BY 1;
```

В результате видны родитель и партиции `mileage_p2024`, `mileage_p2025`, `mileage_p2026` с границами.

**2.b) Почему физическая репликация «не знает» про секции**

Потоковая репликация переносит записи WAL на уровне страниц и файлов, а не логические операции вида «вставка в партицию X». Протокол не оперирует понятиями секция или родительская таблица. На standby та же картина в каталоге и в данных, потому что реплицировался тот же DDL и те же изменения файлов; интерпретация имён таблиц и секций остаётся задачей планировщика и каталога, а не формата WAL.

---

### 3) Логическая репликация и `publish_via_partition_root`

Таблица на publisher: `service.logical_part_root` (ключ `created_at`, партиции в `V3`). На subscriber структура совпадает за счёт тех же миграций Flyway на `hw7_logical_sub`.

**`publish_via_partition_root = on`**

В публикации указывается корневая секционированная таблица; изменения в партициях передаются как изменения корня.

На **master**:

```sql
DROP PUBLICATION IF EXISTS pub_logical_part;
CREATE PUBLICATION pub_logical_part FOR TABLE service.logical_part_root
  WITH (publish_via_partition_root = true);
```

Смена опции у существующей публикации:

```sql
ALTER PUBLICATION pub_logical_part SET (publish_via_partition_root = true);
```

**`publish_via_partition_root = off`**

Публикация привязана к перечисленным реляциям. При публикации только корня без `publish_via_partition_root = true` поведение для строк, попадающих в партиции, может отличаться от ожидаемого; обычно либо включают `publish_via_partition_root = true`, либо добавляют в публикацию сами партиции (`logical_part_2025`, `logical_part_2026` и т.д.) — детали в документации PostgreSQL.

Пример публикации с явным `false` (имя не должно конфликтовать с уже созданной `pub_logical_part`):

```sql
DROP PUBLICATION IF EXISTS pub_logical_part_off;
CREATE PUBLICATION pub_logical_part_off FOR TABLE service.logical_part_root
  WITH (publish_via_partition_root = false);
```

**Подписка на subscriber** (`hw7_logical_sub`, внутри Docker-сети хост master — `hw7_master`):

```sql
DROP SUBSCRIPTION IF EXISTS sub_logical_part;
CREATE SUBSCRIPTION sub_logical_part
  CONNECTION 'host=hw7_master port=5432 dbname=service_db user=postgres password=postgres'
  PUBLICATION pub_logical_part;
```

Проверка потока после создания подписки — вставка на **master**:

```sql
INSERT INTO service.logical_part_root (id, created_at, payload)
VALUES (10, '2025-08-01', 'after sub');
```

Проверка на **subscriber**:

```bat
docker exec -it hw7_logical_sub psql -U postgres -d service_db -c "SELECT * FROM service.logical_part_root ORDER BY created_at;"
```

---

## Часть 2. Шардирование через `postgres_fdw`

В формулировке ДЗ фигурируют два шарда и узел с FDW (в задании это назван «router»). В лекции отдельный термин «router» может не вводиться; по смыслу это экземпляр PostgreSQL, на котором настроены `postgres_fdw` и внешние таблицы к шардам.

### Архитектура

```
[fdw_router] ──postgres_fdw──► [fdw_shard1]
            └──postgres_fdw──► [fdw_shard2]
```

---

### Состав файлов в каталоге `fdw_hw`

```
fdw_hw/
  docker-compose.yml
  shard1/init/01_shard.sql
  shard2/init/01_shard.sql
  router/setup_fdw.sql
```

---

### `fdw_hw/docker-compose.yml`

```yaml
services:
  fdw_shard1:
    image: postgres:15
    container_name: fdw_shard1
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: shard_db
    ports:
      - "5551:5432"
    volumes:
      - ./shard1/init:/docker-entrypoint-initdb.d:ro

  fdw_shard2:
    image: postgres:15
    container_name: fdw_shard2
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: shard_db
    ports:
      - "5552:5432"
    volumes:
      - ./shard2/init:/docker-entrypoint-initdb.d:ro

  fdw_router:
    image: postgres:15
    container_name: fdw_router
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: router_db
    ports:
      - "5550:5432"
    depends_on:
      - fdw_shard1
      - fdw_shard2
    volumes:
      - ./router:/setup:ro
```

Порты: узел с FDW **5550**, шард 1 **5551**, шард 2 **5552**.

Скрипты в `shard1/init/` и `shard2/init/` выполняются при **первом** создании данных кластера. После смены SQL в них нужен полный сброс томов:

```bat
cd 7HW\fdw_hw
docker compose down -v
docker compose up -d
```

---

### Инициализация шардов (файлы `01_shard.sql`)

**Шард 1**

```sql
CREATE SCHEMA shard;
CREATE TABLE shard.listings (
    id         INTEGER PRIMARY KEY,
    seller_id  INTEGER NOT NULL,
    title      TEXT NOT NULL
);

INSERT INTO shard.listings (id, seller_id, title) VALUES
    (1, 101, 'Listing 1 (shard1)'),
    (3, 303, 'Listing 3 (shard1)'),
    (5, 505, 'Listing 5 (shard1)');
```

**Шард 2**

```sql
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
```

---

### Настройка FDW на узле `fdw_router`

Рабочий каталог: `7HW\fdw_hw`. Условие: контейнеры `fdw_shard1`, `fdw_shard2`, `fdw_router` запущены.

```bat
docker exec -it fdw_router psql -U postgres -d router_db -f /setup/setup_fdw.sql
```

Содержимое `router/setup_fdw.sql`:

```sql
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

CREATE FOREIGN TABLE shard_fdw.listings_s2 (
    id         INTEGER NOT NULL,
    seller_id  INTEGER NOT NULL,
    title      TEXT NOT NULL
) SERVER shard2 OPTIONS (schema_name 'shard', table_name 'listings');

CREATE OR REPLACE VIEW shard_fdw.all_listings AS
SELECT id, seller_id, title, 'shard1'::text AS shard FROM shard_fdw.listings
UNION ALL
SELECT id, seller_id, title, 'shard2'::text AS shard FROM shard_fdw.listings_s2;

ANALYZE shard_fdw.listings;
ANALYZE shard_fdw.listings_s2;
```

---

### 4) Запросы и планы (`postgres_fdw`)

Подключение к узлу с FDW с хоста:

```bat
psql -h localhost -p 5550 -U postgres -d router_db
```

**Простой запрос на все данные (оба шарда через представление):**

```sql
EXPLAIN (VERBOSE, COSTS)
SELECT * FROM shard_fdw.all_listings;
```

Типичный план: **Append** с двумя ветками **Foreign Scan** (внешние таблицы на `shard1` и `shard2`), так как представление — `UNION ALL` двух foreign table.

**Простой запрос на один шард (только данные с первого сервера):**

```sql
EXPLAIN (VERBOSE, COSTS)
SELECT * FROM shard_fdw.listings;
```

Типичный план: один **Foreign Scan** по `shard_fdw.listings` с удалённым запросом к `fdw_shard1`. Детали строки плана зависят от версии `postgres_fdw` и настроек; для отчёта копируется фактический вывод `EXPLAIN`.

---

### Полный список каталога `7HW` (обе части)

```
7HW/
  Partitioning.md
  partition_hw/
    docker-compose.yml
    pg_hba_master.conf
    migrations/
      V1__init_schema.sql
      V2__seed_reference.sql
      V3__partitioning_lab.sql
      V4__load_big_data.sql
  fdw_hw/
    docker-compose.yml
    shard1/init/01_shard.sql
    shard2/init/01_shard.sql
    router/setup_fdw.sql
```
