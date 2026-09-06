-- ============================================================
-- Olist E-Commerce Customer & Sales Analytics
-- Sales Analysis
-- ============================================================

-- Note:
-- Unless otherwise stated, sales metrics include delivered
-- orders only.
--
-- Product Sales = SUM(order_items.price)
-- Freight Value = SUM(order_items.freight_value)
-- Total Order Value = Product Sales + Freight Value

-- 1. What are the overall sales KPIs?

SELECT
    ROUND(SUM(oi.price), 2) AS total_product_sales,
    ROUND(SUM(oi.freight_value), 2) AS total_freight_value,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_order_value,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

-- Calculating average order value

WITH order_totals AS
(
    SELECT
        o.order_id,
        SUM(oi.price) AS order_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id
)

SELECT
    ROUND(AVG(order_sales), 2) AS average_order_value
FROM order_totals;

-- 2. How have sales changed over time?

SELECT
    STRFTIME('%Y-%m', o.order_purchase_timestamp) AS month,
    ROUND(SUM(oi.price), 2) AS product_sales
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;

-- 3. Monthly sales + orders + AOV

WITH order_totals AS
(
    SELECT
        o.order_id,
        o.order_purchase_timestamp,
        SUM(oi.price) AS order_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        o.order_id,
        o.order_purchase_timestamp
)

SELECT
    STRFTIME('%Y-%m', order_purchase_timestamp) AS year_month,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_sales), 2) AS product_sales,
    ROUND(AVG(order_sales), 2) AS average_order_value

FROM order_totals
GROUP BY year_month
ORDER BY year_month;

-- 4. What is the month-over-month sales growth?

WITH monthly_sales AS
(
    SELECT
        STRFTIME('%Y-%m', o.order_purchase_timestamp) AS month,
        SUM(oi.price) AS product_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY month
),

sales_with_previous_month AS
(
    SELECT
        month,
        product_sales,

        LAG(product_sales) OVER (
            ORDER BY month
        ) AS previous_month_sales
    FROM monthly_sales
)

SELECT
    month,
    ROUND(product_sales, 2) AS product_sales,
    ROUND(previous_month_sales, 2) AS previous_month_sales,
    ROUND(
        100.0 *
        (product_sales - previous_month_sales)
        / NULLIF(previous_month_sales, 0),
        2
    ) AS monthly_growth_pct
    
FROM sales_with_previous_month
ORDER BY month;

-- 5. Which states generate the most sales?

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS product_sales
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY product_sales DESC;

-- including AOV

WITH order_totals AS
(
    SELECT
        o.order_id,
        c.customer_state,
        SUM(oi.price) AS order_sales
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        o.order_id,
        c.customer_state
)

SELECT
    customer_state,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_sales), 2) AS product_sales,
    ROUND(AVG(order_sales), 2) AS average_order_value
FROM order_totals
GROUP BY customer_state
ORDER BY product_sales DESC;

-- 6. Which product categories generate the most sales?

SELECT
    COALESCE(
        ct.product_category_name_english,
        'Unknown'
    ) AS category,

    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS product_sales
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name =
       ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY product_sales DESC;

-- 7. Top 10 categories by sales

SELECT
    COALESCE(
        ct.product_category_name_english,
        'Unknown'
    ) AS category,

    ROUND(SUM(oi.price), 2) AS product_sales
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name =
       ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY product_sales DESC
LIMIT 10;

-- 8. Which orders have the highest values?

SELECT
    o.order_id,
    c.customer_state,
    COUNT(*) AS number_of_items,
    ROUND(SUM(oi.price), 2) AS order_sales
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY
    o.order_id,
    c.customer_state
ORDER BY order_sales DESC
LIMIT 20;

-- 9. How much do customers pay for freight relative to products?

SELECT
    ROUND(SUM(oi.price), 2) AS product_sales,
    ROUND(SUM(oi.freight_value), 2) AS freight_value,
    ROUND(
    	100.0 * SUM(oi.freight_value) / SUM(oi.price),
    	2
	) AS freight_as_pct_of_product_sales
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

-- by state

SELECT
    c.customer_state,
    ROUND(SUM(oi.price), 2) AS product_sales,
    ROUND(SUM(oi.freight_value), 2) AS freight_value,
    ROUND(
    	100.0 * SUM(oi.freight_value) / SUM(oi.price),
    	2
    ) AS freight_pct

FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY freight_pct DESC;

-- 10. How has Average Order Value changed over time?

WITH order_totals AS
(
    SELECT
        o.order_id,
        o.order_purchase_timestamp,
        SUM(oi.price) AS order_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        o.order_id,
        o.order_purchase_timestamp
)

SELECT
    STRFTIME(
        '%Y-%m',
        order_purchase_timestamp
    ) AS year_month,
    ROUND(
        AVG(order_sales),
        2
    ) AS average_order_value

FROM order_totals
GROUP BY year_month
ORDER BY year_month;

