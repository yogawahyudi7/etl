#!/bin/bash
# Debugging and Optimization Runner Script
# This script helps run and analyze the ETL pipeline performance

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

# Show menu
show_menu() {
    section "Debugging & Optimization Menu"
    echo "1. Generate test data"
    echo "2. Run performance optimization analysis"
    echo "3. Run all optimization tests"
    echo "4. Exit"
    echo
    read -p "Select an option (1-4): " choice
    echo
    
    case $choice in
        1) generate_test_data ;;
        2) run_optimization ;;
        3) run_all_tests ;;
        4) exit 0 ;;
        *) warning "Invalid option" && show_menu ;;
    esac
}

# Generate test data
generate_test_data() {
    section "Generating Test Data"
    
    echo "Running generate_data.py to create test dataset..."
    python debugging-optimization/generate_data.py || error "Failed to generate test data"
    
    success "Test data generated successfully"
    echo "Press Enter to return to menu"
    read
    show_menu
}

# Run optimization script
run_optimization() {
    section "Running Optimization Analysis"
    
    echo "Running optimize_script.py to analyze performance..."
    python debugging-optimization/optimize_script.py || error "Failed to run optimization"
    
    success "Optimization analysis completed"
    echo "Press Enter to return to menu"
    read
    show_menu
}

# Run all tests
run_all_tests() {
    section "Running All Optimization Tests"
    
    generate_test_data
    run_optimization
    
    success "All tests completed successfully"
    echo "Press Enter to return to menu"
    read
    show_menu
}

# Main execution
section "Debugging & Optimization Tools"
echo "This script helps analyze and optimize ETL pipeline performance."
check_postgres
show_menu
