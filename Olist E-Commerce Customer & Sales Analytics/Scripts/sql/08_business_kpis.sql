-- ============================================================
-- Business KPIs
-- ============================================================

-- Note:
-- This file consolidates key metrics from the preceding analyses
-- into dashboard-ready business KPI outputs.
--
-- Product Sales = SUM(order_items.price)
-- Total Order Value = Product Sales + Freight Value
-- Average Order Value is based on product sales, excluding freight.

-- 1. What are the key overall business KPIs?

-- 1. What are the key overall business KPIs?

WITH delivered_orders AS
(
    SELECT
        order_id,
        customer_id,
        order_purchase_timestamp,
        order_delivered_customer_date,
        order_estimated_delivery_date
    FROM orders
    WHERE order_status = 'delivered'
),

order_financials AS
(
    SELECT
        oi.order_id,
        SUM(oi.price) AS product_sales,
        SUM(oi.freight_value) AS freight_value,
        SUM(
            oi.price + oi.freight_value
        ) AS total_order_value,
        COUNT(*) AS items_in_order
    FROM order_items oi
    JOIN delivered_orders d
        ON oi.order_id = d.order_id
    GROUP BY oi.order_id
),

sales_kpis AS
(
    SELECT
        COUNT(*) AS total_orders,
        ROUND(
            SUM(product_sales),
            2
        ) AS total_product_sales,
        ROUND(
            SUM(freight_value),
            2
        ) AS total_freight_value,
        ROUND(
            SUM(total_order_value),
            2
        ) AS total_order_value,
        ROUND(
            AVG(product_sales),
            2
        ) AS average_order_value,
        ROUND(
            AVG(items_in_order),
            2
        ) AS average_items_per_order
    FROM order_financials
),

customer_order_counts AS
(
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT d.order_id)
            AS customer_orders
    FROM delivered_orders d
    JOIN customers c
        ON d.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),

customer_kpis AS
(
    SELECT
        COUNT(*) AS unique_customers,
        SUM(
            CASE
                WHEN customer_orders >= 2
                THEN 1
                ELSE 0
            END
        ) AS repeat_customers,
        ROUND(
            100.0 *
            SUM(
                CASE
                    WHEN customer_orders >= 2
                    THEN 1
                    ELSE 0
                END
            ) / COUNT(*),
            2
        ) AS repeat_customer_rate_pct
    FROM customer_order_counts
),

delivery_kpis AS
(
    SELECT
        ROUND(
            AVG(
                JULIANDAY(order_delivered_customer_date)
                - JULIANDAY(order_purchase_timestamp)
            ),
            1
        ) AS average_delivery_days,
        ROUND(
            100.0 *
            SUM(
                CASE
                    WHEN DATE(order_delivered_customer_date)
                       > DATE(order_estimated_delivery_date)
                    THEN 1
                    ELSE 0
                END
            ) / COUNT(*),
            2
        ) AS late_delivery_rate_pct

    FROM delivered_orders
    WHERE order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
),

ranked_reviews AS
(
    SELECT
        r.*,
        ROW_NUMBER() OVER (
            PARTITION BY r.order_id
            ORDER BY
                r.review_answer_timestamp DESC,
                r.review_creation_date DESC,
                r.review_id DESC
        ) AS review_rank
    FROM order_reviews r
),

latest_reviews AS
(
    SELECT *
    FROM ranked_reviews
    WHERE review_rank = 1
),

review_kpis AS
(
    SELECT
        ROUND(
            AVG(lr.review_score),
            2
        ) AS average_review_score,
        ROUND(
            100.0 *
            SUM(
                CASE
                    WHEN lr.review_score >= 4
                    THEN 1
                    ELSE 0
                END
            ) / COUNT(*),
            2
        ) AS positive_review_rate_pct
    FROM latest_reviews lr
    JOIN delivered_orders d
        ON lr.order_id = d.order_id
)

SELECT
    sk.total_product_sales,
    sk.total_freight_value,
    sk.total_order_value,
    sk.total_orders,
    ck.unique_customers,
    sk.average_order_value,
    sk.average_items_per_order,
    ck.repeat_customers,
    ck.repeat_customer_rate_pct,
    dk.average_delivery_days,
    dk.late_delivery_rate_pct,
    rk.average_review_score,
    rk.positive_review_rate_pct

FROM sales_kpis sk

CROSS JOIN customer_kpis ck
CROSS JOIN delivery_kpis dk
CROSS JOIN review_kpis rk;

-- 2. How have the key business KPIs changed over time?

WITH delivered_orders AS
(
    SELECT
        o.order_id,
        o.customer_id,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        c.customer_unique_id
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),

order_financials AS
(
    SELECT
        d.order_id,
        d.customer_unique_id,
        d.order_purchase_timestamp,
        d.order_delivered_customer_date,
        d.order_estimated_delivery_date,
        SUM(oi.price) AS product_sales,
        SUM(oi.freight_value) AS freight_value,
        COUNT(*) AS items_in_order
    FROM delivered_orders d
    JOIN order_items oi
        ON d.order_id = oi.order_id
    GROUP BY
        d.order_id,
        d.customer_unique_id,
        d.order_purchase_timestamp,
        d.order_delivered_customer_date,
        d.order_estimated_delivery_date
),

ranked_reviews AS
(
    SELECT
        r.*,
        ROW_NUMBER() OVER (
            PARTITION BY r.order_id
            ORDER BY
                r.review_answer_timestamp DESC,
                r.review_creation_date DESC,
                r.review_id DESC
        ) AS review_rank
    FROM order_reviews r
),

latest_reviews AS
(
    SELECT
        order_id,
        review_score
    FROM ranked_reviews
    WHERE review_rank = 1
),

monthly_kpis AS
(
    SELECT
        STRFTIME(
            '%Y-%m',
            of.order_purchase_timestamp
        ) AS year_month,
        COUNT(*) AS total_orders,
        COUNT(
            DISTINCT of.customer_unique_id
        ) AS unique_customers,
        SUM(of.product_sales)
            AS product_sales,
        AVG(of.product_sales)
            AS average_order_value,
        AVG(of.items_in_order)
            AS average_items_per_order,
        AVG(
            JULIANDAY(of.order_delivered_customer_date)
            - JULIANDAY(of.order_purchase_timestamp)
        ) AS average_delivery_days,
        100.0 *
        SUM(
            CASE
                WHEN DATE(of.order_delivered_customer_date)
                   > DATE(of.order_estimated_delivery_date)
                THEN 1
                ELSE 0
            END
        ) / COUNT(*) AS late_delivery_rate_pct,
        AVG(lr.review_score)
            AS average_review_score
    FROM order_financials of
    LEFT JOIN latest_reviews lr
        ON of.order_id = lr.order_id
    GROUP BY year_month
),

monthly_with_growth AS
(
    SELECT
        *,
        LAG(product_sales) OVER (
            ORDER BY year_month
        ) AS previous_month_sales
    FROM monthly_kpis
)

SELECT
    year_month,
    total_orders,
    unique_customers,
    ROUND(
        product_sales,
        2
    ) AS product_sales,
    ROUND(
        average_order_value,
        2
    ) AS average_order_value,
    ROUND(
        average_items_per_order,
        2
    ) AS average_items_per_order,
    ROUND(
        average_delivery_days,
        1
    ) AS average_delivery_days,
    ROUND(
        late_delivery_rate_pct,
        2
    ) AS late_delivery_rate_pct,
    ROUND(
        average_review_score,
        2
    ) AS average_review_score,
    ROUND(
        100.0 *
        (
            product_sales
            - previous_month_sales
        ) / NULLIF(previous_month_sales, 0),
        2
    ) AS monthly_sales_growth_pct
FROM monthly_with_growth
ORDER BY year_month;

