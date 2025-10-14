#!/bin/bash

# Final Comprehensive Fix Script
# Fixes CORS, Swagger server URL, and DuckDNS configuration

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
    print_header "Final Comprehensive Fix"
    
    # Check if running with sudo
    if [[ $EUID -eq 0 ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi
    
    # Get public IP
    PUBLIC_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "172.188.68.150")
    print_message "Public IP: $PUBLIC_IP" "$BLUE"
    
    # Check for DuckDNS domain
    DUCKDNS_DOMAIN=""
    if [ -f ~/duckdns/duck.sh ]; then
        # Extract just the subdomain part
        DUCKDNS_DOMAIN=$(grep "domains=" ~/duckdns/duck.sh | sed -n 's/.*domains=\([^&]*\).*/\1/p')
        if [ ! -z "$DUCKDNS_DOMAIN" ] && [ "$DUCKDNS_DOMAIN" != "https://www.duckdns.org/update?domains" ]; then
            # Only add .duckdns.org if not already present
            if [[ ! "$DUCKDNS_DOMAIN" == *".duckdns.org"* ]]; then
                DUCKDNS_DOMAIN="$DUCKDNS_DOMAIN.duckdns.org"
            fi
            print_message "DuckDNS domain: $DUCKDNS_DOMAIN" "$BLUE"
        else
            print_message "DuckDNS domain not properly configured" "$YELLOW"
        fi
    fi
    
    # Step 1: Clean and create Nginx configuration
    print_header "Step 1: Configuring Nginx"
    
    # Clean up all existing configurations
    print_message "Cleaning existing configurations..." "$BLUE"
    $SUDO rm -f /etc/nginx/sites-enabled/* 2>/dev/null || true
    $SUDO rm -f /etc/nginx/snippets/swagger-headers.conf 2>/dev/null || true
    print_message "✓ Cleaned existing configurations" "$GREEN"
    
    # Create CORS configuration
    $SUDO tee /etc/nginx/snippets/cors.conf > /dev/null << 'EOF'
# CORS Headers
add_header 'Access-Control-Allow-Origin' '*' always;
add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH' always;
add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,Accept,Origin' always;
add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range,Authorization' always;
add_header 'Access-Control-Allow-Credentials' 'true' always;
add_header 'Access-Control-Max-Age' '86400' always;
EOF
    
    # Create URL rewrite configuration to fix localhost issue
    $SUDO tee /etc/nginx/snippets/url-rewrite.conf > /dev/null << EOF
# Rewrite localhost URLs in responses
sub_filter 'http://localhost:8080' 'http://$PUBLIC_IP';
sub_filter 'localhost:8080' '$PUBLIC_IP';
sub_filter_once off;
sub_filter_types application/json application/javascript;
EOF
    
    print_message "✓ Created CORS and URL rewrite configurations" "$GREEN"
    
    # Create main Nginx configuration
    $SUDO tee /etc/nginx/sites-available/smart-agriculture > /dev/null << EOF
server {
    listen 80 default_server;
    server_name _;
    
    client_max_body_size 10M;
    
    # Include URL rewriting
    include /etc/nginx/snippets/url-rewrite.conf;
    
    # Root redirect to Swagger
    location = / {
        return 301 /api/v1/swagger;
    }
    
    # API endpoints
    location /api/ {
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH' always;
            add_header 'Access-Control-Allow-Headers' '*' always;
            add_header 'Access-Control-Max-Age' '86400' always;
            add_header 'Content-Type' 'text/plain; charset=utf-8' always;
            add_header 'Content-Length' '0' always;
            return 204;
        }
        
        include /etc/nginx/snippets/cors.conf;
        
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Swagger UI specific
    location = /api/v1/swagger {
        include /etc/nginx/snippets/cors.conf;
        include /etc/nginx/snippets/url-rewrite.conf;
        
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/swagger;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # OpenAPI JSON
    location = /api/v1/openapi.json {
        include /etc/nginx/snippets/cors.conf;
        
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/openapi.json;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        add_header Content-Type application/json;
    }
    
    location = /SmartAgricultureNutrition/api/v1/openapi.json {
        include /etc/nginx/snippets/cors.conf;
        
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/openapi.json;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        add_header Content-Type application/json;
    }
    
    # Full application path
    location /SmartAgricultureNutrition/ {
        include /etc/nginx/snippets/cors.conf;
        
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/;
        access_log off;
    }
}
EOF
    
    # If DuckDNS is configured, add server block for it
    if [ ! -z "$DUCKDNS_DOMAIN" ]; then
        print_message "Adding DuckDNS configuration..." "$BLUE"
        
        $SUDO tee -a /etc/nginx/sites-available/smart-agriculture > /dev/null << EOF

# DuckDNS domain configuration
server {
    listen 80;
    server_name $DUCKDNS_DOMAIN;
    
    client_max_body_size 10M;
    
    # Include URL rewriting for DuckDNS
    sub_filter 'http://localhost:8080' 'http://$DUCKDNS_DOMAIN';
    sub_filter 'localhost:8080' '$DUCKDNS_DOMAIN';
    sub_filter_once off;
    sub_filter_types application/json text/html application/javascript;
    
    # Same location blocks as above
    location = / {
        return 301 /api/v1/swagger;
    }
    
    location /api/ {
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH' always;
            add_header 'Access-Control-Allow-Headers' '*' always;
            add_header 'Access-Control-Max-Age' '86400' always;
            add_header 'Content-Type' 'text/plain; charset=utf-8' always;
            add_header 'Content-Length' '0' always;
            return 204;
        }
        
        include /etc/nginx/snippets/cors.conf;
        
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /SmartAgricultureNutrition/ {
        include /etc/nginx/snippets/cors.conf;
        
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
        print_message "✓ DuckDNS configuration added" "$GREEN"
    fi
    
    # Enable configuration
    $SUDO ln -sf /etc/nginx/sites-available/smart-agriculture /etc/nginx/sites-enabled/
    
    # Test and reload Nginx
    print_message "Testing Nginx configuration..." "$BLUE"
    if $SUDO nginx -t; then
        $SUDO systemctl reload nginx
        print_message "✓ Nginx reloaded successfully" "$GREEN"
    else
        print_message "✗ Nginx configuration error" "$RED"
        exit 1
    fi
    
    # Step 2: Update application environment
    print_header "Step 2: Updating Application Configuration"
    
    cd ~/SmartAgricultureNutrition
    
    # Create/update .env file with correct server URL
    if [ -f .env ]; then
        grep -v "SWAGGER_SERVER_URL\|CORS_" .env > .env.tmp || true
        mv .env.tmp .env
    fi
    
    echo "SWAGGER_SERVER_URL=http://$PUBLIC_IP/SmartAgricultureNutrition" >> .env
    echo "CORS_ENABLED=true" >> .env
    echo "CORS_ALLOWED_ORIGINS=*" >> .env
    echo "CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS,PATCH" >> .env
    echo "CORS_ALLOWED_HEADERS=*" >> .env
    
    print_message "✓ Environment variables updated" "$GREEN"
    
    # Restart application
    print_message "Restarting application..." "$BLUE"
    if [ -f docker-compose.azure.yml ]; then
        $SUDO docker-compose -f docker-compose.azure.yml restart app
    else
        $SUDO docker-compose -f docker-compose.prod.yml restart app
    fi
    
    print_message "Waiting for application to start..." "$YELLOW"
    sleep 20
    
    # Step 3: Test everything
    print_header "Step 3: Testing Configuration"
    
    # Test application
    print_message "Testing application on port 8080..." "$BLUE"
    if curl -f -s http://localhost:8080/SmartAgricultureNutrition/ > /dev/null; then
        print_message "✓ Application responding" "$GREEN"
    else
        print_message "✗ Application not responding" "$RED"
    fi
    
    # Test through Nginx
    print_message "Testing through Nginx..." "$BLUE"
    if curl -f -s http://$PUBLIC_IP/api/v1/swagger > /dev/null; then
        print_message "✓ Swagger UI accessible" "$GREEN"
    else
        print_message "✗ Swagger UI not accessible" "$RED"
    fi
    
    # Test CORS
    print_message "Testing CORS headers..." "$BLUE"
    CORS_TEST=$(curl -s -I -X OPTIONS http://$PUBLIC_IP/api/v1/auth/users \
        -H "Origin: http://example.com" \
        -H "Access-Control-Request-Method: GET" 2>/dev/null | grep -i "access-control-allow-origin" || echo "")
    
    if [ ! -z "$CORS_TEST" ]; then
        print_message "✓ CORS headers present" "$GREEN"
    else
        print_message "✗ CORS headers missing" "$RED"
    fi
    
    # Test API endpoint
    print_message "Testing API endpoint..." "$BLUE"
    API_TEST=$(curl -s -w "\n%{http_code}" http://$PUBLIC_IP/api/v1/auth/users 2>/dev/null | tail -1)
    if [ "$API_TEST" = "200" ] || [ "$API_TEST" = "403" ]; then
        print_message "✓ API endpoint responding (HTTP $API_TEST)" "$GREEN"
    else
        print_message "✗ API endpoint not working (HTTP $API_TEST)" "$RED"
    fi
    
    # Display summary
    print_header "Configuration Complete!"
    
    print_message "Your API should now be fully functional!" "$GREEN"
    echo
    print_message "Access URLs:" "$BLUE"
    print_message "  Via IP:" "$YELLOW"
    print_message "    Swagger UI: http://$PUBLIC_IP/api/v1/swagger" "$CYAN"
    print_message "    API: http://$PUBLIC_IP/api/v1/" "$CYAN"
    
    if [ ! -z "$DUCKDNS_DOMAIN" ]; then
        print_message "  Via DuckDNS:" "$YELLOW"
        print_message "    Swagger UI: http://$DUCKDNS_DOMAIN/api/v1/swagger" "$CYAN"
        print_message "    API: http://$DUCKDNS_DOMAIN/api/v1/" "$CYAN"
    fi
    
    echo
    print_message "Test with curl:" "$BLUE"
    print_message "  curl -X GET http://$PUBLIC_IP/api/v1/auth/users" "$CYAN"
    print_message "  curl -X POST http://$PUBLIC_IP/api/v1/auth/register \\" "$CYAN"
    print_message "    -H 'Content-Type: application/json' \\" "$CYAN"
    print_message "    -d '{\"username\":\"test\",\"password\":\"test123\",\"email\":\"test@example.com\"}'" "$CYAN"
    
    echo
    print_message "IMPORTANT:" "$YELLOW"
    print_message "  1. Clear your browser cache completely" "$CYAN"
    print_message "  2. Use incognito/private mode for testing" "$CYAN"
    print_message "  3. In Swagger UI, look for a 'Servers' dropdown and select the correct server" "$CYAN"
    print_message "  4. The API calls should now use http://$PUBLIC_IP instead of localhost:8080" "$CYAN"
}

# Run main function
main
