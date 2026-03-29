-- =====================================================
-- Project: Movie Rental Business Analysis (Dashboard Ready)
-- Database: Sakila
-- Tools Used: SQL (MySQL)
-- Author: Pankaj Juyal
-- =====================================================

USE sakila;

-- =====================================================
-- 1. BUSINESS OVERVIEW KPIs
-- =====================================================

-- Total Customers
SELECT COUNT(*) AS total_customers FROM customer;

-- Active vs Inactive Customers
SELECT active, COUNT(*) AS customer_count
FROM customer
GROUP BY active;

-- Total Revenue
SELECT SUM(amount) AS total_revenue FROM payment;

-- =====================================================
-- 2. CUSTOMER ANALYSIS
-- =====================================================

-- Top 10 Customers by Spending
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(p.amount) AS total_spent
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, customer_name
ORDER BY total_spent DESC
LIMIT 10;

-- Customers with No Payments
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name
FROM customer c
WHERE NOT EXISTS (
    SELECT 1 FROM payment p WHERE c.customer_id = p.customer_id
);

-- Customer Segmentation
WITH customer_spending AS (
    SELECT customer_id, SUM(amount) AS total_spent
    FROM payment
    GROUP BY customer_id
)
SELECT 
    customer_id,
    total_spent,
    CASE 
        WHEN total_spent > 150 THEN 'High'
        WHEN total_spent >= 100 THEN 'Medium'
        ELSE 'Low'
    END AS customer_segment
FROM customer_spending;

-- =====================================================
-- 3. REVENUE ANALYSIS
-- =====================================================

-- Monthly Revenue Trend
SELECT 
    DATE_FORMAT(payment_date, '%Y-%m') AS month,
    SUM(amount) AS revenue
FROM payment
GROUP BY month
ORDER BY month;

-- Revenue per Store
SELECT 
    s.store_id,
    SUM(p.amount) AS revenue
FROM payment p
JOIN staff st ON p.staff_id = st.staff_id
JOIN store s ON st.store_id = s.store_id
GROUP BY s.store_id;

-- =====================================================
-- 4. FILM & CATEGORY ANALYSIS
-- =====================================================

-- Most Popular Categories
SELECT 
    c.name AS category,
    COUNT(r.rental_id) AS total_rentals
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN inventory i ON fc.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY c.name
ORDER BY total_rentals DESC;

-- Number of Films per Category
SELECT 
    c.name AS category,
    COUNT(fc.film_id) AS total_films
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
GROUP BY c.name;

-- Least Rented Films
SELECT 
    f.title,
    COUNT(r.rental_id) AS rental_count
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY f.title
ORDER BY rental_count ASC
LIMIT 10;

-- Top 3 Films per Category
WITH category_films AS (
    SELECT 
        f.film_id,
        f.title,
        c.name AS category,
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
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY rental_count DESC) AS rn
    FROM category_films
)
SELECT * FROM ranked WHERE rn <= 3;

-- =====================================================
-- 5. OPERATIONAL ANALYSIS
-- =====================================================

-- Staff Performance
SELECT 
    CONCAT(s.first_name, ' ', s.last_name) AS staff_name,
    COUNT(r.rental_id) AS total_rentals
FROM rental r
JOIN staff s ON r.staff_id = s.staff_id
GROUP BY s.staff_id
ORDER BY total_rentals DESC;

-- =====================================================
-- 6. FINAL DATASETS FOR POWER BI (EXPORT THESE)
-- =====================================================

-- 1. Monthly Revenue (for Line Chart)
SELECT 
    DATE_FORMAT(payment_date, '%Y-%m') AS month,
    SUM(amount) AS revenue
FROM payment
GROUP BY month
ORDER BY month;

-- 2. Category Performance (for Bar Chart)
SELECT 
    c.name AS category,
    COUNT(r.rental_id) AS total_rentals
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN inventory i ON fc.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY c.name;

-- 3. Top Customers (for Table)
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(p.amount) AS total_spent
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, customer_name
ORDER BY total_spent DESC
LIMIT 20;

-- 4. Store Revenue ( for KPI / Card)
SELECT 
    s.store_id,
    SUM(p.amount) AS revenue
FROM payment p
JOIN staff st ON p.staff_id = st.staff_id
JOIN store s ON st.store_id = s.store_id
GROUP BY s.store_id;

