-- ============================================================
-- Olist E-Commerce Customer & Sales Analytics
-- Data Validation
-- ============================================================

-- Checking number of rows

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM customers

UNION ALL

SELECT 'orders', COUNT(*)
FROM orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM order_items

UNION ALL

SELECT 'payments', COUNT(*)
FROM order_payments

UNION ALL

SELECT 'reviews', COUNT(*)
FROM order_reviews

UNION ALL

SELECT 'products', COUNT(*)
FROM products

UNION ALL

SELECT 'sellers', COUNT(*)
FROM sellers

UNION ALL

SELECT 'geolocation', COUNT(*)
FROM geolocation

UNION ALL

SELECT 'category_translation', COUNT(*)
FROM category_translation;

-- Checking columns and data types

PRAGMA table_info(customers);

PRAGMA table_info(orders);

PRAGMA table_info(order_items);

-- Preview each table

SELECT *
FROM customers 
LIMIT 10;

SELECT *
FROM orders
LIMIT 10;

SELECT *
FROM order_items 
LIMIT 10;

SELECT *
FROM order_payments
LIMIT 10;

-- checking primary identifiers for duplicates

SELECT
    customer_id,
    COUNT(*) AS occurrences
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT
    order_id,
    COUNT(*) AS occurrences
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT
    product_id,
    COUNT(*) AS occurrences
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT
    seller_id,
    COUNT(*) AS occurrences
FROM sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;

SELECT
    order_id,
    order_item_id,
    COUNT(*) AS occurrences
FROM order_items
GROUP BY
    order_id,
    order_item_id
HAVING COUNT(*) > 1;

SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS occurrences
FROM order_payments
GROUP BY
    order_id,
    payment_sequential
HAVING COUNT(*) > 1;

SELECT
    review_id,
    order_id,
    COUNT(*) AS occurrences
FROM order_reviews
GROUP BY
    review_id,
    order_id
HAVING COUNT(*) > 1;

SELECT
    review_id,
    COUNT(*) AS occurrences
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1;

SELECT
    product_category_name,
    COUNT(*) AS occurrences
FROM category_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1;

-- Checking relationships between tables

SELECT COUNT(*) AS unmatched_orders
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS unmatched_order_items
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS unmatched_products
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT COUNT(*) AS unmatched_sellers
FROM order_items oi
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- Checking the date range

SELECT
	MIN(order_purchase_timestamp) AS first_order,
	MAX(order_purchase_timestamp) AS last_order
FROM orders;

-- For later monthly analysis

SELECT
    order_purchase_timestamp,
    DATE(order_purchase_timestamp) AS purchase_date,
    STRFTIME('%Y', order_purchase_timestamp) AS purchase_year,
    STRFTIME('%Y-%m', order_purchase_timestamp) AS purchase_month
FROM orders
LIMIT 10;

-- Checking numerical columns

SELECT
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    AVG(price) AS avg_price,
    MIN(freight_value) AS min_freight,
    MAX(freight_value) AS max_freight
FROM order_items;

SELECT
    MIN(payment_value) AS min_payment,
    MAX(payment_value) AS max_payment,
    AVG(payment_value) AS avg_payment
FROM order_payments;

SELECT
    review_score,
    COUNT(*) AS number_of_reviews
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

-- Checking NULL

SELECT
    COUNT(*) AS total_orders,

    SUM(CASE
        WHEN customer_id IS NULL
        THEN 1 ELSE 0
    END) AS missing_customer_id,

    SUM(CASE
        WHEN order_status IS NULL
        THEN 1 ELSE 0
    END) AS missing_order_status,

    SUM(CASE
        WHEN order_purchase_timestamp IS NULL
        THEN 1 ELSE 0
    END) AS missing_purchase_timestamp,

    SUM(CASE
        WHEN order_delivered_customer_date IS NULL
        THEN 1 ELSE 0
    END) AS missing_delivery_date

FROM orders;

SELECT
    COUNT(*) AS total_products,

    SUM(CASE
        WHEN product_category_name IS NULL
        THEN 1 ELSE 0
    END) AS missing_category

FROM products;

SELECT
    COUNT(*) AS total_reviews,

    SUM(CASE
        WHEN review_score IS NULL
        THEN 1 ELSE 0
    END) AS missing_review_score,

    SUM(CASE
        WHEN review_comment_title IS NULL
        THEN 1 ELSE 0
    END) AS missing_review_title,

    SUM(CASE
        WHEN review_comment_message IS NULL
        THEN 1 ELSE 0
    END) AS missing_review_message

FROM order_reviews;