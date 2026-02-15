INSERT INTO service.users (fullName, email, phoneNumber) VALUES
('Иван Иванов', 'ivan@example.com', '+79991234567'),
('Петр Петров', 'petr@example.com', '+79997654321'),
('Анна Смирнова', 'anna@example.com', '+79993456789'),
('Сергей Кузнецов', 'sergey@example.com', '+79991112233'),
('Мария Соколова', 'maria@example.com', '+79992223344');

INSERT INTO service.sellers (userId, typeOf, rating, countOfAds) VALUES
(1, 'individual', 4.50, 2),
(2, 'company', 3.75, 1),
(3, 'individual', 0.00, 0);

INSERT INTO service.moderator (userId, roleOf) VALUES
(1, 'editor'),
(2, 'viewer'),
(4, 'supervisor');

INSERT INTO service.transport (brand, model, yearOfManufacture, color, bodyType, transmission, fuelType, horsePower, stateOf, VIN) VALUES
('Toyota', 'Camry', 2018, 'Белый', 'sedan', 'automatic', 'petrol', 181, 'used', 'JT123456789012345'),
('BMW', 'X5', 2020, 'Черный', 'SUV', 'automatic', 'diesel', 249, 'used', 'WB123456789012345'),
('Tesla', 'Model 3', 2022, 'Красный', 'sedan', 'automatic', 'electric', 283, 'new', '5YJ12345678901234');

INSERT INTO service.advertisements (sellerId, transportId, headerText, description, costOf, status) VALUES
(1, 1, 'Toyota Camry 2018 в хорошем состоянии', 'Один хозяин, все ТО пройдены, зимняя резина в комплекте', 1500000, 'active'),
(2, 2, 'BMW X5 2020 дизель', 'Максимальная комплектация, пробег 30 тыс. км', 4500000, 'active'),
(3, 3, 'Tesla Model 3 новая', 'Электрокар, пробег 100 км, официальная гарантия', 5500000, 'in processing');

INSERT INTO service.photos (adId, url) VALUES
(1, 'http://example.com/camry1.jpg'),
(2, 'http://example.com/bmw1.jpg'),
(3, 'http://example.com/tesla1.jpg');

INSERT INTO service.carLibrary (transportId, ownersCount, ancients, milleage, insurancesInformation, usedInTaxi) VALUES
(1, 1, 'no', 60000, 'КАСКО, ОСАГО', 'no'),
(2, 1, 'no', 30000, 'ОСАГО, страхование жизни водителя', 'no'),
(3, 0, 'no', 100, 'ОСАГО, расширенная гарантия', 'no');

INSERT INTO service.favourites (userId, adId) VALUES
(4, 1),
(5, 2),
(1, 3);

INSERT INTO service.feedbacks (userId, sellerId, textOf, rating) VALUES
(1, 2, 'Все отлично, машина как новая!', 5.0),
(2, 1, 'Продавец ответственный, документы в порядке', 4.5),
(3, 3, 'Очень доволен покупкой Tesla, все честно!', 5.0);

INSERT INTO service.contracts (sellerId, transportId, amount, status) VALUES
(1, 1, 1500000, 'closed'),
(2, 2, 4500000, 'active'),
(3, 3, 5500000, 'pending');
