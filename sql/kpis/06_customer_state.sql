-- Delivery performance by customer state (destination).
SELECT
    customer_state,
    COUNT(*)                              AS orders,
    1 - AVG(is_late::INT)                 AS on_time_rate,
    AVG(lead_time_days)                   AS avg_lead_time_days,
    AVG(promised_days)                    AS avg_promised_days,
    AVG(review_score)                     AS avg_review,
    SUM(freight_value) / SUM(item_value)  AS freight_to_price_ratio
FROM v_delivered
GROUP BY customer_state
ORDER BY orders DESC;
