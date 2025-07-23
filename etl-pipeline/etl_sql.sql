-- ETL Script untuk Sales Data
-- Extract, Transform, Load process dalam SQL

-- Step 1: Create sales table
CREATE TABLE IF NOT EXISTS sales (
    order_id INTEGER PRIMARY KEY,
    user_id INTEGER,
    order_date DATE,
    product_id INTEGER,
    price NUMERIC,
    quantity INTEGER,
    total_amount NUMERIC,
    category VARCHAR(50)
);

-- Step 2: Create temporary table untuk raw data
CREATE TEMP TABLE raw_sales_data (
    order_id INTEGER,
    user_id INTEGER,
    order_date DATE,
    product_id INTEGER,
    price NUMERIC,
    quantity INTEGER
);

-- Step 3: Insert sample data (simulating Extract phase)
INSERT INTO raw_sales_data (order_id, user_id, order_date, product_id, price, quantity) VALUES
(1, 101, '2023-12-01', 501, 100.00, 2),
(2, 102, '2023-12-02', 502, 150.00, 1),
(3, 103, '2023-12-03', 501, 100.00, 3),
(4, 104, '2023-12-04', 502, 150.00, 2);

-- Step 4: Transform and Load data
INSERT INTO sales (order_id, user_id, order_date, product_id, price, quantity, total_amount, category)
SELECT 
    order_id,
    user_id,
    order_date,
    product_id,
    price,
    quantity,
    price * quantity AS total_amount,
    CASE 
        WHEN product_id = 501 THEN 'Electronics'
        WHEN product_id = 502 THEN 'Furniture'
        ELSE 'Other'
    END AS category
FROM raw_sales_data
ON CONFLICT (order_id) DO NOTHING;

-- Step 5: Verify results
SELECT 'ETL Process Results:' AS message;
SELECT 
    'Total records loaded:' AS metric,
    COUNT(*) AS value
FROM sales;

SELECT 
    'Records by category:' AS breakdown,
    category,
    COUNT(*) AS count,
    SUM(total_amount) AS total_amount
FROM sales 
GROUP BY category;

SELECT * FROM sales ORDER BY order_id;
