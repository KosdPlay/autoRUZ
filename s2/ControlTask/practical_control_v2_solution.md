# Решение practical_control_v2

## Задание 1. Оптимизация простого запроса

### SQL-команды
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, shop_id, total_sum, sold_at
FROM store_checks
WHERE shop_id = 77
  AND sold_at >= TIMESTAMP '2025-02-14 00:00:00'
  AND sold_at < TIMESTAMP '2025-02-15 00:00:00';
```

<img width="723" height="186" alt="Снимок экрана 2026-04-01 112810" src="https://github.com/user-attachments/assets/d4aa8212-5496-4155-9bf9-46c3b29fac9a" />

```sql
CREATE INDEX idx_store_checks_shop_sold_at
ON store_checks (shop_id, sold_at);

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, shop_id, total_sum, sold_at
FROM store_checks
WHERE shop_id = 77
  AND sold_at >= TIMESTAMP '2025-02-14 00:00:00'
  AND sold_at < TIMESTAMP '2025-02-15 00:00:00';
```

<img width="717" height="175" alt="Снимок экрана 2026-04-01 112853" src="https://github.com/user-attachments/assets/3b4e359a-4b76-4e3f-9c9d-7476a85e2b69" />

### Краткие пояснения
- **До изменений**: `Seq Scan on store_checks`, удалено фильтром `70001` строк, `Execution Time: ~13.7 ms`.
- **Бесполезные/слабо полезные индексы**: `idx_store_checks_payment_type` и `idx_store_checks_total_sum_hash`, потому что ни `payment_type`, ни `total_sum` не участвуют в условиях `WHERE`.
- **Почему выбран Seq Scan**: без подходящего индекса по `shop_id` и `sold_at` планировщик оценивает полный проход таблицы как единственный вариант.
- **После индекса**: `Index Scan using idx_store_checks_shop_sold_at`, `Execution Time: ~0.07 ms`, чтение только нужного диапазона по композитному ключу.
- **Нужен ли ANALYZE после CREATE INDEX**: обычно не обязателен, потому что статистика по распределению данных в столбцах уже есть; но `ANALYZE` полезен после крупных изменений данных, чтобы улучшить оценки селективности.

## Задание 2. Анализ и улучшение JOIN-запроса

### SQL-команды
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT m.id, m.member_level, v.spend, v.visit_at
FROM club_members m
JOIN club_visits v ON v.member_id = m.id
WHERE m.member_level = 'premium'
  AND v.visit_at >= TIMESTAMP '2025-02-01 00:00:00'
  AND v.visit_at < TIMESTAMP '2025-02-10 00:00:00';
```

<img width="725" height="440" alt="Снимок экрана 2026-04-01 113046" src="https://github.com/user-attachments/assets/9be88aef-7667-4bcc-8b14-31e27d5ec9b5" />

```sql
CREATE INDEX idx_club_visits_visit_member_inc
ON club_visits (visit_at, member_id) INCLUDE (spend);

EXPLAIN (ANALYZE, BUFFERS)
SELECT m.id, m.member_level, v.spend, v.visit_at
FROM club_members m
JOIN club_visits v ON v.member_id = m.id
WHERE m.member_level = 'premium'
  AND v.visit_at >= TIMESTAMP '2025-02-01 00:00:00'
  AND v.visit_at < TIMESTAMP '2025-02-10 00:00:00';
```

<img width="579" height="376" alt="Снимок экрана 2026-04-01 113151" src="https://github.com/user-attachments/assets/213ee8c5-e83b-4d28-aaf3-325910a87cf3" />


### Краткие пояснения
- **Тип JOIN до изменений**: `Hash Join`.
- **Почему выбран Hash Join**: из `club_visits` берется заметный диапазон дат (около 11k строк), а из `club_members` после фильтра `premium` остается ~1.5k строк; в таком случае хэш-таблица по меньшей стороне и последующее сопоставление обычно дешевле массовых индексных lookup.
- **Слабо полезные индексы**: `idx_club_members_full_name` не помогает, потому что фильтр идет по `member_level`; `idx_club_visits_visit_at` полезен частично (только отбор по времени), но не покрывает join-ключ и поле `spend`.
- **Улучшение**: добавлен покрывающий индекс `(visit_at, member_id) INCLUDE (spend)` на таблицу посещений.
- **После изменений**: план сохранил `Hash Join`, но левая часть стала `Index Only Scan` с `Heap Fetches: 0`; время снизилось примерно с `~9.4 ms` до `~6.9 ms`.
- **BUFFERS (shared hit/read)**: преобладание `shared hit` означает чтение из буферного кеша Postgres (быстрее); преобладание `shared read` означает больше обращений к диску (медленнее, «холодные» данные).

## Задание 3. MVCC и очистка

### SQL-команды
```sql
SELECT xmin, xmax, ctid, id, title, stock
FROM warehouse_items
ORDER BY id;

UPDATE warehouse_items
SET stock = stock - 2
WHERE id = 1;

SELECT xmin, xmax, ctid, id, title, stock
FROM warehouse_items
ORDER BY id;

DELETE FROM warehouse_items
WHERE id = 3;

SELECT xmin, xmax, ctid, id, title, stock
FROM warehouse_items
ORDER BY id;
```

### Краткие пояснения
- **После UPDATE**: для `id=1` изменилась версия строки — `xmin` стал новым (`986`), `ctid` сменился с `(0,1)` на `(0,4)`, а видимая строка получила новое значение `stock=38`.
- **Почему UPDATE не "перезапись"**: в MVCC создается новая версия кортежа, а старая помечается как устаревшая для будущих транзакций; это обеспечивает согласованное чтение без блокировки читателей.
- **После DELETE**: строка с `id=3` исчезла из обычного `SELECT`, потому что для текущей транзакции она помечена удаленной и больше не проходит проверку видимости.
- **Сравнение механизмов**:
  - `VACUUM` очищает "мертвые" версии строк и освобождает место для повторного использования внутри таблицы.
  - `autovacuum` делает то же автоматически в фоне по порогам активности.
  - `VACUUM FULL` переписывает таблицу целиком, реально уменьшая файл на диске.
- **Кто может полностью блокировать таблицу**: `VACUUM FULL` (берет `ACCESS EXCLUSIVE` lock).

## Задание 4. Блокировки строк

### SQL-команды
```sql
-- Эксперимент 1
-- Сессия A
BEGIN;
SELECT * FROM booking_slots WHERE id = 1 FOR KEY SHARE;

-- Сессия B
SET statement_timeout = '3s';
DELETE FROM booking_slots WHERE id = 1;

-- Сессия A
ROLLBACK;

-- Эксперимент 2
-- Сессия A
BEGIN;
SELECT * FROM booking_slots WHERE id = 1 FOR NO KEY UPDATE;

-- Сессия B
SET statement_timeout = '3s';
UPDATE booking_slots
SET reserved_count = reserved_count + 1
WHERE id = 1;

-- Сессия A
ROLLBACK;
```

### Краткие пояснения
- **Эксперимент 1 (`FOR KEY SHARE` vs `DELETE`)**: `DELETE` в сессии B блокируется и при `statement_timeout='3s'` завершается ошибкой `canceling statement due to statement timeout`.
- **Эксперимент 2 (`FOR NO KEY UPDATE` vs `UPDATE`)**: конкурирующий `UPDATE` также блокируется и по таймауту завершается ошибкой.
- **Разница между блокировками**: `FOR KEY SHARE` защищает строку от удаления/изменения ключа, но более "слабая" по назначению; `FOR NO KEY UPDATE` — более сильная блокировка для сценариев, где строку планируют менять (кроме ключа) и нужно исключить конкурентные записи.
- **Почему обычный SELECT ведет себя иначе**: обычное чтение не берет row-level lock этих типов, работает по MVCC-снимку и не блокирует/не блокируется так же, как `SELECT ... FOR ...`.
- **Где применять `FOR NO KEY UPDATE`**: в транзакциях бронирования/резервирования/счетчиков, когда нужно прочитать строку и затем безопасно обновить ее без гонки конкурентных изменений.

## Задание 5. Секционирование и partition pruning

### SQL-команды
```sql
DROP TABLE IF EXISTS shipment_stats CASCADE;

CREATE TABLE shipment_stats (
    region_code TEXT NOT NULL,
    shipped_on DATE NOT NULL,
    packages INTEGER NOT NULL,
    avg_weight NUMERIC(8,2)
) PARTITION BY LIST (region_code);

CREATE TABLE shipment_stats_north PARTITION OF shipment_stats FOR VALUES IN ('north');
CREATE TABLE shipment_stats_south PARTITION OF shipment_stats FOR VALUES IN ('south');
CREATE TABLE shipment_stats_west  PARTITION OF shipment_stats FOR VALUES IN ('west');
CREATE TABLE shipment_stats_default PARTITION OF shipment_stats DEFAULT;

INSERT INTO shipment_stats (region_code, shipped_on, packages, avg_weight)
SELECT region_code, shipped_on, packages, avg_weight
FROM shipment_stats_src;

ANALYZE shipment_stats;

EXPLAIN (ANALYZE, BUFFERS)
SELECT region_code, shipped_on, packages
FROM shipment_stats
WHERE region_code = 'north';

EXPLAIN (ANALYZE, BUFFERS)
SELECT region_code, shipped_on, packages
FROM shipment_stats
WHERE shipped_on >= DATE '2025-02-10'
  AND shipped_on < DATE '2025-02-15';
```

### Краткие пояснения
- **Запрос по `region_code='north'`**: pruning есть; в плане участвует только 1 секция (`shipment_stats_north`).
- **Запрос по диапазону `shipped_on`**: pruning по LIST-ключу нет, в плане участвуют все 4 секции (`north`, `south`, `west`, `default`) через `Append`.
- **Причина различия**: секционирование сделано по `region_code`, поэтому отсечение секций работает только когда предикат связан с ключом секционирования.
- **Связь pruning и индексов**: pruning не зависит напрямую от обычного индекса; это логика планировщика на уровне partition bounds.
- **Зачем нужна `DEFAULT`-секция**: чтобы принять строки с кодами регионов, не перечисленными в явных секциях (в данных есть `east`), и избежать ошибки вставки.
