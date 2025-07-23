-- SQL script to process clickstream data and product views
-- Create table for storing clickstream events if it doesn't exist
CREATE TABLE IF NOT EXISTS clickstream_events (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    timestamp BIGINT,
    page VARCHAR(100),
    action VARCHAR(50),
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add processed column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clickstream_events' AND column_name = 'processed'
    ) THEN
        ALTER TABLE clickstream_events ADD COLUMN processed BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- Create table for storing product view metrics
CREATE TABLE IF NOT EXISTS product_views (
    product_id VARCHAR PRIMARY KEY,
    view_count INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data if tables are empty (for demonstration)
INSERT INTO product_views (product_id, view_count, updated_at)
SELECT 'PROD-' || s.id, s.view_count, NOW()
FROM (
    SELECT generate_series(1, 5) AS id, 
           floor(random() * 10 + 1)::int AS view_count
) s
WHERE NOT EXISTS (SELECT 1 FROM product_views LIMIT 1);

-- Create a temporary table to track which events we're processing in this run
CREATE TEMP TABLE events_to_process AS
SELECT 
    id,
    REPLACE(page, '/product-', 'PROD-') AS product_id
FROM clickstream_events 
WHERE 
    page LIKE '/product-%' AND
    (processed = FALSE OR processed IS NULL);

-- Update product views based on events_to_process
WITH new_views AS (
    SELECT 
        product_id,
        COUNT(*) AS new_views
    FROM events_to_process
    GROUP BY product_id
)
UPDATE product_views pv
SET 
    view_count = view_count + nv.new_views,
    updated_at = NOW()
FROM new_views nv
WHERE pv.product_id = nv.product_id;

-- Mark processed events
UPDATE clickstream_events
SET processed = TRUE
WHERE id IN (SELECT id FROM events_to_process);

-- Drop the temporary table
DROP TABLE events_to_process;

-- Show product view metrics
SELECT 'Product view metrics:' AS message;
SELECT * FROM product_views ORDER BY view_count DESC;

-- Sample query showing product views trend
SELECT 'Product views distribution:' AS message;
SELECT 
    CASE 
        WHEN view_count >= 8 THEN 'High Interest'
        WHEN view_count >= 4 THEN 'Medium Interest'
        ELSE 'Low Interest'
    END AS interest_level,
    COUNT(*) AS products_count
FROM product_views
GROUP BY interest_level
ORDER BY products_count DESC;
