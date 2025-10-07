# Аномалии и их решения

# 1. Хранение агрегатов в таблицах (countOfAds, rating)

## Проблема:
В таблице sellers хранились агрегированные данные (countOfAds, rating), которые зависят от других таблиц (advertisiments, feedbacks).

## Влияние:

При изменении или удалении объявления/отзыва данные становятся неактуальными.

Возникают update и insert аномалии, нарушается согласованность данных.

## Решение:

Удалили поля countOfAds и rating из sellers.

Агрегаты считаются через VIEW или SQL-запросы:

CREATE VIEW service.seller_ratings AS
SELECT s.seller_id,
       AVG(f.rating) AS avg_rating,
       COUNT(f.feedback_id) AS reviews_count
FROM service.sellers s
LEFT JOIN service.feedbacks f ON f.seller_id = s.seller_id
GROUP BY s.seller_id;

# 2. Булевы признаки как 'yes'/'no'

## Проблема:
В таблице carLibrary поля ancients и usedInTaxi хранили значения 'yes' / 'no' (строки).

## Влияние:

Возможны опечатки ('Yes', 'YES', 'y' и т.п.).

Усложнена фильтрация и индексирование.

## Решение:

Заменили текстовые поля на логические (BOOLEAN).

Вынесли флаги в отдельную таблицу vehicle_flags:

CREATE TABLE service.vehicle_flags (
    vehicle_id INTEGER PRIMARY KEY REFERENCES service.vehicles(vehicle_id),
    is_classic BOOLEAN DEFAULT FALSE,
    used_in_taxi BOOLEAN DEFAULT FALSE
);

# 3. carLibrary — нарушение нормальных форм

## Проблема:
carLibrary объединяла разнородные данные — владельцев, пробег, страхование, флаги.
Множественные и разнотипные зависимости нарушали 1NF, 2NF и 3NF.

## Влияние:

Нельзя хранить историю (несколько страховок, владельцев, пробегов).

При обновлениях возникают противоречия между связанными атрибутами.

## Решение:
Таблицу разделили на отдельные сущности:

ownerships — история владения транспортом;

mileage_log — журнал пробега;

insurances — страховки;

vehicle_flags — булевы признаки.

Пример:

CREATE TABLE service.ownerships (
    ownership_id SERIAL PRIMARY KEY,
    vehicle_id INTEGER NOT NULL REFERENCES service.vehicles(vehicle_id),
    owner_user_id INTEGER REFERENCES service.users(user_id),
    purchase_date DATE,
    sale_date DATE
);

# 4. Неполная модель контрактов

## Проблема:
В contracts отсутствовали поля покупателя (buyer), даты заключения и ссылка на объявление (adId).

## Влияние:

Сделку невозможно связать с конкретным объявлением.

Невозможно учитывать историю покупок и корректно анализировать сделки.

## Решение:
Расширили таблицу контрактов:

CREATE TABLE service.contracts (
    contract_id SERIAL PRIMARY KEY,
    ad_id INTEGER REFERENCES service.ads(ad_id),
    seller_id INTEGER NOT NULL REFERENCES service.sellers(seller_id),
    buyer_user_id INTEGER NOT NULL REFERENCES service.users(user_id),
    amount INTEGER NOT NULL CHECK (amount >= 0),
    currency CHAR(3) DEFAULT 'USD',
    contract_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) CHECK (status IN ('active','closed','pending'))
);


Теперь контракт полностью описывает сделку.

# 5. Перечисления в виде текста (VARCHAR)

## Проблема:
Типы кузова, топлива, статусы объявлений и роли модераторов задавались строками (VARCHAR).

## Влияние:

Возможны опечатки ('saled' вместо 'sold').

Нет ссылочной целостности, сложно менять наименования.

## Решение:
Вынесли значения в справочные таблицы (lookup tables) и добавили внешние ключи:

body_types

fuel_types

transmissions

ad_statuses

moderator_roles

Пример:

CREATE TABLE service.body_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(30) UNIQUE NOT NULL,
    name VARCHAR(60) NOT NULL
);

# 6. Отсутствие уникальности в favourites

## Проблема:
Один пользователь мог добавить одно и то же объявление несколько раз.

## Решение:
Добавили составной первичный ключ (user_id, ad_id):

CREATE TABLE service.favourites (
    user_id INTEGER NOT NULL REFERENCES service.users(user_id),
    ad_id INTEGER NOT NULL REFERENCES service.ads(ad_id),
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, ad_id)
);

# 7. Неопределённые действия при удалении

## Проблема:
Не были заданы действия ON DELETE для связей между таблицами.

## Влияние:

Возможна потеря истории при удалении пользователя или продавца.

Возможны «висячие» ссылки на несуществующие записи.

## Решение:
Добавили политики удаления:

ON DELETE CASCADE — при удалении родителя удаляются зависимые данные;

ON DELETE SET NULL — если данные должны сохраняться для истории.

Пример:

CREATE TABLE service.feedbacks (
    feedback_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES service.users(user_id) ON DELETE SET NULL,
    seller_id INTEGER REFERENCES service.sellers(seller_id) ON DELETE CASCADE,
    text TEXT,
    rating NUMERIC(3,2) CHECK (rating BETWEEN 0 AND 5)
);

# 8. Неполная валидация и ограничения

## Проблема:
Некоторые поля имели слабую или отсутствующую проверку (VIN, phoneNumber, amount).

## Решение:

Добавили UNIQUE и CHECK ограничения.

Для числовых полей — диапазоны (CHECK (amount >= 0)).

Для VIN — длина 17 символов и уникальность.

Для телефона — регулярное выражение.

Для года выпуска — ограничение в пределах возможных значений (1886–текущий год).

# Итог

После нормализации и реорганизации:

Устранены все формы аномалий (insert, update, delete).

Схема соответствует 3NF и приближена к BCNF.

Обеспечена ссылочная и логическая целостность данных.

Агрегаты и справочные значения вынесены за пределы транзакционных таблиц.

Все ключевые связи и зависимости описаны явно.