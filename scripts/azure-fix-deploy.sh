#!/bin/bash

# Azure VM Fix and Deploy Script
# This script cleans up Docker issues and redeploys the application

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    echo -e "${2}${1}${NC}"
}

# Function to print section header
print_header() {
    echo
    print_message "========================================" "$CYAN"
    print_message "$1" "$CYAN"
    print_message "========================================" "$CYAN"
    echo
}

# Main fix function
main() {
    print_header "Docker Cleanup and Fresh Deployment"
    
    # Change to project root directory
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    if [[ "$SCRIPT_DIR" == *"/scripts" ]]; then
        PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    else
        PROJECT_DIR="$SCRIPT_DIR"
    fi
    
    print_message "Changing to project directory: $PROJECT_DIR" "$BLUE"
    cd "$PROJECT_DIR"
    
    print_message "This script will clean up Docker and redeploy your application" "$YELLOW"
    read -p "Continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    
    # Step 1: Stop all containers
    print_header "Step 1: Stopping All Containers"
    print_message "Stopping all running containers..." "$BLUE"
    sudo docker-compose -f docker-compose.prod.yml down 2>/dev/null || true
    sudo docker-compose -f docker-compose.azure.yml down 2>/dev/null || true
    sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true
    print_message "✓ All containers stopped" "$GREEN"
    
    # Step 2: Remove all containers
    print_header "Step 2: Removing All Containers"
    print_message "Removing all containers..." "$BLUE"
    sudo docker rm -f $(sudo docker ps -aq) 2>/dev/null || true
    print_message "✓ All containers removed" "$GREEN"
    
    # Step 3: Remove problematic images
    print_header "Step 3: Cleaning Docker Images"
    print_message "Removing application images..." "$BLUE"
    sudo docker rmi smart-agriculture-app:latest 2>/dev/null || true
    sudo docker rmi $(sudo docker images -q --filter "dangling=true") 2>/dev/null || true
    print_message "✓ Images cleaned" "$GREEN"
    
    # Step 4: Clean Docker system
    print_header "Step 4: Docker System Cleanup"
    print_message "Cleaning Docker system..." "$BLUE"
    sudo docker system prune -f
    print_message "✓ Docker system cleaned" "$GREEN"
    
    # Step 5: Remove old volumes (optional)
    print_header "Step 5: Volume Management"
    read -p "Do you want to remove database volumes? (This will delete all data) (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_message "Removing volumes..." "$BLUE"
        sudo docker volume rm smartagriculturenutrition_postgres_data 2>/dev/null || true
        sudo docker volume prune -f
        print_message "✓ Volumes removed" "$GREEN"
    else
        print_message "Keeping existing volumes" "$YELLOW"
    fi
    
    # Step 6: Check for compose file
    print_header "Step 6: Selecting Docker Compose File"
    if [ -f "docker-compose.azure.yml" ]; then
        COMPOSE_FILE="docker-compose.azure.yml"
        print_message "Using Azure-optimized configuration" "$GREEN"
    else
        COMPOSE_FILE="docker-compose.prod.yml"
        print_message "Using standard production configuration" "$YELLOW"
    fi
    
    # Step 7: Build fresh images
    print_header "Step 7: Building Fresh Images"
    print_message "Building application image..." "$BLUE"
    sudo docker-compose -f $COMPOSE_FILE build --no-cache
    print_message "✓ Images built successfully" "$GREEN"
    
    # Step 8: Start containers
    print_header "Step 8: Starting Containers"
    print_message "Starting containers..." "$BLUE"
    sudo docker-compose -f $COMPOSE_FILE up -d
    print_message "✓ Containers started" "$GREEN"
    
    # Step 9: Wait for services
    print_header "Step 9: Waiting for Services"
    print_message "Waiting for services to be ready..." "$YELLOW"
    sleep 30
    
    # Step 10: Check status
    print_header "Step 10: Checking Status"
    print_message "Container status:" "$BLUE"
    sudo docker ps
    echo
    
    # Test application
    print_message "Testing application..." "$BLUE"
    if curl -f http://localhost:8080/SmartAgricultureNutrition/ &> /dev/null; then
        print_message "✓ Application is responding!" "$GREEN"
    else
        print_message "⚠ Application may still be starting up..." "$YELLOW"
        print_message "Check logs with: sudo docker-compose -f $COMPOSE_FILE logs" "$YELLOW"
    fi
    
    # Get IP
    PUBLIC_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "YOUR_VM_IP")
    
    # Display summary
    print_header "Deployment Complete!"
    print_message "Your application has been redeployed successfully!" "$GREEN"
    echo
    print_message "Access your application at:" "$BLUE"
    print_message "  http://$PUBLIC_IP/" "$YELLOW"
    print_message "  http://$PUBLIC_IP/api/v1/" "$YELLOW"
    print_message "  http://$PUBLIC_IP/api/v1/swagger" "$YELLOW"
    echo
    print_message "Useful commands:" "$BLUE"
    print_message "  View logs: sudo docker-compose -f $COMPOSE_FILE logs -f" "$CYAN"
    print_message "  Stop app: sudo docker-compose -f $COMPOSE_FILE down" "$CYAN"
    print_message "  Restart app: sudo docker-compose -f $COMPOSE_FILE restart" "$CYAN"
    echo
    print_message "If you still have issues, try:" "$YELLOW"
    print_message "  1. Reboot the VM: sudo reboot" "$CYAN"
    print_message "  2. After reboot, run this script again" "$CYAN"
}

# Run main function
main
