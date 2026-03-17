## 1. WAL

WAL (Write-Ahead Logging) - это механизм логирования в PostgreSQL.

### Определение:
- WAL записывает все изменения данных в журнал ДО записи на диск
- Гарантирует надежность и восстановление после сбоя

### LSN (Log Sequence Number):
- Уникальный идентификатор позиции в WAL (0/30000000)
- Показывает текущую позицию в журнале

### Принцип:
1. INSERT/UPDATE/DELETE → записывается в WAL
2. COMMIT → финальная запись в WAL
3. Если сбой → восстанавливаем из WAL

### Файлы:
- Хранятся в pg_wal директории
- Размер каждого файла: 16MB

## 2a) Сравнение LSN до и после INSERT

```sql
-- LSN ДО INSERT
SELECT pg_current_wal_lsn() as lsn_before_insert;
```
<img width="172" height="56" alt="Снимок экрана 2026-03-17 182933" src="https://github.com/user-attachments/assets/476a6023-4b68-4ca0-856e-af6e5afcacff" />


```sql
-- Вставка данных
INSERT INTO service.body_types(code, name) 
VALUES ('luxury_car', 'Luxury Car') 
ON CONFLICT DO NOTHING;

-- LSN ПОСЛЕ INSERT
SELECT pg_current_wal_lsn() as lsn_after_insert;
```

<img width="163" height="61" alt="Снимок экрана 2026-03-17 183010" src="https://github.com/user-attachments/assets/843059e5-3f20-4b5d-ae96-cc06d28afd9e" />

Вывод: LSN вырос, в WAL записалась информация об INSERT

## 2b) Сравнение WAL до и после COMMIT ==========

```sql
-- LSN ДО транзакции
SELECT pg_current_wal_lsn() as lsn_before_transaction;
```

<img width="201" height="60" alt="Снимок экрана 2026-03-17 183037" src="https://github.com/user-attachments/assets/d6305be2-52cc-41f9-8a18-f0b5f38e6d08" />

```sql
-- Начало транзакции
BEGIN;

-- INSERT внутри транзакции
INSERT INTO service.transmissions(code, name) 
VALUES ('semi_auto', 'Semi Automatic') 
ON CONFLICT DO NOTHING;

-- LSN ДО COMMIT (данные в WAL, но не закоммичено)
SELECT pg_current_wal_lsn() as lsn_before_commit;
```
<img width="187" height="59" alt="Снимок экрана 2026-03-17 183103" src="https://github.com/user-attachments/assets/e675e959-1c6f-4660-a275-b0996cba9f63" />


```sql
-- COMMIT
COMMIT;

-- LSN ПОСЛЕ COMMIT (добавилась COMMIT запись в WAL)
SELECT pg_current_wal_lsn() as lsn_after_commit;
```
<img width="174" height="54" alt="Снимок экрана 2026-03-17 183139" src="https://github.com/user-attachments/assets/1f26a4a7-ae6c-4459-bec4-1e3298c29335" />


Вывод: COMMIT добавляет отдельную запись в WAL


## 2c) Анализ WAL размера после массовой операции

```sql
-- LSN ДО вставки
SELECT pg_current_wal_lsn() as lsn_before;
```

<img width="130" height="65" alt="Снимок экрана 2026-03-17 184052" src="https://github.com/user-attachments/assets/ebd8580a-58d0-4b9b-8038-1b02637b9f52" />


```sql
-- БОЛЬШАЯ ВСТАВКА
INSERT INTO service.vehicles(brand, model, year_of_manufacture, state_code, vin, power_hp)
SELECT 
  'Brand_' || i as brand,
  'Model_' || i as model,
  2020,
  'used',
  'VIN' || LPAD(i::text, 10, '0') as vin,
  150
FROM generate_series(1, 50000) as t(i)
ON CONFLICT (vin) DO NOTHING;

-- LSN ПОСЛЕ вставки
SELECT pg_current_wal_lsn() as lsn_after;
```

<img width="125" height="63" alt="Снимок экрана 2026-03-17 184139" src="https://github.com/user-attachments/assets/7e29be66-824e-44a8-a0f8-0632132093bd" />


-- Разница LSN (в байтах)
```sql
SELECT pg_wal_lsn_diff(
  '0/1C4400F8'::pg_lsn,
  '0/1D332830'::pg_lsn
) as bytes_written_to_wal;
```

<img width="193" height="59" alt="Снимок экрана 2026-03-17 184351" src="https://github.com/user-attachments/assets/cbc0dcbf-f827-46f8-a699-cbfb9e7dc794" />


## 3) DUMP И RESTORE БД

### 3a) DUMP ТОЛЬКО СТРУКТУРЫ БАЗЫ:
```cmd
docker exec my_postgres pg_dump -U postgres -d service_db -n service --schema-only > structure_dump.sql
```

Результат: файл structure_dump.sql содержит только CREATE TABLE, CREATE INDEX и т.д.


3b) DUMP ОДНОЙ ТАБЛИЦЫ:
```cmd
docker exec my_postgres pg_dump -U postgres -d service_db -t service.users > users_table_dump.sql
```
Результат: файл users_table_dump.sql содержит структуру и все данные таблицы service.users


3) RESTORE НА НОВУЮ ЧИСТУЮ БД:

1. Создай новую пустую БД внутри контейнера:
```cmd
docker exec my_postgres psql -U postgres -c "CREATE DATABASE new_service_db;"
```

2. Восстанови структуру:
```cmd
docker exec my_postgres psql -U postgres -d new_service_db < structure_dump.sql
```

3. Восстанови данные таблицы:
```cmd
docker exec my_postgres psql -U postgres -d new_service_db < users_table_dump.sql
```

4. Проверь результат:
```cmd
docker exec my_postgres psql -U postgres -d new_service_db -c "SELECT COUNT(*) FROM service.users;"
```


## 4) SEED ДАННЫЕ И ИДЕМПОТЕНТНОСТЬ

### 4a) Добавление тестовых данных
```sql
INSERT INTO service.users(full_name, email, phone_number) VALUES
  ('Test User 1', 'test.user.1@example.com', '+79001234567'),
  ('Test User 2', 'test.user.2@example.com', '+79002345678'),
  ('Test User 3', 'test.user.3@example.com', '+79003456789')
ON CONFLICT (email) DO NOTHING;


INSERT INTO service.sellers(user_id, seller_type)
SELECT user_id, 'individual'
FROM service.users
WHERE email LIKE 'test.user.%@example.com'
ON CONFLICT DO NOTHING;

INSERT INTO service.body_types(code, name) VALUES
  ('sport', 'Sport'),
  ('classic', 'Classic'),
  ('modern', 'Modern')
ON CONFLICT (code) DO NOTHING;

INSERT INTO service.transmissions(code, name) VALUES
  ('dual_clutch', 'Dual Clutch'),
  ('continuously', 'Continuously Variable')
ON CONFLICT (code) DO NOTHING;

INSERT INTO service.fuel_types(code, name) VALUES
  ('hydrogen', 'Hydrogen'),
  ('methane', 'Methane')
ON CONFLICT (code) DO NOTHING;
```

### 4b) Проверка идемпотентности seed (ON CONFLICT)
```sql
SELECT COUNT(*) as users_count FROM service.users WHERE email LIKE 'test.user.%@example.com';
```
<img width="140" height="58" alt="Снимок экрана 2026-03-17 185415" src="https://github.com/user-attachments/assets/090d0eee-5cff-432b-bd0f-4d1a728109a4" />
```sql
-- Попытка вставить одни и те же данные второй раз - ничего не добавится
INSERT INTO service.users(full_name, email, phone_number) VALUES
  ('Test User 1', 'test.user.1@example.com', '+79001234567'),
  ('Test User 2', 'test.user.2@example.com', '+79002345678')
ON CONFLICT (email) DO NOTHING;

-- Проверка: количество пользователей не изменилось

SELECT COUNT(*) as users_count FROM service.users WHERE email LIKE 'test.user.%@example.com';
```

<img width="140" height="58" alt="Снимок экрана 2026-03-17 185415" src="https://github.com/user-attachments/assets/090d0eee-5cff-432b-bd0f-4d1a728109a4" />

```sql
-- ON CONFLICT DO UPDATE - обновление при дубле

INSERT INTO service.users(full_name, email, phone_number) VALUES
  ('Test User 1 Updated', 'test.user.1@example.com', '+79009999999')
ON CONFLICT (email) 
DO UPDATE SET 
  full_name = EXCLUDED.full_name,
  phone_number = EXCLUDED.phone_number;

-- Проверка: Test User 1 обновлен
SELECT full_name, email, phone_number 
FROM service.users 
WHERE email = 'test.user.1@example.com';
```
<img width="435" height="52" alt="Снимок экрана 2026-03-17 185439" src="https://github.com/user-attachments/assets/e830cc88-d086-444a-af4f-bdda7b6b5181" />

```sql
-- ON CONFLICT для body_types с обновлением
INSERT INTO service.body_types(code, name) VALUES
  ('sport', 'Sport Car Updated')
ON CONFLICT (code) 
DO UPDATE SET name = EXCLUDED.name;

-- Проверка: body_type обновлен
SELECT code, name FROM service.body_types WHERE code = 'sport';
```
<img width="224" height="56" alt="Снимок экрана 2026-03-17 185459" src="https://github.com/user-attachments/assets/2ae9bfcf-c9a5-4e40-a2d6-880b7e1631e0" />
