#!/bin/bash
# ETL Project Runner Script
# This script automates the process of running the ETL project

# Terminal colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default ETL method
ETL_METHOD="sql" # Options: sql or python

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

# Check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        error "$1 is required but not installed."
    fi
}

# Show usage information
show_usage() {
    echo -e "Usage: ./$(basename $0) [OPTIONS]"
    echo -e "Options:"
    echo -e "  --sql      Run ETL using SQL script (default)"
    echo -e "  --python   Run ETL using Python script"
    echo -e "  --stop     Stop all services"
    echo -e "  --help     Show this help message"
    exit 0
}

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --sql)
            ETL_METHOD="sql"
            ;;
        --python)
            ETL_METHOD="python"
            ;;
        --stop)
            STOP_SERVICES=true
            ;;
        --help)
            show_usage
            ;;
    esac
done

# Handle stop command early
if [ "$STOP_SERVICES" = true ]; then
    section "Stopping all services"
    docker-compose down
    success "All services stopped successfully"
    exit 0
fi

# Check for required commands
section "Checking prerequisites"
check_command docker
check_command docker-compose
if [ "$ETL_METHOD" = "python" ]; then
    check_command python
fi
success "All required commands are available"

# Check if services are already running
if docker ps | grep -q "postgres\|zookeeper\|broker"; then
    warning "Some Docker services are already running. Stopping them..."
    docker-compose down
fi

# Start Docker services
section "Starting Docker services"
echo "Starting PostgreSQL, Kafka, Zookeeper, and Kafka UI..."
docker-compose up -d || error "Failed to start Docker services"
success "Docker services started"

# Wait for PostgreSQL to be ready
section "Waiting for PostgreSQL to be ready"
echo "This may take a few moments..."
attempt=1
max_attempts=30

while [ $attempt -le $max_attempts ]; do
    if docker-compose exec -T postgres pg_isready -U etl_user -d clickstream_db -h localhost > /dev/null 2>&1; then
        success "PostgreSQL is ready"
        break
    fi
    echo "Waiting for PostgreSQL... Attempt $attempt/$max_attempts"
    sleep 2
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    error "PostgreSQL failed to become ready in time"
fi

# Run ETL process based on selected method
section "Running ETL process"

if [ "$ETL_METHOD" = "sql" ]; then
    echo "Using SQL-based ETL method..."
    echo "Copying ETL SQL script to PostgreSQL container..."
    docker cp etl-pipeline/etl_sql.sql postgres:/tmp/etl_sql.sql || error "Failed to copy ETL SQL script"

    echo "Executing ETL process with SQL..."
    docker-compose exec -T postgres bash -c "psql -U etl_user -d clickstream_db -f /tmp/etl_sql.sql" || error "ETL process failed"
    success "SQL-based ETL process completed successfully"
else
    echo "Using Python-based ETL method..."
    echo "Running Python ETL script from host machine..."
    
    # Check for required Python packages on the host
    echo "Checking Python dependencies on host..."
    if [ -f "etl-pipeline/requirements.txt" ]; then
        echo "Found requirements.txt, installing dependencies..."
        pip install -r etl-pipeline/requirements.txt || warning "Failed to install all dependencies from requirements.txt, continuing anyway"
    else
        echo "No requirements.txt found, installing minimal required packages..."
        pip install pandas psycopg2-binary || warning "Failed to install Python dependencies, continuing anyway"
    fi
    
    # Update the database config in the Python script to use the mapped port
    echo "Configuring database connection for host access..."
    sed -i.bak 's/"port": 5432/"port": 5433/g' etl-pipeline/etl_script.py || warning "Failed to update port in script, may need to update manually"
    
    # Update the file path in the Python script to use the local path
    echo "Updating file paths in the script..."
    sed -i.bak 's|FILE_PATH = "/tmp/transform_data.csv"|FILE_PATH = "transform_data.csv"|g' etl-pipeline/etl_script.py || warning "Failed to update file path in script, may need to update manually"
    
    echo "Executing ETL process with Python..."
    cd etl-pipeline && python etl_script.py || error "ETL process failed"
    # Only mark success if we actually succeeded
    if [ $? -eq 0 ]; then
        success "Python-based ETL process completed successfully"
    fi
    
    # Restore the original script if it was modified
    if [ -f "etl-pipeline/etl_script.py.bak" ]; then
        mv etl-pipeline/etl_script.py.bak etl-pipeline/etl_script.py
    fi
fi

# Show results
section "ETL Results"
echo "Retrieving processed data summary..."
docker-compose exec -T postgres bash -c "psql -U etl_user -d clickstream_db -c \"SELECT category, COUNT(*) as records, SUM(total_amount) as total_amount FROM sales GROUP BY category;\""

# Show service status
section "Service Status"
docker-compose ps

echo -e "\n${GREEN}=========================================${NC}"
echo -e "${GREEN}✓ ETL Project is running successfully!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo -e "\nAccess points:"
echo -e "  - Kafka UI:    http://localhost:7777"
echo -e "  - PostgreSQL:  localhost:5432 (user: etl_user, database: clickstream_db)"
echo -e "\nETL method used: ${BLUE}$([ "$ETL_METHOD" = "sql" ] && echo "SQL Script" || echo "Python Script")${NC}"

echo -e "\n${RED}============= IMPORTANT =============${NC}"
echo -e "${YELLOW} To stop all services: ${NC}"
echo -e "${RED}  ./$(basename $0) --stop${NC}"
echo -e "${YELLOW} MAKE SURE TO STOP SERVICES WHEN FINISHED ${NC}"
echo -e "${RED}=============================${NC}"
echo -e "\nTo view logs:"
echo -e "  docker-compose logs -f [service_name]"
echo -e "\nTo run with specific ETL method:"
echo -e "  ./$(basename $0) --sql     (for SQL-based ETL)"
echo -e "  ./$(basename $0) --python  (for Python-based ETL)"
