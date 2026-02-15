# Хранимые процедуры и функции

## 1. Процедуры 3 шт + запрос просмотра всех процедур

### 1.1. Процедура для добавления нового объявления

**Что хотим получить:** Процедуру, которая создает новое объявление с проверкой данных.

```sql
CREATE OR REPLACE PROCEDURE service.add_advertisement(
    p_seller_id INTEGER,
    p_vehicle_id INTEGER,
    p_header_text VARCHAR(200),
    p_description TEXT,
    p_price INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Проверка существования продавца
    IF NOT EXISTS (SELECT 1 FROM service.sellers WHERE seller_id = p_seller_id) THEN
        RAISE EXCEPTION 'Продавец с ID % не существует', p_seller_id;
    END IF;
    
    -- Проверка существования транспортного средства
    IF NOT EXISTS (SELECT 1 FROM service.vehicles WHERE vehicle_id = p_vehicle_id) THEN
        RAISE EXCEPTION 'Транспортное средство с ID % не существует', p_vehicle_id;
    END IF;
    
    -- Проверка цены
    IF p_price < 0 THEN
        RAISE EXCEPTION 'Цена не может быть отрицательной';
    END IF;
    
    -- Добавление объявления
    INSERT INTO service.ads (seller_id, vehicle_id, header_text, description, price, status_id)
    VALUES (
        p_seller_id,
        p_vehicle_id,
        p_header_text,
        p_description,
        p_price,
        (SELECT id FROM service.ad_statuses WHERE code = 'active')
    );
    
    RAISE NOTICE 'Объявление успешно добавлено';
END;
$$;
```

**Использование процедуры:**
```sql
CALL service.add_advertisement(
    1,  -- seller_id
    1,  -- vehicle_id
    'Новое объявление Toyota Camry',
    'Отличное состояние, один владелец',
    1600000  -- price
);

SELECT * FROM service.ads WHERE header_text = 'Новое объявление Toyota Camry';
```

<img width="1338" height="78" alt="image" src="https://github.com/user-attachments/assets/df8b9965-88de-4ea3-8e81-8ac85bc13ca6" />


---

### 1.2. Процедура для оформления покупки

**Что хотим получить:** Процедуру, которая оформляет покупку: создает контракт и меняет статус объявления.

```sql
CREATE OR REPLACE PROCEDURE service.process_purchase(
    p_ad_id INTEGER,
    p_buyer_user_id INTEGER,
    p_amount INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_seller_id INTEGER;
    v_vehicle_id INTEGER;
BEGIN
    -- Проверка существования объявления и его статуса
    SELECT seller_id, vehicle_id INTO v_seller_id, v_vehicle_id
    FROM service.ads a
    JOIN service.ad_statuses s ON a.status_id = s.id
    WHERE a.ad_id = p_ad_id AND s.code = 'active';
    
    IF v_seller_id IS NULL THEN
        RAISE EXCEPTION 'Объявление с ID % не найдено или не активно', p_ad_id;
    END IF;
    
    -- Проверка существования покупателя
    IF NOT EXISTS (SELECT 1 FROM service.users WHERE user_id = p_buyer_user_id) THEN
        RAISE EXCEPTION 'Пользователь с ID % не существует', p_buyer_user_id;
    END IF;
    
    -- Проверка суммы
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Сумма должна быть положительной';
    END IF;
    
    -- Создание контракта
    INSERT INTO service.contracts (ad_id, seller_id, buyer_user_id, amount, status)
    VALUES (p_ad_id, v_seller_id, p_buyer_user_id, p_amount, 'closed');
    
    -- Изменение статуса объявления на "продано"
    UPDATE service.ads
    SET status_id = (SELECT id FROM service.ad_statuses WHERE code = 'sold')
    WHERE ad_id = p_ad_id;
    
    RAISE NOTICE 'Покупка успешно оформлена';
END;
$$;
```

**Использование процедуры:**
```sql
-- Перед вызовом процедуры
SELECT ad_id, status_id, 
       (SELECT name FROM service.ad_statuses WHERE id = service.ads.status_id) as status_name
FROM service.ads WHERE ad_id = 1;

CALL service.process_purchase(1, 4, 1500000);

-- После вызова процедуры
SELECT ad_id, status_id, 
       (SELECT name FROM service.ad_statuses WHERE id = service.ads.status_id) as status_name
FROM service.ads WHERE ad_id = 1;

SELECT * FROM service.contracts WHERE ad_id = 1 ORDER BY contract_id DESC;
```

<img width="1129" height="117" alt="image" src="https://github.com/user-attachments/assets/60a06254-62d1-4f82-afe8-38cfb2957af2" />


---

### 1.3. Процедура для обновления цены объявления

**Что хотим получить:** Процедуру, которая обновляет цену объявления с проверками.

```sql
CREATE OR REPLACE PROCEDURE service.update_ad_price(
    p_ad_id INTEGER,
    p_new_price INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Проверка существования объявления
    IF NOT EXISTS (SELECT 1 FROM service.ads WHERE ad_id = p_ad_id) THEN
        RAISE EXCEPTION 'Объявление с ID % не найдено', p_ad_id;
    END IF;
    
    -- Проверка цены
    IF p_new_price < 0 THEN
        RAISE EXCEPTION 'Цена не может быть отрицательной';
    END IF;
    
    -- Обновление цены
    UPDATE service.ads
    SET price = p_new_price
    WHERE ad_id = p_ad_id;
    
    RAISE NOTICE 'Цена объявления обновлена';
END;
$$;
```

**Использование процедуры:**
```sql
SELECT ad_id, header_text, price FROM service.ads WHERE ad_id = 2;

CALL service.update_ad_price(2, 4200000);
```

<img width="452" height="80" alt="image" src="https://github.com/user-attachments/assets/2a99482f-62ad-45d4-a099-cfb6a646d054" />


---

### 1.4. Запрос просмотра всех процедур

**Что хотим получить:** Запрос для просмотра всех созданных процедур в схеме service.

```sql
SELECT 
    p.proname AS procedure_name,
    pg_get_function_arguments(p.oid) AS arguments,
    pg_get_functiondef(p.oid) AS definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'service'
  AND p.prokind = 'p'
ORDER BY p.proname;
```

<img width="1619" height="362" alt="image" src="https://github.com/user-attachments/assets/2211ccf3-b6cd-4709-bfd4-db53eecd3e95" />


---

## 2. Функции 3 шт + функции с переменными 3 шт + запрос просмотра всех функций

### 2.1. Функция для расчета среднего рейтинга продавца

**Что хотим получить:** Функцию, которая принимает ID продавца и возвращает его средний рейтинг на основе отзывов.

```sql
CREATE OR REPLACE FUNCTION service.get_seller_avg_rating(p_seller_id INTEGER)
RETURNS NUMERIC(3,2) AS $$
BEGIN
    RETURN (
        SELECT COALESCE(AVG(rating), 0)
        FROM service.feedbacks
        WHERE seller_id = p_seller_id
    );
END;
$$ LANGUAGE plpgsql;
```

**Использование функции:**
```sql
SELECT seller_id, service.get_seller_avg_rating(seller_id) as avg_rating
FROM service.sellers
ORDER BY seller_id;
```

<img width="346" height="181" alt="image" src="https://github.com/user-attachments/assets/510e48a5-0832-45fd-86d0-9a2ff41d4303" />


---

### 2.2. Функция для подсчета активных объявлений продавца

**Что хотим получить:** Функцию, которая принимает ID продавца и возвращает количество его активных объявлений.

```sql
CREATE OR REPLACE FUNCTION service.count_active_ads(p_seller_id INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM service.ads a
        JOIN service.ad_statuses s ON a.status_id = s.id
        WHERE a.seller_id = p_seller_id 
          AND s.code = 'active'
    );
END;
$$ LANGUAGE plpgsql;
```

**Использование функции:**
```sql
SELECT seller_id, service.count_active_ads(seller_id) as active_ads_count
FROM service.sellers
ORDER BY seller_id;
```

<img width="332" height="176" alt="image" src="https://github.com/user-attachments/assets/8a71ba90-ed7a-4d1a-9e6a-2cc297bbce94" />


---

### 2.3. Функция для проверки существования объявления

**Что хотим получить:** Функцию, которая проверяет, существует ли объявление с указанным ID и является ли оно активным.

```sql
CREATE OR REPLACE FUNCTION service.is_ad_active(p_ad_id INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 
        FROM service.ads a
        JOIN service.ad_statuses s ON a.status_id = s.id
        WHERE a.ad_id = p_ad_id 
          AND s.code = 'active'
    );
END;
$$ LANGUAGE plpgsql;
```

**Использование функции:**
```sql
SELECT ad_id, header_text, service.is_ad_active(ad_id) as is_active
FROM service.ads
ORDER BY ad_id;
```

<img width="592" height="238" alt="image" src="https://github.com/user-attachments/assets/8bcc8157-aab2-4c7b-998e-8ee8794f1210" />


---

### 2.4. Функция с переменными: расчет общей стоимости объявлений продавца

**Что хотим получить:** Функцию с использованием переменных, которая возвращает общую стоимость всех активных объявлений продавца.

```sql
CREATE OR REPLACE FUNCTION service.get_seller_total_price(p_seller_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_total_price INTEGER;
    v_ad_count INTEGER;
BEGIN
    -- Получаем общую стоимость
    SELECT COALESCE(SUM(price), 0) INTO v_total_price
    FROM service.ads a
    JOIN service.ad_statuses s ON a.status_id = s.id
    WHERE a.seller_id = p_seller_id 
      AND s.code = 'active'
      AND price IS NOT NULL;
    
    -- Получаем количество объявлений
    SELECT COUNT(*) INTO v_ad_count
    FROM service.ads a
    JOIN service.ad_statuses s ON a.status_id = s.id
    WHERE a.seller_id = p_seller_id 
      AND s.code = 'active';
    
    -- Если объявлений нет, возвращаем 0
    IF v_ad_count = 0 THEN
        RETURN 0;
    END IF;
    
    RETURN v_total_price;
END;
$$ LANGUAGE plpgsql;
```

**Использование функции:**
```sql
SELECT seller_id, service.get_seller_total_price(seller_id) as total_price
FROM service.sellers
ORDER BY seller_id;
```

<img width="283" height="172" alt="image" src="https://github.com/user-attachments/assets/2b862ba6-93ed-49c2-9019-ee5ba9b4ee4e" />


---

### 2.5. Функция с переменными: получение информации о транспортном средстве

**Что хотим получить:** Функцию с использованием переменных, которая возвращает полную информацию о транспортном средстве в виде текста.

```sql
CREATE OR REPLACE FUNCTION service.get_vehicle_info(p_vehicle_id INTEGER)
RETURNS TEXT AS $$
DECLARE
    v_brand VARCHAR(60);
    v_model VARCHAR(60);
    v_year INTEGER;
    v_color VARCHAR(30);
    v_vin VARCHAR(17);
    v_info TEXT;
BEGIN
    -- Получаем данные о транспортном средстве
    SELECT brand, model, year_of_manufacture, color, vin
    INTO v_brand, v_model, v_year, v_color, v_vin
    FROM service.vehicles
    WHERE vehicle_id = p_vehicle_id;
    
    -- Формируем строку информации
    v_info := CONCAT(
        v_brand, ' ', v_model, ' ', 
        v_year, ' года, ',
        COALESCE(v_color, 'цвет не указан'), ', ',
        'VIN: ', v_vin
    );
    
    RETURN v_info;
END;
$$ LANGUAGE plpgsql;
```

**Использование функции:**
```sql
SELECT vehicle_id, service.get_vehicle_info(vehicle_id) as vehicle_info
FROM service.vehicles
ORDER BY vehicle_id;
```

<img width="625" height="206" alt="image" src="https://github.com/user-attachments/assets/2e9bfb56-0765-44d0-b23a-af5b1161eb48" />


---

### 2.6. Функция с переменными: расчет статистики продавца

**Что хотим получить:** Функцию с использованием переменных, которая возвращает статистику продавца в виде текста.

```sql
CREATE OR REPLACE FUNCTION service.get_seller_statistics(p_seller_id INTEGER)
RETURNS TEXT AS $$
DECLARE
    v_seller_name VARCHAR(100);
    v_avg_rating NUMERIC(3,2);
    v_active_ads INTEGER;
    v_total_price INTEGER;
    v_result TEXT;
BEGIN
    -- Получаем имя продавца
    SELECT u.full_name INTO v_seller_name
    FROM service.sellers s
    JOIN service.users u ON s.user_id = u.user_id
    WHERE s.seller_id = p_seller_id;
    
    -- Получаем средний рейтинг
    SELECT COALESCE(AVG(rating), 0) INTO v_avg_rating
    FROM service.feedbacks
    WHERE seller_id = p_seller_id;
    
    -- Получаем количество активных объявлений
    SELECT COUNT(*) INTO v_active_ads
    FROM service.ads a
    JOIN service.ad_statuses s ON a.status_id = s.id
    WHERE a.seller_id = p_seller_id 
      AND s.code = 'active';
    
    -- Получаем общую стоимость
    SELECT COALESCE(SUM(price), 0) INTO v_total_price
    FROM service.ads a
    JOIN service.ad_statuses s ON a.status_id = s.id
    WHERE a.seller_id = p_seller_id 
      AND s.code = 'active'
      AND price IS NOT NULL;
    
    -- Формируем результат
    v_result := CONCAT(
        'Продавец: ', COALESCE(v_seller_name, 'Не найден'), E'\n',
        'Средний рейтинг: ', v_avg_rating, E'\n',
        'Активных объявлений: ', v_active_ads, E'\n',
        'Общая стоимость: ', v_total_price
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;
```

**Использование функции:**
```sql
SELECT seller_id, service.get_seller_statistics(seller_id) as statistics
FROM service.sellers
ORDER BY seller_id;
```

<img width="948" height="176" alt="image" src="https://github.com/user-attachments/assets/c7fd34a6-e137-403e-8d5b-80506e76d415" />


---

### 2.7. Запрос просмотра всех функций

**Что хотим получить:** Запрос для просмотра всех созданных функций в схеме service.

```sql
SELECT 
    p.proname AS function_name,
    pg_get_function_arguments(p.oid) AS arguments,
    pg_get_function_result(p.oid) AS return_type,
    pg_get_functiondef(p.oid) AS definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'service'
  AND p.prokind = 'f'
ORDER BY p.proname;
```

<img width="1623" height="263" alt="image" src="https://github.com/user-attachments/assets/01a15731-1b9b-4101-8043-ea3070f9e550" />


---

## 3. Блок DO 3 шт

### 3.1. Блок DO: добавление тестовых данных

**Что хотим получить:** Анонимный блок DO для добавления тестового транспортного средства и объявления.

```sql
DO $$
DECLARE
    v_vehicle_id INTEGER;
    v_ad_id INTEGER;
BEGIN
    -- Добавляем транспортное средство
    INSERT INTO service.vehicles 
    (brand, model, year_of_manufacture, color, body_type_id, transmission_id, fuel_type_id, power_hp, state_code, vin)
    VALUES 
    ('Hyundai', 'Solaris', 2020, 'Серый', 2, 1, 1, 123, 'used', 'Z94CB41BBLR123456')
    RETURNING vehicle_id INTO v_vehicle_id;
    
    RAISE NOTICE 'Добавлено транспортное средство с ID: %', v_vehicle_id;
    
    -- Добавляем объявление
    INSERT INTO service.ads (seller_id, vehicle_id, header_text, description, price, status_id)
    VALUES 
    (1, v_vehicle_id, 'Hyundai Solaris 2020', 'Надежный седан', 1200000, 
     (SELECT id FROM service.ad_statuses WHERE code = 'active'))
    RETURNING ad_id INTO v_ad_id;
    
    RAISE NOTICE 'Добавлено объявление с ID: %', v_ad_id;
END;
$$;
```

**Проверка результата:**
```sql
SELECT vehicle_id, brand, model FROM service.vehicles WHERE brand = 'Hyundai' AND model = 'Solaris';
SELECT ad_id, header_text FROM service.ads WHERE header_text = 'Hyundai Solaris 2020';
```

<img width="369" height="84" alt="image" src="https://github.com/user-attachments/assets/e5c5b902-bc16-4757-95ed-cbea82875a28" />


---

### 3.2. Блок DO: обновление статистики продавцов

**Что хотим получить:** Анонимный блок DO для обновления количества объявлений у всех продавцов.

```sql
DO $$
DECLARE
    v_seller_record RECORD;
    v_ads_count INTEGER;
BEGIN
    -- Проходим по всем продавцам
    FOR v_seller_record IN 
        SELECT seller_id FROM service.sellers
    LOOP
        -- Подсчитываем количество объявлений
        SELECT COUNT(*) INTO v_ads_count
        FROM service.ads
        WHERE seller_id = v_seller_record.seller_id;
        
        RAISE NOTICE 'Продавец ID: %, количество объявлений: %', 
                     v_seller_record.seller_id, v_ads_count;
    END LOOP;
    
    RAISE NOTICE 'Статистика обновлена для всех продавцов';
END;
$$;
```

<img width="528" height="175" alt="image" src="https://github.com/user-attachments/assets/f0012fd6-4582-4487-b71c-0f76336dff36" />


---

### 3.3. Блок DO: проверка и исправление данных

**Что хотим получить:** Анонимный блок DO для проверки и исправления объявлений с некорректными ценами.

```sql
DO $$
DECLARE
    v_ad_record RECORD;
    v_updated_count INTEGER := 0;
BEGIN
    -- Находим объявления с отрицательной или нулевой ценой
    FOR v_ad_record IN 
        SELECT ad_id, price, header_text
        FROM service.ads
        WHERE price IS NULL OR price <= 0
    LOOP
        -- Устанавливаем цену по умолчанию
        UPDATE service.ads
        SET price = 1000000
        WHERE ad_id = v_ad_record.ad_id;
        
        v_updated_count := v_updated_count + 1;
        
        RAISE NOTICE 'Обновлено объявление ID: %, заголовок: %', 
                     v_ad_record.ad_id, v_ad_record.header_text;
    END LOOP;
    
    RAISE NOTICE 'Всего обновлено объявлений: %', v_updated_count;
END;
$$;
```

**Проверка результата:**
```sql
SELECT ad_id, header_text, price FROM service.ads WHERE price = 1000000;
```

<img width="424" height="70" alt="image" src="https://github.com/user-attachments/assets/9950b204-4363-46a9-96e8-bd14562ef99e" />


---

## 4. IF 1 шт

### 4.1. Использование IF в процедуре

**Что хотим получить:** Процедуру с использованием IF для условной логики при добавлении отзыва.

```sql
CREATE OR REPLACE PROCEDURE service.add_feedback_with_check(
    p_user_id INTEGER,
    p_seller_id INTEGER,
    p_ad_id INTEGER,
    p_text TEXT,
    p_rating NUMERIC(3,2)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_existing_rating NUMERIC(3,2);
    v_feedback_count INTEGER;
BEGIN
    -- Проверка существования пользователя
    IF NOT EXISTS (SELECT 1 FROM service.users WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'Пользователь с ID % не существует', p_user_id;
    END IF;
    
    -- Проверка существования продавца
    IF NOT EXISTS (SELECT 1 FROM service.sellers WHERE seller_id = p_seller_id) THEN
        RAISE EXCEPTION 'Продавец с ID % не существует', p_seller_id;
    END IF;
    
    -- Проверка рейтинга
    IF p_rating < 0 OR p_rating > 5 THEN
        RAISE EXCEPTION 'Рейтинг должен быть от 0 до 5';
    END IF;
    
    -- Проверяем, существует ли уже отзыв
    SELECT rating INTO v_existing_rating
    FROM service.feedbacks
    WHERE user_id = p_user_id 
      AND seller_id = p_seller_id 
      AND ad_id = p_ad_id;
    
    IF v_existing_rating IS NOT NULL THEN
        -- Если отзыв существует, обновляем его
        UPDATE service.feedbacks
        SET text = p_text,
            rating = p_rating,
            publication_date = CURRENT_TIMESTAMP
        WHERE user_id = p_user_id 
          AND seller_id = p_seller_id 
          AND ad_id = p_ad_id;
        
        RAISE NOTICE 'Отзыв обновлен';
    ELSE
        -- Если отзыва нет, создаем новый
        INSERT INTO service.feedbacks (user_id, seller_id, ad_id, text, rating)
        VALUES (p_user_id, p_seller_id, p_ad_id, p_text, p_rating);
        
        RAISE NOTICE 'Новый отзыв добавлен';
    END IF;
    
    -- Подсчитываем общее количество отзывов
    SELECT COUNT(*) INTO v_feedback_count
    FROM service.feedbacks
    WHERE seller_id = p_seller_id;
    
    IF v_feedback_count > 10 THEN
        RAISE NOTICE 'У продавца более 10 отзывов!';
    END IF;
END;
$$;
```

**Использование процедуры:**
```sql
-- Первый отзыв
CALL service.add_feedback_with_check(2, 1, 1, 'Отличный продавец!', 5.0);

-- Обновление отзыва
CALL service.add_feedback_with_check(2, 1, 1, 'Очень хороший продавец, рекомендую!', 4.8);

SELECT * FROM service.feedbacks WHERE user_id = 2 AND seller_id = 1 AND ad_id = 1;
```

<img width="1106" height="84" alt="image" src="https://github.com/user-attachments/assets/3bb3f8a8-8d7c-4290-8ce7-600647223ec0" />


---

## 5. CASE 1 шт

### 5.1. Использование CASE в функции

**Что хотим получить:** Функцию с использованием CASE для категоризации объявлений по цене.

```sql
CREATE OR REPLACE FUNCTION service.get_price_category(p_ad_id INTEGER)
RETURNS TEXT AS $$
DECLARE
    v_price INTEGER;
    v_category TEXT;
BEGIN
    -- Получаем цену объявления
    SELECT price INTO v_price
    FROM service.ads
    WHERE ad_id = p_ad_id;
    
    -- Определяем категорию на основе цены
    v_category := CASE
        WHEN v_price IS NULL THEN 'Цена не указана'
        WHEN v_price < 1000000 THEN 'Бюджетный сегмент'
        WHEN v_price >= 1000000 AND v_price < 3000000 THEN 'Средний сегмент'
        WHEN v_price >= 3000000 AND v_price < 5000000 THEN 'Премиум сегмент'
        WHEN v_price >= 5000000 THEN 'Люкс сегмент'
        ELSE 'Неопределенная категория'
    END;
    
    RETURN v_category;
END;
$$ LANGUAGE plpgsql;
```

**Использование функции:**
```sql
SELECT 
    ad_id,
    header_text,
    price,
    service.get_price_category(ad_id) as price_category
FROM service.ads
ORDER BY price DESC NULLS LAST;
```

<img width="722" height="270" alt="image" src="https://github.com/user-attachments/assets/f70b3f3e-d3cb-4360-9837-1ae1c3d3ef0d" />


---

## 6. WHILE 2 шт

### 6.1. WHILE: генерация тестовых объявлений

**Что хотим получить:** Процедуру с использованием WHILE для генерации нескольких тестовых объявлений.

```sql
CREATE OR REPLACE PROCEDURE service.generate_test_ads(
    p_seller_id INTEGER,
    p_count INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_counter INTEGER := 1;
    v_vehicle_id INTEGER;
    v_ad_id INTEGER;
BEGIN
    -- Проверка существования продавца
    IF NOT EXISTS (SELECT 1 FROM service.sellers WHERE seller_id = p_seller_id) THEN
        RAISE EXCEPTION 'Продавец с ID % не существует', p_seller_id;
    END IF;
    
    -- Генерируем объявления в цикле WHILE
    WHILE v_counter <= p_count LOOP
        -- Создаем транспортное средство
        INSERT INTO service.vehicles 
        (brand, model, year_of_manufacture, color, body_type_id, transmission_id, fuel_type_id, power_hp, state_code, vin)
        VALUES 
        ('TestBrand', 'TestModel', 2020 + v_counter, 'Цвет' || v_counter, 1, 1, 1, 150, 'used', 
         'TEST' || LPAD(v_counter::TEXT, 13, '0'))
        RETURNING vehicle_id INTO v_vehicle_id;
        
        -- Создаем объявление
        INSERT INTO service.ads (seller_id, vehicle_id, header_text, description, price, status_id)
        VALUES 
        (p_seller_id, v_vehicle_id, 
         'Тестовое объявление #' || v_counter, 
         'Описание тестового объявления номер ' || v_counter,
         1000000 + (v_counter * 100000),
         (SELECT id FROM service.ad_statuses WHERE code = 'active'))
        RETURNING ad_id INTO v_ad_id;
        
        RAISE NOTICE 'Создано объявление #% с ID: %', v_counter, v_ad_id;
        
        v_counter := v_counter + 1;
    END LOOP;
    
    RAISE NOTICE 'Всего создано объявлений: %', p_count;
END;
$$;
```

**Использование процедуры:**
```sql
CALL service.generate_test_ads(1, 3);

SELECT ad_id, header_text, price FROM service.ads WHERE header_text LIKE 'Тестовое объявление%';
```

<img width="458" height="138" alt="image" src="https://github.com/user-attachments/assets/870244f0-c019-455b-968d-00c73d2741af" />


---

### 6.2. WHILE: обновление цен с шагом

**Что хотим получить:** Процедуру с использованием WHILE для постепенного обновления цен объявлений.

```sql
CREATE OR REPLACE PROCEDURE service.update_prices_gradually(
    p_seller_id INTEGER,
    p_discount_percent INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_ad_record RECORD;
    v_new_price INTEGER;
    v_updated_count INTEGER := 0;
    v_current_ad_id INTEGER;
BEGIN
    -- Получаем первое объявление
    SELECT ad_id INTO v_current_ad_id
    FROM service.ads
    WHERE seller_id = p_seller_id
      AND status_id = (SELECT id FROM service.ad_statuses WHERE code = 'active')
    ORDER BY ad_id
    LIMIT 1;
    
    -- Обновляем цены в цикле WHILE
    WHILE v_current_ad_id IS NOT NULL LOOP
        -- Получаем текущую цену
        SELECT price INTO v_new_price
        FROM service.ads
        WHERE ad_id = v_current_ad_id;
        
        -- Если цена существует, применяем скидку
        IF v_new_price IS NOT NULL AND v_new_price > 0 THEN
            v_new_price := v_new_price - (v_new_price * p_discount_percent / 100);
            
            -- Обновляем цену
            UPDATE service.ads
            SET price = v_new_price
            WHERE ad_id = v_current_ad_id;
            
            v_updated_count := v_updated_count + 1;
            
            RAISE NOTICE 'Обновлена цена объявления ID: %, новая цена: %', 
                         v_current_ad_id, v_new_price;
        END IF;
        
        -- Получаем следующее объявление
        SELECT ad_id INTO v_current_ad_id
        FROM service.ads
        WHERE seller_id = p_seller_id
          AND status_id = (SELECT id FROM service.ad_statuses WHERE code = 'active')
          AND ad_id > v_current_ad_id
        ORDER BY ad_id
        LIMIT 1;
        
        -- Ограничиваем количество обновлений
        IF v_updated_count >= 10 THEN
            EXIT;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Всего обновлено объявлений: %', v_updated_count;
END;
$$;
```

**Использование процедуры:**
```sql
-- Перед обновлением
SELECT ad_id, price FROM service.ads 
WHERE seller_id = 1 
  AND status_id = (SELECT id FROM service.ad_statuses WHERE code = 'active')
ORDER BY ad_id;

CALL service.update_prices_gradually(1, 5);  -- Скидка 5%

-- После обновления
SELECT ad_id, price FROM service.ads 
WHERE seller_id = 1 
  AND status_id = (SELECT id FROM service.ad_statuses WHERE code = 'active')
ORDER BY ad_id;
```

<img width="264" height="206" alt="image" src="https://github.com/user-attachments/assets/614c300c-a3cf-45c6-8414-267ccbebdd04" />


---

## 7. EXCEPTION 2 шт

### 7.1. EXCEPTION: обработка ошибок при добавлении объявления

**Что хотим получить:** Процедуру с обработкой исключений при добавлении объявления.

```sql
CREATE OR REPLACE PROCEDURE service.add_ad_with_exception_handling(
    p_seller_id INTEGER,
    p_vehicle_id INTEGER,
    p_header_text VARCHAR(200),
    p_description TEXT,
    p_price INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        -- Попытка добавления объявления
        INSERT INTO service.ads (seller_id, vehicle_id, header_text, description, price, status_id)
        VALUES (
            p_seller_id,
            p_vehicle_id,
            p_header_text,
            p_description,
            p_price,
            (SELECT id FROM service.ad_statuses WHERE code = 'active')
        );
        
        RAISE NOTICE 'Объявление успешно добавлено';
        
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE EXCEPTION 'Ошибка: неверный ID продавца или транспортного средства';
        WHEN check_violation THEN
            RAISE EXCEPTION 'Ошибка: цена не может быть отрицательной';
        WHEN unique_violation THEN
            RAISE EXCEPTION 'Ошибка: такое объявление уже существует';
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Произошла ошибка: %', SQLERRM;
    END;
END;
$$;
```

**Использование процедуры:**
```sql
-- Успешное добавление
CALL service.add_ad_with_exception_handling(1, 1, 'Новое объявление', 'Описание', 1500000);

-- Попытка с неверным seller_id (должна быть ошибка)
CALL service.add_ad_with_exception_handling(999, 1, 'Тест', 'Описание', 1500000);
```

<img width="1322" height="183" alt="image" src="https://github.com/user-attachments/assets/3585fa52-74c5-40ff-8ed3-1ec43b1d91ba" />


---

### 7.2. EXCEPTION: обработка ошибок при оформлении покупки

**Что хотим получить:** Процедуру с обработкой исключений при оформлении покупки.

```sql
CREATE OR REPLACE PROCEDURE service.process_purchase_with_exception(
    p_ad_id INTEGER,
    p_buyer_user_id INTEGER,
    p_amount INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_seller_id INTEGER;
    v_vehicle_id INTEGER;
    v_current_status VARCHAR(50);
BEGIN
    BEGIN
        -- Проверка существования объявления
        SELECT seller_id, vehicle_id, s.code INTO v_seller_id, v_vehicle_id, v_current_status
        FROM service.ads a
        JOIN service.ad_statuses s ON a.status_id = s.id
        WHERE a.ad_id = p_ad_id;
        
        IF v_seller_id IS NULL THEN
            RAISE EXCEPTION 'Объявление с ID % не найдено', p_ad_id;
        END IF;
        
        IF v_current_status != 'active' THEN
            RAISE EXCEPTION 'Объявление не активно. Текущий статус: %', v_current_status;
        END IF;
        
        -- Проверка существования покупателя
        IF NOT EXISTS (SELECT 1 FROM service.users WHERE user_id = p_buyer_user_id) THEN
            RAISE EXCEPTION 'Пользователь с ID % не существует', p_buyer_user_id;
        END IF;
        
        -- Проверка суммы
        IF p_amount <= 0 THEN
            RAISE EXCEPTION 'Сумма должна быть положительной';
        END IF;
        
        -- Создание контракта
        INSERT INTO service.contracts (ad_id, seller_id, buyer_user_id, amount, status)
        VALUES (p_ad_id, v_seller_id, p_buyer_user_id, p_amount, 'closed');
        
        -- Изменение статуса объявления
        UPDATE service.ads
        SET status_id = (SELECT id FROM service.ad_statuses WHERE code = 'sold')
        WHERE ad_id = p_ad_id;
        
        RAISE NOTICE 'Покупка успешно оформлена';
        
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE EXCEPTION 'Ошибка внешнего ключа: проверьте корректность ID';
        WHEN check_violation THEN
            RAISE EXCEPTION 'Ошибка проверки: сумма должна быть положительной';
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка при оформлении покупки: %', SQLERRM;
    END;
END;
$$;
```

**Использование процедуры:**
```sql
-- Успешное оформление
CALL service.process_purchase_with_exception(2, 4, 1500000);

-- Попытка купить уже проданное объявление (должна быть ошибка)
CALL service.process_purchase_with_exception(1, 4, 1500000);
```

<img width="1123" height="189" alt="image" src="https://github.com/user-attachments/assets/92d7dce7-0949-4875-a685-122dc87a993c" />


---

## 8. RAISE 2 шт

### 8.1. RAISE: использование RAISE NOTICE и RAISE WARNING

**Что хотим получить:** Процедуру с использованием RAISE NOTICE и RAISE WARNING для информационных сообщений.

```sql
CREATE OR REPLACE PROCEDURE service.check_seller_status(p_seller_id INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_seller_name VARCHAR(100);
    v_ads_count INTEGER;
    v_avg_rating NUMERIC(3,2);
BEGIN
    -- Получаем информацию о продавце
    SELECT u.full_name INTO v_seller_name
    FROM service.sellers s
    JOIN service.users u ON s.user_id = u.user_id
    WHERE s.seller_id = p_seller_id;
    
    IF v_seller_name IS NULL THEN
        RAISE EXCEPTION 'Продавец с ID % не найден', p_seller_id;
    END IF;
    
    -- Подсчитываем объявления
    SELECT COUNT(*) INTO v_ads_count
    FROM service.ads
    WHERE seller_id = p_seller_id;
    
    -- Получаем средний рейтинг
    SELECT COALESCE(AVG(rating), 0) INTO v_avg_rating
    FROM service.feedbacks
    WHERE seller_id = p_seller_id;
    
    -- Информационные сообщения
    RAISE NOTICE 'Проверка статуса продавца: %', v_seller_name;
    RAISE NOTICE 'Количество объявлений: %', v_ads_count;
    RAISE NOTICE 'Средний рейтинг: %', v_avg_rating;
    
    -- Предупреждения
    IF v_ads_count = 0 THEN
        RAISE WARNING 'У продавца нет объявлений!';
    END IF;
    
    IF v_avg_rating < 3.0 AND v_ads_count > 0 THEN
        RAISE WARNING 'Низкий рейтинг продавца: %. Рекомендуется улучшить качество обслуживания.', v_avg_rating;
    END IF;
    
    IF v_ads_count > 20 THEN
        RAISE WARNING 'У продавца очень много объявлений (%): возможна перегрузка системы.', v_ads_count;
    END IF;
    
    RAISE NOTICE 'Проверка завершена';
END;
$$;
```

**Использование процедуры:**
```sql
CALL service.check_seller_status(1);
```

<img width="504" height="146" alt="image" src="https://github.com/user-attachments/assets/e6396828-e15d-4e79-b99b-583f74a554eb" />


---

### 8.2. RAISE: использование RAISE EXCEPTION с разными уровнями

**Что хотим получить:** Процедуру с использованием RAISE EXCEPTION для обработки различных ошибок.

```sql
CREATE OR REPLACE PROCEDURE service.validate_and_add_ad(
    p_seller_id INTEGER,
    p_vehicle_id INTEGER,
    p_header_text VARCHAR(200),
    p_price INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_seller_exists BOOLEAN;
    v_vehicle_exists BOOLEAN;
    v_ads_count INTEGER;
BEGIN
    RAISE NOTICE 'Начало валидации данных для объявления';
    
    -- Проверка продавца
    SELECT EXISTS(SELECT 1 FROM service.sellers WHERE seller_id = p_seller_id) 
    INTO v_seller_exists;
    
    IF NOT v_seller_exists THEN
        RAISE EXCEPTION 'ОШИБКА: Продавец с ID % не существует. Проверьте корректность данных.', p_seller_id;
    END IF;
    
    RAISE NOTICE 'Продавец найден';
    
    -- Проверка транспортного средства
    SELECT EXISTS(SELECT 1 FROM service.vehicles WHERE vehicle_id = p_vehicle_id) 
    INTO v_vehicle_exists;
    
    IF NOT v_vehicle_exists THEN
        RAISE EXCEPTION 'ОШИБКА: Транспортное средство с ID % не существует. Проверьте корректность данных.', p_vehicle_id;
    END IF;
    
    RAISE NOTICE 'Транспортное средство найдено';
    
    -- Проверка цены
    IF p_price IS NULL THEN
        RAISE EXCEPTION 'ОШИБКА: Цена не может быть NULL. Укажите корректную цену.';
    END IF;
    
    IF p_price < 0 THEN
        RAISE EXCEPTION 'ОШИБКА: Цена не может быть отрицательной. Указана цена: %.', p_price;
    END IF;
    
    IF p_price = 0 THEN
        RAISE WARNING 'ВНИМАНИЕ: Цена равна нулю. Возможно, это ошибка.';
    END IF;
    
    -- Проверка количества объявлений у продавца
    SELECT COUNT(*) INTO v_ads_count
    FROM service.ads
    WHERE seller_id = p_seller_id;
    
    IF v_ads_count > 50 THEN
        RAISE WARNING 'У продавца уже много объявлений (%). Возможна перегрузка.', v_ads_count;
    END IF;
    
    -- Добавление объявления
    INSERT INTO service.ads (seller_id, vehicle_id, header_text, price, status_id)
    VALUES (
        p_seller_id,
        p_vehicle_id,
        p_header_text,
        p_price,
        (SELECT id FROM service.ad_statuses WHERE code = 'active')
    );
    
    RAISE NOTICE 'Объявление успешно добавлено с ID: %', 
                 (SELECT ad_id FROM service.ads 
                  WHERE seller_id = p_seller_id 
                    AND vehicle_id = p_vehicle_id 
                    AND header_text = p_header_text 
                  ORDER BY ad_id DESC LIMIT 1);
END;
$$;
```

**Использование процедуры:**
```sql
-- Успешное добавление
CALL service.validate_and_add_ad(1, 1, 'Проверенное объявление', 1500000);

-- Попытка с неверным seller_id (должна быть ошибка)
CALL service.validate_and_add_ad(999, 1, 'Тест', 1500000);

-- Попытка с отрицательной ценой (должна быть ошибка)
CALL service.validate_and_add_ad(1, 1, 'Тест', -1000);
```

<img width="1177" height="217" alt="image" src="https://github.com/user-attachments/assets/afdc7da2-ac48-4460-81e4-5f11c7791c11" />

<img width="1188" height="83" alt="image" src="https://github.com/user-attachments/assets/ba3229b1-3f6a-4f7a-871c-3a72edfe14b7" />


