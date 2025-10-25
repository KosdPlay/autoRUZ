# Агрегатные запросы и группировки

## 1. Агрегатные функции

### 1.1 COUNT() - Количество объявлений по статусам
Что хотим получить: Статистику по количеству объявлений в каждом статусе

```sql
SELECT 
    ast.name AS status_name,
    COUNT(a.ad_id) AS ads_count
FROM service.ads a
JOIN service.ad_statuses ast ON a.status_id = ast.id
GROUP BY ast.name;
```
<img width="361" height="146" alt="image" src="https://github.com/user-attachments/assets/e9bc5022-03b9-4038-8262-85eebaae5474" />


### 1.2 SUM(), AVG() - Суммарная и средняя стоимость по маркам
Что хотим получить: Аналитику по стоимости автомобилей разных марок

```sql
SELECT 
    v.brand AS марка,
    COUNT(a.ad_id) AS количество,
    SUM(a.price) AS общая_стоимость,
    ROUND(AVG(a.price), 2) AS средняя_цена
FROM service.ads a
JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
GROUP BY v.brand;
```
<img width="676" height="204" alt="image" src="https://github.com/user-attachments/assets/063e4042-1684-477b-b15d-59f519f2ceab" />


## 2. GROUP BY, HAVING
### 2.1 GROUP BY - Продавцы с количеством объявлений
Что хотим получить: Рейтинг продавцов по количеству активных объявлений

```sql
SELECT 
    s.seller_id,
    u.full_name AS продавец,
    COUNT(a.ad_id) AS активных_объявлений
FROM service.sellers s
JOIN service.users u ON s.user_id = u.user_id
LEFT JOIN service.ads a ON s.seller_id = a.seller_id AND a.status_id = 1
GROUP BY s.seller_id, u.full_name
ORDER BY активных_объявлений DESC;
```
<img width="554" height="174" alt="image" src="https://github.com/user-attachments/assets/167e429f-eb3f-45c7-8f8c-9a78c338a584" />


### 2.2 HAVING - Марки со средней ценой выше 3 млн
Что хотим получить: Премиальные марки автомобилей с высокой средней стоимостью

```sql
SELECT 
    v.brand AS марка,
    COUNT(*) AS количество,
    ROUND(AVG(a.price), 2) AS средняя_цена
FROM service.ads a
JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
GROUP BY v.brand
HAVING AVG(a.price) > 3000000
ORDER BY средняя_цена DESC;
```
<img width="508" height="112" alt="image" src="https://github.com/user-attachments/assets/0f273ff9-0992-4b66-8219-49608a282570" />


## 3. GROUPING SETS, ROLLUP и CUBE
### 3.1 ROLLUP - Иерархическая статистика по типам кузова и топлива
Что хотим получить: Многоуровневую статистику с промежуточными итогами

```sql
SELECT 
    COALESCE(bt.name, 'ВСЕ ТИПЫ') AS тип_кузова,
    COALESCE(ft.name, 'ВСЕ ВИДЫ ТОПЛИВА') AS тип_топлива,
    COUNT(*) AS количество,
    AVG(v.power_hp) AS средняя_мощность
FROM service.vehicles v
LEFT JOIN service.body_types bt ON v.body_type_id = bt.id
LEFT JOIN service.fuel_types ft ON v.fuel_type_id = ft.id
GROUP BY ROLLUP (bt.name, ft.name)
ORDER BY bt.name, ft.name;
```
<img width="700" height="360" alt="image" src="https://github.com/user-attachments/assets/46d0cb07-dd68-4df9-a83c-688ebb8b2356" />


### 3.2 CUBE - Многомерная аналитика по состоянию и типу трансмиссии
Что хотим получить: Все возможные комбинации анализа по состоянию и КПП

```sql
SELECT 
    COALESCE(v.state_code, 'ВСЕ СОСТОЯНИЯ') AS состояние,
    COALESCE(t.name, 'ВСЕ КПП') AS коробка_передач,
    COUNT(*) AS количество_авто,
    MIN(v.power_hp) AS мин_мощность,
    MAX(v.power_hp) AS макс_мощность
FROM service.vehicles v
LEFT JOIN service.transmissions t ON v.transmission_id = t.id
GROUP BY CUBE (v.state_code, t.name)
ORDER BY v.state_code, t.name;
```
<img width="838" height="301" alt="image" src="https://github.com/user-attachments/assets/34464401-a689-4b12-95c8-beb9aac31baa" />


## 4. Полный синтаксис SELECT
### 4.1 Полная структура - Детальная статистика по продавцам
Что хотим получить: Комплексный отчет по продавцам с фильтрацией и сортировкой

```sql
SELECT 
    u.full_name AS продавец,
    s.seller_type AS тип_продавца,
    COUNT(a.ad_id) AS всего_объявлений,
    SUM(CASE WHEN a.status_id = 1 THEN 1 ELSE 0 END) AS активных,
    AVG(a.price) AS средняя_цена,
    STRING_AGG(DISTINCT v.brand, ', ') AS бренды
FROM service.sellers s
JOIN service.users u ON s.user_id = u.user_id
LEFT JOIN service.ads a ON s.seller_id = a.seller_id
LEFT JOIN service.vehicles v ON a.vehicle_id = v.vehicle_id
WHERE a.price > 0
GROUP BY u.full_name, s.seller_type
HAVING COUNT(a.ad_id) > 0
ORDER BY всего_объявлений DESC, средняя_цена DESC;
```
<img width="1023" height="166" alt="image" src="https://github.com/user-attachments/assets/274f1c3b-f3a2-45f6-a90c-218e04dffdbb" />


### 4.2 STRING_AGG() - Агрегация данных в строку
Что хотим получить: Сводную информацию по моделям в рамках каждой марки

```sql
SELECT 
    v.brand AS марка,
    COUNT(*) AS количество,
    STRING_AGG(CONCAT(v.model, ' (', v.year_of_manufacture, ')'), '; ') AS модели_и_годы,
    ROUND(AVG(a.price), 2) AS средняя_цена
FROM service.vehicles v
JOIN service.ads a ON v.vehicle_id = a.vehicle_id
GROUP BY v.brand
HAVING COUNT(*) >= 1
ORDER BY количество DESC;
```
<img width="658" height="206" alt="image" src="https://github.com/user-attachments/assets/416e5fc1-d896-407f-b13b-eab81bb88c3e" />
