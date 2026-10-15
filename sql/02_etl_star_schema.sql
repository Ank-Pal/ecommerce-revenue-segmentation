-- ==============================================================================
-- File: 02_etl_star_schema.sql
-- Description: ETL queries to transform raw staged Olist tables into 
--              Kimball Dimensional Star Schema (Dimensions & Facts).
-- ==============================================================================

-- -----------------------------------------------------------------------------
-- 1. POPULATE DIM_GEOGRAPHY
-- -----------------------------------------------------------------------------
INSERT OR REPLACE INTO dim_geography (
    state_code, state_name, macro_region, capital_city, latitude, longitude, zip_prefix_start, zip_prefix_end
) VALUES
('SP', 'Sao Paulo', 'Southeast', 'Sao Paulo', -23.5505, -46.6333, 1000, 19999),
('RJ', 'Rio de Janeiro', 'Southeast', 'Rio de Janeiro', -22.9068, -43.1729, 20000, 28999),
('MG', 'Minas Gerais', 'Southeast', 'Belo Horizonte', -19.9167, -43.9345, 30000, 39999),
('RS', 'Rio Grande do Sul', 'South', 'Porto Alegre', -30.0346, -51.2177, 90000, 99999),
('PR', 'Parana', 'South', 'Curitiba', -25.4284, -49.2733, 80000, 87999),
('SC', 'Santa Catarina', 'South', 'Florianopolis', -27.5954, -48.5480, 88000, 89999),
('BA', 'Bahia', 'Northeast', 'Salvador', -12.9714, -38.5014, 40000, 48999),
('DF', 'Distrito Federal', 'Central-West', 'Brasilia', -15.7975, -47.8919, 70000, 72799),
('GO', 'Goias', 'Central-West', 'Goiania', -16.6869, -49.2648, 72800, 76799),
('PE', 'Pernambuco', 'Northeast', 'Recife', -8.0476, -34.8770, 50000, 56999),
('CE', 'Ceara', 'Northeast', 'Fortaleza', -3.7172, -38.5433, 60000, 63999),
('ES', 'Espirito Santo', 'Southeast', 'Vitoria', -20.3155, -40.3128, 29000, 29999),
('MT', 'Mato Grosso', 'Central-West', 'Cuiaba', -15.6010, -56.0974, 78000, 78899),
('MS', 'Mato Grosso do Sul', 'Central-West', 'Campo Grande', -20.4697, -54.6201, 79000, 79999),
('MA', 'Maranhao', 'Northeast', 'Sao Luis', -2.5307, -44.3068, 65000, 65999),
('PA', 'Para', 'North', 'Belem', -1.4558, -48.4902, 66000, 68899),
('RN', 'Rio Grande do Norte', 'Northeast', 'Natal', -5.7945, -35.2110, 59000, 59999),
('PB', 'Paraiba', 'Northeast', 'Joao Pessoa', -7.1195, -34.8450, 58000, 58999),
('PI', 'Piaui', 'Northeast', 'Teresina', -5.0920, -42.8038, 64000, 64999),
('AL', 'Alagoas', 'Northeast', 'Maceio', -9.6658, -35.7351, 57000, 57999),
('SE', 'Sergipe', 'Northeast', 'Aracaju', -10.9472, -37.0731, 49000, 49999),
('TO', 'Tocantins', 'North', 'Palmas', -10.2491, -48.3243, 77000, 77999),
('RO', 'Rondonia', 'North', 'Porto Velho', -8.7612, -63.9039, 76800, 76999),
('AM', 'Amazonas', 'North', 'Manaus', -3.1190, -60.0217, 69000, 69299),
('AC', 'Acre', 'North', 'Rio Branco', -9.9754, -67.8249, 69900, 69999),
('AP', 'Amapa', 'North', 'Macapa', 0.0355, -51.0705, 68900, 68999),
('RR', 'Roraima', 'North', 'Boa Vista', 2.8235, -60.6758, 69300, 69399);

-- -----------------------------------------------------------------------------
-- 2. POPULATE DIM_PRODUCTS
-- -----------------------------------------------------------------------------
INSERT OR REPLACE INTO dim_products (
    product_id, category_name_pt, category_name_en, product_name_length,
    product_description_length, product_photos_qty, product_weight_g, product_volume_cm3
)
SELECT 
    p.product_id,
    p.product_category_name,
    COALESCE(p.product_category_name_english, p.product_category_name, 'other'),
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    ROUND((p.product_length_cm * p.product_height_cm * p.product_width_cm), 2) AS product_volume_cm3
FROM stg_products p;

-- -----------------------------------------------------------------------------
-- 3. POPULATE DIM_DATES (Calendar Dimension via Recursive CTE)
-- -----------------------------------------------------------------------------
WITH RECURSIVE date_series(d) AS (
    SELECT DATE('2016-01-01')
    UNION ALL
    SELECT DATE(d, '+1 day')
    FROM date_series
    WHERE d < DATE('2018-12-31')
)
INSERT OR REPLACE INTO dim_dates (
    date_key, full_date, day_of_month, day_name, day_of_week,
    is_weekend, calendar_week, calendar_month, month_name, calendar_quarter, calendar_year
)
SELECT 
    CAST(strftime('%Y%m%d', d) AS INTEGER) AS date_key,
    d AS full_date,
    CAST(strftime('%d', d) AS INTEGER) AS day_of_month,
    CASE strftime('%w', d)
        WHEN '0' THEN 'Sunday'
        WHEN '1' THEN 'Monday'
        WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday'
        WHEN '4' THEN 'Thursday'
        WHEN '5' THEN 'Friday'
        ELSE 'Saturday'
    END AS day_name,
    CAST(strftime('%w', d) AS INTEGER) + 1 AS day_of_week,
    CASE WHEN strftime('%w', d) IN ('0', '6') THEN 1 ELSE 0 END AS is_weekend,
    CAST(strftime('%W', d) AS INTEGER) AS calendar_week,
    CAST(strftime('%m', d) AS INTEGER) AS calendar_month,
    CASE strftime('%m', d)
        WHEN '01' THEN 'January'
        WHEN '02' THEN 'February'
        WHEN '03' THEN 'March'
        WHEN '04' THEN 'April'
        WHEN '05' THEN 'May'
        WHEN '06' THEN 'June'
        WHEN '07' THEN 'July'
        WHEN '08' THEN 'August'
        WHEN '09' THEN 'September'
        WHEN '10' THEN 'October'
        WHEN '11' THEN 'November'
        ELSE 'December'
    END AS month_name,
    ((CAST(strftime('%m', d) AS INTEGER) - 1) / 3) + 1 AS calendar_quarter,
    CAST(strftime('%Y', d) AS INTEGER) AS calendar_year
FROM date_series;

-- -----------------------------------------------------------------------------
-- 4. POPULATE DIM_CUSTOMERS WITH LIFETIME AGGREGATES
-- -----------------------------------------------------------------------------
INSERT OR REPLACE INTO dim_customers (
    customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state,
    first_purchase_date, latest_purchase_date, total_lifetime_orders, total_lifetime_spend
)
WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_purchase,
        MAX(o.order_purchase_timestamp) AS latest_purchase,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM stg_customers c
    JOIN stg_orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
),
customer_spend AS (
    SELECT 
        c.customer_unique_id,
        ROUND(SUM(oi.price + oi.freight_value), 2) AS total_spend
    FROM stg_customers c
    JOIN stg_orders o ON c.customer_id = o.customer_id
    JOIN stg_order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)
SELECT 
    c.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,
    co.first_purchase,
    co.latest_purchase,
    COALESCE(co.total_orders, 1),
    COALESCE(cs.total_spend, 0.00)
FROM stg_customers c
LEFT JOIN customer_orders co ON c.customer_unique_id = co.customer_unique_id
LEFT JOIN customer_spend cs ON c.customer_unique_id = cs.customer_unique_id;

-- -----------------------------------------------------------------------------
-- 4. POPULATE FACT_ORDERS (Header Grain)
-- -----------------------------------------------------------------------------
INSERT OR REPLACE INTO fact_orders (
    order_id, customer_key, customer_unique_id, order_status, purchase_date_key,
    purchase_timestamp, approved_timestamp, carrier_delivered_timestamp,
    customer_delivered_timestamp, estimated_delivery_timestamp,
    order_total_value, total_freight_value, item_count,
    delivery_transit_days, delivery_delay_days, is_delayed, review_score
)
WITH order_metrics AS (
    SELECT 
        oi.order_id,
        COUNT(oi.order_item_id) AS item_count,
        ROUND(SUM(oi.price), 2) AS item_subtotal,
        ROUND(SUM(oi.freight_value), 2) AS total_freight,
        ROUND(SUM(oi.price + oi.freight_value), 2) AS total_order_val
    FROM stg_order_items oi
    GROUP BY oi.order_id
)
SELECT 
    o.order_id,
    dc.customer_key,
    dc.customer_unique_id,
    o.order_status,
    CAST(strftime('%Y%m%d', o.order_purchase_timestamp) AS INTEGER) AS purchase_date_key,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    COALESCE(om.total_order_val, 0.00),
    COALESCE(om.total_freight, 0.00),
    COALESCE(om.item_count, 1),
    -- Transit latency in days
    CASE 
        WHEN o.order_delivered_customer_date IS NOT NULL 
        THEN CAST((julianday(o.order_delivered_customer_date) - julianday(o.order_purchase_timestamp)) AS INTEGER)
        ELSE NULL 
    END AS delivery_transit_days,
    -- Delivery delay: positive = days past estimated date
    CASE 
        WHEN o.order_delivered_customer_date IS NOT NULL 
        THEN CAST((julianday(o.order_delivered_customer_date) - julianday(o.order_estimated_delivery_date)) AS INTEGER)
        ELSE NULL 
    END AS delivery_delay_days,
    -- Flag if delivered after estimated date
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1
        ELSE 0
    END AS is_delayed,
    r.review_score
FROM stg_orders o
JOIN dim_customers dc ON o.customer_id = dc.customer_id
LEFT JOIN order_metrics om ON o.order_id = om.order_id
LEFT JOIN stg_reviews r ON o.order_id = r.order_id;

-- -----------------------------------------------------------------------------
-- 5. POPULATE FACT_ORDER_ITEMS (Line Item Grain)
-- -----------------------------------------------------------------------------
INSERT OR REPLACE INTO fact_order_items (
    order_id, order_item_id, product_key, seller_id, shipping_limit_date,
    price, freight_value, total_item_value
)
SELECT 
    oi.order_id,
    oi.order_item_id,
    dp.product_key,
    oi.seller_id,
    oi.shipping_limit_date,
    oi.price,
    oi.freight_value,
    ROUND(oi.price + oi.freight_value, 2) AS total_item_value
FROM stg_order_items oi
JOIN dim_products dp ON oi.product_id = dp.product_id;
