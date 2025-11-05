# Подзапросы в SQL

## 1. Подзапросы в SELECT (3 запроса)

### Определить количество объявлений у каждого продавца

```sql
SELECT s.seller_id,
       (SELECT COUNT(*) FROM service.ads a WHERE a.seller_id = s.seller_id) AS ads_count
FROM service.sellers s;
```

![](https://i.imgur.com/1NKcls2.png)

### Показать среднюю цену объявлений и добавить столбец с процентом от средней

```sql
SELECT ad_id, header_text, price,
       ROUND(price * 100.0 / (SELECT AVG(price) FROM service.ads), 2) AS percent_of_avg
FROM service.ads;
```
![](https://imgur.com/vzMT4wx.png)

### Показать автомобили и год самого нового автомобиля

```sql
SELECT brand, model, year_of_manufacture,
       (SELECT MAX(year_of_manufacture) FROM service.vehicles) AS newest_year
FROM service.vehicles;
```
![](https://imgur.com/3IWywq7.png)

---

## 2. Подзапросы во FROM (3 запроса)

### Вывести продавцов и средний рейтинг из подзапроса

```sql
SELECT s.seller_id, avg_data.avg_rating
FROM service.sellers s
LEFT JOIN (
    SELECT seller_id, ROUND(AVG(rating),2) AS avg_rating
    FROM service.feedbacks
    GROUP BY seller_id
) AS avg_data ON avg_data.seller_id = s.seller_id;
```
![](https://imgur.com/gvr4TJs.png)

### Показать автомобили старше среднего возраста

```sql
SELECT v.brand, v.model, v.year_of_manufacture
FROM service.vehicles v
JOIN (
    SELECT AVG(EXTRACT(YEAR FROM CURRENT_DATE) - year_of_manufacture) AS avg_age
    FROM service.vehicles
) AS t ON EXTRACT(YEAR FROM CURRENT_DATE) - v.year_of_manufacture > t.avg_age;
```
![](https://imgur.com/p9fasKY.png)

### Показать пользователей и количество объявлений в подзапросе

```sql
SELECT u.full_name, ad_data.ads_count
FROM service.users u
LEFT JOIN (
    SELECT s.user_id, COUNT(a.ad_id) AS ads_count
    FROM service.sellers s
    LEFT JOIN service.ads a ON a.seller_id = s.seller_id
    GROUP BY s.user_id
) AS ad_data ON ad_data.user_id = u.user_id;
```
![](https://imgur.com/CY9EKsy.png)

---

## 3. Подзапросы в WHERE (3 запроса)

### Показать автомобили с мощностью выше средней

```sql
SELECT brand, model, power_hp
FROM service.vehicles
WHERE power_hp > (SELECT AVG(power_hp) FROM service.vehicles);
```
![](https://imgur.com/NeqFRiM.png)

### Показать объявления с ценой выше средней по всем объявлениям

```sql
SELECT ad_id, header_text, price
FROM service.ads
WHERE price > (SELECT AVG(price) FROM service.ads);
```
![](https://imgur.com/xEYyGOb.png)

### Показать пользователей, у которых есть объявления

```sql
SELECT full_name, email
FROM service.users
WHERE user_id IN (
    SELECT s.user_id FROM service.sellers s JOIN service.ads a ON s.seller_id = a.seller_id
);
```
![](https://imgur.com/07ZqYug.png)

---

## 4. Подзапросы в HAVING (3 запроса)

### Показать продавцов с количеством объявлений больше среднего

```sql
SELECT seller_id, COUNT(ad_id) AS ads_count
FROM service.ads
GROUP BY seller_id
HAVING COUNT(ad_id) > (SELECT AVG(cnt) FROM (SELECT COUNT(*) AS cnt FROM service.ads GROUP BY seller_id) t);
```
![](https://imgur.com/CjZdaod.png)

### Показать годы выпуска, где больше одного автомобиля

```sql
SELECT year_of_manufacture, COUNT(*) AS cnt
FROM service.vehicles
GROUP BY year_of_manufacture
HAVING COUNT(*) > (SELECT AVG(c) FROM (SELECT COUNT(*) AS c FROM service.vehicles GROUP BY year_of_manufacture) q);
```
![](https://imgur.com/8bpkBoO.png)

### Показать пользователей, у которых больше среднего количества отзывов

```sql
SELECT user_id, COUNT(feedback_id) AS feedbacks
FROM service.feedbacks
GROUP BY user_id
HAVING COUNT(feedback_id) > (SELECT AVG(c) FROM (SELECT COUNT(*) AS c FROM service.feedbacks GROUP BY user_id) t);
```
![](https://imgur.com/0KmJ7P2.png)

---

## 5. Подзапросы с ALL (3 запроса)

### Найти автомобили мощнее всех электромобилей

```sql
SELECT brand, model, power_hp
FROM service.vehicles
WHERE power_hp > ALL (
    SELECT power_hp FROM service.vehicles v
    JOIN service.fuel_types f ON v.fuel_type_id = f.id
    WHERE f.code = 'electric'
);
```
![](https://imgur.com/G8bMpiI.png)

### Показать объявления дороже всех активных

```sql
SELECT ad_id, header_text, price
FROM service.ads
WHERE price > ALL (SELECT price FROM service.ads WHERE status_id = 1);
```
![](https://imgur.com/eIWlKKf.png)

### Показать автомобили новее всех 2015 года

```sql
SELECT brand, model, year_of_manufacture
FROM service.vehicles
WHERE year_of_manufacture > ALL (SELECT 2015);
```
![](https://imgur.com/QcfNocZ.png)

---

## 6. Подзапросы с IN (3 запроса)

### Найти автомобили, участвующие в объявлениях

```sql
SELECT brand, model
FROM service.vehicles
WHERE vehicle_id IN (SELECT vehicle_id FROM service.ads);
```
![](https://imgur.com/Opm2V9X.png)

### Найти пользователей, которые являются продавцами

```sql
SELECT full_name, email
FROM service.users
WHERE user_id IN (SELECT user_id FROM service.sellers);
```
![](https://imgur.com/xSurUTV.png)

### Найти отзывы по существующим объявлениям

```sql
SELECT feedback_id, text
FROM service.feedbacks
WHERE ad_id IN (SELECT ad_id FROM service.ads);
```
![](https://imgur.com/7RJwdbN.png)

---

## 7. Подзапросы с ANY (3 запроса)

### Найти автомобили, мощность которых больше любой мощности дизельных автомобилей 

```sql
SELECT brand, model, power_hp
FROM service.vehicles
WHERE power_hp > ANY (
    SELECT power_hp FROM service.vehicles v
    JOIN service.fuel_types f ON v.fuel_type_id = f.id
    WHERE f.code = 'diesel'
);
```
![](https://imgur.com/4Wk2RKn.png)

### Найти объявления, цена которых меньше любой цены проданных

```sql
SELECT ad_id, price
FROM service.ads
WHERE price < ANY (SELECT price FROM service.ads WHERE status_id = 3);
```
![](https://imgur.com/jY5yyue.png)

### Найти автомобили, год выпуска которых меньше любого из 2020, 2022, 2019

```sql
SELECT brand, model, year_of_manufacture
FROM service.vehicles
WHERE year_of_manufacture < ANY (VALUES (2020), (2022), (2019));
```
![](https://imgur.com/WcoEibY.png)

---

## 8. Подзапросы с EXISTS (3 запроса)

### Найти пользователей, у которых есть объявления

```sql
SELECT u.full_name
FROM service.users u
WHERE EXISTS (
    SELECT 1 FROM service.sellers s JOIN service.ads a ON s.seller_id = a.seller_id
    WHERE s.user_id = u.user_id
);
```
![](https://imgur.com/R1ygJrn.png)

### Найти автомобили, у которых есть страховка

```sql
SELECT brand, model
FROM service.vehicles v
WHERE EXISTS (
    SELECT 1 FROM service.insurances i WHERE i.vehicle_id = v.vehicle_id
);
```
![](https://imgur.com/DBzuD8D.png)

### Найти продавцов, у которых есть отзывы

```sql
SELECT s.seller_id
FROM service.sellers s
WHERE EXISTS (
    SELECT 1 FROM service.feedbacks f WHERE f.seller_id = s.seller_id
);
```
![](https://imgur.com/ae4eVic.png)

---

## 9. Подзапросы со сравнением по нескольким столбцам (3 запроса)

### Найти автомобили с одинаковым состоянием и типом трансмиссии

```sql
SELECT brand, model, year_of_manufacture
FROM service.vehicles v1
WHERE state_code IN (
    SELECT state_code
    FROM service.vehicles
    GROUP BY state_code
    HAVING COUNT(*) > 1
);
```
![](https://imgur.com/ioD1DcM.png)

### Найти объявления, относящиеся к одной и той же марке и году выпуска автомобиля

```sql
SELECT a.ad_id, v.brand, v.state_code, v.fuel_type_id
FROM service.ads a
JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
WHERE (v.state_code, v.fuel_type_id) IN (
    SELECT state_code, fuel_type_id
    FROM service.vehicles
    GROUP BY state_code, fuel_type_id
    HAVING COUNT(*) > 1
);
```
![](https://imgur.com/7TcQ4Na.png)

### Найти объявления, у которых совпадает статус и тип топлива автомобиля

```sql
SELECT a.ad_id, a.status_id, v.fuel_type_id
FROM service.ads a
JOIN service.vehicles v ON v.vehicle_id = a.vehicle_id
WHERE (a.status_id, v.fuel_type_id) IN (
    SELECT a2.status_id, v2.fuel_type_id
    FROM service.ads a2
    JOIN service.vehicles v2 ON v2.vehicle_id = a2.vehicle_id
    GROUP BY a2.status_id, v2.fuel_type_id
    HAVING COUNT(*) > 1
);

```
![](https://imgur.com/kJijFH9.png)

---

# Коррелированные подзапросы (5 запросов)

### Найти автомобили, у которых есть хотя бы одно объявление

```sql
SELECT v.brand, v.model
FROM service.vehicles v
WHERE EXISTS (SELECT 1 FROM service.ads a WHERE a.vehicle_id = v.vehicle_id);
```
![](https://imgur.com/y5R4LOw.png)

### Найти продавцов, у которых средняя цена объявлений выше 20000

```sql
SELECT s.seller_id
FROM service.sellers s
WHERE (SELECT AVG(price) FROM service.ads a WHERE a.seller_id = s.seller_id) > 20000;
```
![](https://imgur.com/iIJASOU.png)

### Найти продавцов, у которых есть хотя бы одно проданное объявление

```sql
SELECT s.seller_id, u.full_name
FROM service.sellers s
JOIN service.users u ON u.user_id = s.user_id
WHERE EXISTS (
    SELECT 1
    FROM service.ads a
    JOIN service.ad_statuses st ON st.id = a.status_id
    WHERE a.seller_id = s.seller_id AND st.code = 'sold'
);
```
![](https://imgur.com/lW1l7zd.png)

### Найти пользователей, которые хоть раз покупали машину через контракт

```sql
SELECT u.user_id, u.full_name
FROM service.users u
WHERE EXISTS (
    SELECT 1
    FROM service.contracts c
    WHERE c.buyer_user_id = u.user_id
);
```
![](https://imgur.com/mMitdhj.png)

### Найти объявления, где цена выше средней для того же продавца

```sql
SELECT a.ad_id, a.price
FROM service.ads a
WHERE a.price > (SELECT AVG(price) FROM service.ads a2 WHERE a2.seller_id = a.seller_id);
```
![](https://imgur.com/ashSarc.png)
