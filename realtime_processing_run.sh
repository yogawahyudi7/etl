#!/bin/bash
# Real-time Processing Runner Script
# This script helps run the Kafka consumer for real-time data processing

# Terminal colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print section header
section() {
    echo -e "\n${BLUE}========== $1 ==========${NC}\n"
}

# Print success message
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Print warning message
warning() {
    echo -e "${YELLOW}! $1${NC}"
}

# Print error message
error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

# Check if services are running
check_services() {
    # Check PostgreSQL
    if ! docker-compose exec -T postgres pg_isready -U etl_user -d clickstream_db -h localhost > /dev/null 2>&1; then
        warning "PostgreSQL is not ready."
        services_ready=false
    else
        success "PostgreSQL is running and ready"
    fi

    # Check Kafka/Zookeeper using docker ps, accepting any status including "health: starting"
    if ! docker ps | grep -q "broker"; then
        warning "Kafka broker is not ready."
        services_ready=false
    else
        # Kafka container is running, assume it's ready even if health check is still starting
        success "Kafka is running and ready"
    fi

    if [ "$services_ready" = false ]; then
        warning "Some services are not ready. Make sure to run './etl_pipeline_run.sh' first."
        exit 1
    fi
}

# Create Kafka topic
create_kafka_topic() {
    section "Creating Kafka Topic"
    
    # Add a short delay to ensure Kafka is fully operational
    echo "Waiting 3 seconds for Kafka to be fully operational..."
    sleep 3
    
    echo "Creating 'SPE-testcase' topic for product views if it doesn't exist..."
    if ! docker-compose exec -T broker kafka-topics --create --if-not-exists --bootstrap-server broker:9093 --replication-factor 1 --partitions 1 --topic SPE-testcase; then
        warning "Failed to create SPE-testcase topic. Waiting another 5 seconds and trying again..."
        sleep 5
        docker-compose exec -T broker kafka-topics --create --if-not-exists --bootstrap-server broker:9093 --replication-factor 1 --partitions 1 --topic SPE-testcase || error "Could not create SPE-testcase topic after retry"
    fi
    
    success "Kafka topic ready"
}

# Run Kafka consumer
run_consumer() {
    section "Running Kafka Consumer (Product Views)"
    
    echo "Starting consumer_script.py to process product view events..."
    echo "This consumer tracks product views and stores aggregated data in PostgreSQL"
    echo "Press Ctrl+C to stop the consumer"
    
    # Try to install Python dependencies locally
    echo "Installing Python dependencies..."
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install -r real-time-processing/requirements.txt
    elif command -v pip >/dev/null 2>&1; then
        pip install -r real-time-processing/requirements.txt
    else
        warning "Python pip not found. Please install Python dependencies manually:"
        echo "pip install confluent_kafka psycopg2-binary"
    fi
    
    echo "Starting consumer (use Ctrl+C to stop)..."
    # Set environment variables for database connection
    export POSTGRES_DB="clickstream_db"
    export POSTGRES_USER="etl_user"
    export POSTGRES_PASSWORD="secure_password_123"
    export DB_HOST="localhost"
    export DB_PORT="5433"
    export KAFKA_BOOTSTRAP_SERVERS="localhost:9092"
    
    # Try to run with python3 first, then python
    if command -v python3 >/dev/null 2>&1; then
        python3 real-time-processing/consumer_script.py
    elif command -v python >/dev/null 2>&1; then
        python real-time-processing/consumer_script.py
    else
        error "Python not found. Please install Python 3.x and required dependencies."
    fi
}

# Produce sample product view messages
produce_sample_messages() {
    section "Producing Product View Messages"
    
    echo "Sending product view messages to 'SPE-testcase' topic..."
    
    # Get current timestamp
    current_timestamp=$(date +%s)
    
    # Define messages as array
    messages=(
        "{\"product_id\": \"PROD-1001\", \"event\": \"view\", \"timestamp\": \"$current_timestamp\", \"user_id\": \"USER-201\"}"
        "{\"product_id\": \"PROD-1002\", \"event\": \"view\", \"timestamp\": \"$current_timestamp\", \"user_id\": \"USER-202\"}"
        "{\"product_id\": \"PROD-1003\", \"event\": \"view\", \"timestamp\": \"$current_timestamp\", \"user_id\": \"USER-203\"}"
        "{\"product_id\": \"PROD-1001\", \"event\": \"view\", \"timestamp\": \"$current_timestamp\", \"user_id\": \"USER-204\"}"
        "{\"product_id\": \"PROD-1002\", \"event\": \"view\", \"timestamp\": \"$current_timestamp\", \"user_id\": \"USER-205\"}"
        "{\"product_id\": \"PROD-1004\", \"event\": \"view\", \"timestamp\": \"$current_timestamp\", \"user_id\": \"USER-206\"}"
        "{\"product_id\": \"PROD-1001\", \"event\": \"view\", \"timestamp\": \"$current_timestamp\", \"user_id\": \"USER-207\"}"
        "{\"product_id\": \"PROD-1005\", \"event\": \"view\", \"timestamp\": \"$current_timestamp\", \"user_id\": \"USER-208\"}"
    )
    
    for message in "${messages[@]}"; do
        echo "$message" | docker-compose exec -T broker kafka-console-producer --broker-list broker:9093 --topic SPE-testcase
        echo "Sent: $message"
        sleep 0.5
    done
    
    success "Product view messages sent to SPE-testcase topic"
    echo "Messages sent: ${#messages[@]} total"
}

# Process results with SQL
process_results() {
    section "Processing Results with SQL"
    
    echo "Displaying all product views data..."
    docker-compose exec -T postgres bash -c "psql -U etl_user -d clickstream_db -f /tmp/proceed_result.sql"
    
    success "Product views data displayed successfully"
}

# View product views table
view_product_views() {
    section "Product Views Data"
    
    echo "Checking if product_views table exists..."
    table_exists=$(docker-compose exec -T postgres psql -U etl_user -d clickstream_db -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'product_views');" | grep -o 't\|f' | head -1)
    
    if [ "$table_exists" = "t" ]; then
        echo "Viewing current product views data..."
        docker-compose exec -T postgres psql -U etl_user -d clickstream_db -c "
            SELECT 
                product_id,
                view_count,
                updated_at,
                CASE 
                    WHEN view_count = 1 THEN 'Low'
                    WHEN view_count <= 3 THEN 'Medium'
                    ELSE 'High'
                END as popularity_level
            FROM product_views 
            ORDER BY view_count DESC, updated_at DESC;
        "
        
        # Show summary statistics
        echo -e "\\n--- Summary Statistics ---"
        docker-compose exec -T postgres psql -U etl_user -d clickstream_db -c "
            SELECT 
                COUNT(*) as total_products,
                SUM(view_count) as total_views,
                AVG(view_count)::numeric(10,2) as avg_views_per_product,
                MAX(view_count) as max_views
            FROM product_views;
        "
        success "Product views data displayed with analytics"
    else
        warning "Product views table does not exist yet."
        echo "This means either:"
        echo "1. No consumer has been run yet"
        echo "2. No messages have been processed"
        echo "Run option 2 (produce messages) and 3 (run consumer) first."
    fi
}

# Show menu
show_menu() {
    section "Real-time Processing Menu"
    
    # Show current status
    echo "🔍 Current Status:"
    topic_exists=$(docker-compose exec -T broker kafka-topics --list --bootstrap-server broker:9093 2>/dev/null | grep "SPE-testcase" || echo "")
    if [ -n "$topic_exists" ]; then
        echo "  ✅ Kafka topic 'SPE-testcase' exists"
    else
        echo "  ❌ Kafka topic needs to be created"
    fi
    
    table_exists=$(docker-compose exec -T postgres psql -U etl_user -d clickstream_db -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'product_views');" 2>/dev/null | grep -o 't\|f' | head -1 || echo "f")
    if [ "$table_exists" = "t" ]; then
        row_count=$(docker-compose exec -T postgres psql -U etl_user -d clickstream_db -c "SELECT COUNT(*) FROM product_views;" 2>/dev/null | grep -o '[0-9]*' | head -1 || echo "0")
        echo "  ✅ Product views table exists with $row_count products"
    else
        echo "  ❌ Product views table not created yet"
    fi
    echo
    
    echo "📋 Available Options:"
    echo "1. Create Kafka topic (SPE-testcase)"
    echo "2. Produce product view messages (8 sample messages)"
    echo "3. Run Kafka consumer (product views aggregation)"
    echo "4. View product views table (with analytics)"
    echo "5. Process results with SQL (display all data)"
    echo "6. Run all steps in sequence (automated workflow)"
    echo "7. Exit"
    echo
    echo "💡 Recommended workflow: 1 → 2 → 3 (keep running) → 4 (in new terminal)"
    echo
    read -p "Select an option (1-7): " choice
    echo
    
    case $choice in
        1) create_kafka_topic && show_menu ;;
        2) produce_sample_messages && show_menu ;;
        3) run_consumer && show_menu ;;
        4) view_product_views && show_menu ;;
        5) process_results && show_menu ;;
        6) run_all_steps && show_menu ;;
        7) exit 0 ;;
        *) warning "Invalid option. Please select 1-7." && show_menu ;;
    esac
}

# Run all steps
run_all_steps() {
    create_kafka_topic
    
    # Copy SQL file to container
    echo "Copying SQL processing script to PostgreSQL container..."
    docker cp real-time-processing/proceed_result.sql postgres:/tmp/proceed_result.sql
    
    produce_sample_messages
    
    echo "Sample messages sent. You can now run the consumer with option 3."
    
    show_menu
}

# Start services if not running
start_services_if_needed() {
    section "Starting Required Services"
    
    echo "Checking if services are already running..."
    if ! docker ps | grep -q "broker\|postgres"; then
        echo "Services are not running. Starting with etl_pipeline_run.sh..."
        ./etl_pipeline_run.sh
        
        # Give services some time to initialize
        echo "Waiting for services to initialize..."
        sleep 5
        
        # Re-check services
        check_services
    else
        echo "Services are already running."
    fi
    
    success "Services check completed"
}

# Variables
services_ready=true

# Main execution
section "Real-time Processing Tools"
echo "This script helps run the Kafka consumer for real-time data processing."

# Try to start services if needed before checking
start_services_if_needed

# If services are still not ready after trying to start them, check_services will exit
check_services

# Copy SQL file to container
echo "Copying SQL processing script to PostgreSQL container..."
docker cp real-time-processing/proceed_result.sql postgres:/tmp/proceed_result.sql || warning "Could not copy SQL file (will try again later)"

show_menu
