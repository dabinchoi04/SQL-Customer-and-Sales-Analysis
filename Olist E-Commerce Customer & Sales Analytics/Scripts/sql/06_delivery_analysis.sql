-- ============================================================
-- Delivery Analysis
-- ============================================================

-- Note:
-- Delivery time is measured from purchase timestamp to customer
-- delivery timestamp.
--
-- Late delivery is determined by comparing the calendar delivery
-- date with the estimated delivery date.

-- 1. What are the overall delivery KPIs?

SELECT
    COUNT(*) AS delivered_orders,
    ROUND(
        AVG(
            JULIANDAY(order_delivered_customer_date)
            - JULIANDAY(order_purchase_timestamp)
        ),
        1
    ) AS avg_delivery_days,
    ROUND(
        AVG(
            JULIANDAY(DATE(order_delivered_customer_date))
            - JULIANDAY(DATE(order_estimated_delivery_date))
        ),
        1
    ) AS avg_days_vs_estimate,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN DATE(order_delivered_customer_date)
                   > DATE(order_estimated_delivery_date)
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*),
        2
    ) AS late_delivery_rate_pct

FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;

-- 2. What percentage of orders are early, on time, or late?

WITH delivery_status AS
(
    SELECT
        order_id,
        CASE
            WHEN DATE(order_delivered_customer_date)
               < DATE(order_estimated_delivery_date)
                THEN 'Early'

            WHEN DATE(order_delivered_customer_date)
               = DATE(order_estimated_delivery_date)
                THEN 'On Time'

            ELSE 'Late'

        END AS delivery_status
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
)

SELECT
    delivery_status,
    COUNT(*) AS orders,
    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS order_pct

FROM delivery_status
GROUP BY delivery_status
ORDER BY orders DESC;

-- 3. Which customer states have the slowest delivery performance?

SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,
    ROUND(
        AVG(
            JULIANDAY(o.order_delivered_customer_date)
            - JULIANDAY(o.order_purchase_timestamp)
        ),
        1
    ) AS avg_delivery_days,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN DATE(o.order_delivered_customer_date)
                   > DATE(o.order_estimated_delivery_date)
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*),
        2
    ) AS late_delivery_rate_pct

FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;

-- 4. How has delivery performance changed over time?

SELECT
    STRFTIME(
        '%Y-%m',
        order_purchase_timestamp
    ) AS year_month,
    COUNT(*) AS delivered_orders,
    ROUND(
        AVG(
            JULIANDAY(order_delivered_customer_date)
            - JULIANDAY(order_purchase_timestamp)
        ),
        1
    ) AS avg_delivery_days,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN DATE(order_delivered_customer_date)
                   > DATE(order_estimated_delivery_date)
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*),
        2
    ) AS late_delivery_rate_pct

FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY year_month
ORDER BY year_month;

-- 5. Where is delivery time being spent: order-to-carrier or carrier-to-customer?

SELECT
    ROUND(
        AVG(
            JULIANDAY(order_delivered_carrier_date)
            - JULIANDAY(order_purchase_timestamp)
        ),
        1
    ) AS avg_days_to_carrier,
    ROUND(
        AVG(
            JULIANDAY(order_delivered_customer_date)
            - JULIANDAY(order_delivered_carrier_date)
        ),
        1
    ) AS avg_carrier_to_customer_days,
    ROUND(
        AVG(
            JULIANDAY(order_delivered_customer_date)
            - JULIANDAY(order_purchase_timestamp)
        ),
        1
    ) AS avg_total_delivery_days

FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL;

-- 6. Do larger orders take longer to deliver?

WITH order_sizes AS
(
    SELECT
        o.order_id,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,

        COUNT(*) AS items_in_order
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY
        o.order_id,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
),

order_size_groups AS
(
    SELECT
        *,
        CASE
            WHEN items_in_order = 1
                THEN '1 item'

            WHEN items_in_order = 2
                THEN '2 items'

            WHEN items_in_order BETWEEN 3 AND 5
                THEN '3-5 items'

            ELSE '6+ items'

        END AS order_size_group
    FROM order_sizes
)

SELECT
    order_size_group,
    COUNT(*) AS orders,
    ROUND(
        AVG(items_in_order),
        2
    ) AS avg_items,
    ROUND(
        AVG(
            JULIANDAY(order_delivered_customer_date)
            - JULIANDAY(order_purchase_timestamp)
        ),
        1
    ) AS avg_delivery_days,
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

FROM order_size_groups
GROUP BY order_size_group
ORDER BY MIN(items_in_order);

-- 7. Is higher freight cost associated with different delivery performance?

WITH order_freight AS
(
    SELECT
        o.order_id,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        SUM(oi.freight_value) AS total_freight
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY
        o.order_id,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
),

freight_groups AS
(
    SELECT
        *,
        NTILE(4) OVER (
            ORDER BY total_freight
        ) AS freight_quartile
    FROM order_freight
)

SELECT
    freight_quartile,
    COUNT(*) AS orders,
    ROUND(
        AVG(total_freight),
        2
    ) AS avg_freight_value,
    ROUND(
        AVG(
            JULIANDAY(order_delivered_customer_date)
            - JULIANDAY(order_purchase_timestamp)
        ),
        1
    ) AS avg_delivery_days,
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

FROM freight_groups
GROUP BY freight_quartile
ORDER BY freight_quartile;
