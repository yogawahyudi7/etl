#!/bin/bash
# SQL Tasks Runner Script
# This script helps run SQL queries from the sql/ folder

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

# Check if PostgreSQL is running
check_postgres() {
    if ! docker-compose exec -T postgres pg_isready -U etl_user -d clickstream_db -h localhost > /dev/null 2>&1; then
        warning "PostgreSQL is not ready. Make sure to run './etl_pipeline_run.sh' first."
        exit 1
    fi
    success "PostgreSQL is running and ready"
}

# Copy SQL files to PostgreSQL container
copy_sql_files() {
    section "Copying SQL Files"
    
    echo "Copying SQL files to PostgreSQL container..."
    docker cp sql/task1_total_spending.sql postgres:/tmp/task1_total_spending.sql || error "Failed to copy task1"
    docker cp sql/task2_city_highest_orders.sql postgres:/tmp/task2_city_highest_orders.sql || error "Failed to copy task2"
    docker cp sql/task3_query_optimization.sql postgres:/tmp/task3_query_optimization.sql || error "Failed to copy task3"
    
    success "SQL files copied successfully"
}

# Run Task 1: Total Spending
run_task1() {
    section "Running Task 1: Total Spending Analysis"
    
    echo "Executing task1_total_spending.sql..."
    docker-compose exec -T postgres bash -c "psql -U etl_user -d clickstream_db -f /tmp/task1_total_spending.sql"
    
    success "Task 1 completed"
    echo "Press Enter to return to menu"
    read
    show_menu
}

# Run Task 2: City with Highest Orders
run_task2() {
    section "Running Task 2: City with Highest Orders"
    
    echo "Executing task2_city_highest_orders.sql..."
    docker-compose exec -T postgres bash -c "psql -U etl_user -d clickstream_db -f /tmp/task2_city_highest_orders.sql"
    
    success "Task 2 completed"
    echo "Press Enter to return to menu"
    read
    show_menu
}

# Run Task 3: Query Optimization
run_task3() {
    section "Running Task 3: Query Optimization"
    
    echo "Executing task3_query_optimization.sql..."
    docker-compose exec -T postgres bash -c "psql -U etl_user -d clickstream_db -f /tmp/task3_query_optimization.sql"
    
    success "Task 3 completed"
    echo "Press Enter to return to menu"
    read
    show_menu
}

# Run all tasks
run_all_tasks() {
    section "Running All SQL Tasks"
    
    run_task1_no_prompt
    run_task2_no_prompt
    run_task3_no_prompt
    
    success "All SQL tasks completed successfully"
    echo "Press Enter to return to menu"
    read
    show_menu
}

# Run Task 1 without prompt
run_task1_no_prompt() {
    section "Running Task 1: Total Spending Analysis"
    
    echo "Executing task1_total_spending.sql..."
    docker-compose exec -T postgres bash -c "psql -U etl_user -d clickstream_db -f /tmp/task1_total_spending.sql"
    
    success "Task 1 completed"
}

# Run Task 2 without prompt
run_task2_no_prompt() {
    section "Running Task 2: City with Highest Orders"
    
    echo "Executing task2_city_highest_orders.sql..."
    docker-compose exec -T postgres bash -c "psql -U etl_user -d clickstream_db -f /tmp/task2_city_highest_orders.sql"
    
    success "Task 2 completed"
}

# Run Task 3 without prompt
run_task3_no_prompt() {
    section "Running Task 3: Query Optimization"
    
    echo "Executing task3_query_optimization.sql..."
    docker-compose exec -T postgres bash -c "psql -U etl_user -d clickstream_db -f /tmp/task3_query_optimization.sql"
    
    success "Task 3 completed"
}

# Show menu
show_menu() {
    section "SQL Tasks Menu"
    echo "1. Run Task 1: Total Spending Analysis"
    echo "2. Run Task 2: City with Highest Orders"
    echo "3. Run Task 3: Query Optimization"
    echo "4. Run all tasks"
    echo "5. Exit"
    echo
    read -p "Select an option (1-5): " choice
    echo
    
    case $choice in
        1) run_task1 ;;
        2) run_task2 ;;
        3) run_task3 ;;
        4) run_all_tasks ;;
        5) exit 0 ;;
        *) warning "Invalid option" && show_menu ;;
    esac
}

# Main execution
section "SQL Tasks Runner"
echo "This script helps run SQL queries from the sql/ folder."
check_postgres
copy_sql_files
show_menu
