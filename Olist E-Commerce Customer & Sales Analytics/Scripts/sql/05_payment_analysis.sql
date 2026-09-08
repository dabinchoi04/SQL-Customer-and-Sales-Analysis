-- ============================================================
-- Payment Analysis
-- ============================================================

-- Note:
-- payment_value represents the amount recorded for an individual
-- payment record.
--
-- One order may have multiple payment records, so payments are
-- aggregated to the order level when calculating order-level
-- payment metrics.

-- 1. Which payment methods are most commonly used?

SELECT
    op.payment_type,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT op.order_id) AS orders_using_method,
    ROUND(
        SUM(op.payment_value),
        2
    ) AS payment_value,
    ROUND(
        100.0 * SUM(op.payment_value) / SUM(SUM(op.payment_value)) OVER (),
        2
    ) AS payment_value_share_pct
FROM order_payments op
JOIN orders o
    ON op.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY op.payment_type
ORDER BY payment_value DESC;

-- 2. How are credit-card installments distributed?

SELECT
    payment_installments,

    COUNT(*) AS credit_card_payments,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS payment_pct
FROM order_payments op
JOIN orders o
    ON op.order_id = o.order_id
WHERE
    o.order_status = 'delivered'
    AND op.payment_type = 'credit_card'
GROUP BY payment_installments
ORDER BY payment_installments;

-- 3. How does payment value vary with the number of installments?

SELECT
    op.payment_installments,
    COUNT(*) AS credit_card_payments,
    ROUND(
        AVG(op.payment_value),
        2
    ) AS avg_payment_value,
    ROUND(
        MIN(op.payment_value),
        2
    ) AS min_payment_value,
    ROUND(
        MAX(op.payment_value),
        2
    ) AS max_payment_value

FROM order_payments op
JOIN orders o
    ON op.order_id = o.order_id
WHERE
    o.order_status = 'delivered'
    AND op.payment_type = 'credit_card'
GROUP BY op.payment_installments
ORDER BY op.payment_installments;

-- 4. How common are split or multiple-method payments?

WITH order_payment_summary AS
(
    SELECT
        op.order_id,
        COUNT(*) AS payment_records,
        COUNT(DISTINCT op.payment_type) AS payment_methods_used,
        SUM(op.payment_value) AS total_payment_value
    FROM order_payments op
    JOIN orders o
        ON op.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY op.order_id
),

payment_groups AS
(
    SELECT
        order_id,
        total_payment_value,
        CASE
            WHEN payment_records = 1
                THEN 'Single Payment'

            WHEN payment_records > 1
                 AND payment_methods_used = 1
                THEN 'Split - Same Method'

            WHEN payment_methods_used > 1
                THEN 'Multiple Payment Methods'

        END AS payment_group
    FROM order_payment_summary
)

SELECT
    payment_group,
    COUNT(*) AS orders,
    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS order_pct,
    ROUND(
        AVG(total_payment_value),
        2
    ) AS avg_payment_value

FROM payment_groups
GROUP BY payment_group
ORDER BY orders DESC;

-- 5. Do recorded payments reconcile with calculated order values?

WITH delivered_orders AS
(
    SELECT order_id
    FROM orders
    WHERE order_status = 'delivered'
),

item_totals AS
(
    SELECT
        oi.order_id,
        SUM(
            oi.price + oi.freight_value
        ) AS calculated_order_value
    FROM order_items oi
    JOIN delivered_orders d
        ON oi.order_id = d.order_id
    GROUP BY oi.order_id
),

payment_totals AS
(
    SELECT
        op.order_id,
        SUM(
            op.payment_value
        ) AS recorded_payment_value
    FROM order_payments op
    JOIN delivered_orders d
        ON op.order_id = d.order_id
    GROUP BY op.order_id
),

order_reconciliation AS
(
    SELECT
        it.order_id,
        it.calculated_order_value,
        pt.recorded_payment_value,
        pt.recorded_payment_value
        - it.calculated_order_value
            AS payment_difference
    FROM item_totals it
    JOIN payment_totals pt
        ON it.order_id = pt.order_id
)

SELECT
    COUNT(*) AS orders_compared,
    ROUND(
        AVG(
            ABS(payment_difference)
        ),
        2
    ) AS avg_absolute_difference,
    ROUND(
        MAX(
            ABS(payment_difference)
        ),
        2
    ) AS max_absolute_difference,
    SUM(
        CASE
            WHEN ABS(payment_difference) > 0.01
                THEN 1
            ELSE 0
        END
    ) AS orders_with_difference
FROM order_reconciliation;
