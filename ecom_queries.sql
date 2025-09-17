-- Total sales amount

SELECT SUM(total_price)
FROM order_items;

-- sales amount by year 

SELECT SUM(oi.total_price) AS sales_amount, 
		EXTRACT(YEAR FROM o.order_date ) AS extracted_year
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
GROUP BY extracted_year
ORDER BY extracted_year ASC;

-- orders xount by year

SELECT COUNT(order_id) AS order_count,
		EXTRACT(YEAR FROM order_date ) AS extracted_year
FROM orders
GROUP BY extracted_year
ORDER BY extracted_year ASC;

-- Sales by product category ALL TIME

SELECT p.category, 
		SUM(oi.total_price) AS product_sales
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY product_sales DESC;

-- AVERAGE ORDER VALUE (ALL TIME)

WITH order_totals AS (
  SELECT order_id, SUM(total_price) AS order_total
  FROM order_items
  GROUP BY order_id
)
SELECT ROUND(AVG(order_total),2) AS avg_order_value
FROM order_totals;

-- AVERAGE ORDER VALUE BY YEAR

WITH order_totals AS (
  SELECT oi.order_id, 
  	SUM(oi.total_price) AS order_total,
	EXTRACT(YEAR FROM o.order_date) AS extracted_year
  FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  WHERE o.order_status != 'Cancelled'
  GROUP BY oi.order_id, extracted_year
)
SELECT ROUND(AVG(order_total),2) AS avg_order_value, extracted_year
FROM order_totals
GROUP BY extracted_year
ORDER BY extracted_year ASC;

-- SALES VALUE PER COUNTRY

WITH order_totals AS (
	SELECT oi.order_id, 
		SUM(oi.total_price) AS order_total,
		c.country AS country
	FROM order_items oi
	JOIN orders o ON o.order_id = oi.order_id
	JOIN customers c ON c.customer_id = o.customer_id
	WHERE o.order_status != 'Cancelled'
	GROUP BY c.country, oi.order_id
	
)

SELECT SUM(order_total), country
FROM order_totals
GROUP BY country
ORDER BY SUM(order_total) DESC;

-- SALES VALUE PER COUNTRY PER YEAR 

WITH order_totals AS (
	SELECT oi.order_id, 
		SUM(oi.total_price) AS order_total,
		c.country AS country,
		EXTRACT(YEAR FROM o.order_date) AS extracted_year
	FROM order_items oi
	JOIN orders o ON o.order_id = oi.order_id
	JOIN customers c ON c.customer_id = o.customer_id
	WHERE o.order_status != 'Cancelled'
	GROUP BY c.country, oi.order_id, extracted_year
	
)

SELECT country, extracted_year, SUM(order_total)
FROM order_totals
GROUP BY country, extracted_year
ORDER BY extracted_year DESC;

-- TOP 5 customer who spent the most all time

SELECT c.customer_id, 
	c.first_name, 
	c.last_name, 
	SUM(oi.total_price) AS total_spent,
	COUNT(DISTINCT(oi.order_id)) AS order_count
FROM customers c 
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status != 'Cancelled'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 5;

-- TOP customers (3) for each year

WITH customer_totals AS (
  SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    EXTRACT(YEAR FROM o.order_date) AS year_extracted,
    SUM(oi.total_price) AS total_spent
  FROM customers c
  JOIN orders o     ON o.customer_id = c.customer_id
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.order_status != 'Cancelled'
  GROUP BY c.customer_id, c.first_name, c.last_name, year_extracted
),
ranked AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY year_extracted ORDER BY total_spent DESC) AS rn
  FROM customer_totals
)
SELECT rn, year_extracted, customer_id, first_name, last_name, total_spent
FROM ranked
WHERE rn <= 3
ORDER BY year_extracted, rn;

-- Customers who made only 1 order

SELECT customer_id
FROM orders
GROUP BY customer_id
HAVING COUNT(order_id) = 1
ORDER BY customer_id;

-- Classifying customers by their total spending and assigning loyalty levels

WITH loyalty AS (
  SELECT c.customer_id,
         SUM(oi.total_price) AS total_spent
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id
  JOIN order_items oi ON o.order_id = oi.order_id
  WHERE o.order_status != 'Cancelled'
  GROUP BY c.customer_id
)
SELECT *,
  CASE 
    WHEN total_spent < 5000 THEN 'Bronze'
    WHEN total_spent >= 5000  AND total_spent < 20000  THEN 'Silver'
    WHEN total_spent >= 20000 AND total_spent < 50000  THEN 'Gold'
    WHEN total_spent >= 50000 AND total_spent < 100000 THEN 'Platinum'
    ELSE 'Diamond'
  END AS loyalty_segment
FROM loyalty
ORDER BY total_spent DESC;

-- customers distribution by country

SELECT country, 
	COUNT(customer_id) AS customers_count,
	ROUND(COUNT(customer_id) * 100.0 / SUM(COUNT(customer_id)) OVER (), 2) AS percent_share
FROM customers
GROUP BY country
ORDER BY percent_share DESC;

-- How many orders there are of each possible status, also in %

SELECT order_status, 
	COUNT(order_status) AS how_many,
	ROUND(COUNT(order_status) * 100.0 / SUM(COUNT(order_status)) OVER (), 2) AS percent_share
FROM orders
GROUP BY order_status
ORDER BY how_many DESC;

--- Top 10 products by quantity sold

SELECT 
  p.product_id,
  p.product_name,
  SUM(oi.quantity) AS quantity_sold
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status != 'Cancelled'
GROUP BY p.product_id, p.product_name
ORDER BY quantity_sold DESC
LIMIT 10;

-- Top 10 products by revenue

SELECT 
  p.product_id,
  p.product_name,
  SUM(oi.total_price) AS total_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status != 'Cancelled'
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

-- Which product categories are most profitable?

SELECT 
  p.category,
  SUM(oi.total_price) AS total_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status != 'Cancelled'
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Creating an index for faster filtering by order status and date /check EXPLAIN ANALYZE before/after

EXPLAIN ANALYZE
SELECT 
  p.product_id,
  p.product_name,
  SUM(oi.total_price) AS total_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status != 'Cancelled'
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

CREATE INDEX idx_orders_status_date ON orders(order_status, order_date);

EXPLAIN ANALYZE
SELECT 
  p.product_id,
  p.product_name,
  SUM(oi.total_price) AS total_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status != 'Cancelled'
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

-- CREATED A VIEW FOR SOME USEFUL QUERY and used it

CREATE VIEW top_products_by_revenue AS (

	SELECT 
  p.product_id,
  p.product_name,
  SUM(oi.total_price) AS total_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status != 'Cancelled'
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC
);

SELECT * 
FROM top_products_by_revenue
LIMIT 5;

SELECT *
FROM top_products_by_revenue
WHERE total_revenue > 1000000;

-- created function and used it

CREATE FUNCTION get_customer_total_spent(cust_id INT)
RETURNS NUMERIC AS $$
  SELECT COALESCE(SUM(oi.total_price), 0)
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  WHERE o.customer_id = cust_id
    AND o.order_status != 'Cancelled';
$$ LANGUAGE SQL;

SELECT get_customer_total_spent(203);

SELECT get_customer_total_spent(34);

SELECT get_customer_total_spent(578);










