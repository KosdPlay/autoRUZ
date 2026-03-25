## Архитектура

### Physical streaming replication (WAL, ASYNC)


[pg_master] ─────► [pg_replica1]    
     └────────────►[pg_replica2]  
Тип: physical streaming (WAL). Режим: async.

### Logical replication (PUB/SUB)
`pg_master` (publisher) → `pg_logical_sub` (subscriber)  

Тип: logical replication (publication/subscription). DDL не реплицируется.

---

## Состав файлов в каталоге `repl_hw`

```
repl_hw/
  docker-compose.yml
  pg_hba_master.conf
  migrations/
    V1__init_service_schema.sql
    V2__seed_reference.sql   (если используется)
```

---

## `pg_hba_master.conf` (без BOM)

Файл должен быть сохранён как UTF-8 **без BOM**.

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

## `docker-compose.yml`

```yaml
services:
  pg_master:
    image: postgres:15
    container_name: pg_master
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: service_db
    ports:
      - "5434:5432"
    volumes:
      - pg_master_data:/var/lib/postgresql/data
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

  pg_replica1:
    image: postgres:15
    container_name: pg_replica1
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: service_db
    ports:
      - "5435:5432"
    volumes:
      - pg_replica1_data:/var/lib/postgresql/data
    depends_on:
      - pg_master

  pg_replica2:
    image: postgres:15
    container_name: pg_replica2
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: service_db
    ports:
      - "5436:5432"
    volumes:
      - pg_replica2_data:/var/lib/postgresql/data
    depends_on:
      - pg_master

  pg_logical_sub:
    image: postgres:15
    container_name: pg_logical_sub
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: service_db
    ports:
      - "5437:5432"
    volumes:
      - pg_logical_sub_data:/var/lib/postgresql/data
    command: >
      postgres
      -c listen_addresses='*'
      -c wal_level=logical
      -c max_wal_senders=10
      -c max_replication_slots=10

  flyway_master:
    image: flyway/flyway:latest
    container_name: flyway_master
    depends_on:
      - pg_master
    command: -url=jdbc:postgresql://pg_master:5432/service_db -user=postgres -password=postgres -schemas=service migrate
    volumes:
      - ./migrations:/flyway/sql

  flyway_logical_sub:
    image: flyway/flyway:latest
    container_name: flyway_logical_sub
    depends_on:
      - pg_logical_sub
    command: -url=jdbc:postgresql://pg_logical_sub:5432/service_db -user=postgres -password=postgres -schemas=service migrate
    volumes:
      - ./migrations:/flyway/sql

volumes:
  pg_master_data:
  pg_replica1_data:
  pg_replica2_data:
  pg_logical_sub_data:
```

---

## Миграции (Flyway)

- `V1__init_service_schema.sql` — таблицы/схема/представление  
- `V2__seed_reference.sql` — справочники (INSERT ... ON CONFLICT DO NOTHING)

---

## Запуск окружения (консоль)

В каталоге `repl_hw`:

### 1) Полный сброс
```bat
docker compose down -v
```

### 2) Поднять master и logical subscriber
```bat
docker compose up -d pg_master pg_logical_sub
```

### 3) Применить миграции на master и logical subscriber
```bat
docker compose up -d flyway_master flyway_logical_sub
```

---

## Настройка Physical streaming replication (консоль)

### 4) Создать пользователя репликации на master
```bat
docker exec -it pg_master psql -U postgres -d service_db -c "CREATE ROLE repl WITH REPLICATION LOGIN PASSWORD 'replpass';"
```

### 5) Создать physical replication slots на master
```bat
docker exec -it pg_master psql -U postgres -d service_db -c "SELECT pg_create_physical_replication_slot('replica1_slot');"
docker exec -it pg_master psql -U postgres -d service_db -c "SELECT pg_create_physical_replication_slot('replica2_slot');"
```

### 6) Создать volumes реплик (если отсутствуют)
```bat
docker volume create repl_hw_pg_replica1_data
docker volume create repl_hw_pg_replica2_data
```

### 7) Выполнить basebackup для replica1
```bat
docker run --rm -it --network repl_hw_default -v repl_hw_pg_replica1_data:/var/lib/postgresql/data postgres:15 bash -lc "rm -rf /var/lib/postgresql/data/* && PGPASSWORD=replpass pg_basebackup -h pg_master -U repl -D /var/lib/postgresql/data -Fp -Xs -P -R && echo \"primary_slot_name = 'replica1_slot'\" >> /var/lib/postgresql/data/postgresql.auto.conf"
```

### 8) Выполнить basebackup для replica2
```bat
docker run --rm -it --network repl_hw_default -v repl_hw_pg_replica2_data:/var/lib/postgresql/data postgres:15 bash -lc "rm -rf /var/lib/postgresql/data/* && PGPASSWORD=replpass pg_basebackup -h pg_master -U repl -D /var/lib/postgresql/data -Fp -Xs -P -R && echo \"primary_slot_name = 'replica2_slot'\" >> /var/lib/postgresql/data/postgresql.auto.conf"
```

### 9) Поднять physical standby
```bat
docker compose up -d pg_replica1 pg_replica2
```

### 10) Статус physical replication (master, консоль)
```bat
docker exec -it pg_master psql -U postgres -d service_db -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"
```

---

## Проверка physical replication данных

### 1) Вставка на master (DBeaver)
```sql
INSERT INTO service.body_types(code, name)
VALUES ('phys_test', 'Physical Test')
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name;
```

### 2) Проверка на replica1 (консоль)
```bat
docker exec -it pg_replica1 psql -U postgres -d service_db -c "SELECT * FROM service.body_types WHERE code='phys_test';"
```

<img width="1091" height="128" alt="Снимок экрана 2026-03-24 215625" src="https://github.com/user-attachments/assets/21764c83-3b0e-4e79-9edc-14922c29ebd9" />


### 3) Проверка на replica2 (консоль)
```bat
docker exec -it pg_replica2 psql -U postgres -d service_db -c "SELECT * FROM service.body_types WHERE code='phys_test';"
```

<img width="1093" height="124" alt="Снимок экрана 2026-03-24 215646" src="https://github.com/user-attachments/assets/46e45d07-9f30-48fb-bddd-8ba3bf00ef15" />


### 4) Попытка вставки на реплике (консоль)
```bat
docker exec -it pg_replica1 psql -U postgres -d service_db -c "INSERT INTO service.body_types(code,name) VALUES ('replica_write','X');"
```

<img width="1095" height="70" alt="Снимок экрана 2026-03-24 215701" src="https://github.com/user-attachments/assets/b2f275a2-2d58-4f07-a337-3f27576f7848" />


Ожидаемый результат: ошибка записи на standby (read-only).

---

## Анализ replication lag (physical)

### 1) Нагрузка INSERT на master (DBeaver)
```sql
INSERT INTO service.vehicles(brand, model, year_of_manufacture, state_code, vin, power_hp)
SELECT 'LagBrand','LagModel',2020,'used','LAGVIN' || lpad(g::text, 11, '0'),150
FROM generate_series(1, 500000) g
ON CONFLICT (vin) DO NOTHING;
```

### 2) Наблюдение lag на master (консоль)
```bat
docker exec -it pg_master psql -U postgres -d service_db -c "SELECT client_addr, state, sync_state, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS lag_bytes FROM pg_stat_replication;"
```

<img width="1103" height="177" alt="Снимок экрана 2026-03-24 223800" src="https://github.com/user-attachments/assets/2b7b86dd-70dc-4cf7-a27b-513db3bad57e" />


---

## Настройка Logical replication (publication/subscription)

### 1) PUBLICATION на master (DBeaver)
```sql
CREATE PUBLICATION pub_service FOR TABLE service.body_types;
```

### 2) SUBSCRIPTION на logical_sub (консоль)
```bat
docker exec -it pg_logical_sub psql -U postgres -d service_db -c "CREATE SUBSCRIPTION sub_service CONNECTION 'host=pg_master port=5432 dbname=service_db user=postgres password=postgres' PUBLICATION pub_service;"
```

---

## Проверки logical replication

### A) Данные реплицируются
1) Master (DBeaver):
```sql
INSERT INTO service.body_types(code, name)
VALUES ('log_test', 'Logical Test')
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name;
```

2) Subscriber (консоль):
```bat
docker exec -it pg_logical_sub psql -U postgres -d service_db -c "SELECT * FROM service.body_types WHERE code='log_test';"
```

<img width="1095" height="129" alt="Снимок экрана 2026-03-24 225230" src="https://github.com/user-attachments/assets/01698f54-a01f-4305-baeb-4425092faf83" />


### B) DDL не реплицируется
1) Master (DBeaver):
```sql
ALTER TABLE service.body_types ADD COLUMN ddl_added text;
```

2) Subscriber (консоль):
```bat
docker exec -it pg_logical_sub psql -U postgres -d service_db -c "\d service.body_types"
```

<img width="1104" height="293" alt="Снимок экрана 2026-03-24 225344" src="https://github.com/user-attachments/assets/e630a2e3-89a3-472d-879c-cf437328ce4f" />


Ожидаемый результат: колонка `ddl_added` отсутствует на subscriber.
