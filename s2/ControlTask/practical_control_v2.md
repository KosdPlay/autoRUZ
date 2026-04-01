# Практическая контрольная работа — вариант 2

## Формат
```text
Что сдавать:
- SQL-команды, которые вы выполняли для решения.
- Краткие письменные пояснения по каждому заданию.

Где требуется анализ плана, используйте EXPLAIN (ANALYZE, BUFFERS).
Короткие пояснения: 1-3 предложения.
Развернутые пояснения: 3-5 предложений.
```

## Задание 1. Оптимизация простого запроса

Используйте таблицу `store_checks`.

Исходный запрос:

```sql
SELECT id, shop_id, total_sum, sold_at
FROM store_checks
WHERE shop_id = 77
  AND sold_at >= TIMESTAMP '2025-02-14 00:00:00'
  AND sold_at < TIMESTAMP '2025-02-15 00:00:00';
```

Что нужно сделать:

```text
1. Постройте план выполнения запроса до изменений.
2. Укажите:
   - какой тип сканирования использован;
   - какие из уже созданных индексов не помогают этому запросу;
   - почему планировщик выбирает именно такой план.
3. Создайте индекс, который лучше подходит под этот запрос.
4. Повторно постройте план выполнения.
5. Кратко объясните, что изменилось в плане и почему.
6. Ответьте, нужно ли после создания индекса выполнять ANALYZE, и зачем.
```

## Задание 2. Анализ и улучшение JOIN-запроса

Используйте таблицы `club_members` и `club_visits`.

Исходный запрос:

```sql
SELECT m.id, m.member_level, v.spend, v.visit_at
FROM club_members m
JOIN club_visits v ON v.member_id = m.id
WHERE m.member_level = 'premium'
  AND v.visit_at >= TIMESTAMP '2025-02-01 00:00:00'
  AND v.visit_at < TIMESTAMP '2025-02-10 00:00:00';
```

Что нужно сделать:

```text
1. Постройте план выполнения запроса до изменений.
2. Определите, какой тип JOIN использован.
3. Объясните, почему планировщик выбрал именно этот тип JOIN.
4. Укажите, какие существующие индексы полезны слабо или не полезны для этого запроса.
5. Предложите и создайте одно улучшение, которое может ускорить запрос.
   Допустимые варианты: новый индекс, другой более подходящий индекс, ANALYZE.
6. Повторно постройте план выполнения.
7. Кратко поясните, улучшился ли план и за счет чего.
8. Отдельно укажите, что означает преобладание shared hit или read в BUFFERS.
```

## Задание 3. MVCC и очистка

Используйте таблицу `warehouse_items`.

Последовательно выполните:

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

Что нужно сделать:

```text
1. Опишите, что изменилось после UPDATE с точки зрения xmin, xmax и ctid.
2. Объясните, почему в модели MVCC UPDATE не является простым "перезаписыванием" строки.
3. Объясните, что произошло после DELETE и почему строка исчезла из обычного SELECT.
4. Кратко сравните:
   - VACUUM;
   - autovacuum;
   - VACUUM FULL.
5. Отдельно укажите, какой из этих механизмов может полностью блокировать таблицу.
```

## Задание 4. Блокировки строк

Используйте таблицу `booking_slots`.

Откройте две сессии к базе данных: `A` и `B`.

В сессии `A` выполните:

```sql
BEGIN;
SELECT * FROM booking_slots WHERE id = 1 FOR KEY SHARE;
```

В сессии `B` выполните:

```sql
DELETE FROM booking_slots
WHERE id = 1;
```

После наблюдения результата завершите сессию `A`:

```sql
ROLLBACK;
```

Затем повторите эксперимент.

В сессии `A` выполните:

```sql
BEGIN;
SELECT * FROM booking_slots WHERE id = 1 FOR NO KEY UPDATE;
```

В сессии `B` выполните:

```sql
UPDATE booking_slots
SET reserved_count = reserved_count + 1
WHERE id = 1;
```

После наблюдения результата завершите сессию `A`:

```sql
ROLLBACK;
```

Что нужно сделать:

```text
1. Опишите, что происходит с DELETE и UPDATE в сессии B в двух экспериментах.
2. Объясните, чем FOR KEY SHARE отличается от FOR NO KEY UPDATE по смыслу и по силе блокировки.
3. Укажите, почему обычный SELECT без FOR KEY SHARE/FOR NO KEY UPDATE ведет себя иначе.
4. Кратко поясните, где в прикладных сценариях может использоваться FOR NO KEY UPDATE.
```

## Задание 5. Секционирование и partition pruning

Используйте таблицу-источник `shipment_stats_src`.

Сначала самостоятельно создайте секционированную таблицу `shipment_stats`:

```text
1. Таблица должна быть секционирована по LIST по полю region_code.
2. Создайте секции:
   - north;
   - south;
   - west;
   - DEFAULT.
3. Перенесите данные из shipment_stats_src в shipment_stats.
```

Постройте планы для двух запросов:

```sql
SELECT region_code, shipped_on, packages
FROM shipment_stats
WHERE region_code = 'north';
```

```sql
SELECT region_code, shipped_on, packages
FROM shipment_stats
WHERE shipped_on >= DATE '2025-02-10'
  AND shipped_on < DATE '2025-02-15';
```

Что нужно сделать:

```text
1. Для каждого запроса укажите, есть ли partition pruning.
2. Для каждого запроса укажите, сколько секций участвует в плане.
3. Объясните, почему в одном случае планировщик может отсечь секции, а в другом — нет.
4. Ответьте, связан ли pruning напрямую с наличием обычного индекса.
5. Кратко объясните, зачем в этом задании нужна секция DEFAULT.
```
