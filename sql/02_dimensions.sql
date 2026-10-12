-- 02_dimensions.sql
-- Conformed dimensions for the star schema.

CREATE OR REPLACE TABLE dim_date AS
SELECT
    CAST(STRFTIME(d, '%Y%m%d') AS INTEGER) AS date_key,
    CAST(d AS DATE)                        AS date,
    YEAR(d)                                AS year,
    QUARTER(d)                             AS quarter,
    MONTH(d)                               AS month,
    STRFTIME(d, '%Y-%m')                   AS year_month,
    STRFTIME(d, '%b')                      AS month_name,
    DAYOFWEEK(d)                           AS day_of_week,  -- 0 = Sunday
    STRFTIME(d, '%a')                      AS day_name,
    DAYOFWEEK(d) IN (0, 6)                 AS is_weekend
FROM RANGE(DATE '2016-01-01', DATE '2019-01-01', INTERVAL 1 DAY) AS t(d);

CREATE OR REPLACE TABLE dim_customer AS
SELECT customer_id, customer_unique_id, zip_prefix, city, state
FROM stg_customers;

CREATE OR REPLACE TABLE dim_seller AS
SELECT seller_id, zip_prefix, city, state
FROM stg_sellers;

CREATE OR REPLACE TABLE dim_product AS
SELECT
    p.product_id,
    p.category_pt,
    -- A few Portuguese categories have no translation; fall back to the original, then 'unknown'.
    COALESCE(t.category_en, p.category_pt, 'unknown') AS category,
    p.photos_qty,
    p.weight_g,
    p.length_cm * p.height_cm * p.width_cm AS volume_cm3
FROM stg_products p
LEFT JOIN stg_category_translation t USING (category_pt);
