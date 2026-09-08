-- ============================================================
-- Customer Satisfaction Analysis
-- ============================================================

-- Note:
-- Because an order may have multiple review records, the most recent
-- review by review_answer_timestamp is used for order-level analysis.
--
-- Review scores range from 1 to 5, where higher values indicate
-- greater customer satisfaction.

-- 1. What are the overall customer satisfaction KPIs?

WITH ranked_reviews AS
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
)

SELECT
    COUNT(*) AS reviewed_orders,
    ROUND(
        AVG(lr.review_score),
        2
    ) AS avg_review_score,
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
    ) AS positive_review_rate_pct,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN lr.review_score <= 2
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*),
        2
    ) AS negative_review_rate_pct
FROM latest_reviews lr
JOIN orders o
    ON lr.order_id = o.order_id
WHERE o.order_status = 'delivered';

-- 2. How does late delivery affect customer satisfaction?

WITH ranked_reviews AS
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

delivery_status AS
(
    SELECT
        order_id,
        CASE
            WHEN DATE(order_delivered_customer_date)
               > DATE(order_estimated_delivery_date)
                THEN 'Late'

            ELSE 'On Time / Early'

        END AS delivery_status
        
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
)

SELECT
    ds.delivery_status,
    COUNT(*) AS reviewed_orders,
    ROUND(
        AVG(lr.review_score),
        2
    ) AS avg_review_score,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN lr.review_score <= 2
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS negative_review_rate_pct
FROM delivery_status ds
JOIN latest_reviews lr
    ON ds.order_id = lr.order_id
GROUP BY ds.delivery_status
ORDER BY avg_review_score DESC;

-- 3. How does the severity of delivery delay affect review scores?

WITH ranked_reviews AS
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

delivery_delays AS
(
    SELECT
        order_id,
        CAST(
            JULIANDAY(DATE(order_delivered_customer_date))
            - JULIANDAY(DATE(order_estimated_delivery_date))
            AS INTEGER
        ) AS days_vs_estimate
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
),

delay_groups AS
(
    SELECT
        order_id,
        CASE
            WHEN days_vs_estimate <= 0
                THEN 'On Time / Early'

            WHEN days_vs_estimate BETWEEN 1 AND 3
                THEN '1-3 Days Late'

            WHEN days_vs_estimate BETWEEN 4 AND 7
                THEN '4-7 Days Late'

            ELSE '8+ Days Late'

        END AS delay_group
    FROM delivery_delays
)

SELECT
    dg.delay_group,
    COUNT(*) AS reviewed_orders,
    ROUND(
        AVG(lr.review_score),
        2
    ) AS avg_review_score,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN lr.review_score <= 2
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS negative_review_rate_pct

FROM delay_groups dg
JOIN latest_reviews lr
    ON dg.order_id = lr.order_id
GROUP BY dg.delay_group
ORDER BY
    CASE dg.delay_group
        WHEN 'On Time / Early' THEN 1
        WHEN '1-3 Days Late' THEN 2
        WHEN '4-7 Days Late' THEN 3
        WHEN '8+ Days Late' THEN 4
    END;

-- 4. Which product categories have the highest and lowest customer satisfaction? 

-- Note:
-- Because reviews are recorded at the order level, an order containing products from multiple 
-- categories contributes its review to each category represented in that order.

WITH ranked_reviews AS
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

order_categories AS
(
    SELECT DISTINCT
        oi.order_id,
        COALESCE(
            ct.product_category_name_english,
            'Unknown'
        ) AS category
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct
        ON p.product_category_name =
           ct.product_category_name
)

SELECT
    oc.category,
    COUNT(*) AS reviewed_orders,
    ROUND(
        AVG(lr.review_score),
        2
    ) AS avg_review_score,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN lr.review_score <= 2
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS negative_review_rate_pct
FROM order_categories oc
JOIN latest_reviews lr
    ON oc.order_id = lr.order_id
JOIN orders o
    ON oc.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY oc.category
HAVING COUNT(*) >= 100
ORDER BY avg_review_score DESC;

-- 5. Which sellers have the strongest and weakest customer satisfaction?

WITH ranked_reviews AS
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

seller_orders AS
(
    SELECT
        oi.order_id,
        MIN(oi.seller_id) AS seller_id

    FROM order_items oi

    GROUP BY oi.order_id

    HAVING COUNT(DISTINCT oi.seller_id) = 1
)

SELECT
    so.seller_id,
    COUNT(*) AS reviewed_orders,
    ROUND(
        AVG(lr.review_score),
        2
    ) AS avg_review_score,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN lr.review_score <= 2
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS negative_review_rate_pct
FROM seller_orders so
JOIN latest_reviews lr
    ON so.order_id = lr.order_id
JOIN orders o
    ON so.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY so.seller_id
HAVING COUNT(*) >= 50
ORDER BY avg_review_score DESC;

-- 6. Does order value relate to customer satisfaction?

WITH ranked_reviews AS
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

order_values AS
(
    SELECT
        o.order_id,
        SUM(oi.price) AS order_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id
),

value_groups AS
(
    SELECT
        *,
        NTILE(4) OVER (
            ORDER BY order_value
        ) AS value_quartile
    FROM order_values
)

SELECT
    vg.value_quartile,
    COUNT(*) AS reviewed_orders,
    ROUND(
        AVG(vg.order_value),
        2
    ) AS avg_order_value,
    ROUND(
        AVG(lr.review_score),
        2
    ) AS avg_review_score,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN lr.review_score <= 2
                THEN 1
                ELSE 0
            END
        )/ COUNT(*),
        2
    ) AS negative_review_rate_pct
FROM value_groups vg
JOIN latest_reviews lr
    ON vg.order_id = lr.order_id
GROUP BY vg.value_quartile
ORDER BY vg.value_quartile;

-- 7. How has customer satisfaction changed over time?

WITH ranked_reviews AS
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
)

SELECT
    STRFTIME(
        '%Y-%m',
        o.order_purchase_timestamp
    ) AS year_month,
    COUNT(*) AS reviewed_orders,
    ROUND(
        AVG(lr.review_score),
        2
    ) AS avg_review_score,
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
    ) AS positive_review_rate_pct,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN lr.review_score <= 2
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS negative_review_rate_pct
FROM orders o
JOIN latest_reviews lr
    ON o.order_id = lr.order_id
WHERE o.order_status = 'delivered'
GROUP BY year_month
ORDER BY year_month;
