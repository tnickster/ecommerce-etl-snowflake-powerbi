-- E-commerce Data Pipeline - Snowflake Setup
-- This script sets up the complete Snowflake environment for the FakeStore API data pipeline

-- Create database and schema
CREATE DATABASE IF NOT EXISTS ECOMMERCE_DB;
CREATE SCHEMA IF NOT EXISTS ECOMMERCE_DB.RAW_DATA;
USE ECOMMERCE_DB.RAW_DATA;

-- TABLE CREATION

-- Products table - stores product catalog information
CREATE OR REPLACE TABLE products_table (
    id INTEGER PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    image VARCHAR(500),
    rating_rate DECIMAL(3,2),
    rating_count INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Users table - stores customer information
CREATE OR REPLACE TABLE users_table (
    id INTEGER PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(50), -- In production, this would be hashed
    phone VARCHAR(20),
    __v INTEGER DEFAULT 0,
    address_geolocation_lat DECIMAL(10,7),
    address_geolocation_long DECIMAL(10,7),
    address_city VARCHAR(100),
    address_street VARCHAR(200),
    address_number INTEGER,
    address_zipcode VARCHAR(20),
    name_firstname VARCHAR(50),
    name_lastname VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Carts table - stores shopping cart and order information
CREATE OR REPLACE TABLE carts_table (
    id INTEGER PRIMARY KEY,
    userid INTEGER NOT NULL,
    date TIMESTAMP NOT NULL,
    products VARIANT NOT NULL, -- JSON array containing product details
    __v INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    
    -- Foreign key constraint
    CONSTRAINT fk_cart_user FOREIGN KEY (userid) REFERENCES users_table(id)
);

-- FILE FORMAT AND STAGE SETUP

-- Create file format for CSV import
CREATE OR REPLACE FILE FORMAT csv_format
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    REPLACE_INVALID_CHARACTERS = TRUE
    NULL_IF = ('NULL', 'null', '', 'None')
    EMPTY_FIELD_AS_NULL = TRUE;

-- Create external stage pointing to S3 bucket
-- NOTE: Replace with your actual AWS credentials
CREATE OR REPLACE STAGE s3_stage
    URL = 's3://ecommerce-cleaned-nick-v1/cleaned/'
    CREDENTIALS = (
        AWS_KEY_ID = 'YOUR_AWS_ACCESS_KEY_ID'
        AWS_SECRET_KEY = 'YOUR_AWS_SECRET_ACCESS_KEY'
    )
    FILE_FORMAT = csv_format;

-- DATA LOADING COMMANDS

-- Load products data from S3
COPY INTO products_table (
    id, title, price, description, category, image, rating_rate, rating_count
)
FROM @s3_stage/products_clean.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE'
PURGE = FALSE;

-- Load users data from S3
COPY INTO users_table (
    id, email, username, password, phone, __v,
    address_geolocation_lat, address_geolocation_long,
    address_city, address_street, address_number, address_zipcode,
    name_firstname, name_lastname
)
FROM @s3_stage/users_clean.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE'
PURGE = FALSE;

-- Load carts data from S3
COPY INTO carts_table (
    id, userid, date, products, __v
)
FROM @s3_stage/carts_clean.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE'
PURGE = FALSE;

-- DATA VALIDATION

-- Verify data loading success
SELECT 
    'PRODUCTS' as table_name, 
    COUNT(*) as row_count,
    MIN(created_at) as first_loaded,
    MAX(created_at) as last_loaded
FROM products_table
UNION ALL
SELECT 
    'USERS' as table_name, 
    COUNT(*) as row_count,
    MIN(created_at) as first_loaded,
    MAX(created_at) as last_loaded
FROM users_table
UNION ALL
SELECT 
    'CARTS' as table_name, 
    COUNT(*) as row_count,
    MIN(created_at) as first_loaded,
    MAX(created_at) as last_loaded
FROM carts_table;

-- Check for any data quality issues
SELECT 
    'Products with missing prices' as check_name,
    COUNT(*) as issue_count
FROM products_table 
WHERE price IS NULL OR price <= 0
UNION ALL
SELECT 
    'Users with invalid emails' as check_name,
    COUNT(*) as issue_count
FROM users_table 
WHERE email IS NULL OR email NOT LIKE '%@%'
UNION ALL
SELECT 
    'Carts with missing user references' as check_name,
    COUNT(*) as issue_count
FROM carts_table c
LEFT JOIN users_table u ON c.userid = u.id
WHERE u.id IS NULL;

-- INDEXES AND OPTIMIZATION

-- Create clustering keys for better query performance
ALTER TABLE products_table CLUSTER BY (category, price);
ALTER TABLE users_table CLUSTER BY (id);
ALTER TABLE carts_table CLUSTER BY (userid, date);

-- Create additional indexes for common query patterns
CREATE OR REPLACE VIEW product_summary AS
SELECT 
    category,
    COUNT(*) as product_count,
    AVG(price) as avg_price,
    MIN(price) as min_price,
    MAX(price) as max_price,
    AVG(rating_rate) as avg_rating
FROM products_table
GROUP BY category;

COMMENT ON TABLE products_table IS 'Product catalog data from FakeStore API';
COMMENT ON TABLE users_table IS 'Customer information and addresses';
COMMENT ON TABLE carts_table IS 'Shopping cart and purchase data with JSON product details';