-- Product categories with at least 1,000 delivered orders.
-- Item-level money is summed per category; delivery outcome is counted once per order and category.
WITH order_category AS (
    SELECT
        d.order_id,
        p.category,
        ANY_VALUE(d.is_late)       AS is_late,
        ANY_VALUE(d.review_score)  AS review_score,
        ANY_VALUE(d.lead_time_days) AS lead_time_days,
        SUM(i.price)               AS item_value,
        SUM(i.freight_value)       AS freight_value
    FROM v_delivered d
    JOIN fact_order_items i USING (order_id)
    JOIN dim_product p USING (product_id)
    GROUP BY d.order_id, p.category
)
SELECT
    category,
    COUNT(*)                              AS orders,
    SUM(item_value)                       AS gmv_brl,
    1 - AVG(is_late::INT)                 AS on_time_rate,
    AVG(lead_time_days)                   AS avg_lead_time_days,
    AVG(review_score)                     AS avg_review,
    SUM(freight_value) / SUM(item_value)  AS freight_to_price_ratio
FROM order_category
GROUP BY category
HAVING COUNT(*) >= 1000
ORDER BY gmv_brl DESC;
