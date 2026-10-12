-- Where does the delivery time go? Average days per stage, on-time vs late orders.
-- Only orders where every stage is non-negative are used (inconsistent timestamps are excluded,
-- see reports/data_quality.md).
SELECT
    CASE WHEN is_late THEN 'Late' ELSE 'On time' END AS delivery_outcome,
    COUNT(*)                 AS orders,
    AVG(approval_days)       AS approval_days,
    AVG(handling_days)       AS seller_handling_days,
    AVG(transit_days)        AS carrier_transit_days,
    AVG(lead_time_days)      AS total_lead_time_days,
    AVG(promised_days)       AS promised_days
FROM v_delivered
WHERE approval_days >= 0 AND handling_days >= 0 AND transit_days >= 0
GROUP BY ALL
ORDER BY delivery_outcome DESC;
