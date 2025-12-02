# Триггеры и Кроны

## 1. Триггеры (12 штук по 2 на каждый тип)

### 1.1. BEFORE Row-level триггеры (2 шт)

#### Триггер 1: Валидация email перед вставкой пользователя
```sql
CREATE OR REPLACE FUNCTION service.validate_user_email()
RETURNS TRIGGER AS $$
BEGIN
    -- Использование NEW для проверки email перед вставкой
    IF NEW.email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RAISE EXCEPTION 'Некорректный формат email: %', NEW.email;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_email_before_insert
    BEFORE INSERT ON service.users
    FOR EACH ROW
    EXECUTE FUNCTION service.validate_user_email();
```

**Пример использования:**

Успешная вставка с корректным email
```sql
INSERT INTO service.users (full_name, email, phone_number)
VALUES ('Иванов Иван Иванович', 'ivanov123@example.com', '+79991234567');
```

Попытка вставки с некорректным email (вызовет ошибку)
```sql
INSERT INTO service.users (full_name, email, phone_number)
VALUES ('Петров Петр Петрович', 'неправильный-email', '+79991234568');
-- Ошибка: Некорректный формат email: неправильный-email
```
<img width="630" height="105" alt="Снимок экрана 2025-12-02 163829" src="https://github.com/user-attachments/assets/840b7aeb-5ace-4b7f-bd51-003f56e0f271" />


Проверка результата
```sql
SELECT user_id, full_name, email FROM service.users WHERE email LIKE '%@%';
```

<img width="464" height="223" alt="Снимок экрана 2025-12-02 163743" src="https://github.com/user-attachments/assets/15e1620c-b1cc-4c29-8db8-cf1857414c69" />


#### Триггер 2: Нормализация заголовка объявления
```sql
CREATE OR REPLACE FUNCTION service.normalize_ad_header()
RETURNS TRIGGER AS $$
BEGIN
    -- Использование NEW для нормализации заголовка
    -- Удаляем лишние пробелы и делаем первую букву заголовка заглавной
    NEW.header_text := TRIM(NEW.header_text);
    
    -- Удаляем множественные пробелы
    WHILE NEW.header_text LIKE '%  %' LOOP
        NEW.header_text := REPLACE(NEW.header_text, '  ', ' ');
    END LOOP;
    
    -- Делаем первую букву заглавной, остальные - строчными
    IF LENGTH(NEW.header_text) > 0 THEN
        NEW.header_text := UPPER(SUBSTRING(NEW.header_text, 1, 1)) || 
                          LOWER(SUBSTRING(NEW.header_text, 2));
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_normalize_header_before_insert
    BEFORE INSERT ON service.ads
    FOR EACH ROW
    EXECUTE FUNCTION service.normalize_ad_header();
```

**Пример использования:**

Вставка объявления с некорректным форматированием заголовка
```sql
INSERT INTO service.ads (seller_id, vehicle_id, header_text, description, price, status_id)
VALUES (1, 1, '  ПРОДАМ   АВТОМОБИЛЬ  ', 'Отличное состояние', 500000, 1);
```

Проверка, что заголовок был нормализован автоматически
```sql
SELECT ad_id, header_text, price, status_id 
FROM service.ads 
WHERE ad_id = (SELECT MAX(ad_id) FROM service.ads);
```
<img width="468" height="75" alt="image" src="https://github.com/user-attachments/assets/77e7c3a8-30a7-4038-9d6b-d8fc128e2595" />


### 1.2. AFTER Row-level триггеры (2 шт)

#### Триггер 3: Автоматическое создание записи о пробеге при добавлении транспорта
```sql
CREATE OR REPLACE FUNCTION service.create_initial_mileage()
RETURNS TRIGGER AS $$
BEGIN
    -- Использование NEW для создания начальной записи о пробеге
    -- Если транспорт новый (state_code = 'new'), пробег = 0
    IF NEW.state_code = 'new' THEN
        INSERT INTO service.mileage_log (vehicle_id, mileage_km)
        VALUES (NEW.vehicle_id, 0);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_initial_mileage_after_insert
    AFTER INSERT ON service.vehicles
    FOR EACH ROW
    EXECUTE FUNCTION service.create_initial_mileage();
```

**Пример использования:**

Вставляем новый транспорт (state_code = 'new')
```sql
INSERT INTO service.vehicles (brand, model, year_of_manufacture, vin, state_code)
VALUES ('Toyota', 'Camry', 2024, 'JH4KA8260PC123456', 'new');
```

Проверяем, что автоматически создалась запись о пробеге
```sql
SELECT * FROM service.mileage_log 
WHERE vehicle_id = (SELECT MAX(vehicle_id) FROM service.vehicles);
```
<img width="531" height="78" alt="image" src="https://github.com/user-attachments/assets/a68cd69c-d79c-4776-a854-a079c47796ab" />


#### Триггер 4: Логирование изменений цены объявления
```sql
-- Создаем таблицу для логов изменений цены (если еще не создана)
CREATE TABLE IF NOT EXISTS service.price_change_log (
    log_id SERIAL PRIMARY KEY,
    ad_id INTEGER NOT NULL,
    old_price INTEGER,
    new_price INTEGER,
    price_difference INTEGER,
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION service.log_price_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Использование OLD и NEW для логирования изменений цены
    IF OLD.price IS DISTINCT FROM NEW.price THEN
        INSERT INTO service.price_change_log (ad_id, old_price, new_price, price_difference)
        VALUES (NEW.ad_id, OLD.price, NEW.price, NEW.price - OLD.price);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_price_change_after_update
    AFTER UPDATE ON service.ads
    FOR EACH ROW
    EXECUTE FUNCTION service.log_price_change();
```

**Пример использования:**

Создаем объявление с ценой
```sql
INSERT INTO service.ads (seller_id, vehicle_id, header_text, description, price, status_id)
VALUES (1, 1, 'Продам автомобиль', 'Описание', 500000, 1);
```

Обновляем цену объявления
```sql
UPDATE service.ads 
SET price = 450000 
WHERE ad_id = (SELECT MAX(ad_id) FROM service.ads WHERE header_text = 'Продам автомобиль');
```

Проверяем лог изменений цены
```sql
SELECT * FROM service.price_change_log 
WHERE ad_id = (SELECT MAX(ad_id) FROM service.ads WHERE header_text = 'Продам автомобиль')
ORDER BY change_date DESC;
```
<img width="704" height="78" alt="image" src="https://github.com/user-attachments/assets/de0beffd-4896-49ef-afe4-1ea8c0e7f6a0" />


### 1.3. BEFORE Statement-level триггеры (2 шт)

#### Триггер 5: Проверяем, что массовое обновление выполняется в рабочее время
```sql
CREATE OR REPLACE FUNCTION service.check_bulk_update_permission()
RETURNS TRIGGER AS $$
BEGIN
    IF EXTRACT(HOUR FROM CURRENT_TIME) < 9 OR EXTRACT(HOUR FROM CURRENT_TIME) >= 18 THEN
        RAISE EXCEPTION 'Массовые обновления разрешены только в рабочее время (9:00-18:00). Текущее время: %', CURRENT_TIME;
    END IF;
    RAISE NOTICE 'Выполняется массовое обновление объявлений в %', CURRENT_TIMESTAMP;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_bulk_update_permission_before
    BEFORE UPDATE ON service.ads
    FOR EACH STATEMENT
    EXECUTE FUNCTION service.check_bulk_update_permission();
```

**Пример использования:**

Попытка массового обновления в нерабочее время (вызовет ошибку)
```sql
-- Если текущее время вне диапазона 9:00-18:00, будет ошибка
UPDATE service.ads 
SET status_id = 2 
WHERE status_id = 1 AND publication_date < CURRENT_DATE - INTERVAL '30 days';
```
<img width="836" height="120" alt="image" src="https://github.com/user-attachments/assets/6837aa11-a2e7-4c87-9713-56e206991119" />


#### Триггер 6: Логирование начала массовой вставки отзывов
```sql
-- Создаем таблицу для мониторинга массовых операций (если еще не создана)
CREATE TABLE IF NOT EXISTS service.bulk_operation_monitor (
    monitor_id SERIAL PRIMARY KEY,
    operation_type VARCHAR(50),
    table_name VARCHAR(50),
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_name VARCHAR(100)
);

CREATE OR REPLACE FUNCTION service.monitor_bulk_feedback_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Statement-level триггер: логируем начало массовой вставки отзывов
    INSERT INTO service.bulk_operation_monitor (operation_type, table_name, user_name)
    VALUES ('INSERT', 'feedbacks', CURRENT_USER);
    RAISE NOTICE 'Начата массовая вставка отзывов. Время: %', CURRENT_TIMESTAMP;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_monitor_bulk_feedback_before
    BEFORE INSERT ON service.feedbacks
    FOR EACH STATEMENT
    EXECUTE FUNCTION service.monitor_bulk_feedback_insert();
```

**Пример использования:**

Массовая вставка отзывов
```sql
INSERT INTO service.feedbacks (user_id, seller_id, text, rating)
VALUES 
    (1, 1, 'Отзыв 1', 4.5),
    (2, 1, 'Отзыв 2', 5.0),
    (3, 1, 'Отзыв 3', 4.0);
```
<img width="622" height="96" alt="image" src="https://github.com/user-attachments/assets/52a6d894-7e31-43dd-9b2b-343155b279cf" />


Проверяем мониторинг операций
```sql
SELECT * FROM service.bulk_operation_monitor 
WHERE table_name = 'feedbacks'
ORDER BY started_at DESC LIMIT 5;
```
<img width="795" height="74" alt="image" src="https://github.com/user-attachments/assets/38330ce2-6ea2-4758-a565-f63a33563dfa" />


### 1.4. AFTER Statement-level триггеры (2 шт)

#### Триггер 7: Логирование массового удаления объявлений
```sql
-- Создаем таблицу для логов массовых операций (если еще не создана)
CREATE TABLE IF NOT EXISTS service.bulk_operation_log (
    log_id SERIAL PRIMARY KEY,
    operation_type VARCHAR(50),
    table_name VARCHAR(50),
    operation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    affected_rows INTEGER,
    user_name VARCHAR(100)
);

CREATE OR REPLACE FUNCTION service.log_bulk_delete()
RETURNS TRIGGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Statement-level триггер: логируем массовое удаление
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    INSERT INTO service.bulk_operation_log (operation_type, table_name, affected_rows, user_name)
    VALUES ('DELETE', 'ads', deleted_count, CURRENT_USER);
    RAISE NOTICE 'Удалено объявлений: %', deleted_count;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_bulk_delete_after
    AFTER DELETE ON service.ads
    FOR EACH STATEMENT
    EXECUTE FUNCTION service.log_bulk_delete();
```

**Пример использования:**

Массовое удаление объявлений
```sql
DELETE FROM service.ads 
WHERE status_id = 3 AND publication_date < CURRENT_DATE - INTERVAL '1 year';
```
<img width="345" height="98" alt="Снимок экрана 2025-12-02 233029" src="https://github.com/user-attachments/assets/982e5468-0002-40df-a6d9-d15ea477dd37" />

Проверяем лог массовых операций
```sql
SELECT * FROM service.bulk_operation_log 
WHERE operation_type = 'DELETE' 
ORDER BY operation_date DESC LIMIT 5;
```
<img width="915" height="83" alt="Снимок экрана 2025-12-02 233049" src="https://github.com/user-attachments/assets/abbbebc9-f4af-4762-8287-e29af1be696b" />


#### Триггер 8: Уведомление администраторам о массовой вставке транспорта
```sql
-- Удаляем старый триггер и функцию, если они существуют
DROP TRIGGER IF EXISTS trigger_validate_bulk_vehicle_insert_after ON service.vehicles;
DROP FUNCTION IF EXISTS service.validate_bulk_vehicle_insert();

-- Создаем таблицу для административных уведомлений (если еще не создана)
CREATE TABLE IF NOT EXISTS service.admin_notifications (
    notification_id SERIAL PRIMARY KEY,
    notification_type VARCHAR(50),
    table_name VARCHAR(50),
    message TEXT,
    record_count INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN DEFAULT FALSE
);

CREATE OR REPLACE FUNCTION service.notify_admin_bulk_vehicle_insert()
RETURNS TRIGGER AS $$
DECLARE
    inserted_count INTEGER;
    brands_summary TEXT;
BEGIN
    -- Statement-level триггер: уведомляем администраторов о массовой вставке транспорта
    GET DIAGNOSTICS inserted_count = ROW_COUNT;
    
    -- Собираем список марок из последних вставленных записей
    SELECT STRING_AGG(DISTINCT brand, ', ' ORDER BY brand)
    INTO brands_summary
    FROM (
        SELECT brand
        FROM service.vehicles
        ORDER BY vehicle_id DESC
        LIMIT GREATEST(inserted_count, 1)
    ) recent_vehicles;
    
    -- Создаем уведомление о массовой вставке
    INSERT INTO service.admin_notifications (notification_type, table_name, message, record_count)
    VALUES (
        'bulk_insert',
        'vehicles',
        'Массовая вставка транспорта: ' || inserted_count || ' записей. Марки: ' || COALESCE(brands_summary, 'не указаны'),
        inserted_count
    );
    
    RAISE NOTICE 'Создано уведомление администратору о массовой вставке % записей', inserted_count;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_admin_bulk_vehicle_insert_after
    AFTER INSERT ON service.vehicles
    FOR EACH STATEMENT
    EXECUTE FUNCTION service.notify_admin_bulk_vehicle_insert();
```

**Пример использования:**

Массовая вставка транспорта (2+ записей)
```sql
INSERT INTO service.vehicles (brand, model, year_of_manufacture, vin)
VALUES 
    ('Toyota', 'Camry', 2020, 'JH4KA8260PC123450'),
    ('Honda', 'Civic', 2021, 'SHHFK8H50FU123450');
```

Проверяем уведомления администраторам
```sql
SELECT * FROM service.admin_notifications 
WHERE notification_type = 'bulk_insert'
ORDER BY created_at DESC LIMIT 5;
```
<img width="1195" height="82" alt="image" src="https://github.com/user-attachments/assets/0c994ee7-683b-40cc-a5e0-5a31aed5e5cf" />



### 1.5. Row-level триггеры с использованием NEW (2 шт)

#### Триггер 9: Автоматическое создание уведомления при низком рейтинге
```sql
-- Создаем таблицу для уведомлений продавцам (если еще не создана)
CREATE TABLE IF NOT EXISTS service.seller_notifications (
    notification_id SERIAL PRIMARY KEY,
    seller_id INTEGER NOT NULL REFERENCES service.sellers(seller_id) ON DELETE CASCADE,
    feedback_id INTEGER REFERENCES service.feedbacks(feedback_id),
    notification_type VARCHAR(50),
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN DEFAULT FALSE
);

CREATE OR REPLACE FUNCTION service.notify_low_rating()
RETURNS TRIGGER AS $$
BEGIN
    -- Использование NEW для создания уведомления при низком рейтинге
    IF NEW.rating < 3.0 THEN
        INSERT INTO service.seller_notifications (seller_id, feedback_id, notification_type, message)
        VALUES (
            NEW.seller_id, 
            NEW.feedback_id,
            'low_rating',
            'Получен отзыв с низким рейтингом: ' || NEW.rating::TEXT || '. Текст: ' || COALESCE(NEW.text, 'без текста')
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_low_rating_after_feedback
    AFTER INSERT ON service.feedbacks
    FOR EACH ROW
    EXECUTE FUNCTION service.notify_low_rating();
```

**Пример использования:**

Добавляем отзыв с низким рейтингом
```sql
INSERT INTO service.feedbacks (user_id, seller_id, text, rating)
VALUES (1, 1, 'Не понравилось обслуживание', 2.0);
```

Проверяем, что уведомление было создано автоматически
```sql
SELECT * FROM service.seller_notifications 
WHERE seller_id = 1
ORDER BY created_at DESC LIMIT 1;
```
<img width="1240" height="88" alt="image" src="https://github.com/user-attachments/assets/97fb2054-6133-4020-a9f2-adabad8dd578" />


Добавляем отзыв с высоким рейтингом (уведомление не создастся)
```sql
INSERT INTO service.feedbacks (user_id, seller_id, text, rating)
VALUES (2, 1, 'Отлично!', 5.0);
```

#### Триггер 10: Проверка и нормализация VIN перед вставкой транспорта
```sql
CREATE OR REPLACE FUNCTION service.normalize_vin()
RETURNS TRIGGER AS $$
BEGIN
    -- Использование NEW для нормализации VIN (перевод в верхний регистр)
    NEW.vin := UPPER(TRIM(NEW.vin));
    
    -- Проверка длины VIN
    IF LENGTH(NEW.vin) != 17 THEN
        RAISE EXCEPTION 'VIN должен содержать 17 символов, получено: %', LENGTH(NEW.vin);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_normalize_vin_before_insert
    BEFORE INSERT ON service.vehicles
    FOR EACH ROW
    EXECUTE FUNCTION service.normalize_vin();
```

**Пример использования:**

Вставка транспорта с VIN в нижнем регистре и пробелами
```sql
INSERT INTO service.vehicles (brand, model, year_of_manufacture, color, vin)
VALUES ('Toyota', 'Camry', 2020, 'Black', 'jh4ka8260pc123456');
```

Проверяем, что VIN был нормализован
```sql
SELECT vehicle_id, brand, model, vin FROM service.vehicles 
WHERE brand = 'Toyota' AND model = 'Camry';
```
<img width="598" height="27" alt="image" src="https://github.com/user-attachments/assets/9cb9eb1e-e7e0-4b09-aa2d-d2b4894a16d8" />


Попытка вставить VIN неправильной длины (вызовет ошибку)
```sql
INSERT INTO service.vehicles (brand, model, year_of_manufacture, vin)
VALUES ('Honda', 'Civic', 2019, 'SHORTVIN');
```
<img width="581" height="118" alt="image" src="https://github.com/user-attachments/assets/67fce58b-5c96-4b6f-af79-40cf73544fba" />


### 1.6. Row-level триггеры с использованием OLD (2 шт)

#### Триггер 11: Автоматическое обновление статуса договоров при удалении объявления
```sql
CREATE OR REPLACE FUNCTION service.update_contracts_on_ad_delete()
RETURNS TRIGGER AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    -- BEFORE DELETE: закрываем активные/ожидающие договоры и убираем ссылку на ad_id у ВСЕХ договоров
    -- Это необходимо, чтобы избежать нарушения внешнего ключа
    UPDATE service.contracts 
    SET status = CASE 
                    WHEN status IN ('active', 'pending') THEN 'closed'
                    ELSE status
                 END,
        ad_id = NULL
    WHERE ad_id = OLD.ad_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    IF updated_count > 0 THEN
        RAISE NOTICE 'Обновлено договоров: % для удаляемого объявления ad_id: %', updated_count, OLD.ad_id;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_contracts_on_ad_delete
    BEFORE DELETE ON service.ads
    FOR EACH ROW
    EXECUTE FUNCTION service.update_contracts_on_ad_delete();
```

**Пример использования:**

Проверяем активные договоры для объявления
```sql
SELECT contract_id, ad_id, status, amount 
FROM service.contracts 
WHERE ad_id = (SELECT MAX(ad_id) FROM service.ads)
  AND status IN ('active', 'pending');
```

<img width="373" height="78" alt="image" src="https://github.com/user-attachments/assets/7d91a6ed-b42d-49e6-b74f-901c68496748" />

Удаляем объявление
```sql
DELETE FROM service.ads 
WHERE ad_id = (SELECT MAX(ad_id) FROM service.ads);
```

Проверяем, что статусы договоров были обновлены автоматически
```sql
SELECT contract_id, ad_id, status 
FROM service.contracts 

```
<img width="363" height="26" alt="image" src="https://github.com/user-attachments/assets/0922bc6f-4e32-409c-a65d-7ba8a651b96e" />


#### Триггер 12: Архивирование удаленных объявлений с полной информацией
```sql
-- Создаем таблицу архива (если еще не создана)
CREATE TABLE IF NOT EXISTS service.ads_archive (
    ad_id INTEGER,
    seller_id INTEGER,
    vehicle_id INTEGER,
    header_text VARCHAR(200),
    description TEXT,
    price INTEGER,
    publication_date TIMESTAMP,
    status_id INTEGER,
    deleted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_by VARCHAR(100) DEFAULT CURRENT_USER
);

CREATE OR REPLACE FUNCTION service.archive_deleted_ad()
RETURNS TRIGGER AS $$
BEGIN
    -- Использование OLD для архивирования удаленного объявления
    INSERT INTO service.ads_archive 
        (ad_id, seller_id, vehicle_id, header_text, description, price, publication_date, status_id, deleted_by)
    VALUES 
        (OLD.ad_id, OLD.seller_id, OLD.vehicle_id, OLD.header_text, 
         OLD.description, OLD.price, OLD.publication_date, OLD.status_id, CURRENT_USER);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_archive_ad_after_delete
    AFTER DELETE ON service.ads
    FOR EACH ROW
    EXECUTE FUNCTION service.archive_deleted_ad();
```

**Пример использования:**

Получаем ID объявления для удаления
```sql
SELECT ad_id, header_text, status_id FROM service.ads 
WHERE status_id = 3 LIMIT 1;
```
<img width="493" height="82" alt="image" src="https://github.com/user-attachments/assets/df8c7ade-d388-4f9d-8ef3-871fbab219db" />


Удаляем объявление
```sql
DELETE FROM service.ads 
WHERE ad_id = (SELECT ad_id FROM service.ads WHERE status_id = 3 LIMIT 1);
```

Проверяем, что объявление было заархивировано с информацией о пользователе
```sql
SELECT * FROM service.ads_archive 
ORDER BY deleted_date DESC LIMIT 1;
```
<img width="1295" height="73" alt="Снимок экрана 2025-12-03 005409" src="https://github.com/user-attachments/assets/f29474c4-6ed8-41bf-a3fb-1ed1fade19cf" />

## 2. Отображение списка триггеров

### Запрос для просмотра всех триггеров в схеме service
```sql
SELECT 
    t.trigger_name AS "Имя триггера",
    t.event_manipulation AS "Событие",
    t.event_object_table AS "Таблица",
    t.action_timing AS "Время выполнения",
    t.action_statement AS "Действие",
    CASE 
        WHEN t.action_orientation = 'ROW' THEN 'Row-level'
        WHEN t.action_orientation = 'STATEMENT' THEN 'Statement-level'
    END AS "Уровень",
    p.proname AS "Функция"
FROM information_schema.triggers t
JOIN pg_trigger pt ON pt.tgname = t.trigger_name
JOIN pg_proc p ON p.oid = pt.tgfoid
WHERE t.trigger_schema = 'service'
ORDER BY t.event_object_table, t.trigger_name;
```
<img width="1291" height="343" alt="image" src="https://github.com/user-attachments/assets/b8214033-4b75-4156-ae51-ccb42352d272" />


---

## 3. Кроны (3 штуки)

### Крон 1: Ежедневная очистка старых объявлений (удаление объявлений старше 1 года со статусом 'sold')
```sql
SELECT cron.schedule(
    'cleanup-old-sold-ads',           -- Имя задачи
    '0 2 * * *',                      -- Расписание: каждый день в 2:00 ночи
    $$DELETE FROM service.ads 
      WHERE status_id = (SELECT id FROM service.ad_statuses WHERE code = 'sold')
        AND publication_date < CURRENT_DATE - INTERVAL '1 year'$$
);
```

### Крон 2: Еженедельное обновление рейтингов продавцов (каждый понедельник в 3:00)
```sql
SELECT cron.schedule(
    'update-seller-ratings',          -- Имя задачи
    '0 3 * * 1',                      -- Расписание: каждый понедельник в 3:00
    $$INSERT INTO service.seller_rating_cache (seller_id, avg_rating, reviews_count)
      SELECT 
          s.seller_id,
          COALESCE(AVG(f.rating), 0) AS avg_rating,
          COUNT(f.feedback_id) AS reviews_count
      FROM service.sellers s
      LEFT JOIN service.feedbacks f ON f.seller_id = s.seller_id
      GROUP BY s.seller_id
      ON CONFLICT (seller_id) 
      DO UPDATE SET 
          avg_rating = EXCLUDED.avg_rating,
          reviews_count = EXCLUDED.reviews_count$$
);
```

### Крон 3: Ежемесячная архивация старых логов (1-го числа каждого месяца в 4:00)
```sql
SELECT cron.schedule(
    'archive-old-logs',               -- Имя задачи
    '0 4 1 * *',                      -- Расписание: 1-го числа каждого месяца в 4:00
    $$DELETE FROM service.ad_status_log 
      WHERE change_date < CURRENT_DATE - INTERVAL '6 months';
      
      DELETE FROM service.bulk_operation_log 
      WHERE operation_date < CURRENT_DATE - INTERVAL '6 months'$$
);
```

---

## 4. Запрос на просмотр выполнения кронов

### Запрос для просмотра истории выполнения кронов
```sql
SELECT 
    jobid AS "ID задачи",
    jobname AS "Имя задачи",
    schedule AS "Расписание",
    command AS "Команда",
    nodename AS "Узел",
    nodeport AS "Порт",
    database AS "База данных",
    username AS "Пользователь",
    active AS "Активна",
    jobid AS "ID"
FROM cron.job
ORDER BY jobname;
```

### Запрос для просмотра успешных выполнений
```sql
SELECT 
    j.jobname AS "Имя задачи",
    jrd.start_time AS "Время начала",
    jrd.end_time AS "Время окончания",
    jrd.end_time - jrd.start_time AS "Длительность",
    jrd.status AS "Статус",
    jrd.return_message AS "Сообщение"
FROM cron.job_run_details jrd
JOIN cron.job j ON j.jobid = jrd.jobid
WHERE jrd.status = 'succeeded'
ORDER BY jrd.start_time DESC
LIMIT 20;
```

### Запрос для просмотра неудачных выполнений
```sql
SELECT 
    j.jobname AS "Имя задачи",
    jrd.start_time AS "Время начала",
    jrd.end_time AS "Время окончания",
    jrd.status AS "Статус",
    jrd.return_message AS "Сообщение ошибки"
FROM cron.job_run_details jrd
JOIN cron.job j ON j.jobid = jrd.jobid
WHERE jrd.status = 'failed'
ORDER BY jrd.start_time DESC
LIMIT 20;
```

---

## 5. Запрос на просмотр кронов

### Основной запрос для просмотра всех настроенных кронов
```sql
SELECT 
    jobid AS "ID задачи",
    jobname AS "Имя задачи",
    schedule AS "Расписание (cron)",
    command AS "SQL команда",
    nodename AS "Узел",
    nodeport AS "Порт",
    database AS "База данных",
    username AS "Пользователь",
    active AS "Активна",
    CASE active
        WHEN true THEN 'Да'
        ELSE 'Нет'
    END AS "Статус"
FROM cron.job
ORDER BY jobname;
```

