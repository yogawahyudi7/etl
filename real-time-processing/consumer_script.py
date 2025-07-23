from psycopg2.pool import SimpleConnectionPool
import psycopg2
import json
import time
from confluent_kafka import Consumer, KafkaError

# Create a global connection pool - we'll try both container name and localhost
db_config = {
    "dbname": "clickstream_db",
    "user": "etl_user",
    "password": "secure_password_123",
    "host": "localhost",  # Use localhost when running from host
    "port": 5433,  # Port diubah ke 5433
}

# Initialize connection pool as None first
connection_pool = None

# Try to setup database connection - if it fails, we'll run in simulation mode
def setup_db():
    global connection_pool
    try:
        print("Setting up database connection...")
        connection_pool = SimpleConnectionPool(1, 10, **db_config)
        
        # Test the connection by getting one
        conn = connection_pool.getconn()
        with conn.cursor() as cursor:
            # Create the clickstream events table if it doesn't exist
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS clickstream_events (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER,
                    timestamp BIGINT,
                    page VARCHAR(100),
                    action VARCHAR(50),
                    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
            conn.commit()
        # Return connection to pool
        connection_pool.putconn(conn)
        print("Database setup completed successfully")
        return True
    except Exception as e:
        print(f"Database setup error: {e}")
        print("Running in simulation mode - events will be printed but not stored in DB")
        return False

# Try to setup DB, but don't fail if it doesn't work
db_available = setup_db()

def process_message(message):
    # Parse message first
    try:
        message_data = json.loads(message)
        # Extract fields with proper fallback
        user_id = message_data.get("user_id", 0)
        timestamp = message_data.get("timestamp", str(int(time.time())))
        page = message_data.get("page", "/unknown")
        action = message_data.get("action", "unknown")
        
        # Format for display
        print(f"Processing: user={user_id}, page={page}, action={action}")
        
        # If DB connection isn't available, just simulate the processing
        if not db_available or connection_pool is None:
            print(f"Simulated storing in DB: user={user_id}, page={page}, action={action}")
            return
            
        # Get a connection from the pool and store in DB
        conn = connection_pool.getconn()
        try:
            with conn.cursor() as cursor:
                # Create the events table if it doesn't exist (should already be created in setup_db)
                cursor.execute("""
                    INSERT INTO clickstream_events (user_id, timestamp, page, action)
                    VALUES (%s, %s, %s, %s)
                """, (user_id, timestamp, page, action))
                conn.commit()
                print(f"Successfully stored event in database")
        except psycopg2.Error as e:
            print(f"Database error: {e}")
        finally:
            # Release the connection back to the pool
            connection_pool.putconn(conn)
            
    except json.JSONDecodeError as e:
        print(f"Failed to decode JSON message: {e}")
    except Exception as e:
        print(f"Unexpected error processing message: {e}")

def consume_messages(topic):
    # Configure Consumer
    consumer_conf = {
        'bootstrap.servers': 'localhost:9092',  # Use localhost for external connections
        'group.id': 'clickstream_consumer',
        'auto.offset.reset': 'earliest'
    }
    
    # Create Consumer instance
    consumer = Consumer(consumer_conf)
    
    # Subscribe to topic
    consumer.subscribe([topic])
    print(f"Subscribed to topic: {topic}")

    try:
        print("Waiting for messages...")
        while True:
            # Poll for messages
            msg = consumer.poll(1.0)
            
            if msg is None:
                continue
                
            if msg.error():
                if msg.error().code() == KafkaError._PARTITION_EOF:
                    # End of partition, continue to next message
                    continue
                else:
                    # Error
                    print(f"Consumer error: {msg.error()}")
                    continue
                    
            # Process message
            try:
                message = msg.value().decode('utf-8')
                print(f"Received message: {message}")
                process_message(message)
            except Exception as e:
                print(f"Error processing message: {e}")
                
    except KeyboardInterrupt:
        print("\nExiting consumer...")
    finally:
        consumer.close()

if __name__ == "__main__":
    topic = "clickstream_data"
    consume_messages(topic)
