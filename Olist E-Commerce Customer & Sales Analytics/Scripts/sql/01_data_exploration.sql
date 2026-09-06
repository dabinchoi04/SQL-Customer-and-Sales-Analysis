-- ============================================================
-- Olist E-Commerce Customer & Sales Analytics
-- Exploratory Data Analysis
-- ============================================================

-- 1. How many orders are in the dataset?

SELECT
    COUNT(*) AS total_orders
FROM orders;

-- 2. How many unique customers?

SELECT
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers;

-- 3. How many products?

SELECT
    COUNT(DISTINCT product_id) AS total_products
FROM products;

-- 4. How many sellers?

SELECT
    COUNT(DISTINCT seller_id) AS total_sellers
FROM sellers;

-- 5. How many product categories?

SELECT
    COUNT(DISTINCT product_category_name_english)
        AS total_product_categories
FROM category_translation;

-- 6. What period does the dataset cover?

SELECT
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM orders;

-- 7. What are the different order statuses?

SELECT
    order_status,
    COUNT(*) AS number_of_orders
FROM orders
GROUP BY order_status
ORDER BY number_of_orders DESC;

-- 8. How are customers located?

SELECT
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS customers
FROM customers
GROUP BY customer_state
ORDER BY customers DESC;

-- top 10 cities

SELECT
    customer_city,
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS customers
FROM customers
GROUP BY
    customer_city,
    customer_state
ORDER BY customers DESC
LIMIT 10;

-- 9. What payment methods are used?

SELECT
    payment_type,
    COUNT(*) AS payment_records
FROM order_payments
GROUP BY payment_type
ORDER BY payment_records DESC;

-- 10. How many installments do customers use?

SELECT
    payment_installments,
    COUNT(*) AS payment_records
FROM order_payments
GROUP BY payment_installments
ORDER BY payment_installments;

-- 11. What are the review score distributions?
SELECT
    review_score,
    COUNT(*) AS number_of_reviews
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

-- 12. How many order items does an order contain?

SELECT
    order_id,
    COUNT(*) AS number_of_line_items
FROM order_items
GROUP BY order_id
ORDER BY number_of_line_items DESC
LIMIT 20;

-- 13. Examine category distribution

SELECT
    ct.product_category_name_english AS category,
    COUNT(DISTINCT p.product_id) AS number_of_products
FROM products p
LEFT JOIN category_translation ct
    ON p.product_category_name =
       ct.product_category_name
GROUP BY ct.product_category_name_english
ORDER BY number_of_products DESC;
