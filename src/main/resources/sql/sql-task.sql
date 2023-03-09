--Вывести к каждому самолету класс обслуживания и количество мест этого класса
SELECT ad.model->>lang() model,
       s.fare_conditions,
       count(fare_conditions) seats
FROM aircrafts_data ad
JOIN seats s
ON ad.aircraft_code = s.aircraft_code
GROUP BY ad.model,
         s.fare_conditions;
--Найти 3 самых вместительных самолета (модель + кол-во мест)
SELECT ad.model->>lang(),
       count(seat_no) seats
FROM aircrafts_data ad
JOIN seats s
ON ad.aircraft_code = s.aircraft_code
GROUP BY ad.model
ORDER BY seats DESC
LIMIT 3;
--Вывести код,модель самолета и места не эконом класса для самолета
--'Аэробус A321-200' с сортировкой по местам
SELECT ad.aircraft_code,
       ad.model->>lang() model,
       s.seat_no,
       s.fare_conditions
FROM aircrafts_data ad
JOIN seats s
ON ad.aircraft_code = s.aircraft_code
WHERE ad.model @> '{"ru":"Аэробус A321-200"}'
AND s.fare_conditions NOT LIKE 'Economy'
ORDER BY s.seat_no;
--Вывести города в которых больше 1 аэропорта ( код аэропорта, аэропорт, город)
SELECT airport_code,
       airport_name->lang() airport_name,
       city->>lang() city
FROM airports_data
WHERE city IN (
SELECT city
FROM airports_data
GROUP BY city
HAVING count(city) > 1);
-- Найти ближайший вылетающий рейс из Екатеринбурга в Москву,
--на который еще не завершилась регистрация
SELECT * FROM flights
WHERE departure_airport IN(
		SELECT airport_code
		FROM airports_data
		WHERE city @> '{"ru":"Екатеринбург"}')
AND arrival_airport IN (
        SELECT airport_code
		FROM airports_data
		WHERE city @> '{"ru":"Москва"}')
AND status IN ('Scheduled')
ORDER BY scheduled_departure
LIMIT 1;
--Вывести самый дешевый и дорогой билет и стоимость ( в одном результирующем ответе)
SELECT ticket_no,
       amount
FROM (SELECT ticket_no,
             amount
      FROM ticket_flights
      ORDER BY amount
      LIMIT 1) cheapest_ticket
UNION
SELECT ticket_no,
       amount
FROM (SELECT ticket_no,
             amount
      FROM ticket_flights
      ORDER BY amount DESC
      LIMIT 1) most_expensive_ticket;
-- Написать DDL таблицы Customers , должны быть поля id , firstName, LastName,
--email , phone. Добавить ограничения на поля ( constraints).
CREATE TABLE IF NOT EXISTS customers (
id BIGSERIAL,
first_name VARCHAR (50) NOT NULL,
last_name VARCHAR (50),
email VARCHAR (50) UNIQUE NOT NULL,
phone CHAR (13) CHECK(phone LIKE '+375%'),
PRIMARY KEY(id));
--Написать DDL таблицы Orders , должен быть id, customerId,	quantity.
--Должен быть внешний ключ на таблицу customers + ограничения
CREATE TABLE IF NOT EXISTS orders (
id BIGSERIAL PRIMARY KEY,
customerId BIGSERIAL NOT NULL REFERENCES customers(id),
quantity BIGINT);
--Написать 5 insert в эти таблицы
INSERT INTO customers (first_name, last_name, email, phone)
VALUES ('Ivan', 'Ivanov', 'Ivanov@gmail.com', '+375291111111'),
       ('Petr', 'Petrov', 'Petrov@gmail.com', '+375292222222'),
       ('Sidor', 'Sidorov', 'Sidorov@gmail.com', '+375293333333'),
       ('Sveta', 'Svetikova', 'Svetikova@gmail.com', '+375294444444'),
       ('Magamed', 'Magamedov', 'Magamedov@gmail.com', '+375295555555');
INSERT INTO orders (customerId, quantity)
VALUES (1, 21),
       (2, 45),
       (3, 63),
       (4, 2),
       (5, 1);
-- удалить таблицы
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
--Написать свой кастомный запрос ( rus + sql)
--Вывести полную информацию о бронированиях пассажиров в чьих фамилиях присутствует
--суффикс "ov", рейсы должны быть выполненными, информация отсортирована по стоимости,
--города отправления и прибытия вывеести вместе с кодом аэропорта
SELECT b.book_ref,
       t.ticket_no,
       t.passenger_id,
       t.passenger_name,
       tf.fare_conditions,
       tf.amount,
       f.scheduled_departure_local,
       f.scheduled_arrival_local,
       concat(f.departure_city,' (',f.departure_airport, ')') departure,
       concat(f.arrival_city,' (',f.arrival_airport, ')') arrival,
       bp.seat_no
FROM   bookings b
JOIN tickets t ON b.book_ref = t.book_ref
JOIN ticket_flights tf ON tf.ticket_no = t.ticket_no
JOIN flights_v f ON tf.flight_id = f.flight_id
LEFT JOIN boarding_passes bp ON tf.flight_id = bp.flight_id
                            AND tf.ticket_no = bp.ticket_no
WHERE t.passenger_name ILIKE '%ov%'
AND f.status LIKE 'Arrived'
ORDER BY tf.amount DESC;
