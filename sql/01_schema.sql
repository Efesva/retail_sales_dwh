-- Retail Sales Data Warehouse: star schema
-- Demo project with synthetic data. Standard SQL (tested on SQLite, portable to PostgreSQL / SQL Server).

-- Dimensions -----------------------------------------------------------

CREATE TABLE dim_date (
    date_key      INTEGER PRIMARY KEY,   -- YYYYMMDD
    full_date     DATE NOT NULL,
    year          INTEGER NOT NULL,
    quarter       INTEGER NOT NULL,
    month         INTEGER NOT NULL,
    month_name    VARCHAR(12) NOT NULL,
    day_of_week   VARCHAR(10) NOT NULL
);

CREATE TABLE dim_store (
    store_key     INTEGER PRIMARY KEY,
    store_code    VARCHAR(10) NOT NULL,
    store_name    VARCHAR(60) NOT NULL,
    city          VARCHAR(40) NOT NULL,
    format        VARCHAR(20) NOT NULL,   -- Supermarket, Express, Hypermarket
    shelf_meters  DECIMAL(8,2) NOT NULL   -- total linear shelf space
);

CREATE TABLE dim_product (
    product_key   INTEGER PRIMARY KEY,
    sku           VARCHAR(20) NOT NULL,
    product_name  VARCHAR(80) NOT NULL,
    category      VARCHAR(40) NOT NULL,
    brand         VARCHAR(40) NOT NULL,
    unit_cost     DECIMAL(10,2) NOT NULL
);

CREATE TABLE dim_customer (
    customer_key   INTEGER PRIMARY KEY,
    customer_code  VARCHAR(20) NOT NULL,
    segment        VARCHAR(20) NOT NULL,  -- Loyalty Gold, Loyalty Silver, Non-member
    city           VARCHAR(40) NOT NULL,
    signup_date    DATE
);

-- Facts ----------------------------------------------------------------

-- Grain: one row per product per ticket line
CREATE TABLE fact_sales (
    sales_id      INTEGER PRIMARY KEY,
    date_key      INTEGER NOT NULL REFERENCES dim_date(date_key),
    store_key     INTEGER NOT NULL REFERENCES dim_store(store_key),
    product_key   INTEGER NOT NULL REFERENCES dim_product(product_key),
    customer_key  INTEGER NOT NULL REFERENCES dim_customer(customer_key),
    ticket_id     VARCHAR(20) NOT NULL,
    quantity      INTEGER NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL,
    discount      DECIMAL(10,2) NOT NULL DEFAULT 0,
    net_amount    DECIMAL(12,2) NOT NULL
);

-- Grain: one row per product per store per month (planogram snapshot)
CREATE TABLE fact_shelf_space (
    month_key     INTEGER NOT NULL,       -- YYYYMM
    store_key     INTEGER NOT NULL REFERENCES dim_store(store_key),
    product_key   INTEGER NOT NULL REFERENCES dim_product(product_key),
    facings       INTEGER NOT NULL,
    shelf_meters  DECIMAL(8,2) NOT NULL,
    PRIMARY KEY (month_key, store_key, product_key)
);

CREATE INDEX ix_sales_date    ON fact_sales(date_key);
CREATE INDEX ix_sales_store   ON fact_sales(store_key);
CREATE INDEX ix_sales_product ON fact_sales(product_key);
