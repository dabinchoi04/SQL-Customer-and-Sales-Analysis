-- ============================================================
-- Product Analysis
-- ============================================================

-- Note:
-- Product Sales = SUM(order_items.price), excluding freight.
--
-- Individual products are identified by product_id because
-- the dataset does not contain descriptive product names.

-- 1. Which individual products perform best?

WITH product_performance AS
(
    SELECT
        oi.product_id,
        COALESCE(
            ct.product_category_name_english,
            'Unknown'
        ) AS category,
        COUNT(*) AS items_sold,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
        ROUND(
            SUM(oi.price),
            2
        ) AS product_sales
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct
        ON p.product_category_name =
           ct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY
        oi.product_id,
        category
)

SELECT
    product_id,
    category,
    items_sold,
    total_orders,
    unique_customers,
    product_sales,
    RANK() OVER (
        ORDER BY product_sales DESC
    ) AS sales_rank,
    RANK() OVER (
        ORDER BY items_sold DESC
    ) AS units_rank
  
FROM product_performance
ORDER BY product_sales DESC
LIMIT 20;

-- 2. Which products have the strongest repeat-purchase behaviour? 

WITH customer_product_orders AS
(
    SELECT
        c.customer_unique_id,
        oi.product_id,
        COUNT(DISTINCT o.order_id)
            AS orders_with_product
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        c.customer_unique_id,
        oi.product_id
),

product_repeat_behavior AS
(
    SELECT
        product_id,
        COUNT(*) AS customers_who_bought,
        SUM(
            CASE
                WHEN orders_with_product >= 2
                THEN 1
                ELSE 0
            END
        ) AS repeat_customers
    FROM customer_product_orders
    GROUP BY product_id
)

SELECT
    pr.product_id,
    COALESCE(
        ct.product_category_name_english,
        'Unknown'
    ) AS category,
    pr.customers_who_bought,
    pr.repeat_customers,
    ROUND(
        100.0 * pr.repeat_customers
        / pr.customers_who_bought,
        2
    ) AS repeat_purchase_rate_pct

FROM product_repeat_behavior pr
JOIN products p
    ON pr.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name =
       ct.product_category_name
WHERE pr.customers_who_bought >= 10
ORDER BY
    repeat_purchase_rate_pct DESC,
    customers_who_bought DESC;

-- 3. How concentrated are sales across the product catalog?

WITH product_sales AS
(
    SELECT
        oi.product_id,
        SUM(oi.price) AS product_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.product_id
),

product_deciles AS
(
    SELECT
        product_id,
        product_sales,
        NTILE(10) OVER (
            ORDER BY product_sales DESC
        ) AS sales_decile
    FROM product_sales
)

SELECT
    sales_decile,
    COUNT(*) AS products,
    ROUND(
        SUM(product_sales),
        2
    ) AS product_sales,
    ROUND(
        100.0 * SUM(product_sales)
        / SUM(SUM(product_sales)) OVER (),
        2
    ) AS sales_share_pct

FROM product_deciles
GROUP BY sales_decile
ORDER BY sales_decile;

-- 4. Which categories have the highest average selling prices?

SELECT
    COALESCE(
        ct.product_category_name_english,
        'Unknown'
    ) AS category,
    COUNT(*) AS items_sold,
    ROUND(
        AVG(oi.price),
        2
    ) AS average_item_price,
    ROUND(
        MIN(oi.price),
        2
    ) AS minimum_item_price,
    ROUND(
        MAX(oi.price),
        2
    ) AS maximum_item_price

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
ORDER BY average_item_price DESC;

-- 5. Which categories generate the most sales per product?

SELECT
    COALESCE(
        ct.product_category_name_english,
        'Unknown'
    ) AS category,
    COUNT(DISTINCT oi.product_id)
        AS distinct_products_sold,

    COUNT(*) AS items_sold,
    ROUND(
        SUM(oi.price),
        2
    ) AS product_sales,
    ROUND(
        SUM(oi.price)
        / COUNT(DISTINCT oi.product_id),
        2
    ) AS sales_per_product,
    ROUND(
        1.0 * COUNT(*)
        / COUNT(DISTINCT oi.product_id),
        2
    ) AS items_sold_per_product

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
ORDER BY sales_per_product DESC;

-- 6. Which categories are most likely to appear multiple times in one order?

WITH order_category_items AS
(
    SELECT
        o.order_id,
        COALESCE(
            ct.product_category_name_english,
            'Unknown'
        ) AS category,
        COUNT(*) AS items_in_category
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct
        ON p.product_category_name =
           ct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY
        o.order_id,
        category
)

SELECT
    category,
    COUNT(*) AS orders_with_category,
    ROUND(
        AVG(items_in_category),
        2
    ) AS avg_items_per_order,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN items_in_category >= 2
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*),
        2
    ) AS multi_item_order_pct

FROM order_category_items
GROUP BY category
ORDER BY multi_item_order_pct DESC;

-- 7. How does product weight affect freight cost?

SELECT
    CASE

        WHEN p.product_weight_g < 500
            THEN 'Under 0.5 kg'

        WHEN p.product_weight_g < 1000
            THEN '0.5 - 1 kg'

        WHEN p.product_weight_g < 2000
            THEN '1 - 2 kg'

        WHEN p.product_weight_g < 5000
            THEN '2 - 5 kg'

        ELSE '5+ kg'

    END AS weight_group,
    COUNT(*) AS items_sold,
    ROUND(
        AVG(oi.price),
        2
    ) AS avg_product_price,
    ROUND(
        AVG(oi.freight_value),
        2
    ) AS avg_freight_value,
    ROUND(
        100.0 * SUM(oi.freight_value)
        / NULLIF(SUM(oi.price), 0),
        2
    ) AS freight_as_pct_of_product_sales

FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE
    o.order_status = 'delivered'
    AND p.product_weight_g IS NOT NULL
GROUP BY weight_group
ORDER BY
    MIN(p.product_weight_g);

-- 8. Which product categories are growing or declining year-over-year?
-- Note:
-- "Unknown" represents products with a missing product category or without a matching English category translation.
-- These products are retained so that valid sales are not excluded from the analysis.

WITH monthly_category_sales AS
(
    SELECT
        COALESCE(
            ct.product_category_name_english,
            'Unknown'
        ) AS category,
        CAST(
            STRFTIME(
                '%Y',
                o.order_purchase_timestamp
            ) AS INTEGER
        ) AS sales_year,
        CAST(
            STRFTIME(
                '%m',
                o.order_purchase_timestamp
            ) AS INTEGER
        ) AS sales_month,
        SUM(oi.price) AS product_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct
        ON p.product_category_name =
           ct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY
        category,
        sales_year,
        sales_month
)

SELECT
    current.category,
    current.sales_year,
    current.sales_month,
    ROUND(
        current.product_sales,
        2
    ) AS current_sales,
    ROUND(
        previous.product_sales,
        2
    ) AS previous_year_sales,
    ROUND(
        100.0 *
        (
            current.product_sales
            - previous.product_sales
        )
        / NULLIF(previous.product_sales, 0),
        2
    ) AS yoy_growth_pct
FROM monthly_category_sales current

JOIN monthly_category_sales previous
    ON current.category = previous.category
    AND current.sales_month = previous.sales_month
    AND current.sales_year =
        previous.sales_year + 1
ORDER BY
    current.category,
    current.sales_year,
    current.sales_month;