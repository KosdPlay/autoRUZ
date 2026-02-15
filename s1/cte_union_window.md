# 5 CTE
## 1) Рейтинги продавцов с количеством отзывов
    WITH seller_stats AS (
    SELECT 
        s.seller_id,
        u.full_name as seller_name,
        COUNT(f.feedback_id) as feedback_count,
        COALESCE(AVG(f.rating), 0) as avg_rating
    FROM service.sellers s
    JOIN service.users u ON s.user_id = u.user_id
    LEFT JOIN service.feedbacks f ON s.seller_id = f.seller_id
    GROUP BY s.seller_id, u.full_name
    )
    SELECT
        seller_name,
        feedback_count,
        ROUND(avg_rating, 2) as rating
    FROM seller_stats
    WHERE feedback_count > 0
    ORDER BY avg_rating DESC;
<img width="397" height="124" alt="image" src="https://github.com/user-attachments/assets/e98bb437-55d9-4e3c-8545-187dea5bfe0a" />


## 2) Статистика по автомобилям с пробегом
    WITH vehicle_mileage AS (
    SELECT 
        v.vehicle_id,
        v.brand,
        v.model,
        v.year_of_manufacture,
        ml.mileage_km,
        bt.name as body_type
    FROM service.vehicles v
    JOIN service.mileage_log ml ON v.vehicle_id = ml.vehicle_id
    JOIN service.body_types bt ON v.body_type_id = bt.id
    ),
    price_info AS (
        SELECT
            vehicle_id,
            AVG(price) as avg_price
        FROM service.ads
        GROUP BY vehicle_id
    )
    SELECT
        vm.brand,
        vm.model,
        vm.year_of_manufacture,
        vm.mileage_km,
        vm.body_type,
        ROUND(pi.avg_price, 2) as average_price
    FROM vehicle_mileage vm
    JOIN price_info pi ON vm.vehicle_id = pi.vehicle_id
    ORDER BY vm.mileage_km;

<img width="851" height="150" alt="image" src="https://github.com/user-attachments/assets/ec3daef4-0aa0-4e20-8093-60eca95be918" />

## 3) Продажи по месяцам
    WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', c.contract_date) as month,
        COUNT(c.contract_id) as contracts_count,
        SUM(c.amount) as total_amount,
        ROUND(AVG(c.amount),2) as avg_amount
    FROM service.contracts c
    WHERE c.status = 'closed'
    GROUP BY DATE_TRUNC('month', c.contract_date)
    ),
    seller_performance AS (
        SELECT
            DATE_TRUNC('month', c.contract_date) as month,
            s.seller_id,
            u.full_name as seller_name,
            COUNT(c.contract_id) as seller_contracts
        FROM service.contracts c
        JOIN service.sellers s ON c.seller_id = s.seller_id
        JOIN service.users u ON s.user_id = u.user_id
        WHERE c.status = 'closed'
        GROUP BY DATE_TRUNC('month', c.contract_date), s.seller_id, u.full_name
    )
    SELECT
        TO_CHAR(ms.month, 'YYYY-MM') as month,
        ms.contracts_count,
        ms.total_amount,
        ms.avg_amount,
        sp.seller_name as top_seller
    FROM monthly_sales ms
    JOIN seller_performance sp ON ms.month = sp.month
    WHERE sp.seller_contracts = (
        SELECT MAX(seller_contracts)
        FROM seller_performance sp2
        WHERE sp2.month = ms.month
    )
    ORDER BY ms.month;

<img width="593" height="77" alt="image" src="https://github.com/user-attachments/assets/df23c791-43f6-48d4-aa58-9bb436232d67" />

## 4) Анализ цен по типам кузова
    WITH body_type_stats AS (
    SELECT 
        bt.id as body_type_id,
        bt.name as body_type_name,
        COUNT(a.ad_id) as ad_count,
        AVG(a.price) as avg_price,
        MIN(a.price) as min_price,
        MAX(a.price) as max_price
    FROM service.body_types bt
    LEFT JOIN service.vehicles v ON bt.id = v.body_type_id
    LEFT JOIN service.ads a ON v.vehicle_id = a.vehicle_id
    WHERE a.price IS NOT NULL
    GROUP BY bt.id, bt.name
    ),
    price_categories AS (
        SELECT
            body_type_name,
            avg_price,
            CASE
                WHEN avg_price > 30000 THEN 'Премиум'
                WHEN avg_price > 20000 THEN 'Средний'
                ELSE 'Бюджетный'
            END as price_category
        FROM body_type_stats
        WHERE ad_count > 0
    )
    SELECT
        body_type_name,
        ROUND(avg_price, 2) as average_price,
        price_category
    FROM price_categories
    ORDER BY avg_price DESC;

<img width="417" height="148" alt="image" src="https://github.com/user-attachments/assets/b9e8a7e1-a664-49da-b3e2-b7833760cfd8" />

## 5) История изменения пробега
    WITH mileage_history AS (
    SELECT 
        v.vehicle_id,
        v.brand,
        v.model,
        ml.mileage_km,
        ml.recorded_at,
        LAG(ml.mileage_km) OVER (PARTITION BY v.vehicle_id ORDER BY ml.recorded_at) as prev_mileage
    FROM service.vehicles v
    JOIN service.mileage_log ml ON v.vehicle_id = ml.vehicle_id
    ),
    mileage_changes AS (
        SELECT
            vehicle_id,
            brand,
            model,
            mileage_km as current_mileage,
            recorded_at,
            COALESCE(mileage_km - prev_mileage, 0) as mileage_increase
        FROM mileage_history
    )
    SELECT
        brand,
        model,
        current_mileage,
        recorded_at as last_update,
        mileage_increase
    FROM mileage_changes
    WHERE mileage_increase > 0
    ORDER BY brand, model, recorded_at;


<img width="792" height="205" alt="image" src="https://github.com/user-attachments/assets/5510573e-d438-4e2d-91fa-626d9c559e9e" />

# Onion - 3 запроса
## 1) Объединение активных и проданных автомобилей
    SELECT 
        'active' as status_type,
        a.ad_id,
        v.brand,
        v.model,
        a.price
    FROM service.ads a
    JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
    WHERE a.status_id = (SELECT id FROM service.ad_statuses WHERE code = 'active')
    
    UNION
    
    SELECT
        'sold' as status_type,
        a.ad_id,
        v.brand,
        v.model,
        c.amount as price
    FROM service.ads a
    JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
    JOIN service.contracts c ON a.ad_id = c.ad_id
    WHERE c.status = 'closed'
    ORDER BY status_type, price DESC;

<img width="585" height="151" alt="image" src="https://github.com/user-attachments/assets/54ea4045-6958-44dc-933c-3b156ade74a5" />

## 2) Контакты всех пользователей (продавцы и покупатели)
    SELECT 
        'seller' as user_type,
        u.full_name,
        u.email,
        u.phone_number
    FROM service.users u
    JOIN service.sellers s ON u.user_id = s.user_id
    
    UNION
    
    SELECT
        'buyer' as user_type,
        u.full_name,
        u.email,
        u.phone_number
    FROM service.users u
    JOIN service.contracts c ON u.user_id = c.buyer_user_id
    
    ORDER BY user_type, full_name;

<img width="592" height="222" alt="image" src="https://github.com/user-attachments/assets/ee7733cf-98ae-4aca-a79f-441a377157a6" />

## 3) Статистика по типам топлива и трансмиссиям
    SELECT 
        'fuel_type' as category,
        ft.name as item_name,
        COUNT(v.vehicle_id) as vehicle_count
    FROM service.fuel_types ft
    LEFT JOIN service.vehicles v ON ft.id = v.fuel_type_id
    GROUP BY ft.name
    
    UNION
    
    SELECT
        'transmission' as category,
        t.name as item_name,
        COUNT(v.vehicle_id) as vehicle_count
    FROM service.transmissions t
    LEFT JOIN service.vehicles v ON t.id = v.transmission_id
    GROUP BY t.name
    
    ORDER BY category, vehicle_count DESC;

<img width="399" height="246" alt="image" src="https://github.com/user-attachments/assets/e82f7b36-5653-4ad1-948f-0365456b843a" />

# INTERSECT - 3 запроса
## 1)  Пользователи, которые и продавали, и покупали
    SELECT 
        u.user_id, 
        u.full_name
    FROM service.users u
    JOIN service.sellers s ON u.user_id = s.user_id
    
    INTERSECT
    
    SELECT 
        u.user_id, 
        u.full_name
    FROM service.users u
    JOIN service.contracts c ON u.user_id = c.buyer_user_id;

<img width="277" height="94" alt="image" src="https://github.com/user-attachments/assets/ff5e265e-967d-4f33-967d-411f33828681" />

## 2) Автомобили, которые были и новыми, и с пробегом
    SELECT 
        brand, 
        model
    FROM service.vehicles
    WHERE state_code = 'new'
    
    INTERSECT
    
    SELECT 
        brand, 
        model
    FROM service.vehicles v
    JOIN service.mileage_log ml ON v.vehicle_id = ml.vehicle_id
    WHERE ml.mileage_km > 0;

<img width="354" height="74" alt="image" src="https://github.com/user-attachments/assets/26e91468-5a8a-4644-8b82-f61927f6dbb6" />

## 3) Продавцы с отзывами и завершенными сделками
    SELECT 
        s.seller_id, 
        u.full_name
    FROM service.sellers s
    JOIN service.users u ON s.user_id = u.user_id
    JOIN service.feedbacks f ON s.seller_id = f.seller_id
    
    INTERSECT
    
    SELECT 
        s.seller_id, 
        u.full_name
    FROM service.sellers s
    JOIN service.users u ON s.user_id = u.user_id
    JOIN service.contracts c ON s.seller_id = c.seller_id
    WHERE c.status = 'closed';

<img width="287" height="77" alt="image" src="https://github.com/user-attachments/assets/02689084-ea97-4898-887e-822433cca0ef" />

# EXCEPT - 3 запроса
## 1) Автомобили без отзывов
    SELECT 
        v.vehicle_id, 
        v.brand, 
        v.model
    FROM service.vehicles v
    JOIN service.ads a ON v.vehicle_id = a.vehicle_id
    
    EXCEPT
    
    SELECT 
        v.vehicle_id, 
        v.brand, 
        v.model
    FROM service.vehicles v
    JOIN service.ads a ON v.vehicle_id = a.vehicle_id
    JOIN service.feedbacks f ON a.ad_id = f.ad_id;

<img width="436" height="102" alt="image" src="https://github.com/user-attachments/assets/fa81a2c0-9cca-40eb-8190-c21ddd40bb83" />

## 2) Пользователи, которые только покупали, но не продавали
    SELECT 
        u.user_id, 
        u.full_name
    FROM service.users u
    JOIN service.contracts c ON u.user_id = c.buyer_user_id
    
    EXCEPT
    
    SELECT 
        u.user_id, 
        u.full_name
    FROM service.users u
    JOIN service.sellers s ON u.user_id = s.user_id;

<img width="283" height="76" alt="image" src="https://github.com/user-attachments/assets/d810783a-a26f-44d8-9749-442fec525a3d" />

## 3) Активные объявления без фотографий
    SELECT 
        a.ad_id, 
        v.brand, 
        v.model
    FROM service.ads a
    JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
    WHERE a.status_id = (
        SELECT id 
        FROM service.ad_statuses 
        WHERE code = 'active')
    
    EXCEPT
    
    SELECT 
        a.ad_id, 
        v.brand, 
        v.model
    FROM service.ads a
    JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
    JOIN service.ad_photos ap ON a.ad_id = ap.ad_id
    WHERE a.status_id = (
        SELECT id 
        FROM service.ad_statuses 
        WHERE code = 'active');

<img width="421" height="75" alt="image" src="https://github.com/user-attachments/assets/f98c9e54-d827-4565-acee-a1288a5ee1bc" />

# PARTITION BY - 2 запроса
## 1) Средняя цена по марке и типу кузова
    SELECT 
        v.brand,
        bt.name as body_type,
        a.price,
        ROUND(AVG(a.price) OVER (PARTITION BY v.brand, bt.name), 2) as avg_price_by_brand_body,
        ROUND(AVG(a.price) OVER (PARTITION BY v.brand), 2) as avg_price_by_brand
    FROM service.ads a
    JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
    JOIN service.body_types bt ON v.body_type_id = bt.id
    WHERE a.price IS NOT NULL   
    ORDER BY v.brand, bt.name;

<img width="733" height="199" alt="image" src="https://github.com/user-attachments/assets/be87f677-db10-4f8a-8160-d40a142d029e" />

## 2) Количество объявлений по продавцам и их доля
    SELECT 
        s.seller_id,
        u.full_name as seller_name,
        COUNT(a.ad_id) as ads_count,
        ROUND(COUNT(a.ad_id) * 100.0 / SUM(COUNT(a.ad_id)) OVER (PARTITION BY s.seller_type), 2) AS percentage_by_type,
        s.seller_type
    FROM service.sellers s
    JOIN service.users u ON s.user_id = u.user_id
    LEFT JOIN service.ads a ON s.seller_id = a.seller_id
    GROUP BY s.seller_id, u.full_name, s.seller_type
    ORDER BY s.seller_type, ads_count DESC;

<img width="669" height="145" alt="image" src="https://github.com/user-attachments/assets/4ac2caf7-e07c-48b8-903d-cc294aa9c7c5" />

# PARTITION BY + ORDER BY - 2 запроса
## 1) Рейтинг автомобилей по цене в пределах марки
    SELECT 
        v.brand,
        v.model,
        a.price,
        ROW_NUMBER() OVER (PARTITION BY v.brand ORDER BY a.price DESC) as price_rank_in_brand,
        RANK() OVER (PARTITION BY v.brand ORDER BY a.price DESC) as price_rank_with_gaps,
        DENSE_RANK() OVER (PARTITION BY v.brand ORDER BY a.price DESC) as price_dense_rank
    FROM service.ads a
    JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
    WHERE a.price IS NOT NULL
    ORDER BY v.brand, price_rank_in_brand;

<img width="838" height="200" alt="image" src="https://github.com/user-attachments/assets/171dec47-e7a4-47e3-9b7a-38719a9635ed" />

## 2) Накопительный итог продаж по месяцам
    SELECT 
        TO_CHAR(c.contract_date, 'YYYY-MM') as month,
        SUM(c.amount) as monthly_amount,
        SUM(SUM(c.amount)) OVER (ORDER BY TO_CHAR(c.contract_date, 'YYYY-MM')) as cumulative_amount,
        ROUND(AVG(SUM(c.amount)) OVER (ORDER BY TO_CHAR(c.contract_date, 'YYYY-MM') ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) as moving_avg_3_months
    FROM service.contracts c
    WHERE c.status = 'closed'
    GROUP BY TO_CHAR(c.contract_date, 'YYYY-MM')
    ORDER BY month;

<img width="541" height="76" alt="image" src="https://github.com/user-attachments/assets/da0bcd36-7864-4e8d-a535-d75da63ef6d5" />

# ROWS - 2 запроса
## 1) Скользящее среднее цены за последние 3 объявления
    SELECT 
        ad_id,
        brand,
        model,
        price,
        ROUND(AVG(price) OVER (ORDER BY publication_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) as moving_avg_price_3_ads
    FROM (
        SELECT
            a.ad_id,
            v.brand,
            v.model,
            a.price,
            a.publication_date
        FROM service.ads a
        JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
        WHERE a.price IS NOT NULL
        ORDER BY a.publication_date
    ) subquery;

<img width="669" height="199" alt="image" src="https://github.com/user-attachments/assets/09a534f1-03a1-4e22-ae49-310d4bf0e385" />

## 2) Разница с предыдущей записью пробега
    SELECT 
        vehicle_id,
        brand,
        model,
        mileage_km,
        recorded_at,
        LAG(mileage_km) OVER (PARTITION BY vehicle_id ORDER BY recorded_at) as prev_mileage,
        mileage_km - LAG(mileage_km) OVER (PARTITION BY vehicle_id ORDER BY recorded_at) as mileage_increase
    FROM (
        SELECT
            v.vehicle_id,
            v.brand,
            v.model,
            ml.mileage_km,
            ml.recorded_at
        FROM service.vehicles v
        JOIN service.mileage_log ml ON v.vehicle_id = ml.vehicle_id
    ) subquery
    ORDER BY vehicle_id, recorded_at;

<img width="957" height="328" alt="image" src="https://github.com/user-attachments/assets/4a37b106-9066-415d-b432-8683c7224e27" />

# RANGE - 2 запроса
## 1) Средняя цена в диапазоне ±500 000 от текущей цены
    SELECT 
        ad_id,
        brand,
        model,
        price,
        ROUND(AVG(price) OVER (
            ORDER BY price 
            RANGE BETWEEN 500000 PRECEDING AND 500000 FOLLOWING
        ), 2) AS avg_price_similar_range
    FROM (
        SELECT
            a.ad_id,
            v.brand,
            v.model,
            a.price
        FROM service.ads a
        JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
        WHERE a.price IS NOT NULL
    ) subquery
    ORDER BY price;

<img width="654" height="200" alt="image" src="https://github.com/user-attachments/assets/23dad3f4-0ff7-45ea-8803-77949066d3da" />

## 2) Количество контрактов в диапазоне дат
    SELECT 
        contract_id,
        seller_id,
        amount,
        contract_date,
        COUNT(*) OVER (ORDER BY contract_date RANGE BETWEEN INTERVAL '7 days' PRECEDING AND CURRENT ROW) as contracts_last_7_days,
        SUM(amount) OVER (ORDER BY contract_date RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW) as amount_last_30_days
    FROM service.contracts
    ORDER BY contract_date;

<img width="786" height="128" alt="image" src="https://github.com/user-attachments/assets/5bdb1e50-34ff-45cf-8bf4-bed4a56fc865" />

# Ранжирующие функции
## ROW_NUMBER - сквозная нумерация
    SELECT 
        ROW_NUMBER() OVER (ORDER BY a.price DESC) as row_num,
        v.brand,
        v.model,
        a.price,
        u.full_name as seller_name
    FROM service.ads a
    JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
    JOIN service.sellers s ON a.seller_id = s.seller_id
    JOIN service.users u ON s.user_id = u.user_id
    WHERE a.price IS NOT NULL
    ORDER BY a.price DESC;

<img width="661" height="200" alt="image" src="https://github.com/user-attachments/assets/9994fe92-9d9e-4414-84dc-9b252a30164e" />

## RANK - ранжирование с пропусками
    SELECT 
        v.brand,
        v.model,
        a.price,
        RANK() OVER (ORDER BY a.price DESC) as price_rank,
        u.full_name as seller_name
    FROM service.ads a
    JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
    JOIN service.sellers s ON a.seller_id = s.seller_id
    JOIN service.users u ON s.user_id = u.user_id
    WHERE a.price IS NOT NULL
    ORDER BY price_rank;

<img width="668" height="200" alt="image" src="https://github.com/user-attachments/assets/b3d83896-59bb-477f-8bd2-d08d58b043e2" />

## DENSE_RANK - ранжирование без пропусков
    SELECT 
        v.brand,
        v.model,
        a.price,
        DENSE_RANK() OVER (ORDER BY a.price DESC) as price_dense_rank,
        u.full_name as seller_name
    FROM service.ads a
    JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
    JOIN service.sellers s ON a.seller_id = s.seller_id
    JOIN service.users u ON s.user_id = u.user_id
    WHERE a.price IS NOT NULL
    ORDER BY price_dense_rank;

<img width="713" height="203" alt="image" src="https://github.com/user-attachments/assets/a7d3ba8d-471b-4186-abf7-3e18b5e2258e" />

## NTILE - разбиение на группы
    SELECT 
        v.brand,
        v.model,
        a.price,
        NTILE(4) OVER (ORDER BY a.price DESC) as price_quartile,
        CASE 
            WHEN NTILE(4) OVER (ORDER BY a.price DESC) = 1 THEN 'Высокая'
            WHEN NTILE(4) OVER (ORDER BY a.price DESC) = 2 THEN 'Выше средней'
            WHEN NTILE(4) OVER (ORDER BY a.price DESC) = 3 THEN 'Ниже средней'
            ELSE 'Низкая'
        END as price_category
    FROM service.ads a
    JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
    WHERE a.price IS NOT NULL
    ORDER BY price DESC;

<img width="644" height="205" alt="image" src="https://github.com/user-attachments/assets/a2e4e75f-6b03-41f1-908d-83be81ded95b" />

# Функции смещения 
## LAG - предыдущее значение
    SELECT 
        v.brand,
        v.model,
        a.price,
        LAG(a.price) OVER (ORDER BY a.publication_date) as prev_ad_price,
        a.price - LAG(a.price) OVER (ORDER BY a.publication_date) as price_difference
    FROM service.ads a
    JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
    WHERE a.price IS NOT NULL
    ORDER BY a.publication_date;

<img width="646" height="199" alt="image" src="https://github.com/user-attachments/assets/1624f3f5-1c63-42e6-8911-ff70d7d5ee5b" />

## LEAD - следующее значение
    SELECT 
        v.brand,
        v.model,
        a.price,
        LEAD(a.price) OVER (ORDER BY a.publication_date) as next_ad_price,
        LEAD(a.price) OVER (ORDER BY a.publication_date) - a.price as price_change_to_next
    FROM service.ads a
    JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
    WHERE a.price IS NOT NULL
    ORDER BY a.publication_date;

<img width="681" height="205" alt="image" src="https://github.com/user-attachments/assets/d873344e-4da8-4266-b784-854234ccea6e" />

## FIRST_VALUE - первое значение в окне
    SELECT
        v.brand,
        v.model,
        a.price,
        FIRST_VALUE(a.price) OVER (PARTITION BY v.brand ORDER BY a.price) as lowest_price_in_brand,
        a.price - FIRST_VALUE(a.price) OVER (PARTITION BY v.brand ORDER BY a.price) as difference_from_lowest
    FROM service.ads a
    JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
    WHERE a.price IS NOT NULL
    ORDER BY v.brand, a.price;

<img width="732" height="196" alt="image" src="https://github.com/user-attachments/assets/a7c12a90-8197-49a5-87c1-fd23c0a0b239" />

## LAST_VALUE - последнее значение в окне
    SELECT 
        v.brand,
        v.model,
        a.price,
        LAST_VALUE(a.price) OVER (PARTITION BY v.brand ORDER BY a.price ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as highest_price_in_brand,
        LAST_VALUE(a.price) OVER (PARTITION BY v.brand ORDER BY a.price ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) - a.price as difference_from_highest
    FROM service.ads a
    JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
    WHERE a.price IS NOT NULL
    ORDER BY v.brand, a.price;

<img width="748" height="205" alt="image" src="https://github.com/user-attachments/assets/8c708ce1-2670-4296-bec2-a2f354cbb0ff" />
