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
    
    sudo tee /etc/nginx/sites-available/smart-agriculture-duckdns > /dev/null << EOF
server {
    listen 80;
    server_name $DUCKDNS_SUBDOMAIN.duckdns.org;
    
    client_max_body_size 10M;
    
    # Root path - redirect to Swagger UI
    location = / {
        return 301 /api/v1/swagger;
    }
    
    # API endpoints
    location /api/ {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Swagger UI
    location /api/v1/swagger {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/swagger;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # OpenAPI JSON - Fix the path
    location /SmartAgricultureNutrition/api/v1/openapi.json {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/openapi.json;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
    }
    
    # Alternative OpenAPI path
    location /api/v1/openapi.json {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/openapi.json;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
    }
    
    # Swagger resources
    location /SmartAgricultureNutrition/api/v1/swagger-ui/ {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/api/v1/swagger-ui/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
    }
    
    # Main application path
    location /SmartAgricultureNutrition/ {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/;
        proxy_http_version 1.1;
        access_log off;
    }
}

# Keep the IP-based access as fallback
server {
    listen 80 default_server;
    server_name _;
    
    client_max_body_size 10M;
    
    location / {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF
    
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

# Optional: Setup HTTPS with Let's Encrypt
setup_https() {
    print_header "HTTPS Setup with Let's Encrypt (Optional)"
    
    read -p "Do you want to setup HTTPS with Let's Encrypt? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "Skipping HTTPS setup" "$YELLOW"
        return
    fi
    
    print_message "Installing Certbot..." "$BLUE"
    sudo apt-get update
    sudo apt-get install -y certbot python3-certbot-nginx
    
    print_message "Obtaining SSL certificate..." "$BLUE"
    sudo certbot --nginx -d $DUCKDNS_SUBDOMAIN.duckdns.org --non-interactive --agree-tos --email admin@$DUCKDNS_SUBDOMAIN.duckdns.org --redirect
    
    print_message "✓ HTTPS enabled!" "$GREEN"
    print_message "Your application is now accessible at:" "$GREEN"
    print_message "  🔒 https://$DUCKDNS_SUBDOMAIN.duckdns.org" "$YELLOW"
    
    # Setup auto-renewal
    print_message "Setting up auto-renewal..." "$BLUE"
    sudo systemctl enable certbot.timer
    sudo systemctl start certbot.timer
    
    print_message "✓ SSL certificate will auto-renew" "$GREEN"
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
