-- E-commerce Analytics Queries
-- Business intelligence and analytical queries for the FakeStore data
-- Run these after data has been loaded into Snowflake

USE ECOMMERCE_DB.RAW_DATA;

-- PRODUCT ANALYSIS

-- 1. Product Performance by Category
SELECT 
    category,
    COUNT(*) as product_count,
    ROUND(AVG(price), 2) as avg_price,
    ROUND(MIN(price), 2) as min_price,
    ROUND(MAX(price), 2) as max_price,
    ROUND(AVG(rating_rate), 2) as avg_rating,
    SUM(rating_count) as total_reviews
FROM products_table 
GROUP BY category
ORDER BY avg_rating DESC, avg_price DESC;

-- 2. Top 10 Most Expensive Products
SELECT 
    id,
    title,
    category,
    price,
    rating_rate,
    rating_count
FROM products_table
ORDER BY price DESC
LIMIT 10;

-- 3. Best Rated Products (minimum 100 reviews)
SELECT 
    id,
    title,
    category,
    price,
    rating_rate,
    rating_count,
    ROUND(price / rating_rate, 2) as price_per_rating_point
FROM products_table
WHERE rating_count >= 100
ORDER BY rating_rate DESC, rating_count DESC
LIMIT 15;

-- 4. Price Distribution Analysis
SELECT 
    CASE 
        WHEN price < 25 THEN 'Under $25'
        WHEN price < 50 THEN '$25-$49'
        WHEN price < 100 THEN '$50-$99'
        WHEN price < 200 THEN '$100-$199'
        ELSE '$200+'
    END as price_range,
    COUNT(*) as product_count,
    ROUND(AVG(rating_rate), 2) as avg_rating
FROM products_table
GROUP BY 
    CASE 
        WHEN price < 25 THEN 'Under $25'
        WHEN price < 50 THEN '$25-$49'
        WHEN price < 100 THEN '$50-$99'
        WHEN price < 200 THEN '$100-$199'
        ELSE '$200+'
    END
ORDER BY MIN(price);

-- CUSTOMER ANALYSIS

-- 5. Geographic Distribution of Users
SELECT 
    address_city,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM users_table 
WHERE address_city IS NOT NULL
GROUP BY address_city
ORDER BY user_count DESC;

-- 6. User Address Patterns
SELECT 
    SUBSTR(address_zipcode, 1, 5) as zip_prefix,
    address_city,
    COUNT(*) as user_count
FROM users_table
WHERE address_zipcode IS NOT NULL AND address_city IS NOT NULL
GROUP BY SUBSTR(address_zipcode, 1, 5), address_city
ORDER BY user_count DESC
LIMIT 10;

-- SHOPPING CART ANALYSIS

-- 7. Cart Size Distribution
WITH cart_analysis AS (
    SELECT 
        id as cart_id,
        userid,
        DATE(date) as cart_date,
        ARRAY_SIZE(PARSE_JSON(products)) as product_count
    FROM carts_table
)
SELECT 
    CASE 
        WHEN product_count = 1 THEN '1 item'
        WHEN product_count = 2 THEN '2 items'
        WHEN product_count = 3 THEN '3 items'
        WHEN product_count BETWEEN 4 AND 5 THEN '4-5 items'
        ELSE '6+ items'
    END as cart_size,
    COUNT(*) as cart_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM cart_analysis
GROUP BY 
    CASE 
        WHEN product_count = 1 THEN '1 item'
        WHEN product_count = 2 THEN '2 items'
        WHEN product_count = 3 THEN '3 items'
        WHEN product_count BETWEEN 4 AND 5 THEN '4-5 items'
        ELSE '6+ items'
    END
ORDER BY MIN(product_count);

-- 8. Most Popular Products in Carts
WITH cart_products AS (
    SELECT 
        c.id as cart_id,
        c.userid,
        f.value:productId::int as product_id,
        f.value:quantity::int as quantity
    FROM carts_table c,
    LATERAL FLATTEN(input => PARSE_JSON(c.products)) f
)
SELECT 
    cp.product_id,
    p.title,
    p.category,
    p.price,
    COUNT(DISTINCT cp.cart_id) as times_in_cart,
    SUM(cp.quantity) as total_quantity,
    COUNT(DISTINCT cp.userid) as unique_customers
FROM cart_products cp
JOIN products_table p ON cp.product_id = p.id
GROUP BY cp.product_id, p.title, p.category, p.price
ORDER BY times_in_cart DESC, total_quantity DESC
LIMIT 15;

-- 9. Customer Purchase Behavior
WITH customer_metrics AS (
    SELECT 
        c.userid,
        u.name_firstname,
        u.name_lastname,
        u.address_city,
        COUNT(c.id) as total_carts,
        SUM(ARRAY_SIZE(PARSE_JSON(c.products))) as total_items,
        COUNT(DISTINCT DATE(c.date)) as shopping_days
    FROM carts_table c
    JOIN users_table u ON c.userid = u.id
    GROUP BY c.userid, u.name_firstname, u.name_lastname, u.address_city
)
SELECT 
    userid,
    CONCAT(name_firstname, ' ', name_lastname) as customer_name,
    address_city,
    total_carts,
    total_items,
    shopping_days,
    ROUND(total_items / total_carts, 2) as avg_items_per_cart,
    ROUND(total_carts / shopping_days, 2) as carts_per_day
FROM customer_metrics
ORDER BY total_items DESC, total_carts DESC
LIMIT 20;

-- REVENUE ANALYSIS

-- 10. Revenue Potential by Cart
WITH cart_revenue AS (
    SELECT 
        c.id as cart_id,
        c.userid,
        u.name_firstname || ' ' || u.name_lastname as customer_name,
        DATE(c.date) as cart_date,
        cp.product_id,
        p.title as product_name,
        p.category,
        cp.quantity,
        p.price,
        ROUND(cp.quantity * p.price, 2) as line_total
    FROM carts_table c
    JOIN users_table u ON c.userid = u.id,
    LATERAL FLATTEN(input => PARSE_JSON(c.products)) f
    JOIN products_table p ON f.value:productId::int = p.id,
    TABLE(FLATTEN(input => ARRAY_CONSTRUCT(OBJECT_CONSTRUCT('product_id', f.value:productId::int, 'quantity', f.value:quantity::int)))) cp(SEQ, KEY, VALUE)
    WHERE cp.value:product_id = p.id
)
SELECT 
    cart_id,
    customer_name,
    cart_date,
    COUNT(DISTINCT product_id) as unique_products,
    SUM(quantity) as total_items,
    ROUND(SUM(line_total), 2) as cart_value
FROM cart_revenue
GROUP BY cart_id, customer_name, cart_date
ORDER BY cart_value DESC
LIMIT 20;

-- 11. Customer Lifetime Value Analysis
WITH customer_revenue AS (
    SELECT 
        c.userid,
        u.name_firstname || ' ' || u.name_lastname as customer_name,
        u.address_city,
        COUNT(c.id) as total_orders,
        SUM(ARRAY_SIZE(PARSE_JSON(c.products))) as total_items_purchased,
        -- Calculate total revenue per customer
        SUM(
            (SELECT SUM(f.value:quantity::int * p.price)
             FROM LATERAL FLATTEN(input => PARSE_JSON(c.products)) f
             JOIN products_table p ON f.value:productId::int = p.id)
        ) as total_revenue
    FROM carts_table c
    JOIN users_table u ON c.userid = u.id
    GROUP BY c.userid, u.name_firstname, u.name_lastname, u.address_city
)
SELECT 
    userid,
    customer_name,
    address_city,
    total_orders,
    total_items_purchased,
    ROUND(total_revenue, 2) as lifetime_value,
    ROUND(total_revenue / total_orders, 2) as avg_order_value,
    ROUND(total_items_purchased / total_orders, 2) as avg_items_per_order
FROM customer_revenue
WHERE total_revenue > 0
ORDER BY lifetime_value DESC
LIMIT 25;

-- TIME-BASED ANALYSIS

-- 12. Shopping Patterns by Date
SELECT 
    DATE(date) as shopping_date,
    DAYNAME(date) as day_of_week,
    COUNT(*) as total_carts,
    COUNT(DISTINCT userid) as unique_customers,
    SUM(ARRAY_SIZE(PARSE_JSON(products))) as total_items
FROM carts_table
GROUP BY DATE(date), DAYNAME(date)
ORDER BY shopping_date;

-- 13. Monthly Shopping Trends
SELECT 
    YEAR(date) as year,
    MONTH(date) as month,
    MONTHNAME(date) as month_name,
    COUNT(*) as total_carts,
    COUNT(DISTINCT userid) as unique_customers,
    ROUND(AVG(ARRAY_SIZE(PARSE_JSON(products))), 2) as avg_items_per_cart
FROM carts_table
GROUP BY YEAR(date), MONTH(date), MONTHNAME(date)
ORDER BY year, month;

-- BUSINESS INSIGHTS SUMMARY

-- 14. Executive Summary Dashboard
SELECT 'BUSINESS_METRICS' as metric_type, 'Total Products' as metric, COUNT(*)::VARCHAR as value FROM products_table
UNION ALL
SELECT 'BUSINESS_METRICS', 'Total Customers', COUNT(*)::VARCHAR FROM users_table
UNION ALL
SELECT 'BUSINESS_METRICS', 'Total Carts', COUNT(*)::VARCHAR FROM carts_table
UNION ALL
SELECT 'BUSINESS_METRICS', 'Avg Products per Category', ROUND(COUNT(*) / COUNT(DISTINCT category), 1)::VARCHAR FROM products_table
UNION ALL
SELECT 'REVENUE_METRICS', 'Highest Product Price', '$' || MAX(price)::VARCHAR FROM products_table
UNION ALL
SELECT 'REVENUE_METRICS', 'Average Product Price', '$' || ROUND(AVG(price), 2)::VARCHAR FROM products_table
UNION ALL
SELECT 'QUALITY_METRICS', 'Average Product Rating', ROUND(AVG(rating_rate), 2)::VARCHAR FROM products_table
UNION ALL
SELECT 'QUALITY_METRICS', 'Products with 4+ Stars', COUNT(*)::VARCHAR FROM products_table WHERE rating_rate >= 4.0
ORDER BY metric_type, metric;

-- DATA QUALITY CHECKS

-- 15. Data Quality Report
SELECT 
    'Products' as table_name,
    'Total Records' as check_type,
    COUNT(*)::VARCHAR as result
FROM products_table
UNION ALL
SELECT 'Products', 'Missing Prices', COUNT(*)::VARCHAR FROM products_table WHERE price IS NULL
UNION ALL
SELECT 'Products', 'Invalid Ratings', COUNT(*)::VARCHAR FROM products_table WHERE rating_rate < 0 OR rating_rate > 5
UNION ALL
SELECT 'Users', 'Total Records', COUNT(*)::VARCHAR FROM users_table
UNION ALL
SELECT 'Users', 'Missing Emails', COUNT(*)::VARCHAR FROM users_table WHERE email IS NULL
UNION ALL
SELECT 'Users', 'Invalid Emails', COUNT(*)::VARCHAR FROM users_table WHERE email NOT LIKE '%@%.%'
UNION ALL
SELECT 'Carts', 'Total Records', COUNT(*)::VARCHAR FROM carts_table
UNION ALL
SELECT 'Carts', 'Orphaned Carts', COUNT(*)::VARCHAR FROM carts_table c LEFT JOIN users_table u ON c.userid = u.id WHERE u.id IS NULL
ORDER BY table_name, check_type;