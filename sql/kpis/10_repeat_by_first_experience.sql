-- Does a late first delivery reduce the chance that a customer buys again?
-- Customers are identified by customer_unique_id (customer_id is per order in this dataset).
-- Any later order (any status, within the analysis window) counts as a repeat purchase.
WITH ranked AS (
    SELECT
        customer_unique_id,
        is_delivered,
        is_late,
        ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY purchase_ts, order_id) AS order_rank,
        COUNT(*)     OVER (PARTITION BY customer_unique_id)                      AS customer_orders
    FROM v_orders
)
SELECT
    CASE WHEN is_late THEN 'First order late' ELSE 'First order on time' END AS first_order_experience,
    COUNT(*)                          AS customers,
    AVG((customer_orders > 1)::INT)   AS repeat_rate
FROM ranked
WHERE order_rank = 1 AND is_delivered
GROUP BY ALL
ORDER BY first_order_experience DESC;
