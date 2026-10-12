-- 05_analysis_views.sql
-- Shared analysis scope for the KPI queries, so every KPI uses the same population.
--
-- Analysis window: orders purchased 2017-01-01 to 2018-08-31.
--   * 2016 has only a few hundred test-phase orders.
--   * Orders from Sep/Oct 2018 were mostly still open when the snapshot was taken; including them
--     would bias delivery KPIs toward the fast deliveries that had already completed.

CREATE OR REPLACE VIEW v_orders AS
SELECT f.*, d.year_month, c.state AS customer_state, c.customer_unique_id
FROM fact_orders f
JOIN dim_date d     ON f.purchase_date_key = d.date_key
JOIN dim_customer c USING (customer_id)
WHERE f.purchase_ts >= TIMESTAMP '2017-01-01'
  AND f.purchase_ts <  TIMESTAMP '2018-09-01';

-- Delivered orders with a usable delivery date: the population for all delivery KPIs.
CREATE OR REPLACE VIEW v_delivered AS
SELECT * FROM v_orders WHERE is_delivered;

-- Order x seller grain (an order can ship from several sellers). Delivery dates are recorded
-- per order, so a multi-seller order counts toward each of its sellers.
CREATE OR REPLACE VIEW v_delivered_by_seller AS
SELECT DISTINCT d.*, i.seller_id, s.state AS seller_state
FROM v_delivered d
JOIN fact_order_items i USING (order_id)
JOIN dim_seller s USING (seller_id);
