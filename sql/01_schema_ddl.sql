-- ==============================================================================
-- File: 01_schema_ddl.sql
-- Description: Kimball Dimensional Star Schema DDL for Olist E-Commerce Data Warehouse.
-- Tables:
--   - dim_customers: Customer demographic, state, and geographic keys
--   - dim_products: Product attributes, standardized categories, and physical specs
--   - dim_dates: Calendar date dimension with day, month, quarter, year, weekend flags
--   - dim_geography: Brazilian states, macro-regions, coordinates, and zip ranges
--   - fact_orders: Order header grain with timestamps, payment value, and delivery latency
--   - fact_order_items: Item line-level grain with price, freight, seller, and delivery flags
-- ==============================================================================

PRAGMA foreign_keys = OFF;

-- Drop child fact tables first, then dimension tables
DROP TABLE IF EXISTS fact_order_items;
DROP TABLE IF EXISTS fact_orders;
DROP TABLE IF EXISTS dim_customers;
DROP TABLE IF EXISTS dim_products;
DROP TABLE IF EXISTS dim_dates;
DROP TABLE IF EXISTS dim_geography;

PRAGMA foreign_keys = ON;

-- -----------------------------------------------------------------------------
-- 1. DIMENSION: GEOGRAPHY
-- -----------------------------------------------------------------------------
CREATE TABLE dim_geography (
    state_code VARCHAR(2) PRIMARY KEY,
    state_name VARCHAR(50) NOT NULL,
    macro_region VARCHAR(20) NOT NULL,
    capital_city VARCHAR(50) NOT NULL,
    latitude DECIMAL(9, 6) NOT NULL,
    longitude DECIMAL(9, 6) NOT NULL,
    zip_prefix_start INTEGER NOT NULL,
    zip_prefix_end INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 2. DIMENSION: CUSTOMERS
-- -----------------------------------------------------------------------------
CREATE TABLE dim_customers (
    customer_key INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id VARCHAR(32) UNIQUE NOT NULL,
    customer_unique_id VARCHAR(32) NOT NULL,
    customer_zip_code_prefix INTEGER NOT NULL,
    customer_city VARCHAR(100) NOT NULL,
    customer_state VARCHAR(2) NOT NULL,
    first_purchase_date TIMESTAMP,
    latest_purchase_date TIMESTAMP,
    total_lifetime_orders INTEGER DEFAULT 1,
    total_lifetime_spend DECIMAL(12, 2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_state) REFERENCES dim_geography(state_code)
);

CREATE INDEX idx_dim_customers_unique_id ON dim_customers(customer_unique_id);
CREATE INDEX idx_dim_customers_state ON dim_customers(customer_state);

-- -----------------------------------------------------------------------------
-- 3. DIMENSION: PRODUCTS
-- -----------------------------------------------------------------------------
CREATE TABLE dim_products (
    product_key INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id VARCHAR(32) UNIQUE NOT NULL,
    category_name_pt VARCHAR(100),
    category_name_en VARCHAR(100),
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g DECIMAL(10, 2),
    product_volume_cm3 DECIMAL(12, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_products_category ON dim_products(category_name_en);

-- -----------------------------------------------------------------------------
-- 4. DIMENSION: DATES
-- -----------------------------------------------------------------------------
CREATE TABLE dim_dates (
    date_key INTEGER PRIMARY KEY,         -- Format: YYYYMMDD
    full_date DATE UNIQUE NOT NULL,
    day_of_month INTEGER NOT NULL,
    day_name VARCHAR(10) NOT NULL,
    day_of_week INTEGER NOT NULL,          -- 1=Sunday, 7=Saturday
    is_weekend BOOLEAN NOT NULL,
    calendar_week INTEGER NOT NULL,
    calendar_month INTEGER NOT NULL,
    month_name VARCHAR(15) NOT NULL,
    calendar_quarter INTEGER NOT NULL,
    calendar_year INTEGER NOT NULL
);

-- -----------------------------------------------------------------------------
-- 5. FACT TABLE: ORDERS (Header Grain)
-- -----------------------------------------------------------------------------
CREATE TABLE fact_orders (
    order_key INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id VARCHAR(32) UNIQUE NOT NULL,
    customer_key INTEGER NOT NULL,
    customer_unique_id VARCHAR(32) NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    purchase_date_key INTEGER NOT NULL,
    purchase_timestamp TIMESTAMP NOT NULL,
    approved_timestamp TIMESTAMP,
    carrier_delivered_timestamp TIMESTAMP,
    customer_delivered_timestamp TIMESTAMP,
    estimated_delivery_timestamp TIMESTAMP NOT NULL,
    
    -- Logistics & Delivery KPI metrics
    order_total_value DECIMAL(12, 2) NOT NULL,
    total_freight_value DECIMAL(12, 2) NOT NULL,
    item_count INTEGER NOT NULL,
    delivery_transit_days INTEGER,
    delivery_delay_days INTEGER,          -- positive = late, negative/zero = on-time
    is_delayed BOOLEAN NOT NULL,
    review_score INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (customer_key) REFERENCES dim_customers(customer_key),
    FOREIGN KEY (purchase_date_key) REFERENCES dim_dates(date_key)
);

CREATE INDEX idx_fact_orders_cust_uniq ON fact_orders(customer_unique_id);
CREATE INDEX idx_fact_orders_purchase_date ON fact_orders(purchase_timestamp);
CREATE INDEX idx_fact_orders_delayed ON fact_orders(is_delayed);

-- -----------------------------------------------------------------------------
-- 6. FACT TABLE: ORDER ITEMS (Line Item Grain)
-- -----------------------------------------------------------------------------
CREATE TABLE fact_order_items (
    order_item_key INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id VARCHAR(32) NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_key INTEGER NOT NULL,
    seller_id VARCHAR(32) NOT NULL,
    shipping_limit_date TIMESTAMP NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    freight_value DECIMAL(10, 2) NOT NULL,
    total_item_value DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES fact_orders(order_id),
    FOREIGN KEY (product_key) REFERENCES dim_products(product_key)
);

CREATE INDEX idx_fact_order_items_order_id ON fact_order_items(order_id);
CREATE INDEX idx_fact_order_items_product_key ON fact_order_items(product_key);
