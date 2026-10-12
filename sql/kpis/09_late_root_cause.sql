-- Root cause split for late deliveries: did the seller miss the carrier hand-over deadline
-- (shipping_limit_date), or was the order handed over on time and delayed in transit?
SELECT
    CASE WHEN seller_missed_handover THEN 'Seller missed hand-over deadline'
         ELSE 'Seller handed over on time' END            AS handover,
    COUNT(*)                                             AS orders,
    COUNT(*) FILTER (WHERE is_late)                      AS late_orders,
    AVG(is_late::INT)                                    AS late_rate,
    COUNT(*) FILTER (WHERE is_late) * 1.0
        / SUM(COUNT(*) FILTER (WHERE is_late)) OVER ()   AS share_of_all_late_orders
FROM v_delivered
WHERE seller_missed_handover IS NOT NULL
GROUP BY ALL
ORDER BY handover;
