-- 01_staging.sql
-- Typed, lightly cleaned copies of the raw Olist CSVs. One staging table per source file.
-- {raw} is replaced by build_warehouse.py with the path to data/raw.

CREATE OR REPLACE TABLE stg_orders AS
SELECT
    order_id,
    customer_id,
    order_status,
    CAST(order_purchase_timestamp      AS TIMESTAMP) AS purchase_ts,
    CAST(order_approved_at             AS TIMESTAMP) AS approved_ts,
    CAST(order_delivered_carrier_date  AS TIMESTAMP) AS carrier_ts,
    CAST(order_delivered_customer_date AS TIMESTAMP) AS delivered_ts,
    CAST(order_estimated_delivery_date AS DATE)      AS estimated_date
FROM read_csv('{raw}/olist_orders_dataset.csv', header = true);

CREATE OR REPLACE TABLE stg_order_items AS
SELECT
    order_id,
    CAST(order_item_id AS INTEGER)          AS order_item_id,
    product_id,
    seller_id,
    CAST(shipping_limit_date AS TIMESTAMP)  AS shipping_limit_ts,
    CAST(price AS DECIMAL(10, 2))           AS price,
    CAST(freight_value AS DECIMAL(10, 2))   AS freight_value
FROM read_csv('{raw}/olist_order_items_dataset.csv', header = true);

CREATE OR REPLACE TABLE stg_payments AS
SELECT
    order_id,
    CAST(payment_sequential AS INTEGER)   AS payment_sequential,
    payment_type,
    CAST(payment_installments AS INTEGER) AS payment_installments,
    CAST(payment_value AS DECIMAL(10, 2)) AS payment_value
FROM read_csv('{raw}/olist_order_payments_dataset.csv', header = true);

CREATE OR REPLACE TABLE stg_customers AS
SELECT
    customer_id,
    customer_unique_id,
    LPAD(CAST(customer_zip_code_prefix AS VARCHAR), 5, '0') AS zip_prefix,
    customer_city  AS city,
    UPPER(customer_state) AS state
FROM read_csv('{raw}/olist_customers_dataset.csv', header = true);

CREATE OR REPLACE TABLE stg_sellers AS
SELECT
    seller_id,
    LPAD(CAST(seller_zip_code_prefix AS VARCHAR), 5, '0') AS zip_prefix,
    seller_city  AS city,
    UPPER(seller_state) AS state
FROM read_csv('{raw}/olist_sellers_dataset.csv', header = true);

CREATE OR REPLACE TABLE stg_products AS
SELECT
    product_id,
    product_category_name                  AS category_pt,
    CAST(product_photos_qty AS INTEGER)    AS photos_qty,
    CAST(product_weight_g AS INTEGER)      AS weight_g,
    CAST(product_length_cm AS INTEGER)     AS length_cm,
    CAST(product_height_cm AS INTEGER)     AS height_cm,
    CAST(product_width_cm AS INTEGER)      AS width_cm
FROM read_csv('{raw}/olist_products_dataset.csv', header = true);

CREATE OR REPLACE TABLE stg_category_translation AS
SELECT product_category_name AS category_pt, product_category_name_english AS category_en
FROM read_csv('{raw}/product_category_name_translation.csv', header = true);

-- Raw reviews: some orders have more than one review and some review_ids repeat across orders.
CREATE OR REPLACE TABLE stg_reviews_raw AS
SELECT
    review_id,
    order_id,
    CAST(review_score AS INTEGER)              AS review_score,
    review_comment_message IS NOT NULL         AS has_comment,
    CAST(review_creation_date AS TIMESTAMP)    AS review_created_ts,
    CAST(review_answer_timestamp AS TIMESTAMP) AS review_answered_ts
FROM read_csv('{raw}/olist_order_reviews_dataset.csv', header = true);

-- One review per order: keep the most recently answered one (the customer's final opinion).
CREATE OR REPLACE TABLE stg_reviews AS
SELECT * EXCLUDE (rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY order_id ORDER BY review_answered_ts DESC, review_id) AS rn
    FROM stg_reviews_raw
)
WHERE rn = 1;
