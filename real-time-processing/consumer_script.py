from psycopg2.pool import SimpleConnectionPool
import psycopg2
import json
import os
from confluent_kafka import Consumer, KafkaException, KafkaError

# Create a global connection pool
db_config = {
    "dbname": os.getenv("POSTGRES_DB", "clickstream_db"),
    "user": os.getenv("POSTGRES_USER", "etl_user"),
    "password": os.getenv("POSTGRES_PASSWORD", "secure_password_123"),
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", "5433")),
}

try:
    connection_pool = SimpleConnectionPool(1, 10, **db_config)
    print("Database connection pool created successfully")
except Exception as e:
    print(f"Failed to create database connection pool: {e}")
    connection_pool = None

def process_message(message):
    conn = None
    try:
        if connection_pool is None:
            print("Database connection pool not available")
            return
            
        # Get a connection from the pool
        conn = connection_pool.getconn()
        with conn.cursor() as cursor:
            # Parsing the message
            message_data = json.loads(message)
            product_id = message_data.get("product_id")
            event = message_data.get("event")

            if not product_id or not event:
                print("Invalid message format, skipping...")
                return
            # Create the sales table if it doesn't exist
            create_table_query = """
                CREATE TABLE IF NOT EXISTS product_views (
                    product_id VARCHAR PRIMARY KEY,
                    view_count INTEGER DEFAULT 0,
                    updated_at TIMESTAMP
                );
            """
            cursor.execute(create_table_query)
            conn.commit()

            # Only process "view" events
            if event == "view":
                cursor.execute(
                    """
                    INSERT INTO product_views (product_id, view_count, updated_at)
                    VALUES (%s, 1, now())
                    ON CONFLICT (product_id)
                    DO UPDATE SET 
                        view_count = product_views.view_count + 1,
                        updated_at = now();
                    """,
                    (product_id,)
                )
                conn.commit()
                print(f"Processed view event for product_id: {product_id}")

    except psycopg2.Error as e:
        print(f"Database error: {e}")
    except json.JSONDecodeError as e:
        print(f"Failed to decode JSON message: {e}")
    finally:
        if conn and connection_pool:
            # Release the connection back to the pool
            connection_pool.putconn(conn)

def consume_messages(consumer, topic):
    consumer.subscribe([topic])
    print(f"Subscribed to topic: {topic}")

    try:
        while True:
            msg = consumer.poll(timeout=1.0)
            if msg is None:
                continue
            if msg.error():
                if msg.error().code() == KafkaError._PARTITION_EOF:
                    print(f"End of partition reached: {msg.topic()} [{msg.partition()}]")
                elif msg.error():
                    raise KafkaException(msg.error())
            else:
                message = msg.value().decode("utf-8")
                print(f"Received message: {message}")
                process_message(message)
    except KeyboardInterrupt:
        print("\nExiting consumer...")
    finally:
        consumer.close()

if __name__ == "__main__":
    # Use broker:9093 when running inside container, localhost:9092 when running from host
    bootstrap_servers = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
    
    consumer = Consumer({
        'bootstrap.servers': bootstrap_servers,
        'group.id': 'python-consumer-group',
        'auto.offset.reset': 'earliest'
    })
    topic = "SPE-testcase"
    consume_messages(consumer, topic)
