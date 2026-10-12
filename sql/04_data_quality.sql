-- 04_data_quality.sql
-- One row per check. severity = 'blocking' must have rows_affected = 0 or the build fails;
-- 'warning' rows are known source issues that the KPIs handle and that are reported in data_quality.md.

CREATE OR REPLACE TABLE dq_results AS
SELECT * FROM (VALUES
    ('blocking', 'fact_orders row count differs from source orders',
        ABS((SELECT COUNT(*) FROM fact_orders) - (SELECT COUNT(*) FROM stg_orders))),
    ('blocking', 'fact_order_items row count differs from source items',
        ABS((SELECT COUNT(*) FROM fact_order_items) - (SELECT COUNT(*) FROM stg_order_items))),
    ('blocking', 'duplicate order_id in fact_orders',
        (SELECT COUNT(*) - COUNT(DISTINCT order_id) FROM fact_orders)),
    ('blocking', 'orders whose customer is missing from dim_customer',
        (SELECT COUNT(*) FROM fact_orders f ANTI JOIN dim_customer c USING (customer_id))),
    ('blocking', 'order items whose seller is missing from dim_seller',
        (SELECT COUNT(*) FROM fact_order_items f ANTI JOIN dim_seller s USING (seller_id))),
    ('blocking', 'order items whose product is missing from dim_product',
        (SELECT COUNT(*) FROM fact_order_items f ANTI JOIN dim_product p USING (product_id))),
    ('blocking', 'order purchase dates outside dim_date',
        (SELECT COUNT(*) FROM fact_orders f ANTI JOIN dim_date d ON f.purchase_date_key = d.date_key)),

    ('warning', 'status = delivered but no customer delivery date',
        (SELECT COUNT(*) FROM fact_orders WHERE order_status = 'delivered' AND delivered_ts IS NULL)),
    ('warning', 'customer delivery date present but status is not delivered',
        (SELECT COUNT(*) FROM fact_orders WHERE order_status <> 'delivered' AND delivered_ts IS NOT NULL)),
    ('warning', 'negative approval time (approved before purchase)',
        (SELECT COUNT(*) FROM fact_orders WHERE approval_days < 0)),
    ('warning', 'negative seller handling time (handed to carrier before approval)',
        (SELECT COUNT(*) FROM fact_orders WHERE handling_days < 0)),
    ('warning', 'negative carrier transit time (delivered before handed to carrier)',
        (SELECT COUNT(*) FROM fact_orders WHERE transit_days < 0)),
    ('warning', 'orders with no items',
        (SELECT COUNT(*) FROM fact_orders WHERE item_count IS NULL)),
    ('warning', 'orders with no payment record',
        (SELECT COUNT(*) FROM fact_orders WHERE payment_value IS NULL)),
    ('warning', 'payment differs from items + freight by more than 1 BRL',
        (SELECT COUNT(*) FROM fact_orders
         WHERE ABS(payment_value - (item_value + freight_value)) > 1)),
    ('warning', 'orders with more than one review (latest kept)',
        (SELECT COUNT(*) FROM (SELECT order_id FROM stg_reviews_raw GROUP BY order_id HAVING COUNT(*) > 1))),
    ('warning', 'review_ids shared by more than one order',
        (SELECT COUNT(*) FROM (SELECT review_id FROM stg_reviews_raw GROUP BY review_id HAVING COUNT(*) > 1))),
    ('warning', 'products with no category',
        (SELECT COUNT(*) FROM dim_product WHERE category = 'unknown')),
    ('warning', 'delivered orders with no review',
        (SELECT COUNT(*) FROM fact_orders WHERE is_delivered AND review_score IS NULL))
) AS t(severity, check_name, rows_affected);
