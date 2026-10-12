-- Monthly trend: demand, GMV and delivery performance by purchase month.
SELECT
    year_month,
    COUNT(*)                                                                         AS orders_placed,
    SUM(item_value) FILTER (WHERE order_status NOT IN ('canceled', 'unavailable'))   AS gmv_brl,
    COUNT(*) FILTER (WHERE is_delivered)                                             AS orders_delivered,
    1 - AVG(is_late::INT) FILTER (WHERE is_delivered)                                AS on_time_rate,
    AVG(lead_time_days) FILTER (WHERE is_delivered)                                  AS avg_lead_time_days,
    AVG(promised_days) FILTER (WHERE is_delivered)                                   AS avg_promised_days,
    AVG(review_score) FILTER (WHERE is_delivered)                                    AS avg_review
FROM v_orders
GROUP BY year_month
ORDER BY year_month;
