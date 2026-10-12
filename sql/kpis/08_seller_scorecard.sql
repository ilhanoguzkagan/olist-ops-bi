-- Seller scorecard for sellers with at least 50 delivered orders.
-- Tier rules are deliberately simple so an account manager can explain them to a seller.
WITH seller_items AS (
    SELECT i.seller_id, SUM(i.price) AS gmv_brl
    FROM fact_order_items i
    JOIN v_delivered d USING (order_id)
    GROUP BY i.seller_id
),
seller_orders AS (
    SELECT
        seller_id,
        ANY_VALUE(seller_state)                                    AS seller_state,
        COUNT(*)                                                   AS orders,
        1 - AVG(is_late::INT)                                      AS on_time_rate,
        AVG(seller_missed_handover::INT)                           AS missed_handover_rate,
        AVG(handling_days) FILTER (WHERE handling_days >= 0)       AS avg_handling_days,
        AVG(review_score)                                          AS avg_review
    FROM v_delivered_by_seller
    GROUP BY seller_id
    HAVING COUNT(*) >= 50
)
SELECT
    o.*,
    i.gmv_brl,
    CASE
        WHEN o.on_time_rate >= 0.95 AND o.avg_review >= 4.2 THEN 'A - Top performer'
        WHEN o.on_time_rate <  0.85 OR  o.avg_review <  3.8 THEN 'C - Needs improvement plan'
        ELSE                                                    'B - Monitor'
    END AS tier
FROM seller_orders o
JOIN seller_items i USING (seller_id)
ORDER BY i.gmv_brl DESC;
