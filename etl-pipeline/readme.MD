# Documentation for ETL Script

## Overview
This script performs Extract, Transform, and Load (ETL) process for sales data. It extracts data from a CSV file, transforms the data by calculating total amounts and adding product categories, then loads the data into a PostgreSQL database.

## Prerequisites
- Python environment with the required libraries:
  - `pandas`
  - `psycopg2`
- PostgreSQL database set up with credentials matching the `DB_CONFIG` in the script.

## File Information
- **Input File**: `transform_data.csv` (raw sales data in CSV format)
- **Database Table**: `sales`

## Process Steps
1. **Extract**:
   - Loads raw sales data from the CSV file specified in `FILE_PATH`.
2. **Transform**:
   - Converts `price` and `quantity` columns to numeric values.
   - Calculates `total_amount` as the product of `price` and `quantity`.
   - Maps `product_id` to a `category` using `PRODUCT_CATEGORY_MAP`.
   - Removes rows with missing or invalid data.
3. **Load**:
   - Creates the `sales` table in the PostgreSQL database if it does not exist.
   - Inserts transformed data into the `sales` table, ensuring no duplicate entries for `order_id`.

## Database Table Structure
The `sales` table has the following schema:
- `order_id` (INTEGER, PRIMARY KEY)
- `user_id` (INTEGER)
- `order_date` (DATE)
- `product_id` (INTEGER)
- `price` (NUMERIC)
- `quantity` (INTEGER)
- `total_amount` (NUMERIC)
- `category` (VARCHAR)

## Configuration
- Update the `DB_CONFIG` dictionary with your PostgreSQL database credentials:
  ```python
  DB_CONFIG = {
      "dbname": "your_database",
      "user": "your_username",
      "password": "your_password",
      "host": "localhost",
      "port": 5432,
  }
  ```

- Ensure the input CSV file is placed at the path specified by `FILE_PATH`.

## Running the Script
Execute the script using:
```bash
python etl_script.py
```

## Error Handling
- The script includes exception handling to capture and report errors during extraction, transformation, and loading.
- Database connections are safely closed after the operation.

