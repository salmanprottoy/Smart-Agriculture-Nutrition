#!/bin/bash

# Swagger UI Server URL Fix Script
# This script fixes the Swagger UI to use the correct server URL

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
    print_header "Fixing Swagger UI Server URL"
    
    # Detect environment
    if [ -f /etc/nginx/sites-available/smart-agriculture-duckdns ]; then
        print_message "DuckDNS configuration detected" "$BLUE"
        # Get DuckDNS domain from Nginx config
        DOMAIN=$(grep "server_name" /etc/nginx/sites-available/smart-agriculture-duckdns | head -1 | awk '{print $2}' | sed 's/;//')
        if [ ! -z "$DOMAIN" ] && [ "$DOMAIN" != "_" ]; then
            SERVER_URL="http://$DOMAIN"
            print_message "Using DuckDNS domain: $SERVER_URL" "$GREEN"
        fi
    fi
    
    # If no DuckDNS, use IP
    if [ -z "$SERVER_URL" ]; then
        PUBLIC_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "localhost")
        SERVER_URL="http://$PUBLIC_IP"
        print_message "Using IP address: $SERVER_URL" "$YELLOW"
    fi
    
    # Create environment variable file for the application
    print_message "Creating server URL configuration..." "$BLUE"
    
    # Check if running with sudo
    if [[ $EUID -eq 0 ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi
    
    # Update docker-compose environment
    cd ~/SmartAgricultureNutrition
    
    # Add SWAGGER_SERVER_URL to .env file
    if [ -f .env ]; then
        # Remove old SWAGGER_SERVER_URL if exists
        grep -v "SWAGGER_SERVER_URL" .env > .env.tmp || true
        mv .env.tmp .env
    fi
    
    # Add new SWAGGER_SERVER_URL
    echo "SWAGGER_SERVER_URL=$SERVER_URL/SmartAgricultureNutrition" >> .env
    print_message "✓ Environment variable added" "$GREEN"
    
    # Create a custom Swagger configuration
    print_message "Creating Swagger configuration override..." "$BLUE"
    
    # Create swagger config directory
    mkdir -p ~/SmartAgricultureNutrition/swagger-config
    
    # Create OpenAPI spec override
    cat > ~/SmartAgricultureNutrition/swagger-config/openapi-servers.json << EOF
{
  "servers": [
    {
      "url": "$SERVER_URL/SmartAgricultureNutrition/api/v1",
      "description": "Production Server"
    },
    {
      "url": "http://localhost:8080/SmartAgricultureNutrition/api/v1",
      "description": "Local Development"
    }
  ]
}
EOF
    
    print_message "✓ Swagger configuration created" "$GREEN"
    
    # Update Nginx to inject correct server URL
    print_message "Updating Nginx configuration..." "$BLUE"
    
    # Create Nginx snippet for header injection
    $SUDO tee /etc/nginx/snippets/swagger-headers.conf > /dev/null << EOF
# Inject correct server URL for Swagger
sub_filter 'http://localhost:8080' '$SERVER_URL';
sub_filter_once off;
sub_filter_types application/json text/html;
EOF
    
    # Update main Nginx config to include the snippet
    if [ -f /etc/nginx/sites-available/smart-agriculture-duckdns ]; then
        CONFIG_FILE="/etc/nginx/sites-available/smart-agriculture-duckdns"
    elif [ -f /etc/nginx/sites-available/smart-agriculture ]; then
        CONFIG_FILE="/etc/nginx/sites-available/smart-agriculture"
    else
        CONFIG_FILE="/etc/nginx/sites-available/default"
    fi
    
    # Check if sub_filter module is available
    if $SUDO nginx -V 2>&1 | grep -q "http_sub_module"; then
        print_message "✓ Nginx sub_filter module available" "$GREEN"
        
        # Add include directive if not already present
        if ! grep -q "swagger-headers.conf" $CONFIG_FILE; then
            # Backup original config
            $SUDO cp $CONFIG_FILE ${CONFIG_FILE}.backup
            
            # Add include after server_name
            $SUDO sed -i '/server_name/a\    include /etc/nginx/snippets/swagger-headers.conf;' $CONFIG_FILE
            
            print_message "✓ Nginx configuration updated" "$GREEN"
        else
            print_message "Nginx already configured" "$YELLOW"
        fi
    else
        print_message "⚠ Nginx sub_filter module not available" "$YELLOW"
    fi
    
    # Test and reload Nginx
    print_message "Testing Nginx configuration..." "$BLUE"
    if $SUDO nginx -t; then
        $SUDO systemctl reload nginx
        print_message "✓ Nginx reloaded" "$GREEN"
    else
        print_message "✗ Nginx configuration error, reverting..." "$RED"
        if [ -f ${CONFIG_FILE}.backup ]; then
            $SUDO mv ${CONFIG_FILE}.backup $CONFIG_FILE
            $SUDO systemctl reload nginx
        fi
    fi
    
    # Restart application to pick up new environment
    print_message "Restarting application..." "$BLUE"
    cd ~/SmartAgricultureNutrition
    
    if [ -f docker-compose.azure.yml ]; then
        $SUDO docker-compose -f docker-compose.azure.yml restart app
    else
        $SUDO docker-compose -f docker-compose.prod.yml restart app
    fi
    
    print_message "✓ Application restarted" "$GREEN"
    
    # Wait for application to be ready
    print_message "Waiting for application to be ready..." "$YELLOW"
    sleep 15
    
    # Display summary
    print_header "Swagger Fix Complete!"
    
    print_message "The Swagger UI should now use the correct server URL:" "$GREEN"
    print_message "  Server URL: $SERVER_URL" "$YELLOW"
    print_message "  Swagger UI: $SERVER_URL/api/v1/swagger" "$YELLOW"
    echo
    print_message "Test the API directly:" "$BLUE"
    print_message "  curl -X POST $SERVER_URL/api/v1/auth/register \\" "$CYAN"
    print_message "    -H 'Content-Type: application/json' \\" "$CYAN"
    print_message "    -d '{\"username\":\"test\",\"password\":\"test123\",\"email\":\"test@example.com\"}'" "$CYAN"
    echo
    print_message "If you still see localhost in Swagger UI:" "$YELLOW"
    print_message "  1. Clear your browser cache" "$CYAN"
    print_message "  2. Try incognito/private mode" "$CYAN"
    print_message "  3. Use the server dropdown in Swagger UI to select the correct server" "$CYAN"
}

# Run main function
main
