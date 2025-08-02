# Data Engineer ETL Project

Modern ETL Pipeline with Kafka, PostgreSQL, and Real-time Data Processing

> **🌐 Read this in other languages:** [English](#) • [Bahasa Indonesia](README.id.md)

## ⚠️ Important Note
This ETL pipeline provides a robust and efficient solution for processing data from various sources. **IMPORTANT:** After using the services, run `./etl_pipeline_run.sh --stop` to properly shut down all containers and free up system resources.

## 📋 Table of Contents
- [Prerequisites](#prerequisites)
- [Quick Start Guide](#quick-start-guide)
- [Project Structure](#-project-structure)
- [Infrastructure Setup](#️-infrastructure-setup)
- [Execution Sequence](#-execution-sequence)
- [ETL Pipeline Execution](#-etl-pipeline-execution)
- [Real-time Processing](#-real-time-processing)
- [SQL Tasks](#-sql-tasks)
- [Debugging & Optimization](#debugging--optimization)
- [Troubleshooting](#-troubleshooting)
- [Monitoring](#-monitoring)
- [Next Steps](#-next-steps)
- [Quick Reference Commands](#quick-reference-commands)

## 🏗️ Infrastructure Setup

### Prerequisites
- Docker and Docker Compose v2+
- At least 4GB RAM available for containers
- Ports 5433, 7777, 9092, 9093 should be available

### 🤖 Automation Scripts

This project includes several automation scripts for ease of use:

1. **etl_pipeline_run.sh** *(Run this first to set up infrastructure)*
   - Runs the main ETL pipeline
   - Starts and stops all Docker services
   - Format: 
     - `./etl_pipeline_run.sh [--sql|--python]` (default: --sql)
     - `./etl_pipeline_run.sh --stop` (to stop services)
   - When using `--python` option:
     - Runs the Python script from the host machine (not in container)
     - Automatically installs required Python packages from `requirements.txt`
     - Temporarily configures ETL script for host-to-container database access
2. **realtime_processing_run.sh** *(Run after ETL pipeline)*
   - Interactive menu for real-time processing
   - Kafka producer/consumer and SQL processing
   - Format: `./realtime_processing_run.sh`
3. **sql_tasks_run.sh** *(Run after real-time processing)*
   - Interactive menu for running SQL tasks
   - Runs various analytical queries and optimizations
   - Format: `./sql_tasks_run.sh`
4. **debugging_optimization_run.sh** *(Run when needed for performance tuning)*
   - Interactive menu for debugging and optimization
   - Generates test data and performance analysis
   - Format: `./debugging_optimization_run.sh`

## 📁 Project Structure
```
etl/
├── docker-compose.yaml       # Infrastructure setup
├── .env                     # Environment variables
├── README.md               # This file
├── README.id.md            # Indonesian version
├── etl_pipeline_run.sh      # Automation script for ETL pipeline
├── debugging_optimization_run.sh  # Automation script for debugging & optimization
├── realtime_processing_run.sh     # Automation script for real-time processing
├── sql_tasks_run.sh        # Automation script for SQL tasks
├── etl-pipeline/
│   ├── etl_sql.sql         # SQL-based ETL script
│   ├── etl_script.py       # Python ETL script (alternative)
│   └── requirements.txt    # Python dependencies
├── data-modeling/
├── debugging-optimization/
├── real-time-processing/
└── sql/
```

### Quick Start Guide
1. **Clone and setup environment**
   ```bash
   git clone <repository-url>
   cd etl
   cp .env.example .env  # Edit with your credentials
   ```
2. **Start the infrastructure**
   ```bash
   docker-compose up -d
   ```
3. **Verify services are running**
   ```bash
   docker-compose ps
   docker-compose logs -f
   ```

### 🔗 Service URLs
- **Kafka UI**: http://localhost:7777
- **PostgreSQL**: localhost:5433
- **Kafka Broker**: localhost:9092 (external), broker:9093 (internal)

### 🛠️ Configuration
#### Environment Variables
Create a `.env` file with:
```env
POSTGRES_USER=etl_user
POSTGRES_PASSWORD=secure_password_123
POSTGRES_DB=clickstream_db
```

#### Volume Persistence
All data is persisted in Docker volumes:
- `postgres_data`: PostgreSQL data
- `kafka_data`: Kafka topics and logs
- `zookeeper_data`: Zookeeper data

## 📊 ETL Pipeline Execution

### Step-by-Step ETL Process
#### Method 1: Using Automation Script
1. **Run the ETL Project Automation Script**
   ```bash
   # On Linux/Mac: Give execution permission (first time only)
   chmod +x etl_pipeline_run.sh
   # On Windows with Git Bash:
   bash etl_pipeline_run.sh
   # On Windows with CMD/PowerShell:
   bash -c "./etl_pipeline_run.sh"
   ```
   This will automatically:
   - Start all Docker services
   - Wait for PostgreSQL to be ready (on port 5433)
   - Run the ETL process
   - Show results and service status
2. **Stop all services when done**
   ```bash
   bash etl_pipeline_run.sh --stop
   ```

#### Method 2: Manual Execution
1. **Ensure Docker services are running**
   ```bash
   docker-compose ps
   # All services should show 'Up' status
   ```
2. **Run the ETL pipeline using SQL script**
   ```bash
   # Copy ETL script to PostgreSQL container
   docker cp etl-pipeline/etl_sql.sql postgres:/tmp/etl_sql.sql
   # Execute ETL process
   docker-compose exec postgres bash -c "psql -U etl_user -d clickstream_db -f /tmp/etl_sql.sql"
   ```
3. **Verify ETL results**
   The script will automatically display:
   - Total records loaded
   - Breakdown by category
   - Sample of transformed data

### ETL Process Overview
The ETL pipeline performs:
- **Extract**: Creates sample order data (simulating data source)
- **Transform**: Calculates total_amount (price × quantity) and categorizes products
- **Load**: Stores processed data in the target table

### Expected Output
```
CREATE TABLE
CREATE TABLE
INSERT 0 4
INSERT 0 4
       message
----------------------
 ETL Process Results:
(1 row)
        metric         | value
-----------------------+-------
 Total records loaded: |     4
(1 row)
      breakdown       |  category   | count | total_amount
----------------------+-------------+-------+--------------
 Records by category: | Furniture   |     2 |       450.00
 Records by category: | Electronics |     2 |       500.00
(2 rows)
```

### 🔍 Troubleshooting
#### Check service status
```bash
docker-compose ps
docker-compose logs -f [service-name]
```

#### Common issues
- **PostgreSQL connection refused**: Wait for health check to pass
- **Kafka not ready**: Ensure Zookeeper is healthy first
- **Port conflicts**: Check if ports 5433, 7777, 9092 are available

#### Manual database access
```bash
# Connect to PostgreSQL directly
docker-compose exec postgres psql -U etl_user -d clickstream_db
# List tables
\dt
# Query data
SELECT * FROM sales;
```

### 🧹 Cleanup
```bash
# Stop all services
docker-compose down
# Remove all data (caution: this deletes all volumes)
docker-compose down -v
# Remove everything including images
docker-compose down --rmi all -v
```

## 🚀 Execution Sequence

For optimal results, follow this recommended execution sequence:

### Step 1: Set Up Infrastructure and Run ETL Pipeline
```bash
# On Windows with Git Bash (using SQL - default):
bash etl_pipeline_run.sh
# OR using Python:
bash etl_pipeline_run.sh --python

# OR on Windows with CMD:
bash -c "./etl_pipeline_run.sh"
bash -c "./etl_pipeline_run.sh --python"  # Using Python
```
This first step will:
- Start all Docker containers (PostgreSQL, Kafka, Zookeeper)
- Create necessary database tables
- Load initial data
- Run the ETL transformations

### Step 2: Process Real-time Data
```bash
# After ETL pipeline completes successfully:
bash realtime_processing_run.sh
```
From the interactive menu:
1. Select option 1 to create Kafka topic
2. Select option 2 to send product view messages
3. Select option 3 to run Kafka consumer
4. Select option 4 to view real-time aggregated results

### Step 3: Run SQL Analytical Tasks
```bash
# After real-time processing:
bash sql_tasks_run.sh
```
This will provide analytical insights based on processed data.

### Step 4: Debugging & Optimization (When Needed)
```bash
# For performance tuning:
bash debugging_optimization_run.sh
```

### Stopping All Services
```bash
# When finished:
bash etl_pipeline_run.sh --stop
```

## 🏃‍♂️ Project Components
1. **ETL Pipeline** (`etl-pipeline/`)
   - Data extraction, transformation, and loading scripts
   - Batch processing using PostgreSQL
   - Sample data generation for simulation

2. **Real-time Processing** (`real-time-processing/`)
   - Kafka consumer for product view stream processing
   - Producer for sending product view events to Kafka
   - Real-time aggregation of product views in PostgreSQL
   - SQL processing for analytics on aggregated data

3. **SQL Tasks** (`sql/`)
   - Database queries and optimizations
   - Task for total spending analysis
   - Task for finding city with highest orders
   - Task for query optimization

4. **Data Modeling** (`data-modeling/`)
   - Database schema and diagrams
   - Entity-relationship diagram

5. **Debugging & Optimization** (`debugging-optimization/`)
   - Performance analysis and optimization scripts
   - Data generator for testing
   - Script for performance optimization

## 🔄 Real-time Processing

The real-time pipeline uses Kafka for stream processing with a dedicated consumer for product view analytics:

### 🎯 Consumer Features

**Enhanced Consumer** (`consumer_script.py`)
- Processes product view events from `SPE-testcase` topic
- Aggregates product view counts in real-time
- Uses connection pooling for better performance
- Automatically creates `product_views` table with:
  - `product_id`: Unique product identifier
  - `view_count`: Aggregated view count per product
  - `updated_at`: Last update timestamp

### 🚀 Running Real-time Processing

```bash
bash realtime_processing_run.sh
```

**Interactive Menu Options:**
1. **Create Kafka topic** - Sets up `SPE-testcase` topic for product views
2. **Produce product view messages** - Sends 8 sample product view events for aggregation
3. **Run Kafka consumer** - Processes product views with real-time aggregation (runs continuously)
4. **View product views table** - Shows aggregated data with analytics and popularity levels
5. **Process results with SQL** - Displays all product views data using SQL file
6. **Run all steps in sequence** - Automated setup and message production
7. **Exit**

**Enhanced Features:**
- 🔍 **Real-time Status Display** - Shows current topic and table status
- 📊 **Analytics Dashboard** - View counts with popularity levels (Low/Medium/High)
- 📈 **Summary Statistics** - Total products, views, averages, and maximums
- 🔄 **Smart Error Handling** - Checks dependencies and provides helpful guidance
- 💡 **Workflow Guidance** - Recommended step-by-step process

### 🎪 Usage Example

**For Product View Analytics:**
1. Choose option **1** (Create topic)
2. Choose option **2** (Send product view messages)
3. Choose option **3** (Run consumer) - keep this running
4. In another terminal, choose option **4** (View results) to see real-time aggregation

### 🔧 Environment Variables

The consumer (`consumer_script.py`) uses these environment variables (automatically set by the script):
- `POSTGRES_DB=clickstream_db`
- `POSTGRES_USER=etl_user` 
- `POSTGRES_PASSWORD=secure_password_123`
- `DB_HOST=localhost`
- `DB_PORT=5433`

### 📊 Sample Message Format

**Product View Event:**
```json
{
  "product_id": "PROD-1001",
  "event": "view",
  "timestamp": "1643723400",
  "user_id": "USER-201"
}
```

## 🔍 Additional Troubleshooting
### Common Issues:
1. **Port conflicts**: Ensure ports 5433, 7777, 9092, 9093 are free
2. **Memory issues**: Allocate at least 4GB RAM to Docker
3. **Permission issues**: Ensure Docker has proper permissions
4. **Connection issues**: When accessing from outside containers, use localhost:9092 for Kafka and localhost:5433 for PostgreSQL

### Health Checks:
All services include health checks. Monitor with:
```bash
docker-compose ps
```

## 📊 Monitoring
- Use Kafka UI at http://localhost:7777 to monitor topics and messages
- PostgreSQL can be accessed via any PostgreSQL client
- Check container logs for debugging: `docker-compose logs [service]`

## 🎯 Next Steps
1. **Scale the pipeline**: Add more complex transformations
2. **Real-time processing**: Implement Kafka consumers for streaming data
3. **Monitoring**: Add logging and metrics collection
4. **Data quality**: Implement validation and error handling
5. **Automation**: Set up CI/CD pipeline for deployments

### Quick Reference Commands
```bash
# Start services
docker-compose up -d
# Stop services
docker-compose down
# Remove everything (including volumes)
docker-compose down -v
# View logs
docker-compose logs -f [service-name]
# Check service health
docker-compose ps
```
