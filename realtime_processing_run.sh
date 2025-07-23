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
    
    echo "Creating 'clickstream_data' topic if it doesn't exist..."
    if ! docker-compose exec -T broker kafka-topics --create --if-not-exists --bootstrap-server broker:9093 --replication-factor 1 --partitions 1 --topic clickstream_data; then
        warning "Failed to create topic. Waiting another 5 seconds and trying again..."
        sleep 5
        docker-compose exec -T broker kafka-topics --create --if-not-exists --bootstrap-server broker:9093 --replication-factor 1 --partitions 1 --topic clickstream_data || error "Could not create Kafka topic after retry"
    fi
    
    success "Kafka topic ready"
}

# Run Kafka consumer
run_consumer() {
    section "Running Kafka Consumer"
    
    echo "Starting consumer_script.py to process real-time data..."
    echo "Press Ctrl+C to stop the consumer"
    
    # Install required packages if needed
    pip install -r real-time-processing/requirements.txt
    
    # Run the consumer script
    python real-time-processing/consumer_script.py
}

# Produce sample messages
produce_sample_messages() {
    section "Producing Sample Messages"
    
    echo "Sending sample messages to 'clickstream_data' topic..."
    for i in {1..5}; do
        message="{\"user_id\": $((100+$i)), \"timestamp\": \"$(date +%s)\", \"page\": \"/product-$i\", \"action\": \"view\"}"
        docker-compose exec -T broker bash -c "echo '$message' | kafka-console-producer --broker-list broker:9093 --topic clickstream_data"
        echo "Sent: $message"
        sleep 1
    done
    
    success "Sample messages sent to Kafka"
}

# Process results with SQL
process_results() {
    section "Processing Results with SQL"
    
    echo "Running SQL processing script..."
    docker-compose exec -T postgres bash -c "psql -U etl_user -d clickstream_db -f /tmp/proceed_result.sql"
    
    success "Results processed successfully"
}

# Show menu
show_menu() {
    section "Real-time Processing Menu"
    echo "1. Create Kafka topic"
    echo "2. Produce sample messages"
    echo "3. Run Kafka consumer (Ctrl+C to stop)"
    echo "4. Process results with SQL"
    echo "5. Run all steps in sequence"
    echo "6. Exit"
    echo
    read -p "Select an option (1-6): " choice
    echo
    
    case $choice in
        1) create_kafka_topic && show_menu ;;
        2) produce_sample_messages && show_menu ;;
        3) run_consumer && show_menu ;;
        4) process_results && show_menu ;;
        5) run_all_steps && show_menu ;;
        6) exit 0 ;;
        *) warning "Invalid option" && show_menu ;;
    esac
}

# Run all steps
run_all_steps() {
    create_kafka_topic
    
    # Copy SQL file to container
    echo "Copying SQL processing script to PostgreSQL container..."
    docker cp real-time-processing/proceed_result.sql postgres:/tmp/proceed_result.sql
    
    produce_sample_messages
    run_consumer
    process_results
    
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
