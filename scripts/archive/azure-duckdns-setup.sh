#!/bin/bash

# DuckDNS Setup Script for Azure VM
# This script configures DuckDNS dynamic DNS for your Azure VM

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

# Main setup function
setup_duckdns() {
    print_header "DuckDNS Setup for Azure VM"
    
    # Get DuckDNS subdomain
    print_message "Enter your DuckDNS subdomain (without .duckdns.org):" "$BLUE"
    print_message "Example: If your domain is myapp.duckdns.org, enter: myapp" "$YELLOW"
    read -p "Subdomain: " DUCKDNS_SUBDOMAIN
    
    # Get DuckDNS token
    print_message "\nEnter your DuckDNS token:" "$BLUE"
    print_message "You can find it at: https://www.duckdns.org (after login)" "$YELLOW"
    read -p "Token: " DUCKDNS_TOKEN
    
    # Validate inputs
    if [ -z "$DUCKDNS_SUBDOMAIN" ] || [ -z "$DUCKDNS_TOKEN" ]; then
        print_message "Error: Subdomain and token are required!" "$RED"
        exit 1
    fi
    
    # Create DuckDNS directory
    print_message "\nCreating DuckDNS configuration..." "$BLUE"
    mkdir -p ~/duckdns
    cd ~/duckdns
    
    # Create update script
    print_message "Creating update script..." "$BLUE"
    cat > duck.sh << EOF
#!/bin/bash
# DuckDNS update script
echo "Updating DuckDNS IP..."
echo url="https://www.duckdns.org/update?domains=$DUCKDNS_SUBDOMAIN&token=$DUCKDNS_TOKEN&ip=" | curl -k -o ~/duckdns/duck.log -K -
echo "Update completed at: \$(date)" >> ~/duckdns/duck.log
EOF
    
    # Make script executable
    chmod +x duck.sh
    
    # Test the script
    print_message "Testing DuckDNS update..." "$BLUE"
    ./duck.sh
    
    # Check if update was successful
    if grep -q "OK" ~/duckdns/duck.log; then
        print_message "✓ DuckDNS update successful!" "$GREEN"
    else
        print_message "✗ DuckDNS update failed. Please check your token and subdomain." "$RED"
        cat ~/duckdns/duck.log
        exit 1
    fi
    
    # Setup cron job for automatic updates
    print_message "\nSetting up automatic updates (every 5 minutes)..." "$BLUE"
    
    # Remove existing DuckDNS cron jobs
    crontab -l 2>/dev/null | grep -v "duck.sh" | crontab - 2>/dev/null || true
    
    # Add new cron job
    (crontab -l 2>/dev/null; echo "*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1") | crontab -
    
    print_message "✓ Cron job created for automatic updates" "$GREEN"
    
    # Update Nginx configuration for DuckDNS domain
    print_message "\nUpdating Nginx configuration for DuckDNS domain..." "$BLUE"
    
    # Use the existing nginx.azure.conf as base and modify for DuckDNS
    if [ -f ~/SmartAgricultureNutrition/nginx/nginx.azure.conf ]; then
        print_message "Using updated Nginx configuration from repository..." "$GREEN"
        # Copy and modify the configuration
        sudo cp ~/SmartAgricultureNutrition/nginx/nginx.azure.conf /etc/nginx/sites-available/smart-agriculture-duckdns
        
        # Update server_name for DuckDNS domain
        sudo sed -i "s/server_name _;/server_name $DUCKDNS_SUBDOMAIN.duckdns.org;/" /etc/nginx/sites-available/smart-agriculture-duckdns
        sudo sed -i "s/listen 80 default_server;/listen 80;/" /etc/nginx/sites-available/smart-agriculture-duckdns
        
        # Add IP-based fallback server block
        sudo tee -a /etc/nginx/sites-available/smart-agriculture-duckdns > /dev/null << 'EOF'

# IP-based access fallback (keep existing configuration)
server {
    listen 80 default_server;
    server_name _;
    
    client_max_body_size 10M;
    
    # Global URL rewriting to fix localhost:8080 in all responses
    sub_filter_types application/json application/javascript text/javascript;
    sub_filter_once off;
    sub_filter 'http://localhost:8080' '$scheme://$host';
    sub_filter 'https://localhost:8080' '$scheme://$host';
    sub_filter 'localhost:8080' '$host';
    
    # Root redirect to Swagger UI
    location = / {
        return 301 /api/v1/swagger;
    }
    
    # API endpoints with CORS support
    location /api/ {
        # Handle CORS preflight requests
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,Accept,Origin,X-Api-Key,X-Auth-Token' always;
            add_header 'Access-Control-Max-Age' '86400' always;
            add_header 'Content-Type' 'text/plain; charset=utf-8' always;
            add_header 'Content-Length' '0' always;
            return 204;
        }
        
        # CORS headers for all requests
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,Accept,Origin,X-Api-Key,X-Auth-Token' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range,Authorization,X-Total-Count,Link' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        add_header 'Access-Control-Max-Age' '86400' always;
        
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # Ensure CORS headers are not duplicated from backend
        proxy_hide_header 'Access-Control-Allow-Origin';
        proxy_hide_header 'Access-Control-Allow-Methods';
        proxy_hide_header 'Access-Control-Allow-Headers';
        proxy_hide_header 'Access-Control-Allow-Credentials';
    }
    
    # Swagger UI specific endpoint with comprehensive URL fix
    location = /api/v1/swagger {
        # Handle OPTIONS preflight
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
            add_header 'Access-Control-Allow-Headers' '*' always;
            add_header 'Access-Control-Max-Age' '86400' always;
            return 204;
        }
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
        add_header 'Access-Control-Allow-Headers' '*' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        
        # Comprehensive URL rewriting to fix localhost:8080 issue
        sub_filter_types application/json application/javascript text/javascript;
        sub_filter_once off;
        sub_filter 'http://localhost:8080' '$scheme://$host';
        sub_filter 'https://localhost:8080' '$scheme://$host';
        sub_filter 'localhost:8080' '$host';
        sub_filter '"url":"http://localhost:8080' '"url":"$scheme://$host';
        sub_filter '"servers":[{"url":"http://localhost:8080' '"servers":[{"url":"$scheme://$host';
        sub_filter 'basePath":"http://localhost:8080' 'basePath":"$scheme://$host';
        
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/swagger;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        
        # Hide backend CORS headers to avoid duplication
        proxy_hide_header 'Access-Control-Allow-Origin';
        proxy_hide_header 'Access-Control-Allow-Methods';
    }
    
    # OpenAPI JSON endpoints
    location = /api/v1/openapi.json {
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Content-Type' 'application/json' always;
        
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/openapi.json;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
    
    location = /SmartAgricultureNutrition/api/v1/openapi.json {
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Content-Type' 'application/json' always;
        
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/openapi.json;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
    
    # Full application path (for backward compatibility)
    location /SmartAgricultureNutrition/ {
        # Handle OPTIONS preflight
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
            add_header 'Access-Control-Allow-Headers' '*' always;
            add_header 'Access-Control-Max-Age' '86400' always;
            add_header 'Content-Type' 'text/plain; charset=utf-8' always;
            add_header 'Content-Length' '0' always;
            return 204;
        }
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
        add_header 'Access-Control-Allow-Headers' '*' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Hide backend CORS headers to avoid duplication
        proxy_hide_header 'Access-Control-Allow-Origin';
        proxy_hide_header 'Access-Control-Allow-Methods';
        proxy_hide_header 'Access-Control-Allow-Headers';
        proxy_hide_header 'Access-Control-Allow-Credentials';
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/;
        proxy_http_version 1.1;
    }
}
EOF
    else
        print_message "Creating Nginx configuration for DuckDNS..." "$YELLOW"
        # Create complete configuration if nginx.azure.conf doesn't exist
        sudo tee /etc/nginx/sites-available/smart-agriculture-duckdns > /dev/null << EOF
# DuckDNS domain server block
server {
    listen 80;
    server_name $DUCKDNS_SUBDOMAIN.duckdns.org;
    
    client_max_body_size 10M;
    
    # Global URL rewriting to fix localhost:8080 in all responses
    sub_filter_types application/json application/javascript text/javascript;
    sub_filter_once off;
    sub_filter 'http://localhost:8080' '\$scheme://\$host';
    sub_filter 'https://localhost:8080' '\$scheme://\$host';
    sub_filter 'localhost:8080' '\$host';
    
    # Root redirect to Swagger UI
    location = / {
        return 301 /api/v1/swagger;
    }
    
    # API endpoints with CORS support
    location /api/ {
        # Handle CORS preflight requests
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,Accept,Origin,X-Api-Key,X-Auth-Token' always;
            add_header 'Access-Control-Max-Age' '86400' always;
            add_header 'Content-Type' 'text/plain; charset=utf-8' always;
            add_header 'Content-Length' '0' always;
            return 204;
        }
        
        # CORS headers for all requests
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,Accept,Origin,X-Api-Key,X-Auth-Token' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range,Authorization,X-Total-Count,Link' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        add_header 'Access-Control-Max-Age' '86400' always;
        
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        
        # Ensure CORS headers are not duplicated from backend
        proxy_hide_header 'Access-Control-Allow-Origin';
        proxy_hide_header 'Access-Control-Allow-Methods';
        proxy_hide_header 'Access-Control-Allow-Headers';
        proxy_hide_header 'Access-Control-Allow-Credentials';
    }
    
    # Swagger UI specific endpoint with comprehensive URL fix
    location = /api/v1/swagger {
        # Handle OPTIONS preflight
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
            add_header 'Access-Control-Allow-Headers' '*' always;
            add_header 'Access-Control-Max-Age' '86400' always;
            return 204;
        }
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
        add_header 'Access-Control-Allow-Headers' '*' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        
        # Comprehensive URL rewriting to fix localhost:8080 issue
        sub_filter_types application/json application/javascript text/javascript;
        sub_filter_once off;
        sub_filter 'http://localhost:8080' '\$scheme://\$host';
        sub_filter 'https://localhost:8080' '\$scheme://\$host';
        sub_filter 'localhost:8080' '\$host';
        sub_filter '"url":"http://localhost:8080' '"url":"\$scheme://\$host';
        sub_filter '"servers":[{"url":"http://localhost:8080' '"servers":[{"url":"\$scheme://\$host';
        sub_filter 'basePath":"http://localhost:8080' 'basePath":"\$scheme://\$host';
        
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/swagger;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        
        # Hide backend CORS headers to avoid duplication
        proxy_hide_header 'Access-Control-Allow-Origin';
        proxy_hide_header 'Access-Control-Allow-Methods';
    }
    
    # OpenAPI JSON endpoints
    location = /api/v1/openapi.json {
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Content-Type' 'application/json' always;
        
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/openapi.json;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
    }
    
    location = /SmartAgricultureNutrition/api/v1/openapi.json {
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Content-Type' 'application/json' always;
        
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/openapi.json;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
    }
    
    # Full application path (for backward compatibility)
    location /SmartAgricultureNutrition/ {
        # Handle OPTIONS preflight
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
            add_header 'Access-Control-Allow-Headers' '*' always;
            add_header 'Access-Control-Max-Age' '86400' always;
            add_header 'Content-Type' 'text/plain; charset=utf-8' always;
            add_header 'Content-Length' '0' always;
            return 204;
        }
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
        add_header 'Access-Control-Allow-Headers' '*' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Hide backend CORS headers to avoid duplication
        proxy_hide_header 'Access-Control-Allow-Origin';
        proxy_hide_header 'Access-Control-Allow-Methods';
        proxy_hide_header 'Access-Control-Allow-Headers';
        proxy_hide_header 'Access-Control-Allow-Credentials';
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/;
        proxy_http_version 1.1;
    }
}
EOF
    fi
    
    # Enable the new configuration
    sudo ln -sf /etc/nginx/sites-available/smart-agriculture-duckdns /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/smart-agriculture
    
    # Test and reload Nginx
    sudo nginx -t
    sudo systemctl reload nginx
    
    print_message "✓ Nginx configured for DuckDNS domain" "$GREEN"
    
    # Get current public IP
    PUBLIC_IP=$(curl -s https://api.ipify.org)
    
    # Display summary
    print_header "DuckDNS Setup Complete!"
    
    print_message "Your application is now accessible at:" "$GREEN"
    print_message "  🌐 http://$DUCKDNS_SUBDOMAIN.duckdns.org" "$YELLOW"
    print_message "  📊 http://$DUCKDNS_SUBDOMAIN.duckdns.org/api/v1/" "$YELLOW"
    print_message "  📚 http://$DUCKDNS_SUBDOMAIN.duckdns.org/api/v1/swagger" "$YELLOW"
    echo
    print_message "You can also still access via IP:" "$BLUE"
    print_message "  http://$PUBLIC_IP" "$CYAN"
    echo
    print_message "DuckDNS Configuration:" "$BLUE"
    print_message "  Domain: $DUCKDNS_SUBDOMAIN.duckdns.org" "$CYAN"
    print_message "  Current IP: $PUBLIC_IP" "$CYAN"
    print_message "  Update script: ~/duckdns/duck.sh" "$CYAN"
    print_message "  Log file: ~/duckdns/duck.log" "$CYAN"
    print_message "  Auto-update: Every 5 minutes via cron" "$CYAN"
    echo
    print_message "To check DuckDNS updates:" "$BLUE"
    print_message "  cat ~/duckdns/duck.log" "$CYAN"
    print_message "  crontab -l  # View cron jobs" "$CYAN"
}

# Setup HTTPS with Let's Encrypt
setup_https() {
    print_header "HTTPS Setup with Let's Encrypt"
    
    print_message "Do you want to setup HTTPS with Let's Encrypt?" "$YELLOW"
    print_message "This will enable secure HTTPS access to your API." "$YELLOW"
    read -p "Setup HTTPS? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "Skipping HTTPS setup" "$YELLOW"
        print_message "You can run this script again later to enable HTTPS" "$CYAN"
        return
    fi
    
    # Check if domain is set
    if [ -z "$DUCKDNS_SUBDOMAIN" ]; then
        print_message "Error: DuckDNS subdomain not set!" "$RED"
        return
    fi
    
    print_message "Installing Certbot..." "$BLUE"
    sudo apt-get update -qq
    sudo apt-get install -y certbot python3-certbot-nginx
    
    # First, ensure port 443 is open in Azure NSG
    print_message "IMPORTANT: Make sure port 443 is open in Azure Network Security Group!" "$YELLOW"
    print_message "Go to Azure Portal > Your VM > Networking > Add inbound port rule for 443" "$YELLOW"
    read -p "Press Enter when port 443 is open in Azure NSG..."
    
    print_message "Obtaining SSL certificate for $DUCKDNS_SUBDOMAIN.duckdns.org..." "$BLUE"
    
    # Get user email for Let's Encrypt
    print_message "Enter your email for Let's Encrypt notifications:" "$BLUE"
    read -p "Email: " USER_EMAIL
    
    if [ -z "$USER_EMAIL" ]; then
        USER_EMAIL="admin@$DUCKDNS_SUBDOMAIN.duckdns.org"
    fi
    
    # Run certbot
    sudo certbot --nginx \
        -d $DUCKDNS_SUBDOMAIN.duckdns.org \
        --non-interactive \
        --agree-tos \
        --email $USER_EMAIL \
        --redirect \
        --expand
    
    if [ $? -eq 0 ]; then
        print_message "✓ HTTPS enabled successfully!" "$GREEN"
        
        # Update Nginx configuration to handle WebSocket for Swagger UI
        sudo tee /tmp/nginx-ssl-fix.conf > /dev/null << 'EOF'
# Additional headers for HTTPS
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
EOF
        
        # Apply the additional headers
        sudo sed -i '/listen 443 ssl/a\    include /tmp/nginx-ssl-fix.conf;' /etc/nginx/sites-enabled/smart-agriculture-duckdns
        
        # Test and reload Nginx
        sudo nginx -t && sudo systemctl reload nginx
        
        print_message "Your application is now accessible at:" "$GREEN"
        print_message "  🔒 https://$DUCKDNS_SUBDOMAIN.duckdns.org" "$YELLOW"
        print_message "  🔒 https://$DUCKDNS_SUBDOMAIN.duckdns.org/api/v1/swagger" "$YELLOW"
        echo
        print_message "HTTP requests will automatically redirect to HTTPS" "$CYAN"
        
        # Setup auto-renewal
        print_message "Setting up auto-renewal..." "$BLUE"
        sudo systemctl enable certbot.timer
        sudo systemctl start certbot.timer
        
        # Test renewal
        print_message "Testing certificate renewal..." "$BLUE"
        sudo certbot renew --dry-run
        
        if [ $? -eq 0 ]; then
            print_message "✓ SSL certificate auto-renewal configured" "$GREEN"
        else
            print_message "⚠ Auto-renewal test failed, but certificate is installed" "$YELLOW"
        fi
    else
        print_message "✗ Failed to obtain SSL certificate" "$RED"
        print_message "Common issues:" "$YELLOW"
        print_message "  1. Port 443 not open in Azure NSG" "$CYAN"
        print_message "  2. Domain not pointing to this server" "$CYAN"
        print_message "  3. Rate limit exceeded (wait 1 hour)" "$CYAN"
    fi
}

# Main execution
main() {
    print_message "DuckDNS Dynamic DNS Setup for Azure VM" "$GREEN"
    print_message "This will configure your VM to use a DuckDNS subdomain" "$GREEN"
    echo
    
    # Check if running on Azure VM
    if [ ! -f ~/SmartAgricultureNutrition/docker-compose.prod.yml ]; then
        print_message "Warning: Application not found. Please run azure-vm-setup.sh first!" "$YELLOW"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
    
    # Setup DuckDNS
    setup_duckdns
    
    # Optional HTTPS setup
    setup_https
    
    print_message "\n✅ DuckDNS setup completed successfully!" "$GREEN"
}

# Run main function
main
