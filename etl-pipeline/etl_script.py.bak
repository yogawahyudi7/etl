import pandas as pd
import psycopg2
from psycopg2 import sql

# Database credentials (updated for Docker container)
DB_CONFIG = {
    "dbname": "clickstream_db",
    "user": "etl_user",
    "password": "secure_password_123",
    "host": "localhost",  # When running inside container, use localhost
    "port": 5433,
}

# File path for the raw CSV file
FILE_PATH = "transform_data.csv"  # Path relative to the etl-pipeline directory

# Mapping for product categories
PRODUCT_CATEGORY_MAP = {
    501: "Electronics",
    502: "Furniture",
}

def extract(file_path):
    """Load the raw sales data from a CSV file."""
    try:
        data = pd.read_csv(file_path)
        print("Data loaded successfully.")
        return data
    except Exception as e:
        raise Exception(f"Error loading data: {e}")

def transform(data):
    """Transform the raw data to calculate total_amount and add category."""
    try:
        # Ensure numeric columns for calculations
        data["price"] = pd.to_numeric(data["price"], errors="coerce")
        data["quantity"] = pd.to_numeric(data["quantity"], errors="coerce")
        
        # Calculate total_amount
        data["total_amount"] = data["price"] * data["quantity"]
        
        # Add category column
        data["category"] = data["product_id"].map(PRODUCT_CATEGORY_MAP)
        
        # Drop rows with missing or invalid values
        data_cleaned = data.dropna()
        print("Data transformed successfully.")
        return data_cleaned
    except Exception as e:
        raise Exception(f"Error during transformation: {e}")

def load(data, db_config):
    """Load the transformed data into a PostgreSQL database."""
    conn = None
    cursor = None
    try:
        # Connect to the PostgreSQL database
        conn = psycopg2.connect(**db_config)
        cursor = conn.cursor()
        
        # Create the sales table if it doesn't exist
        create_table_query = """
        CREATE TABLE IF NOT EXISTS sales (
            order_id INTEGER PRIMARY KEY,
            user_id INTEGER,
            order_date DATE,
            product_id INTEGER,
            price NUMERIC,
            quantity INTEGER,
            total_amount NUMERIC,
            category VARCHAR
        );
        """
        cursor.execute(create_table_query)
        conn.commit()
        
        # Insert data into the sales table
        insert_query = """
        INSERT INTO sales (order_id, user_id, order_date, product_id, price, quantity, total_amount, category)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (order_id) DO NOTHING;
        """
        for _, row in data.iterrows():
            cursor.execute(insert_query, (
                int(row["order_id"]),
                int(row["user_id"]),
                row["order_date"],
                int(row["product_id"]),
                float(row["price"]),
                int(row["quantity"]),
                float(row["total_amount"]),
                row["category"]
            ))
        
        # Commit the transaction
        conn.commit()
        print("Data loaded into PostgreSQL successfully.")
    except Exception as e:
        raise Exception(f"Error loading data into PostgreSQL: {e}")
    finally:
        # Close the database connection
        if cursor:
            cursor.close()
        if conn:
            conn.close()

def main():
    """Main function to execute the ETL process."""
    try:
        # Extract
        raw_data = extract(FILE_PATH)
        
        # Transform
        transformed_data = transform(raw_data)
        
        # Load
        load(transformed_data, DB_CONFIG)
    except Exception as e:
        print(f"ETL process failed: {e}")

if __name__ == "__main__":
    main()
