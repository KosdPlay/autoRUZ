INSERT INTO service.body_types (code, name) VALUES
('sedan', 'Седан'),
('hatchback', 'Хэтчбек'),
('suv', 'Внедорожник'),
('coupe', 'Купе'),
('pickup', 'Пикап');

INSERT INTO service.transmissions (code, name) VALUES
('manual', 'Механическая'),
('automatic', 'Автоматическая'),
('cvt', 'Вариатор'),
('robot', 'Роботизированная');

INSERT INTO service.fuel_types (code, name) VALUES
('petrol', 'Бензин'),
('diesel', 'Дизель'),
('electric', 'Электро'),
('hybrid', 'Гибрид');

INSERT INTO service.ad_statuses (code, name) VALUES
('active', 'Активное объявление'),
('in_processing', 'На модерации'),
('sold', 'Продано');

INSERT INTO service.moderator_roles (code, name) VALUES
('supervisor', 'Супервизор'),
('editor', 'Редактор'),
('viewer', 'Просмотрщик');

-- === Пользователи ===
INSERT INTO service.users (full_name, email, phone_number) VALUES
('Иван Иванов', 'ivanov@example.com', '+79990001122'),
('Петр Петров', 'petrov@example.com', '+79990003344'),
('ООО "АвтоЛюкс"', 'autolux@example.com', '+79991234567'),
('Мария Смирнова', 'smirnova@example.com', '+79995556677'),
('Сергей Кузнецов', 'kuznetsov@example.com', '+79997778899');

INSERT INTO service.sellers (user_id, seller_type) VALUES
(1, 'individual'),
(2, 'individual'),
(3, 'company'),
(4, 'individual');

INSERT INTO service.vehicles 
(brand, model, year_of_manufacture, color, body_type_id, transmission_id, fuel_type_id, power_hp, state_code, vin)
VALUES
('Toyota', 'Camry', 2020, 'Белый', 1, 2, 1, 181, 'used', 'JTNB11HK603456789'),
('Volkswagen', 'Golf', 2018, 'Серый', 2, 1, 1, 125, 'used', 'WVWZZZ1KZJP345678'),
('Tesla', 'Model 3', 2022, 'Красный', 1, 2, 3, 258, 'new', '5YJ3E1EA5KF317654'),
('Ford', 'Ranger', 2019, 'Синий', 5, 1, 2, 200, 'used', '1FTYR15E1YTA34567'),
('BMW', 'X5', 2021, 'Черный', 3, 2, 4, 340, 'used', 'WBAVL1C50EVR34567');

INSERT INTO service.ads (seller_id, vehicle_id, header_text, description, price, status_id) VALUES
(1, 1, 'Toyota Camry 2020 — отличное состояние', 'Один владелец, пробег 45 000 км, без ДТП', 2300000, 1),
(2, 2, 'Volkswagen Golf 2018', 'Надежный немец, ухоженный салон, механика', 1100000, 1),
(3, 3, 'Новая Tesla Model 3 2022', 'Электрокар в наличии, без пробега', 5500000, 2),
(4, 4, 'Ford Ranger 2019', 'Отличный пикап для работы и отдыха', 2800000, 1),
(1, 5, 'BMW X5 2021', 'Максимальная комплектация, не бит', 5200000, 3);

INSERT INTO service.ad_photos (ad_id, url, is_primary) VALUES
(1, 'https://example.com/photos/camry1.jpg', TRUE),
(1, 'https://example.com/photos/camry2.jpg', FALSE),
(2, 'https://example.com/photos/golf1.jpg', TRUE),
(3, 'https://example.com/photos/tesla1.jpg', TRUE),
(4, 'https://example.com/photos/ranger1.jpg', TRUE),
(5, 'https://example.com/photos/x5_1.jpg', TRUE);

INSERT INTO service.favourites (user_id, ad_id) VALUES
(4, 1),
(5, 3),
(2, 4);

INSERT INTO service.feedbacks (user_id, seller_id, ad_id, text, rating) VALUES
(4, 1, 1, 'Все честно и быстро, машина как на фото', 4.8),
(5, 2, 2, 'Продавец адекватный, все показал', 4.5),
(1, 3, 3, 'Хорошая компания, Tesla доставили вовремя', 5.0);

INSERT INTO service.ownerships (vehicle_id, owner_user_id, purchase_date, sale_date, note) VALUES
(1, 1, '2020-03-15', '2024-02-01', 'Продана после 4 лет эксплуатации'),
(2, 2, '2018-05-10', NULL, 'Все еще в собственности'),
(3, 3, '2022-07-01', NULL, 'Собственная демонстрационная машина');

INSERT INTO service.mileage_log (vehicle_id, mileage_km, recorded_at) VALUES
(1, 45000, '2024-01-10'),
(2, 78000, '2025-03-05'),
(4, 61000, '2025-02-20'),
(5, 38000, '2024-12-12');

INSERT INTO service.insurances (vehicle_id, insurer, policy_number, valid_from, valid_to, info) VALUES
(1, 'Росгосстрах', 'POL1234567', '2024-02-01', '2025-02-01', 'КАСКО + ОСАГО'),
(2, 'Ингосстрах', 'POL7654321', '2023-06-01', '2024-06-01', 'ОСАГО'),
(3, 'Tesla Insurance', 'TESLA-9988', '2022-07-01', '2025-07-01', 'Полная страховка'),
(5, 'АльфаСтрахование', 'ALF-123456', '2024-03-01', '2025-03-01', 'КАСКО');

INSERT INTO service.vehicle_flags (vehicle_id, is_classic, used_in_taxi) VALUES
(1, FALSE, FALSE),
(2, FALSE, TRUE),
(3, FALSE, FALSE),
(4, FALSE, TRUE),
(5, FALSE, FALSE);

INSERT INTO service.moderators (user_id, role_id) VALUES
(5, 1),
(3, 2);

INSERT INTO service.contracts (ad_id, seller_id, buyer_user_id, amount, currency, status) VALUES
(1, 1, 4, 2300000, 'RUB', 'closed'),
(2, 2, 5, 1100000, 'RUB', 'active'),
(4, 4, 2, 2800000, 'RUB', 'pending');
