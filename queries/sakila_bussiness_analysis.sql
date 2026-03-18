-- =====================================================
-- Project: Movie Rental Business Analysis
-- Database: Sakila
-- Tools Used: SQL (MySQL)
-- Author: Pankaj Juyal
-- =====================================================

USE sakila;

-- Total number of customers
SELECT COUNT(*) AS total_customers
FROM customer;

-- Active vs inactive customers
SELECT active, COUNT(*) AS customer_count
FROM customer
GROUP BY active;

-- Total revenue
SELECT SUM(amount) AS total_revenue
FROM payment;

-- Top 10 customers by total spending
SELECT c.customer_id, c.first_name, c.last_name,
       SUM(p.amount) AS total_spent
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 10;

-- customers with no payment
select c.first_name,c.last_name
From customer c
where not exists
(select 1 from payment p  where c.customer_id=p.customer_id);

-- Monthly revenue trend
SELECT 
    DATE_FORMAT(payment_date, '%Y-%m') AS month,
    SUM(amount) AS revenue
FROM payment
GROUP BY month
ORDER BY month;

-- Revenue per store
SELECT s.store_id, SUM(p.amount) AS revenue
FROM payment p
JOIN staff st ON p.staff_id = st.staff_id
JOIN store s ON st.store_id = s.store_id
GROUP BY s.store_id;

-- films hving more rental then average rental
SELECT f.title
FROM film f
join inventory i on f.film_id = i.film_id
join rental r on i.inventory_id=r.inventory_id
group by f.film_id,f.title
having count(r.rental_id)>(select avg (rental_count) from (SELECT count(r.rental_id) AS rental_count
FROM film f
join inventory i on f.film_id = i.film_id
join rental r on i.inventory_id=r.inventory_id
group by f.film_id) as avg_table);

-- Customer segmentation based on spending
WITH customer_spending AS (
    SELECT customer_id, SUM(amount) AS total_spent
    FROM payment
    GROUP BY customer_id
)
SELECT *,
CASE 
    WHEN total_spent > 150 THEN 'High'
    WHEN total_spent >= 100 THEN 'Medium'
    ELSE 'Low'
END AS customer_segment
FROM customer_spending;

-- Least rented films
SELECT f.title, COUNT(r.rental_id) AS rental_count
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY f.title
ORDER BY rental_count ASC
LIMIT 10;

-- Number of films per category
SELECT c.name, COUNT(fc.film_id) AS total_films
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
GROUP BY c.name;

-- staff who handled most rentals
select s.first_name,s.last_name,count(r.rental_id) as total_rentals
from rental r
join staff s
on r.staff_id=s.staff_id
group by s.staff_id
order by total_rentals DESC
limit 1; 

-- Most popular categories
SELECT c.name, COUNT(r.rental_id) AS total_rentals
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN inventory i ON fc.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY c.name
ORDER BY total_rentals DESC;

-- films with their rating category
select title,rating,
case
    when rating  in ('G','PG') then'Family'
    when rating = 'PG-13' then 'teen'
    when rating =  'R' then 'adult'
    when rating = 'NC-17' then 'restricted'
end as rating_category
from film;    

--  top 5 customer who rented the most films 
select c.customer_id,count(r.rental_id) AS total_rentals
from customer c
join rental r
on c.customer_id=r.customer_id
group by c.customer_id
order by total_rentals DESC
limit 5; 

-- top 3 films per category based on rentals
WITH category_films AS (
    SELECT 
        f.film_id,
        f.title,
        c.name AS category_name,
        COUNT(r.rental_id) AS rental_count
    FROM film f
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    GROUP BY f.film_id, f.title, c.name
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY rental_count DESC) AS rn
    FROM category_films
)
SELECT *
FROM ranked
WHERE rn <= 3;

