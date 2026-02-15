1. Выборка всех данных из таблицы  
1.1 Все записи из service.users  
```sql
SELECT * FROM service.users;
```
![](https://i.imgur.com/Nd1TS5W.png)

1.2 Все записи из service.vehicles  
```sql
SELECT * FROM service.vehicles;
```
![](https://i.imgur.com/2qIIpAp.png)

2. Выборка отдельных столбцов  
2.1 Имена и email пользователей  
```sql
SELECT full_name, email FROM service.users;
```
![](https://i.imgur.com/1FVb2eI.png)

2.2 Марка, модель и год выпуска автомобиля  
```sql
SELECT brand, model, year_of_manufacture FROM service.vehicles;
```
![](https://i.imgur.com/CigtGIr.png)

3. Присвоение новых имен столбцам  
3.1 Имя пользователя как "Имя", Email как "Почта"  
```sql
SELECT full_name AS "Имя", email AS "Почта" FROM service.users;
```
![](https://i.imgur.com/N2OvYjv.png)

3.2 Марка и модель автомобиля с новыми заголовками  
```sql
SELECT brand AS "Бренд", model AS "Модель" FROM service.vehicles;
```
![](https://i.imgur.com/Hht9wIc.png)

4. Выборка с вычисляемым столбцом  
4.1 Цена в рублях и долларах (курс 1$ = 100₽)  
```sql
SELECT ad_id, price, price / 100 AS price_usd FROM service.ads;
```
![](https://i.imgur.com/kHqcRc6.png)

4.2 Мощность двигателя в киловаттах  
```sql
SELECT vehicle_id, power_hp, ROUND(power_hp * 0.7355, 1) AS power_kw FROM service.vehicles;
```
![](https://i.imgur.com/3CNWkIn.png)

5. Логические функции и CASE  
5.1 Новый/не новый авто  
```sql
SELECT vehicle_id, state_code, 
       CASE WHEN state_code = 'new' THEN 'Новый' ELSE 'Не новый' END AS car_status 
FROM service.vehicles;
```
![](https://i.imgur.com/Rn7oRvw.png)

5.2 Человекочитаемый статус объявления  
```sql
SELECT ad_id, status_id, 
       CASE status_id 
            WHEN 1 THEN 'Активное'
            WHEN 2 THEN 'На модерации'
            WHEN 3 THEN 'Продано'
            ELSE 'Неизвестно'
       END AS ad_status
FROM service.ads;
```
![](https://i.imgur.com/GDYfbEi.png)

6. Выборка по условию  
6.1 Авто мощнее 200 л.с  
```sql
SELECT * FROM service.vehicles WHERE power_hp > 200;
```
![](https://i.imgur.com/wa9jVEQ.png)

6.2 Пользователи, зарегистрированные после 2024-01-01  
```sql
SELECT * FROM service.users WHERE registration_date > '2024-01-01';
```
![](https://i.imgur.com/mDjPPZ1.png)

7. Логические операции  
7.1 Объявления с ценой > 5 млн или мощность авто > 250  
```sql
SELECT a.*, v.power_hp 
FROM service.ads a
JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
WHERE a.price > 5000000 OR v.power_hp > 250;
```
![](https://i.imgur.com/9y7u9ic.png)

7.2 Авто не «черного» и не «белого» цвета  
```sql
SELECT * FROM service.vehicles WHERE color NOT IN ('Черный', 'Белый');
```
![](https://i.imgur.com/QE2xUFf.png)

8. BETWEEN, IN  
8.1 Объявления с ценой от 1 до 3 млн  
```sql
SELECT * FROM service.ads WHERE price BETWEEN 1000000 AND 3000000;
```
![](https://i.imgur.com/4m1tcQe.png)

8.2 Автомобили с типом кузова «седан» или «купе»  
```sql
SELECT * FROM service.vehicles 
WHERE body_type_id IN (SELECT id FROM service.body_types WHERE code IN ('sedan', 'coupe'));
```
![](https://i.imgur.com/7bh8NvB.png)

9. Сортировка  
9.1 Объявления по цене по убыванию  
```sql
SELECT * FROM service.ads ORDER BY price DESC;
```
![](https://i.imgur.com/keBazYh.png)

9.2 Пользователи по дате регистрации  
```sql
SELECT * FROM service.users ORDER BY registration_date ASC;
```
![](https://i.imgur.com/0OBr623.png)

10. LIKE  
10.1 Авто, где цвет начинается на «С»  
```sql
SELECT * FROM service.vehicles WHERE color LIKE 'С%';
```
![](https://i.imgur.com/kuDToKI.png)

10.2 Email пользователей содержит «lux»  
```sql
SELECT * FROM service.users WHERE email LIKE '%lux%';
```
![](https://i.imgur.com/HCvccPH.png)

11. Уникальные элементы  
11.1 Уникальные цвета авто  
```sql
SELECT DISTINCT color FROM service.vehicles;
```
![](https://i.imgur.com/z0D0jDv.png)

11.2 Уникальные типы продавцов  
```sql
SELECT DISTINCT seller_type FROM service.sellers;
```
![](https://i.imgur.com/Duyired.png)

12. Ограничение количества строк  
12.1 Первые 3 объявления  
```sql
SELECT * FROM service.ads LIMIT 3;
```
![](https://i.imgur.com/SDvM9Kq.png)

12.2 2 самых мощных авто  
```sql
SELECT * FROM service.vehicles ORDER BY power_hp DESC LIMIT 2;
```
![](https://i.imgur.com/pPA9GRl.png)

13. INNER JOIN  
13.1 Объявления с данными авто  
```sql
SELECT a.*, v.brand, v.model 
FROM service.ads a
INNER JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id;
```
![](https://i.imgur.com/LdXnFk5.png)

13.2 Отзывы с данными продавца  
```sql
SELECT f.*, s.seller_type, u.full_name 
FROM service.feedbacks f
INNER JOIN service.sellers s ON f.seller_id = s.seller_id
INNER JOIN service.users u ON s.user_id = u.user_id;
```
![](https://i.imgur.com/aImcnP5.png)

14. LEFT и RIGHT OUTER JOIN  
14.1 Авто и их страхование (LEFT JOIN)  
```sql
SELECT v.brand, v.model, i.insurer, i.policy_number
FROM service.vehicles v
LEFT JOIN service.insurances i ON v.vehicle_id = i.vehicle_id;
```
![](https://i.imgur.com/EHFQS2B.png)

14.2 Страховые записи и авто (RIGHT JOIN)  
```sql
SELECT i.insurer, i.policy_number, v.brand, v.model
FROM service.insurances i
RIGHT JOIN service.vehicles v ON i.vehicle_id = v.vehicle_id;
```
![](https://i.imgur.com/DOw9rix.png)

15. CROSS JOIN  
15.1 Все пользователи со всеми ролями модератора  
```sql
SELECT u.full_name, mr.name AS moderator_role
FROM service.users u
CROSS JOIN service.moderator_roles mr;
```
![](https://i.imgur.com/CbmNsUT.png)

15.2 Все типы кузова для всех продавцов  
```sql
SELECT s.seller_id, bt.name AS body_type
FROM service.sellers s
CROSS JOIN service.body_types bt;
```
![](https://i.imgur.com/DKyEBC6.png)

16. Запросы из нескольких таблиц  
16.1 Информация о продаже - покупатель, продавец, авто, цена  
```sql
SELECT c.contract_id, b.full_name AS buyer, s.seller_id, v.brand, v.model, c.amount
FROM service.contracts c
JOIN service.users b ON c.buyer_user_id = b.user_id
JOIN service.sellers s ON c.seller_id = s.seller_id
JOIN service.vehicles v ON s.seller_id = v.vehicle_id;
```
![](https://i.imgur.com/uBlwhOu.png)

16.2 Избранные объявления пользователя с авто  
```sql
SELECT f.user_id, a.header_text, v.brand, v.model
FROM service.favourites f
JOIN service.ads a ON f.ad_id = a.ad_id
JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id;
```
![](https://i.imgur.com/ryyJEE6.png)