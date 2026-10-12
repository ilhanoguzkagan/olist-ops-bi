-- 03_facts.sql
-- fact_order_items: grain = one row per order item (price, freight, seller, product).
-- fact_orders:      grain = one row per order (status, timestamps, lead-time components, value, review).

CREATE OR REPLACE TABLE fact_order_items AS
SELECT
    i.order_id,
    i.order_item_id,
    i.product_id,
    i.seller_id,
    o.customer_id,
    CAST(STRFTIME(o.purchase_ts, '%Y%m%d') AS INTEGER) AS purchase_date_key,
    i.shipping_limit_ts,
    i.price,
    i.freight_value
FROM stg_order_items i
JOIN stg_orders o USING (order_id);

CREATE OR REPLACE TABLE fact_orders AS
WITH items AS (
    SELECT
        order_id,
        COUNT(*)                  AS item_count,
        COUNT(DISTINCT seller_id) AS seller_count,
        SUM(price)                AS item_value,
        SUM(freight_value)        AS freight_value,
        MAX(shipping_limit_ts)    AS shipping_limit_ts
    FROM stg_order_items
    GROUP BY order_id
),
payments AS (
    SELECT order_id, SUM(payment_value) AS payment_value
    FROM stg_payments
    GROUP BY order_id
)
SELECT
    o.order_id,
    o.customer_id,
    CAST(STRFTIME(o.purchase_ts, '%Y%m%d') AS INTEGER) AS purchase_date_key,
    o.order_status,
    o.purchase_ts,
    o.approved_ts,
    o.carrier_ts,
    o.delivered_ts,
    o.estimated_date,
    o.order_status = 'delivered' AND o.delivered_ts IS NOT NULL AS is_delivered,

    -- Lead-time components in days (fractional). Can be negative where source timestamps are
    -- inconsistent; KPIs exclude negative components (counted in data_quality.md).
    DATE_DIFF('minute', o.purchase_ts, o.approved_ts)  / 1440.0 AS approval_days,
    DATE_DIFF('minute', o.approved_ts, o.carrier_ts)   / 1440.0 AS handling_days,
    DATE_DIFF('minute', o.carrier_ts, o.delivered_ts)  / 1440.0 AS transit_days,
    DATE_DIFF('minute', o.purchase_ts, o.delivered_ts) / 1440.0 AS lead_time_days,
    DATE_DIFF('day', o.purchase_ts::DATE, o.estimated_date)     AS promised_days,

    -- On time = delivered on or before the estimated date shown to the customer (date level).
    CASE WHEN o.delivered_ts IS NOT NULL
         THEN o.delivered_ts::DATE > o.estimated_date END        AS is_late,
    CASE WHEN o.delivered_ts IS NOT NULL
         THEN GREATEST(DATE_DIFF('day', o.estimated_date, o.delivered_ts::DATE), 0) END AS days_late,
    -- Seller missed the hand-over deadline to the carrier.
    CASE WHEN o.carrier_ts IS NOT NULL
         THEN o.carrier_ts > i.shipping_limit_ts END              AS seller_missed_handover,

    i.item_count,
    i.seller_count,
    i.item_value,
    i.freight_value,
    p.payment_value,
    r.review_score,
    r.has_comment AS review_has_comment
FROM stg_orders o
LEFT JOIN items    i USING (order_id)
LEFT JOIN payments p USING (order_id)
LEFT JOIN stg_reviews r USING (order_id);
