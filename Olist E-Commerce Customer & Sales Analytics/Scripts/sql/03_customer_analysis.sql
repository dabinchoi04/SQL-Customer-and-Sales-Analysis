-- ============================================================
-- Customer Analysis
-- ============================================================

-- Note:
-- customer_unique_id is used to identify individual customers across multiple orders.
--
-- Customer monetary value is based on product sales (SUM(order_items.price)), excluding freight.

-- 1. What percentage of customers make repeat purchases?

WITH customer_order_counts AS
(
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    COUNT(*) AS total_customers,
    SUM(
        CASE
            WHEN total_orders = 1 THEN 1
            ELSE 0
        END
    ) AS one_time_customers,
    SUM(
        CASE
            WHEN total_orders >= 2 THEN 1
            ELSE 0
        END
    ) AS repeat_customers,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN total_orders >= 2 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS repeat_customer_rate_pct
   
FROM customer_order_counts;

-- 2. How frequently do customers place orders?

WITH customer_order_counts AS
(
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

order_distribution AS
(
    SELECT
        total_orders AS orders_per_customer,
        COUNT(*) AS customers
    FROM customer_order_counts
    GROUP BY total_orders
)

SELECT
    orders_per_customer,
    customers,
    ROUND(
        100.0 * customers
        / SUM(customers) OVER (),
        2
    ) AS customer_pct
 
FROM order_distribution
ORDER BY orders_per_customer;

-- 3. Who are the highest-value customers?

SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(
        SUM(oi.price),
        2
    ) AS historical_customer_value,
    ROUND(
        SUM(oi.price)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value,
    MIN(o.order_purchase_timestamp) AS first_purchase,
    MAX(o.order_purchase_timestamp) AS last_purchase
 
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY historical_customer_value DESC
LIMIT 20;

-- 4. How have new and returning customers changed over time?

WITH customer_orders AS
(
    SELECT DISTINCT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),

orders_with_first_purchase AS
(
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,

        MIN(order_purchase_timestamp) OVER (
            PARTITION BY customer_unique_id
        ) AS first_purchase_timestamp
    FROM customer_orders
)

SELECT
    STRFTIME(
        '%Y-%m',
        order_purchase_timestamp
    ) AS year_month,

    COUNT(
        DISTINCT CASE
            WHEN STRFTIME('%Y-%m', order_purchase_timestamp)
               = STRFTIME('%Y-%m', first_purchase_timestamp)
            THEN customer_unique_id
        END
    ) AS new_customers,

    COUNT(
        DISTINCT CASE
            WHEN STRFTIME('%Y-%m', order_purchase_timestamp)
               > STRFTIME('%Y-%m', first_purchase_timestamp)
            THEN customer_unique_id
        END
    ) AS returning_customers

FROM orders_with_first_purchase
GROUP BY year_month
ORDER BY year_month;

-- 5. How long does it take customers to make a second purchase? 

WITH customer_orders AS
(
    SELECT DISTINCT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),

ranked_orders AS
(
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY
                order_purchase_timestamp,
                order_id
        ) AS order_number
    FROM customer_orders
),

first_second_purchase AS
(
    SELECT
        customer_unique_id,
        MAX(
            CASE
                WHEN order_number = 1
                THEN order_purchase_timestamp
            END
        ) AS first_purchase,
        MAX(
            CASE
                WHEN order_number = 2
                THEN order_purchase_timestamp
            END
        ) AS second_purchase
    FROM ranked_orders
    GROUP BY customer_unique_id
)

SELECT
    COUNT(*) AS repeat_customers,
    ROUND(
        AVG(
            JULIANDAY(second_purchase)
            - JULIANDAY(first_purchase)
        ),
        1
    ) AS avg_days_to_second_purchase,
    ROUND(
        MIN(
            JULIANDAY(second_purchase)
            - JULIANDAY(first_purchase)
        ),
        1
    ) AS min_days_to_second_purchase,
    ROUND(
        MAX(
            JULIANDAY(second_purchase)
            - JULIANDAY(first_purchase)
        ),
        1
    ) AS max_days_to_second_purchase

FROM first_second_purchase
WHERE second_purchase IS NOT NULL;

-- 6. How concentrated are sales among high-value customers?

WITH customer_value AS
(
    SELECT
        c.customer_unique_id,
        SUM(oi.price) AS customer_sales
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

customer_deciles AS
(
    SELECT
        customer_unique_id,
        customer_sales,
        NTILE(10) OVER (
            ORDER BY customer_sales DESC
        ) AS spend_decile
    FROM customer_value
)

SELECT
    spend_decile,
    COUNT(*) AS customers,
    ROUND(
        SUM(customer_sales),
        2
    ) AS product_sales,
    ROUND(
        100.0 * SUM(customer_sales)
        / SUM(SUM(customer_sales)) OVER (),
        2
    ) AS sales_share_pct

FROM customer_deciles
GROUP BY spend_decile
ORDER BY spend_decile;

-- 7. How can customers be segmented using RFM?

WITH analysis_date AS
(
    SELECT
        DATE(
            MAX(order_purchase_timestamp),
            '+1 day'
        ) AS analysis_date
    FROM orders
    WHERE order_status = 'delivered'
),

rfm AS
(
    SELECT
        c.customer_unique_id,
        CAST(
            JULIANDAY(ad.analysis_date)
            - JULIANDAY(MAX(o.order_purchase_timestamp))
            AS INTEGER
        ) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(
            SUM(oi.price),
            2
        ) AS monetary
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    CROSS JOIN analysis_date ad
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

rfm_scores AS
(
    SELECT
        *,
        NTILE(4) OVER (
            ORDER BY recency_days DESC
        ) AS recency_score,
        NTILE(4) OVER (
            ORDER BY monetary
        ) AS monetary_score
    FROM rfm
),

customer_segments AS
(
    SELECT
        *,
        CASE

            WHEN frequency >= 2
                 AND recency_score >= 3
                 AND monetary_score >= 3
                THEN 'Loyal High Value'

            WHEN frequency >= 2
                 AND recency_score <= 2
                THEN 'At Risk Repeat'

            WHEN frequency >= 2
                THEN 'Repeat Customers'

            WHEN frequency = 1
                 AND recency_score >= 3
                 AND monetary_score >= 3
                THEN 'Recent High Value'

            WHEN frequency = 1
                 AND recency_score >= 3
                THEN 'Recent One-Time'

            ELSE 'Other One-Time'

        END AS customer_segment
    FROM rfm_scores
)

SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_pct,
    ROUND(
        AVG(recency_days),
        1
    ) AS avg_recency_days,
    ROUND(
        AVG(frequency),
        2
    ) AS avg_frequency,
    ROUND(
        AVG(monetary),
        2
    ) AS avg_monetary_value

FROM customer_segments
GROUP BY customer_segment
ORDER BY customers DESC;

-- 8. How does customer retention vary by acquisition cohort?

WITH customer_orders AS
(
    SELECT DISTINCT
        c.customer_unique_id,
        DATE(
            o.order_purchase_timestamp,
            'start of month'
        ) AS order_month
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),

first_purchase AS
(
    SELECT
        customer_unique_id,
        MIN(order_month) AS cohort_month
    FROM customer_orders
    GROUP BY customer_unique_id
),

cohort_activity AS
(
    SELECT
        co.customer_unique_id,
        fp.cohort_month,
        co.order_month,
        (
            (
                CAST(STRFTIME('%Y', co.order_month) AS INTEGER)
                -
                CAST(STRFTIME('%Y', fp.cohort_month) AS INTEGER)
            ) * 12
            +
            (
                CAST(STRFTIME('%m', co.order_month) AS INTEGER)
                -
                CAST(STRFTIME('%m', fp.cohort_month) AS INTEGER)
            )
        ) AS month_number
    FROM customer_orders co
    JOIN first_purchase fp
        ON co.customer_unique_id = fp.customer_unique_id
),

cohort_counts AS
(
    SELECT
        cohort_month,
        month_number,

        COUNT(DISTINCT customer_unique_id)
            AS active_customers
    FROM cohort_activity
    GROUP BY
        cohort_month,
        month_number
),

cohort_sizes AS
(
    SELECT
        cohort_month,
        active_customers AS cohort_size
    FROM cohort_counts
    WHERE month_number = 0
)

SELECT
    STRFTIME(
        '%Y-%m',
        cc.cohort_month
    ) AS cohort_month,
    cc.month_number,
    cc.active_customers,
    cs.cohort_size,
    ROUND(
        100.0 * cc.active_customers
        / cs.cohort_size,
        2
    ) AS retention_rate_pct

FROM cohort_counts cc
JOIN cohort_sizes cs
    ON cc.cohort_month = cs.cohort_month
ORDER BY
    cc.cohort_month,
    cc.month_number;
