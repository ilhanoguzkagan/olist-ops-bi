-- Headline KPIs for the analysis window (one row).
WITH placed AS (
    SELECT
        COUNT(*)                                                         AS orders_placed,
        SUM(item_value) FILTER (WHERE order_status NOT IN ('canceled', 'unavailable')) AS gmv_brl,
        COUNT(DISTINCT customer_unique_id)                               AS unique_customers
    FROM v_orders
),
delivered AS (
    SELECT
        COUNT(*)                                                AS orders_delivered,
        1 - AVG(is_late::INT)                                   AS on_time_rate,
        AVG(lead_time_days)                                     AS avg_lead_time_days,
        MEDIAN(lead_time_days)                                  AS median_lead_time_days,
        QUANTILE_CONT(lead_time_days, 0.9)                      AS p90_lead_time_days,
        AVG(promised_days)                                      AS avg_promised_days,
        AVG(review_score)                                       AS avg_review,
        AVG(review_score) FILTER (WHERE NOT is_late)            AS avg_review_on_time,
        AVG(review_score) FILTER (WHERE is_late)                AS avg_review_late,
        SUM(freight_value) / SUM(item_value)                    AS freight_to_price_ratio
    FROM v_delivered
)
SELECT * FROM placed, delivered;
