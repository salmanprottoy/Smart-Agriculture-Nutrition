#!/bin/bash

# Azure Nginx Configuration Fix Script
# This script fixes Nginx routing for the Smart Agriculture API

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

# Main function
main() {
    print_header "Fixing Nginx Configuration"
    
    # Check if running with sudo
    if [[ $EUID -eq 0 ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi
    
    print_message "Creating proper Nginx configuration..." "$BLUE"
    
    # Create the Nginx configuration
    $SUDO tee /etc/nginx/sites-available/smart-agriculture > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;
    
    client_max_body_size 10M;
    
    # Root path - redirect to Swagger UI
    location = / {
        return 301 /api/v1/swagger;
    }
    
    # API endpoints
    location /api/ {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Swagger UI
    location /api/v1/swagger {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/swagger;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # OpenAPI JSON
    location /api/v1/openapi.json {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/openapi.json;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
    
    # Swagger resources
    location /SmartAgricultureNutrition/api/v1/swagger-ui/ {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/swagger-ui/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
    
    # Main application path
    location /SmartAgricultureNutrition/ {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/;
        proxy_http_version 1.1;
        access_log off;
    }
}
EOF
    
    print_message "✓ Nginx configuration created" "$GREEN"
    
    # Enable the site
    print_message "Enabling the site..." "$BLUE"
    $SUDO ln -sf /etc/nginx/sites-available/smart-agriculture /etc/nginx/sites-enabled/
    
    # Remove default site if it exists
    if [ -f /etc/nginx/sites-enabled/default ]; then
        $SUDO rm -f /etc/nginx/sites-enabled/default
        print_message "✓ Removed default site" "$GREEN"
    fi
    
    # Test Nginx configuration
    print_message "Testing Nginx configuration..." "$BLUE"
    if $SUDO nginx -t; then
        print_message "✓ Nginx configuration is valid" "$GREEN"
    else
        print_message "✗ Nginx configuration has errors" "$RED"
        exit 1
    fi
    
    # Reload Nginx
    print_message "Reloading Nginx..." "$BLUE"
    $SUDO systemctl reload nginx
    print_message "✓ Nginx reloaded" "$GREEN"
    
    # Check if application is running
    print_header "Checking Application Status"
    
    if curl -f http://localhost:8080/SmartAgricultureNutrition/ &> /dev/null; then
        print_message "✓ Application is running on port 8080" "$GREEN"
    else
        print_message "⚠ Application may not be running" "$YELLOW"
        print_message "Check with: sudo docker ps" "$YELLOW"
        print_message "Start with: cd ~/SmartAgricultureNutrition && sudo docker-compose -f docker-compose.azure.yml up -d" "$YELLOW"
    fi
    
    # Get public IP
    PUBLIC_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "YOUR_VM_IP")
    
    # Display summary
    print_header "Nginx Configuration Fixed!"
    
    print_message "Your application endpoints are now accessible at:" "$GREEN"
    echo
    print_message "Main URLs:" "$BLUE"
    print_message "  Homepage: http://$PUBLIC_IP/" "$YELLOW"
    print_message "  Swagger UI: http://$PUBLIC_IP/api/v1/swagger" "$YELLOW"
    print_message "  API Base: http://$PUBLIC_IP/api/v1/" "$YELLOW"
    echo
    print_message "API Endpoints:" "$BLUE"
    print_message "  Auth: http://$PUBLIC_IP/api/v1/auth/login" "$CYAN"
    print_message "  Crops: http://$PUBLIC_IP/api/v1/crops" "$CYAN"
    print_message "  Weather: http://$PUBLIC_IP/api/v1/weather" "$CYAN"
    print_message "  Nutrition: http://$PUBLIC_IP/api/v1/nutrition" "$CYAN"
    echo
    print_message "Direct Access (port 8080):" "$BLUE"
    print_message "  http://$PUBLIC_IP:8080/SmartAgricultureNutrition/" "$CYAN"
    print_message "  http://$PUBLIC_IP:8080/SmartAgricultureNutrition/api/v1/swagger" "$CYAN"
    echo
    print_message "Test the configuration:" "$BLUE"
    print_message "  curl http://$PUBLIC_IP/api/v1/swagger" "$CYAN"
    print_message "  curl http://$PUBLIC_IP/health" "$CYAN"
}

# Run main function
main
