#!/bin/bash

# Complete Fix Script for Smart Agriculture API
# Fixes CORS, OpenAPI JSON path, and Swagger UI issues

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
    print_header "Complete Fix for Smart Agriculture API"
    
    # Check if running with sudo
    if [[ $EUID -eq 0 ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi
    
    # Get public IP
    PUBLIC_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "localhost")
    print_message "Public IP: $PUBLIC_IP" "$BLUE"
    
    # Step 1: Create comprehensive Nginx configuration
    print_header "Step 1: Fixing Nginx Configuration"
    
    # Create CORS configuration
    $SUDO tee /etc/nginx/snippets/cors.conf > /dev/null << 'EOF'
# CORS Headers
add_header 'Access-Control-Allow-Origin' '*' always;
add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH' always;
add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,Accept,Origin' always;
add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range,Authorization' always;
add_header 'Access-Control-Allow-Credentials' 'true' always;
add_header 'Access-Control-Max-Age' '86400' always;

# Handle preflight requests
if ($request_method = 'OPTIONS') {
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH' always;
    add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,Accept,Origin' always;
    add_header 'Access-Control-Max-Age' '86400' always;
    add_header 'Content-Type' 'text/plain; charset=utf-8' always;
    add_header 'Content-Length' '0' always;
    return 204;
}
EOF
    
    print_message "✓ CORS configuration created" "$GREEN"
    
    # Create main Nginx configuration
    $SUDO tee /etc/nginx/sites-available/smart-agriculture > /dev/null << 'EOF'
server {
    listen 80 default_server;
    server_name _;
    
    client_max_body_size 10M;
    
    # Root redirect to Swagger
    location = / {
        return 301 /api/v1/swagger;
    }
    
    # Main API path with CORS
    location /api/ {
        include /etc/nginx/snippets/cors.conf;
        
        # Remove /api prefix when proxying
        rewrite ^/api/(.*)$ /SmartAgricultureNutrition/api/$1 break;
        
        proxy_pass http://localhost:8080;
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
    
    # Swagger UI specific path
    location = /api/v1/swagger {
        include /etc/nginx/snippets/cors.conf;
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/swagger;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Swagger UI resources
    location /api/v1/swagger-ui/ {
        include /etc/nginx/snippets/cors.conf;
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/swagger-ui/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
    
    # OpenAPI JSON - Multiple paths for compatibility
    location = /api/v1/openapi.json {
        include /etc/nginx/snippets/cors.conf;
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/openapi.json;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        add_header Content-Type application/json;
    }
    
    location = /SmartAgricultureNutrition/api/v1/openapi.json {
        include /etc/nginx/snippets/cors.conf;
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/openapi.json;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        add_header Content-Type application/json;
    }
    
    # Full application path (for compatibility)
    location /SmartAgricultureNutrition/ {
        include /etc/nginx/snippets/cors.conf;
        
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
    
    # Health check
    location /health {
        include /etc/nginx/snippets/cors.conf;
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/;
        proxy_http_version 1.1;
        access_log off;
    }
}
EOF
    
    print_message "✓ Nginx configuration created" "$GREEN"
    
    # Enable the configuration
    $SUDO ln -sf /etc/nginx/sites-available/smart-agriculture /etc/nginx/sites-enabled/
    $SUDO rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
    
    # Test Nginx
    print_message "Testing Nginx configuration..." "$BLUE"
    if $SUDO nginx -t; then
        $SUDO systemctl reload nginx
        print_message "✓ Nginx reloaded successfully" "$GREEN"
    else
        print_message "✗ Nginx configuration error" "$RED"
        exit 1
    fi
    
    # Step 2: Check if application is running
    print_header "Step 2: Checking Application Status"
    
    cd ~/SmartAgricultureNutrition
    
    # Check Docker containers
    if $SUDO docker ps | grep -q "agriculture-app"; then
        print_message "✓ Application container is running" "$GREEN"
    else
        print_message "⚠ Application container not running, starting..." "$YELLOW"
        
        if [ -f docker-compose.azure.yml ]; then
            $SUDO docker-compose -f docker-compose.azure.yml up -d
        else
            $SUDO docker-compose -f docker-compose.prod.yml up -d
        fi
        
        print_message "Waiting for application to start..." "$YELLOW"
        sleep 30
    fi
    
    # Step 3: Test endpoints
    print_header "Step 3: Testing Endpoints"
    
    # Test main application
    print_message "Testing main application..." "$BLUE"
    if curl -f -s http://localhost:8080/SmartAgricultureNutrition/ > /dev/null; then
        print_message "✓ Application responding on port 8080" "$GREEN"
    else
        print_message "✗ Application not responding" "$RED"
    fi
    
    # Test OpenAPI JSON
    print_message "Testing OpenAPI JSON..." "$BLUE"
    if curl -f -s http://localhost:8080/SmartAgricultureNutrition/api/v1/openapi.json > /dev/null; then
        print_message "✓ OpenAPI JSON available" "$GREEN"
    else
        print_message "⚠ OpenAPI JSON not found at expected path" "$YELLOW"
        
        # Try alternative paths
        if curl -f -s http://localhost:8080/SmartAgricultureNutrition/openapi.json > /dev/null; then
            print_message "✓ OpenAPI JSON found at /SmartAgricultureNutrition/openapi.json" "$GREEN"
            
            # Create a redirect
            $SUDO sed -i '/location = \/SmartAgricultureNutrition\/api\/v1\/openapi.json {/,/}/c\
    location = /SmartAgricultureNutrition/api/v1/openapi.json {\
        include /etc/nginx/snippets/cors.conf;\
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/openapi.json;\
        proxy_http_version 1.1;\
        proxy_set_header Host $host;\
        add_header Content-Type application/json;\
    }' /etc/nginx/sites-available/smart-agriculture
            
            $SUDO nginx -t && $SUDO systemctl reload nginx
            print_message "✓ Updated Nginx to use correct OpenAPI path" "$GREEN"
        fi
    fi
    
    # Test through Nginx
    print_message "Testing through Nginx..." "$BLUE"
    if curl -f -s http://$PUBLIC_IP/api/v1/swagger > /dev/null; then
        print_message "✓ Swagger UI accessible through Nginx" "$GREEN"
    else
        print_message "✗ Swagger UI not accessible" "$RED"
    fi
    
    # Test CORS
    print_message "Testing CORS..." "$BLUE"
    CORS_TEST=$(curl -s -I -X OPTIONS http://$PUBLIC_IP/api/v1/auth/users \
        -H "Origin: http://example.com" \
        -H "Access-Control-Request-Method: GET" | grep -i "access-control-allow-origin" || echo "")
    
    if [ ! -z "$CORS_TEST" ]; then
        print_message "✓ CORS headers present" "$GREEN"
    else
        print_message "⚠ CORS headers may not be working" "$YELLOW"
    fi
    
    # Step 4: Create test HTML file
    print_header "Step 4: Creating Test Page"
    
    cat > ~/test-api.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>API Test</title>
</head>
<body>
    <h1>Smart Agriculture API Test</h1>
    <button onclick="testAPI()">Test API</button>
    <div id="result"></div>
    
    <script>
    function testAPI() {
        fetch('http://$PUBLIC_IP/api/v1/auth/users')
            .then(response => response.json())
            .then(data => {
                document.getElementById('result').innerHTML = 
                    '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
            })
            .catch(error => {
                document.getElementById('result').innerHTML = 
                    'Error: ' + error.message;
            });
    }
    </script>
</body>
</html>
EOF
    
    print_message "✓ Test page created at ~/test-api.html" "$GREEN"
    
    # Display summary
    print_header "Fix Complete!"
    
    print_message "All issues should now be fixed!" "$GREEN"
    echo
    print_message "Access points:" "$BLUE"
    print_message "  Swagger UI: http://$PUBLIC_IP/api/v1/swagger" "$YELLOW"
    print_message "  API Base: http://$PUBLIC_IP/api/v1/" "$YELLOW"
    print_message "  OpenAPI JSON: http://$PUBLIC_IP/api/v1/openapi.json" "$YELLOW"
    echo
    print_message "Test endpoints:" "$BLUE"
    print_message "  Auth Users: http://$PUBLIC_IP/api/v1/auth/users" "$CYAN"
    print_message "  Register: http://$PUBLIC_IP/api/v1/auth/register" "$CYAN"
    print_message "  Login: http://$PUBLIC_IP/api/v1/auth/login" "$CYAN"
    echo
    print_message "Test with curl:" "$BLUE"
    print_message "  curl http://$PUBLIC_IP/api/v1/auth/users" "$CYAN"
    echo
    print_message "If issues persist:" "$YELLOW"
    print_message "  1. Check logs: sudo docker-compose logs app" "$CYAN"
    print_message "  2. Restart app: sudo docker-compose restart app" "$CYAN"
    print_message "  3. Check Nginx: sudo nginx -t && sudo systemctl status nginx" "$CYAN"
}

# Run main function
main
