# Documentation for Kafka Consumer with PostgreSQL Integration

## Overview
This script processes messages from a Kafka topic and updates a PostgreSQL database with product view counts. It implements a connection pool to efficiently manage database connections, reducing the overhead of repeatedly creating connections.

## Prerequisites
- **Kafka**:
  - Kafka server running and accessible at `localhost:9092`.
  - Kafka topic: `SPE-testcase`.
- **PostgreSQL**:
  - Database configured with the following schema:
    ```sql
    CREATE TABLE product_views (
        product_id VARCHAR PRIMARY KEY,
        view_count INT NOT NULL,
        updated_at TIMESTAMP NOT NULL
    );
    ```
  - Database credentials and connection details must match `db_config`.

## Configuration
### Database Configuration
- Update `db_config` with your PostgreSQL database credentials:
  ```python
  db_config = {
      "dbname": "postgres",
      "user": "your_username",
      "password": "your_password",
      "host": "localhost",
      "port": 5432,
  }
  ```

### Kafka Configuration
- Consumer settings:
  - `bootstrap.servers`: Kafka broker address.
  - `group.id`: Consumer group ID.
  - `auto.offset.reset`: Set to `earliest` to process messages from the beginning.

## Process Workflow
1. **Database Connection Pool**:
   - A global connection pool is initialized with `SimpleConnectionPool` to manage database connections efficiently.
2. **Message Processing**:
   - Parses JSON messages from the Kafka topic.
   - Processes only valid messages with the "view" event.
   - Updates the `product_views` table using an upsert mechanism.
3. **Kafka Consumer**:
   - Subscribes to the `SPE-testcase` topic.
   - Polls messages continuously and processes them.

## Running the Script
1. Ensure Kafka and PostgreSQL services are running.
2. Execute the script:
   ```bash
   python kafka_postgres_consumer.py
   ```
3. open `localhost:7777` -> topic -> create topic `SPE-testcase` -> Produce Message -> {"user_id": "101", "timestamp": "2023-12-01T12:00:00", "event": "view", "product_id": "501"}

## Error Handling
- Handles database errors (`psycopg2.Error`) and JSON parsing errors (`json.JSONDecodeError`).
- Logs invalid messages and skips processing.
- Ensures database connections are returned to the pool after use.

## Exiting
- Use `Ctrl+C` to gracefully exit the consumer process.