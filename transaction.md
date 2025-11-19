## 1. Базовые операции с транзакциями

### 1.1. Транзакция с BEGIN ... COMMIT

**Задача:** Создать транзакцию, которая добавляет новую запись в одну таблицу и обновляет связанную запись в другой.

#### Пример 1: Оформление продажи автомобиля

До транзакции:
```sql
-- Статус объявления до продажи
SELECT a.ad_id, a.header_text, a.status_id, 
       (SELECT name FROM service.ad_statuses WHERE id = a.status_id) as status_name
FROM service.ads a WHERE a.ad_id = 1;

-- Контракты для этого объявления (если есть)
SELECT contract_id, ad_id, buyer_user_id, amount, status 
FROM service.contracts WHERE ad_id = 1;

-- История владения до продажи
SELECT ownership_id, vehicle_id, owner_user_id, purchase_date, sale_date, note
FROM service.ownerships WHERE vehicle_id = 1
ORDER BY ownership_id;
```
<br>
<img width="645" height="71" alt="image" src="https://github.com/user-attachments/assets/f1ad56b2-2f8c-4de7-807d-f0c94f230fa0" />
<img width="553" height="105" alt="image" src="https://github.com/user-attachments/assets/3d18a28a-5ec4-4242-848e-7d9039e3149a" />
<img width="758" height="78" alt="image" src="https://github.com/user-attachments/assets/a66236c5-a1e1-4b38-a705-bac22e14b054" />

```sql
-- Транзакция: покупатель приобретает автомобиль - создаем контракт, обновляем статус объявления, фиксируем смену владельца
BEGIN;

-- Создаем контракт о продаже
INSERT INTO service.contracts (ad_id, seller_id, buyer_user_id, amount, currency, status)
VALUES
(1, 1, 4, 2300000, 'RUB', 'closed');

-- Обновляем статус объявления на "продано"
UPDATE service.ads 
SET status_id = (SELECT id FROM service.ad_statuses WHERE code = 'sold')
WHERE ad_id = 1;

-- Фиксируем смену владельца в истории владения
UPDATE service.ownerships 
SET sale_date = CURRENT_DATE
WHERE vehicle_id = 1 AND sale_date IS NULL;

INSERT INTO service.ownerships (vehicle_id, owner_user_id, purchase_date, note)
VALUES
(1, 4, CURRENT_DATE, 'Покупка через автоплощадку');

COMMIT;

```

После транзакции:
```sql
-- Проверяем состояние ПОСЛЕ транзакции
SELECT '=== СОСТОЯНИЕ ПОСЛЕ ТРАНЗАКЦИИ ===' as info;

-- Статус объявления после продажи
SELECT a.ad_id, a.header_text, a.status_id, 
       (SELECT name FROM service.ad_statuses WHERE id = a.status_id) as status_name
FROM service.ads a WHERE a.ad_id = 1;

-- Новый контракт
SELECT contract_id, ad_id, seller_id, buyer_user_id, amount, currency, status, contract_date
FROM service.contracts WHERE ad_id = 1
ORDER BY contract_id DESC;

-- Обновленная история владения
SELECT ownership_id, vehicle_id, owner_user_id, purchase_date, sale_date, note
FROM service.ownerships WHERE vehicle_id = 1
ORDER BY ownership_id;
```
 <br>
<img width="648" height="73" alt="image" src="https://github.com/user-attachments/assets/fc4e00e6-41b7-4005-bf10-bf5701566af5" />
<img width="916" height="77" alt="image" src="https://github.com/user-attachments/assets/ed772562-8cf7-40f2-939b-408424fe8681" />
<img width="771" height="116" alt="image" src="https://github.com/user-attachments/assets/8f4d8b64-45f7-46b3-a3eb-159e84affc76" />

**Результат:** Продажа автомобиля оформлена: создан контракт, объявление помечено как проданное, обновлена история владения.


#### Пример 2: Публикация объявления с фотографиями

До транзакции:
```sql
-- Количество транспортных средств с маркой Audi
SELECT COUNT(*) as audi_count FROM service.vehicles WHERE brand = 'Audi' AND model = 'A4';

-- Количество объявлений продавца с ID = 1
SELECT COUNT(*) as seller_ads_count FROM service.ads WHERE seller_id = 1;
```
<br>
<img width="142" height="74" alt="image" src="https://github.com/user-attachments/assets/2101adf3-6e93-41e7-95c6-4f5018f57e78" />
<img width="177" height="72" alt="image" src="https://github.com/user-attachments/assets/7d61f8b8-6239-4436-90d1-eddfbc6249b8" />


```sql
-- Транзакция: продавец публикует объявление с несколькими фотографиями
BEGIN;

-- Добавляем новое транспортное средство
INSERT INTO service.vehicles 
(brand, model, year_of_manufacture, color, body_type_id, transmission_id, fuel_type_id, power_hp, state_code, vin)
VALUES
('Audi', 'A4', 2021, 'Серебристый', 1, 2, 1, 190, 'used', 'WAUZZZ8KZNA123456');

-- Создаем объявление
INSERT INTO service.ads (seller_id, vehicle_id, header_text, description, price, status_id)
VALUES
(1, (SELECT MAX(vehicle_id) FROM service.vehicles), 'Audi A4 2021', 'Отличное состояние, один владелец', 3200000, 2);

-- Добавляем фотографии (первая - основная)
INSERT INTO service.ad_photos (ad_id, url, is_primary)
VALUES
((SELECT MAX(ad_id) FROM service.ads), 'https://example.com/photos/audi1.jpg', TRUE),
((SELECT MAX(ad_id) FROM service.ads), 'https://example.com/photos/audi2.jpg', FALSE),
((SELECT MAX(ad_id) FROM service.ads), 'https://example.com/photos/audi3.jpg', FALSE);

COMMIT;
```

После транзакции:
```sql
-- Новое транспортное средство
SELECT vehicle_id, brand, model, year_of_manufacture, color, vin
FROM service.vehicles WHERE brand = 'Audi' AND model = 'A4' AND vin = 'WAUZZZ8KZNA123456';

-- Новое объявление
SELECT a.ad_id, a.header_text, a.description, a.price, 
       (SELECT name FROM service.ad_statuses WHERE id = a.status_id) as status_name
FROM service.ads a WHERE a.header_text = 'Audi A4 2021';

-- Все фотографии объявления
SELECT photo_id, ad_id, url, is_primary
FROM service.ad_photos 
WHERE ad_id = (SELECT ad_id FROM service.ads WHERE header_text = 'Audi A4 2021')
ORDER BY photo_id;
```
<br>
<img width="900" height="77" alt="image" src="https://github.com/user-attachments/assets/79fd7036-3cfb-4eef-bee3-5f84d0fead3e" />
<img width="765" height="91" alt="image" src="https://github.com/user-attachments/assets/779c9baf-58b8-4775-816a-12447ed079be" />
<img width="540" height="136" alt="image" src="https://github.com/user-attachments/assets/ced7f8a0-4714-4b55-815e-2ca0fa533269" />

**Результат:** Объявление с транспортным средством и тремя фотографиями успешно опубликовано. Все данные добавлены атомарно.

---

### 1.2. Транзакция с ROLLBACK

**Задача:** Выполнить тот же запрос, но добавить ROLLBACK вместо COMMIT — проверить, что изменений нет.

#### Пример 1: Отмена продажи автомобиля

До транзакции:
```sql
-- Статус объявления до транзакции
SELECT ad_id, status_id, 
       (SELECT name FROM service.ad_statuses WHERE id = service.ads.status_id) as status_name
FROM service.ads WHERE ad_id = 2;

-- Контракты для этого объявления
SELECT * FROM service.contracts WHERE ad_id = 2 AND buyer_user_id = 5;
```
<br>
<img width="396" height="70" alt="image" src="https://github.com/user-attachments/assets/954a08c0-fedd-4e38-b8d0-b00c96884d4a" />
<img width="908" height="97" alt="image" src="https://github.com/user-attachments/assets/ff1cb8ee-4871-4c44-a6c5-0d1c6ee855d2" />

```sql
-- Транзакция с ROLLBACK: покупатель передумал - отменяем сделку
BEGIN;

-- Создаем контракт
INSERT INTO service.contracts (ad_id, seller_id, buyer_user_id, amount, currency, status)
VALUES
(2, 2, 5, 1100000, 'RUB', 'closed');

-- Обновляем статус объявления на "продано"
UPDATE service.ads 
SET status_id = (SELECT id FROM service.ad_statuses WHERE code = 'sold')
WHERE ad_id = 2;

-- Проверяем изменения (в рамках транзакции)
SELECT c.contract_id, c.status, a.status_id, 
       (SELECT name FROM service.ad_statuses WHERE id = a.status_id) as status_name
FROM service.contracts c
JOIN service.ads a ON c.ad_id = a.ad_id
WHERE c.contract_id = (SELECT MAX(contract_id) FROM service.contracts);

-- Покупатель передумал - ОТКАТЫВАЕМ все изменения
ROLLBACK;
```
<br>
<img width="533" height="89" alt="image" src="https://github.com/user-attachments/assets/4ab3068b-277b-4f86-a36d-2fe6d13a20c8" />


После ROLLBACK:
```sql
-- Проверяем, что контракт не создан и статус объявления не изменился
SELECT * FROM service.contracts WHERE ad_id = 2 AND buyer_user_id = 5;
SELECT ad_id, status_id, 
       (SELECT name FROM service.ad_statuses WHERE id = service.ads.status_id) as status_name
FROM service.ads WHERE ad_id = 2;
```
<br>
<img width="919" height="104" alt="image" src="https://github.com/user-attachments/assets/c3c95482-e4bd-40b6-a460-3097434196c8" />
<img width="410" height="89" alt="image" src="https://github.com/user-attachments/assets/57edb9f6-4d0c-42ce-8ef2-a535f290e6d4" />

**Результат:** После ROLLBACK контракт не был создан, статус объявления остался прежним. Сделка отменена.

#### Пример 2: Отмена изменения цены объявления

До транзакции:
```sql
-- Сохраняем текущую цену для проверки
SELECT ad_id, price, header_text FROM service.ads WHERE ad_id = 1;
```
<br>
<img width="476" height="76" alt="image" src="https://github.com/user-attachments/assets/835d026c-5f52-444d-b92e-a1839ebaebb1" />


```sql
-- Транзакция с ROLLBACK: продавец решил изменить цену, но передумал
BEGIN;

-- Продавец снижает цену для быстрой продажи
UPDATE service.ads 
SET price = price - 200000
WHERE ad_id = 1;

-- Проверяем новую цену (в рамках транзакции)
SELECT ad_id, price, header_text FROM service.ads WHERE ad_id = 1;

-- Продавец передумал - ОТКАТЫВАЕМ изменение цены
ROLLBACK;
```
<br>
<img width="486" height="74" alt="image" src="https://github.com/user-attachments/assets/9c201cb2-cf14-4484-9a01-f60ec34c9560" />


После ROLLBACK:
```sql
-- Проверяем, что цена вернулась к исходному значению
SELECT ad_id, price, header_text FROM service.ads WHERE ad_id = 1;
```
<br>
<img width="491" height="85" alt="image" src="https://github.com/user-attachments/assets/72068951-3096-45db-8444-01be258090ea" />

**Результат:** После ROLLBACK цена вернулась к исходному значению. Изменение не было сохранено.

---

### 1.3. Транзакция с ошибкой (автоматический откат)

**Задача:** Добавить в транзакцию ошибку (например, деление на 0) — пронаблюдать, как PostgreSQL откатывает все изменения.

#### Пример 1: Ошибка при попытке продать уже проданный автомобиль

До транзакции:
```sql
-- Статус объявления и контракты
SELECT a.ad_id, a.status_id, 
       (SELECT name FROM service.ad_statuses WHERE id = a.status_id) as status_name
FROM service.ads a WHERE a.ad_id = 5;

SELECT COUNT(*) as contracts_count FROM service.contracts WHERE ad_id = 5;
```
<br>
<img width="389" height="78" alt="image" src="https://github.com/user-attachments/assets/b28a48f7-1367-4ac3-85d3-8d95c45364da" />
<img width="182" height="80" alt="image" src="https://github.com/user-attachments/assets/b902cab4-5ce5-4a00-b3cd-e3a26d95b4fb" />



```sql
-- Транзакция с ошибкой: попытка создать контракт на уже проданный автомобиль
BEGIN;

-- Пытаемся создать контракт на объявление, которое уже продано
INSERT INTO service.contracts (ad_id, seller_id, buyer_user_id, amount, currency, status)
VALUES
(5, 1, 4, 5200000, 'RUB', 'closed');

-- Обновляем статус объявления (но оно уже продано - статус = 'sold')
UPDATE service.ads 
SET status_id = (SELECT id FROM service.ad_statuses WHERE code = 'sold')
WHERE ad_id = 5;

-- Если бы была проверка на уровне приложения, мы бы откатили транзакцию
-- Но для демонстрации используем деление на ноль как пример ошибки
SELECT 100 / 0;

-- Из-за ошибки транзакция откатится автоматически
```
<br>
<img width="238" height="106" alt="image" src="https://github.com/user-attachments/assets/ad2b06b9-7e82-4673-a22e-33441c7f7e7d" />


После ошибки (транзакция автоматически откатилась):
```sql
-- Статус объявления не изменился
SELECT a.ad_id, a.status_id, 
       (SELECT name FROM service.ad_statuses WHERE id = a.status_id) as status_name
FROM service.ads a WHERE a.ad_id = 5;

-- Контракт не был создан
SELECT COUNT(*) as contracts_count FROM service.contracts WHERE ad_id = 5 AND buyer_user_id = 4;
```
<br>
<img width="389" height="86" alt="image" src="https://github.com/user-attachments/assets/9111e23b-0320-43a3-9e90-70508988281a" />
<img width="183" height="76" alt="image" src="https://github.com/user-attachments/assets/ec63b468-6d1b-4967-8a6f-79a264eb252a" />

**Результат:** PostgreSQL автоматически откатил транзакцию из-за ошибки. Контракт не был создан, изменения не применены.

#### Пример 2: Ошибка при добавлении автомобиля с дублирующимся VIN

До транзакции:
```sql
-- Проверяем существующий VIN
SELECT vehicle_id, brand, model, vin FROM service.vehicles WHERE vin = 'JTNB11HK603456789';

-- Количество объявлений продавца с ID = 2
SELECT COUNT(*) as seller_ads_count FROM service.ads WHERE seller_id = 2;
```
<br>
<img width="612" height="73" alt="image" src="https://github.com/user-attachments/assets/fd9201d0-24c5-4d3f-b883-7aff6fc3dace" />
<img width="189" height="85" alt="image" src="https://github.com/user-attachments/assets/c3729125-eb62-46fd-9e4c-ac2fba575d3d" />



```sql
-- Транзакция с ошибкой: попытка добавить автомобиль с уже существующим VIN
BEGIN;

-- Пытаемся добавить транспортное средство с уже существующим VIN
INSERT INTO service.vehicles 
(brand, model, year_of_manufacture, color, body_type_id, transmission_id, fuel_type_id, power_hp, state_code, vin)
VALUES
('Honda', 'Civic', 2019, 'Синий', 2, 1, 1, 140, 'used', 'JTNB11HK603456789');

-- Если бы не было ошибки, мы бы создали объявление
INSERT INTO service.ads (seller_id, vehicle_id, header_text, description, price, status_id)
VALUES
(2, (SELECT MAX(vehicle_id) FROM service.vehicles), 'Honda Civic 2019', 'Новое объявление', 1500000, 1);

-- Из-за ошибки уникальности VIN транзакция откатится автоматически
```
<br>
<img width="724" height="145" alt="image" src="https://github.com/user-attachments/assets/24cfb1d7-a364-4b09-9825-3fe77f6fa052" />


После ошибки (транзакция автоматически откатилась):
```sql
-- VIN остался единственным (дубликат не добавился)
SELECT vehicle_id, brand, model, vin FROM service.vehicles WHERE vin = 'JTNB11HK603456789';

-- Объявление не было создано
SELECT COUNT(*) as seller_ads_count FROM service.ads WHERE seller_id = 2 AND header_text = 'Honda Civic 2019';
```
<br>
<img width="612" height="73" alt="image" src="https://github.com/user-attachments/assets/fd9201d0-24c5-4d3f-b883-7aff6fc3dace" />
<img width="189" height="85" alt="image" src="https://github.com/user-attachments/assets/c3729125-eb62-46fd-9e4c-ac2fba575d3d" />

**Результат:** PostgreSQL автоматически откатил транзакцию из-за нарушения ограничения UNIQUE на поле VIN. Ни транспортное средство, ни объявление не были добавлены.

---

## 2. Уровни изоляции транзакций

### 2.1. READ UNCOMMITTED / READ COMMITTED

#### Задание 1: Продавец меняет цену, покупатель смотрит объявление

**Транзакция 1 (T1 - продавец):**
```sql
-- T1: Продавец снижает цену, но еще не подтвердил изменение
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

UPDATE service.ads 
SET price = price - 300000
WHERE ad_id = 1;

-- Продавец еще думает, не делает COMMIT
-- (в другом окне/сессии покупатель смотрит объявление)
```

**Транзакция 2 (T2 - покупатель):**
```sql
-- T2: Покупатель просматривает объявление
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Покупатель видит старую цену (незакоммиченные изменения не видны)
SELECT ad_id, header_text, price, 
       (SELECT name FROM service.ad_statuses WHERE id = service.ads.status_id) as status_name
FROM service.ads WHERE ad_id = 1;

-- В PostgreSQL покупатель НЕ увидит новую цену, пока продавец не закоммитит
```

**Результат:** Покупатель видит старую цену, так как изменения продавца еще не закоммичены. Это предотвращает "грязное чтение" - покупатель не увидит незавершенные изменения.

До запуска транзакции T1: 
<br>
<img width="631" height="86" alt="Снимок экрана 2025-11-19 003948" src="https://github.com/user-attachments/assets/8b684a55-fa01-4801-95ae-fab092efe261" />

После запуска транзакции T1 и T2:
<br>
<img width="631" height="86" alt="Снимок экрана 2025-11-19 003948" src="https://github.com/user-attachments/assets/8b684a55-fa01-4801-95ae-fab092efe261" />


#### Задание 2: Модератор проверяет объявление, пока продавец его редактирует

**Транзакция 1 (T1 - продавец):**
```sql
-- T1: Продавец редактирует описание объявления
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

UPDATE service.ads 
SET description = 'Обновленное описание: машина в идеальном состоянии, все документы в порядке'
WHERE ad_id = 2;

-- Продавец еще редактирует, не делает COMMIT
```

**Транзакция 2 (T2 - модератор):**
```sql
-- T2: Модератор проверяет объявление на модерации
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Модератор видит старое описание
SELECT ad_id, header_text, description, status_id,
       (SELECT name FROM service.ad_statuses WHERE id = service.ads.status_id) as status_name
FROM service.ads WHERE ad_id = 2;

-- Модератор пытается изменить статус (будет ждать, пока продавец не завершит редактирование)
UPDATE service.ads 
SET status_id = (SELECT id FROM service.ad_statuses WHERE code = 'active')
WHERE ad_id = 2;

-- T2 будет ждать завершения T1
```

**Результат:** Модератор видит старое описание. При попытке обновить ту же строку модератор блокируется и ждет завершения транзакции продавца.

До запуска транзакции T1: 
<br>
<img width="830" height="77" alt="image" src="https://github.com/user-attachments/assets/69cbfe3c-c722-4161-86db-dab496353695" />
После запуска транзакции T1 и T2:
<br>
<img width="830" height="77" alt="image" src="https://github.com/user-attachments/assets/69cbfe3c-c722-4161-86db-dab496353695" />
<img width="1286" height="393" alt="image" src="https://github.com/user-attachments/assets/a45f3b0c-0ecd-43c5-aa75-295ae69765b4" />

---

### 2.2. READ COMMITTED: Неповторяющееся чтение (Non-repeatable Read)

#### Задание 3: Покупатель дважды проверяет цену, пока продавец ее меняет

**Транзакция 1 (T1 - покупатель):**
```sql
-- T1: Покупатель проверяет цену перед покупкой
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Первое чтение цены
SELECT ad_id, header_text, price, 
       (SELECT name FROM service.ad_statuses WHERE id = service.ads.status_id) as status_name
FROM service.ads WHERE ad_id = 3;

-- Покупатель думает, ждет
-- (в это время продавец меняет цену в T2)

-- Второе чтение (после того как продавец закоммитил изменение цены)
SELECT ad_id, header_text, price, 
       (SELECT name FROM service.ad_statuses WHERE id = service.ads.status_id) as status_name
FROM service.ads WHERE ad_id = 3;

-- Видим РАЗНУЮ цену (неповторяющееся чтение)
COMMIT;
```

**Транзакция 2 (T2 - продавец):**
```sql
-- T2: Продавец снижает цену для быстрой продажи
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

UPDATE service.ads 
SET price = price - 200000
WHERE ad_id = 3;

COMMIT; -- Продавец подтверждает изменение цены
```

**Результат:** Покупатель видит разную цену при первом и втором чтении. Это демонстрирует неповторяющееся чтение - данные могут измениться между чтениями в одной транзакции.

Первое чтение T1 <br>
<img width="541" height="77" alt="image" src="https://github.com/user-attachments/assets/9afc3094-d188-4d6d-949f-7c4a66ce6be5" />

Второе чтение T1 <br>
<img width="543" height="84" alt="image" src="https://github.com/user-attachments/assets/0e7f6b70-4b8a-481f-aabe-644c44f56ece" />

#### Задание 4: Аналитик считает средний рейтинг продавца, пока добавляются новые отзывы

**Транзакция 1 (T1 - аналитик):**
```sql
-- T1: Аналитик готовит отчет о рейтинге продавца
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Первое чтение среднего рейтинга продавца
SELECT s.seller_id, 
       u.full_name,
       AVG(f.rating) as avg_rating,
       COUNT(f.feedback_id) as reviews_count
FROM service.sellers s
JOIN service.users u ON s.user_id = u.user_id
LEFT JOIN service.feedbacks f ON f.seller_id = s.seller_id
WHERE s.seller_id = 1
GROUP BY s.seller_id, u.full_name;

-- Аналитик продолжает работу
-- (в это время покупатель добавляет новый отзыв в T2)

-- Второе чтение (после добавления нового отзыва)
SELECT s.seller_id, 
       u.full_name,
       AVG(f.rating) as avg_rating,
       COUNT(f.feedback_id) as reviews_count
FROM service.sellers s
JOIN service.users u ON s.user_id = u.user_id
LEFT JOIN service.feedbacks f ON f.seller_id = s.seller_id
WHERE s.seller_id = 1
GROUP BY s.seller_id, u.full_name;

COMMIT;
```

**Транзакция 2 (T2 - покупатель):**
```sql
-- T2: Покупатель оставляет отзыв после покупки
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

INSERT INTO service.feedbacks (user_id, seller_id, ad_id, text, rating)
VALUES
(2, 1, 1, 'Отличный продавец, рекомендую!', 5.0);

COMMIT;
```

**Результат:** Аналитик видит разные значения среднего рейтинга и количества отзывов при первом и втором чтении из-за нового отзыва.

Первое чтение T1 <br>
<img width="547" height="78" alt="image" src="https://github.com/user-attachments/assets/2e4e9836-f479-425c-b973-4a6c3717ae5d" />

Второе чтение T1 <br>
<img width="542" height="84" alt="image" src="https://github.com/user-attachments/assets/e1feb5a3-f68d-49c7-9f6c-85538512a235" />


---

### 2.3. REPEATABLE READ

#### Задание 5: Финансовый отчет - цена не меняется в рамках транзакции

**Транзакция 1 (T1 - бухгалтер):**
```sql
-- T1: Бухгалтер готовит финансовый отчет, нужна согласованность данных
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Первое чтение цены объявления для отчета
SELECT ad_id, header_text, price, 
       (SELECT name FROM service.ad_statuses WHERE id = service.ads.status_id) as status_name
FROM service.ads WHERE ad_id = 4;

-- Бухгалтер продолжает формировать отчет
-- (в это время продавец меняет цену в T2)

-- Второе чтение (должно показать ТО ЖЕ значение, что и первое)
SELECT ad_id, header_text, price, 
       (SELECT name FROM service.ad_statuses WHERE id = service.ads.status_id) as status_name
FROM service.ads WHERE ad_id = 4;

-- Значения одинаковые - отчет согласован (повторяющееся чтение)
COMMIT;
```

**Транзакция 2 (T2 - продавец):**
```sql
-- T2: Продавец обновляет цену и статус
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

UPDATE service.ads 
SET price = price - 300000,
    status_id = (SELECT id FROM service.ad_statuses WHERE code = 'sold')
WHERE ad_id = 4;

COMMIT; -- Продавец подтверждает изменения
```

**Результат:** Бухгалтер видит одинаковые значения при обоих чтениях, несмотря на то, что продавец изменил данные. Это гарантирует согласованность отчета - данные не меняются в рамках транзакции.

Первое чтение T1 <br>
<img width="544" height="74" alt="image" src="https://github.com/user-attachments/assets/1a48102c-f462-45e7-97b0-f4472c7ecd06" />
Второе чтение T1 <br>
<img width="544" height="74" alt="image" src="https://github.com/user-attachments/assets/1a48102c-f462-45e7-97b0-f4472c7ecd06" />

#### Задание 6: Подсчет активных объявлений продавца

**Транзакция 1 (T1 - менеджер):**
```sql
-- T1: Менеджер считает активные объявления продавца для статистики
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Первое чтение: считаем количество активных объявлений продавца
SELECT seller_id, COUNT(*) as active_ads_count
FROM service.ads 
WHERE seller_id = 1 
  AND status_id = (SELECT id FROM service.ad_statuses WHERE code = 'active')
GROUP BY seller_id;

-- Менеджер продолжает работу
-- (в это время продавец публикует новое объявление в T2)

-- Второе чтение: снова считаем (должно быть то же количество)
SELECT seller_id, COUNT(*) as active_ads_count
FROM service.ads 
WHERE seller_id = 1 
  AND status_id = (SELECT id FROM service.ad_statuses WHERE code = 'active')
GROUP BY seller_id;

-- В REPEATABLE READ количество должно быть одинаковым
COMMIT;
```

**Транзакция 2 (T2 - продавец):**
```sql
-- T2: Продавец публикует новое объявление
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Добавляем новое транспортное средство
INSERT INTO service.vehicles 
(brand, model, year_of_manufacture, color, body_type_id, transmission_id, fuel_type_id, power_hp, state_code, vin)
VALUES
('Lexus', 'RX', 2021, 'Белый', 3, 2, 4, 295, 'used', 'JTJBC1BAXM2123456');

-- Добавляем новое активное объявление
INSERT INTO service.ads (seller_id, vehicle_id, header_text, description, price, status_id)
VALUES
(1, (SELECT MAX(vehicle_id) FROM service.vehicles), 'Lexus RX 2021', 'Премиум внедорожник', 4500000, 1);

COMMIT;
```

**Результат:** Менеджер видит одинаковое количество объявлений при обоих чтениях, несмотря на то, что продавец добавил новое. В PostgreSQL на уровне REPEATABLE READ фантомное чтение предотвращается.

Первое чтение T1 <br>
<img width="260" height="73" alt="image" src="https://github.com/user-attachments/assets/30ea91db-aaf2-472d-a855-1f8a1ab7e3fc" />

Второе чтение T1 <br>
<img width="260" height="73" alt="image" src="https://github.com/user-attachments/assets/30ea91db-aaf2-472d-a855-1f8a1ab7e3fc" />

---

### 2.4. SERIALIZABLE

#### Задание 7: Два покупателя пытаются купить последний автомобиль одновременно

**Транзакция 1 (T1 - покупатель 1):**
```sql
-- T1: Первый покупатель оформляет покупку
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Проверяем, что объявление еще активно
SELECT ad_id, status_id, 
       (SELECT name FROM service.ad_statuses WHERE id = service.ads.status_id) as status_name
FROM service.ads 
WHERE ad_id = 2;

-- Создаем контракт
INSERT INTO service.contracts (ad_id, seller_id, buyer_user_id, amount, currency, status)
VALUES
(2, 2, 5, 1100000, 'RUB', 'closed');

-- Обновляем статус на "продано"
UPDATE service.ads 
SET status_id = (SELECT id FROM service.ad_statuses WHERE code = 'sold')
WHERE ad_id = 2;

-- Ждем выполнения T2
-- Если T2 тоже попытается купить, получим ошибку сериализации
COMMIT;
```

**Транзакция 2 (T2 - покупатель 2):**
```sql
-- T2: Второй покупатель одновременно пытается купить тот же автомобиль
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Проверяем, что объявление еще активно (может быть уже куплено T1)
SELECT ad_id, status_id, 
       (SELECT name FROM service.ad_statuses WHERE id = service.ads.status_id) as status_name
FROM service.ads 
WHERE ad_id = 2;

-- Пытаемся создать контракт (конфликт с T1)
INSERT INTO service.contracts (ad_id, seller_id, buyer_user_id, amount, currency, status)
VALUES
(2, 2, 4, 1100000, 'RUB', 'closed');

-- Обновляем статус
UPDATE service.ads 
SET status_id = (SELECT id FROM service.ad_statuses WHERE code = 'sold')
WHERE ad_id = 2;

COMMIT;
```

**Результат:** Одна из транзакций получит ошибку "не удалось сериализовать доступ из-за параллельного изменения ". Это предотвращает двойную продажу одного автомобиля - только один покупатель сможет завершить покупку.

T1  <br>
<img width="312" height="84" alt="image" src="https://github.com/user-attachments/assets/23286a27-ba94-414d-8155-6faa08f88d48" />

T2  <br>
<img width="653" height="126" alt="image" src="https://github.com/user-attachments/assets/0aa7281b-2354-4229-96ef-7b8cba30768f" />



#### Задание 8: Два продавца одновременно меняют цену - обработка конфликта

**Транзакция 1 (T1 - продавец):**
```sql
-- T1: Продавец повышает цену
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Читаем текущую цену
SELECT ad_id, price FROM service.ads WHERE ad_id = 5;

-- Повышаем цену
UPDATE service.ads 
SET price = price + 50000
WHERE ad_id = 5;

-- Ждем выполнения T2
-- Если получим ошибку, нужно будет повторить транзакцию
COMMIT;
```

**Транзакция 2 (T2 - другой продавец или администратор):**
```sql
-- T2: Параллельно изменяем цену того же объявления
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Читаем текущую цену
SELECT ad_id, price FROM service.ads WHERE ad_id = 5;

-- Снижаем цену (конфликт с T1)
UPDATE service.ads 
SET price = price - 30000
WHERE ad_id = 5;

COMMIT;
```

**Повтор транзакции после ошибки:**
```sql
-- Если T1 получила ошибку "could not serialize access due to concurrent update",
-- нужно повторить транзакцию с учетом новых данных:

BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Повторяем операцию (теперь с учетом изменений T2)
SELECT ad_id, price FROM service.ads WHERE ad_id = 5;

UPDATE service.ads 
SET price = price + 50000
WHERE ad_id = 5;

COMMIT;
```

**Результат:** Одна из транзакций получит ошибку сериализации. После обработки ошибки транзакцию нужно повторить, чтобы учесть изменения, сделанные другой транзакцией.

T1 <br>
<img width="222" height="83" alt="image" src="https://github.com/user-attachments/assets/be4699ae-4899-479f-a804-02148b87a0ca" />

Попытка T2 <br>
<img width="541" height="109" alt="image" src="https://github.com/user-attachments/assets/cf2155f8-3500-44ac-972a-8314a9be8f02" />

Вторая попытка T2 <br>
<img width="221" height="78" alt="image" src="https://github.com/user-attachments/assets/7abccdc1-32b3-44f8-b596-53944d5ce451" />


---

## 3. SAVEPOINT

### 3.1. Транзакция с точкой сохранения

**Задача:** Создать транзакцию с несколькими изменениями и точкой сохранения. Убедиться, что изменения до SAVEPOINT остались.

До транзакции:
```sql
-- Количество транспортных средств Hyundai Solaris
SELECT COUNT(*) as hyundai_count FROM service.vehicles WHERE brand = 'Hyundai' AND model = 'Solaris';

-- Количество объявлений с заголовком Hyundai
SELECT COUNT(*) as hyundai_ads_count FROM service.ads WHERE header_text LIKE 'Hyundai%';
```
<br>
<img width="190" height="90" alt="image" src="https://github.com/user-attachments/assets/db7f3361-8e0b-452e-8b8e-dc912c73980e" />

<br>
<img width="202" height="79" alt="image" src="https://github.com/user-attachments/assets/3bec7cb6-bfae-4081-b895-df11014f6f9b" />

```sql
-- Транзакция: продавец публикует объявление, но передумал добавлять фото
BEGIN;

-- Шаг 1: Добавляем транспортное средство
INSERT INTO service.vehicles 
(brand, model, year_of_manufacture, color, body_type_id, transmission_id, fuel_type_id, power_hp, state_code, vin)
VALUES
('Hyundai', 'Solaris', 2020, 'Серый', 2, 1, 1, 123, 'used', 'Z94CB41BBLR123456');

-- Проверяем, что транспортное средство добавлено
SELECT vehicle_id, brand, model FROM service.vehicles WHERE brand = 'Hyundai' AND model = 'Solaris';

-- Создаем точку сохранения перед добавлением объявления
SAVEPOINT before_ad;

-- Шаг 2: Создаем объявление
INSERT INTO service.ads (seller_id, vehicle_id, header_text, description, price, status_id)
VALUES
(3, (SELECT MAX(vehicle_id) FROM service.vehicles), 'Hyundai Solaris 2020', 'Надежный седан', 1200000, 1);

-- Шаг 3: Добавляем фотографии
INSERT INTO service.ad_photos (ad_id, url, is_primary)
VALUES
((SELECT MAX(ad_id) FROM service.ads), 'https://example.com/photos/hyundai1.jpg', TRUE),
((SELECT MAX(ad_id) FROM service.ads), 'https://example.com/photos/hyundai2.jpg', FALSE);

-- Проверяем все изменения
SELECT 'Vehicles' as table_name, COUNT(*) as count FROM service.vehicles WHERE brand = 'Hyundai'
UNION ALL
SELECT 'Ads', COUNT(*) FROM service.ads WHERE header_text LIKE 'Hyundai%'
UNION ALL
SELECT 'Photos', COUNT(*) FROM service.ad_photos WHERE ad_id = (SELECT MAX(ad_id) FROM service.ads);

-- Продавец передумал публиковать объявление, но хочет оставить транспортное средство
-- Откатываемся к точке сохранения (откатятся объявление и фото, транспортное средство останется)
ROLLBACK TO SAVEPOINT before_ad;

-- Проверяем, что транспортное средство осталось
SELECT vehicle_id, brand, model FROM service.vehicles WHERE brand = 'Hyundai' AND model = 'Solaris';

-- Проверяем, что объявление и фото откатились
SELECT * FROM service.ads WHERE header_text LIKE 'Hyundai%';
SELECT * FROM service.ad_photos WHERE ad_id IN (SELECT ad_id FROM service.ads WHERE header_text LIKE 'Hyundai%');

-- Завершаем транзакцию (сохраняем только транспортное средство)
COMMIT;
```
До SAVEPOINT before_ad;
<br>
<img width="457" height="82" alt="image" src="https://github.com/user-attachments/assets/8dcdb27d-39fd-4623-a028-897acfb19cf1" />

Между SAVEPOINT before_ad и ROLLBACK TO SAVEPOINT before_ad
<br>
<img width="221" height="142" alt="image" src="https://github.com/user-attachments/assets/62dba599-7860-485c-86e7-a6812f0a53b0" />

После ROLLBACK TO SAVEPOINT before_ad;
<br>
<img width="451" height="69" alt="image" src="https://github.com/user-attachments/assets/e1a1b24d-57cb-4df2-bad1-ce2398efa9a4" />
<br>
<img width="902" height="129" alt="image" src="https://github.com/user-attachments/assets/c2bcbc7b-f1d8-4b5d-86be-aae5a61afdba" />
<br>
<img width="351" height="102" alt="image" src="https://github.com/user-attachments/assets/b885cfc2-4b56-4613-8ced-6f73a8096b01" />

**Результат:** После ROLLBACK TO SAVEPOINT транспортное средство осталось в базе, а объявление и фотографии откатились. После COMMIT в базе осталось только транспортное средство.

---

### 3.2. Два SAVEPOINT с откатом

**Задача:** Добавить два SAVEPOINT, попробовать вернуться на первый и второй.

До транзакции:
```sql
-- Проверяем, нет ли уже пользователя с таким email
SELECT COUNT(*) as user_exists FROM service.users WHERE email = 'volkov@example.com';
```
<br>
<img width="157" height="82" alt="image" src="https://github.com/user-attachments/assets/1f94b41b-1221-43ac-a69b-724ae66d023b" />


```sql
-- Транзакция: регистрация нового продавца с возможностью отката на разных этапах
BEGIN;

-- Шаг 1: Регистрируем нового пользователя
INSERT INTO service.users (full_name, email, phone_number)
VALUES
('Дмитрий Волков', 'volkov@example.com', '+79994445566');

-- Проверяем
SELECT user_id, full_name, email FROM service.users WHERE email = 'volkov@example.com';

-- Первая точка сохранения - после регистрации пользователя
SAVEPOINT after_user_registration;

-- Шаг 2: Создаем профиль продавца
INSERT INTO service.sellers (user_id, seller_type)
VALUES
((SELECT MAX(user_id) FROM service.users), 'individual');

-- Проверяем
SELECT s.seller_id, u.full_name, s.seller_type 
FROM service.sellers s
JOIN service.users u ON s.user_id = u.user_id
WHERE u.email = 'volkov@example.com';

-- Вторая точка сохранения - после создания профиля продавца
SAVEPOINT after_seller_profile;

-- Шаг 3: Добавляем первое транспортное средство
INSERT INTO service.vehicles 
(brand, model, year_of_manufacture, color, body_type_id, transmission_id, fuel_type_id, power_hp, state_code, vin)
VALUES
('Mazda', 'CX-5', 2021, 'Красный', 3, 2, 1, 194, 'used', 'JM3KFBDM0M0123456');

-- Проверяем
SELECT vehicle_id, brand, model FROM service.vehicles WHERE brand = 'Mazda' AND model = 'CX-5';

-- Пользователь передумал добавлять транспортное средство, но хочет оставить профиль продавца
-- Откатываемся ко второй точке сохранения (sp2)
ROLLBACK TO SAVEPOINT after_seller_profile;

-- Проверяем состояние:
-- - Пользователь должен быть (до sp1)
-- - Продавец должен быть (до sp2)
-- - Транспортное средство НЕ должно быть (после sp2, откатилось)
SELECT 'Users' as table_name, COUNT(*) as count FROM service.users WHERE email = 'volkov@example.com'
UNION ALL
SELECT 'Sellers', COUNT(*) FROM service.sellers WHERE user_id = (SELECT MAX(user_id) FROM service.users WHERE email = 'volkov@example.com')
UNION ALL
SELECT 'Vehicles', COUNT(*) FROM service.vehicles WHERE brand = 'Mazda';

-- Шаг 4: Пользователь решил создать объявление для существующего транспортного средства (после отката)
INSERT INTO service.ads (seller_id, vehicle_id, header_text, description, price, status_id)
VALUES
((SELECT MAX(seller_id) FROM service.sellers), 1, 'Продаю через новую площадку', 'Первое объявление', 1000000, 1);

-- Пользователь передумал быть продавцом, но хочет остаться пользователем
-- Откатываемся к первой точке сохранения (sp1)
ROLLBACK TO SAVEPOINT after_user_registration;

-- Проверяем состояние:
-- - Пользователь должен быть (до sp1)
-- - Продавец НЕ должен быть (после sp1, откатился)
-- - Объявление НЕ должно быть (после sp1, откатилось)
SELECT 'Users' as table_name, COUNT(*) as count FROM service.users WHERE email = 'volkov@example.com'
UNION ALL
SELECT 'Sellers', COUNT(*) FROM service.sellers WHERE user_id = (SELECT MAX(user_id) FROM service.users WHERE email = 'volkov@example.com')
UNION ALL
SELECT 'Ads', COUNT(*) FROM service.ads WHERE header_text = 'Продаю через новую площадку';

-- Завершаем транзакцию (сохраняем только пользователя)
COMMIT;
```
<br>
<img width="462" height="78" alt="image" src="https://github.com/user-attachments/assets/bb020a80-8f71-4c84-8ea3-2d7fa979a83a" />
<br>
<img width="446" height="89" alt="image" src="https://github.com/user-attachments/assets/f4bca7f5-9259-45ae-abc5-26711ebd61fc" />
<br>
<img width="464" height="94" alt="image" src="https://github.com/user-attachments/assets/bb625d58-7996-45fb-95e6-985e894e50aa" />

<br>
<img width="220" height="133" alt="image" src="https://github.com/user-attachments/assets/7acbaa4a-81a3-4a3f-885c-2b5952463ab1" />
<br>
<img width="220" height="136" alt="image" src="https://github.com/user-attachments/assets/53c74232-d607-45a4-9857-ae50ce127231" />


После COMMIT:
```sql
-- Пользователь сохранен
SELECT user_id, full_name, email FROM service.users WHERE email = 'volkov@example.com';

-- Продавец не сохранен (откатился)
SELECT COUNT(*) as sellers_count FROM service.sellers WHERE user_id = (SELECT user_id FROM service.users WHERE email = 'volkov@example.com');

-- Транспортное средство не сохранено (откатилось)
SELECT COUNT(*) as vehicles_count FROM service.vehicles WHERE brand = 'Mazda' AND model = 'CX-5' AND vin = 'JM3KFBDM0M0123456';

-- Объявление не сохранено (откатилось)
SELECT COUNT(*) as ads_count FROM service.ads WHERE header_text = 'Продаю через новую площадку';
```
<br>
<img width="482" height="82" alt="image" src="https://github.com/user-attachments/assets/d007a879-a354-4934-86cb-488a05b87d57" />
<br>
<img width="175" height="80" alt="image" src="https://github.com/user-attachments/assets/cb8b1cfb-f6dd-48c9-a8be-69e9e7a50520" />

<br>
<img width="201" height="81" alt="image" src="https://github.com/user-attachments/assets/c8d413f2-ef9c-4c0f-b0e6-d86212336c94" />

<br>
<img width="157" height="93" alt="image" src="https://github.com/user-attachments/assets/5b69df6f-1879-4c38-9b65-7641dce0313f" />

**Результат:** 
- После ROLLBACK TO SAVEPOINT after_seller_profile: пользователь и продавец остались, транспортное средство откатилось
- После ROLLBACK TO SAVEPOINT after_user_registration: только пользователь остался, продавец и все последующие изменения откатились
- После COMMIT: в базе остался только пользователь, который может позже создать профиль продавца
