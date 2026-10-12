-- Shipping lanes (seller state -> customer state) with at least 300 delivered orders.
SELECT
    seller_state || ' -> ' || customer_state            AS lane,
    seller_state,
    customer_state,
    COUNT(*)                                            AS orders,
    1 - AVG(is_late::INT)                               AS on_time_rate,
    AVG(lead_time_days)                                 AS avg_lead_time_days,
    AVG(promised_days)                                  AS avg_promised_days,
    SUM(freight_value) / SUM(item_value)                AS freight_to_price_ratio
FROM v_delivered_by_seller
GROUP BY ALL
HAVING COUNT(*) >= 300
ORDER BY on_time_rate;
