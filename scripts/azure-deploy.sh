#!/bin/bash

# Azure VM Manual Setup Script for Smart Agriculture Nutrition API
# Run this script on your Azure VM after creating it manually through Azure Portal

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

# Check if running as root or with sudo
check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        print_message "Please run this script as a regular user, not as root" "$RED"
        print_message "The script will use sudo when needed" "$YELLOW"
        exit 1
    fi
}

# Update system
update_system() {
    print_header "Updating System Packages"
    print_message "Updating package lists..." "$BLUE"
    sudo apt-get update
    
    print_message "Upgrading packages..." "$BLUE"
    sudo apt-get upgrade -y
    
    print_message "System updated successfully" "$GREEN"
}

# Install Docker
install_docker() {
    print_header "Installing Docker"
    
    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        print_message "Docker is already installed" "$GREEN"
        docker --version
    else
        print_message "Installing Docker..." "$BLUE"
        
        # Install prerequisites
        sudo apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
        
        # Add Docker's official GPG key
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        
        # Add current user to docker group
        sudo usermod -aG docker $USER
        
        # Clean up
        rm get-docker.sh
        
        print_message "Docker installed successfully" "$GREEN"
        print_message "NOTE: You may need to log out and back in for docker group changes to take effect" "$YELLOW"
    fi
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
}

# Install Docker Compose
install_docker_compose() {
    print_header "Installing Docker Compose"
    
    if command -v docker-compose &> /dev/null; then
        print_message "Docker Compose is already installed" "$GREEN"
        docker-compose --version
    else
        print_message "Installing Docker Compose..." "$BLUE"
        sudo apt-get install -y docker-compose
        print_message "Docker Compose installed successfully" "$GREEN"
    fi
}

# Install other required tools
install_tools() {
    print_header "Installing Required Tools"
    
    print_message "Installing Git, Nginx, and other tools..." "$BLUE"
    sudo apt-get install -y \
        git \
        nginx \
        curl \
        wget \
        htop \
        net-tools \
        postgresql-client
    
    print_message "Tools installed successfully" "$GREEN"
}

# Clone repository
clone_repository() {
    print_header "Setting Up Application"
    
    cd ~
    
    # Check if repository already exists
    if [ -d "SmartAgricultureNutrition" ]; then
        print_message "Repository already exists. Pulling latest changes..." "$YELLOW"
        cd SmartAgricultureNutrition
        git pull origin main
    else
        print_message "Cloning repository..." "$BLUE"
        git clone https://github.com/salmanprottoy/Smart-Agriculture-Nutrition.git SmartAgricultureNutrition
        cd SmartAgricultureNutrition
    fi
    
    print_message "Repository ready" "$GREEN"
}

# Setup environment file with CORS settings
setup_env_file() {
    print_header "Setting Up Environment Configuration"
    
    # Get public IP for Swagger configuration
    VM_IP=$(curl -s https://api.ipify.org 2>/dev/null || curl -s ifconfig.me)
    
    if [ -f ".env" ]; then
        print_message "Existing .env file found. Creating backup..." "$YELLOW"
        cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # Copy Azure environment template if it exists
    if [ -f ".env.azure" ]; then
        print_message "Using .env.azure template..." "$BLUE"
        cp .env.azure .env
    else
        print_message "Creating .env file..." "$BLUE"
        cat > .env << 'EOF'
# Database Configuration
POSTGRES_DB=smart_agriculture_nutrition
POSTGRES_USER=agriculture_user
POSTGRES_PASSWORD=AgriNutri2024SecurePass!

# Database connection (for application)
DB_HOST=postgres
DB_PORT=5432
DB_NAME=smart_agriculture_nutrition
DB_USERNAME=agriculture_user
DB_PASSWORD=AgriNutri2024SecurePass!

# API Keys (replace with your actual keys)
WEATHER_API_KEY=your_weather_api_key_here
USDA_API_KEY=your_usda_api_key_here

# JWT Secret
JWT_SECRET=your-super-secure-jwt-secret-key-2024

# Application
PORT=8080
APP_ENVIRONMENT=production
EOF
    fi
    
    # Add CORS and Swagger configuration
    print_message "Adding CORS and Swagger configuration..." "$BLUE"
    echo "" >> .env
    echo "# CORS Configuration" >> .env
    echo "CORS_ENABLED=true" >> .env
    echo "CORS_ALLOWED_ORIGINS=*" >> .env
    echo "CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS,PATCH" >> .env
    echo "CORS_ALLOWED_HEADERS=*" >> .env
    echo "" >> .env
    echo "# Swagger Configuration" >> .env
    echo "SWAGGER_SERVER_URL=http://$VM_IP/SmartAgricultureNutrition" >> .env
    
    print_message "✓ .env file created with CORS settings" "$GREEN"
    print_message "IMPORTANT: Edit the .env file to add your actual API keys:" "$RED"
    print_message "  nano ~/SmartAgricultureNutrition/.env" "$YELLOW"
}

# Build and start application
start_application() {
    print_header "Starting Application with Docker Compose"
    
    # Check if Azure-specific compose file exists, otherwise use prod
    if [ -f "docker-compose.azure.yml" ]; then
        COMPOSE_FILE="docker-compose.azure.yml"
        print_message "Using Azure-optimized Docker Compose configuration..." "$GREEN"
    else
        COMPOSE_FILE="docker-compose.prod.yml"
        print_message "Using standard production Docker Compose configuration..." "$YELLOW"
    fi
    
    # Fix for Docker Compose 'ContainerConfig' error
    print_message "Cleaning up any existing containers..." "$BLUE"
    sudo docker-compose -f $COMPOSE_FILE down --remove-orphans 2>/dev/null || true
    
    # Remove problematic containers if they exist
    sudo docker rm -f agriculture-postgres smart-agriculture-app 2>/dev/null || true
    
    # Clean up volumes to avoid conflicts
    print_message "Cleaning up old volumes..." "$BLUE"
    sudo docker volume prune -f 2>/dev/null || true
    
    print_message "Building Docker images..." "$BLUE"
    sudo docker-compose -f $COMPOSE_FILE build
    
    print_message "Starting containers with fresh state..." "$BLUE"
    # Use docker compose (v2) if available, otherwise fall back to docker-compose
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        print_message "Using Docker Compose V2..." "$GREEN"
        sudo docker compose -f $COMPOSE_FILE up -d --force-recreate
    else
        print_message "Using Docker Compose V1..." "$YELLOW"
        sudo docker-compose -f $COMPOSE_FILE up -d --force-recreate --renew-anon-volumes
    fi
    
    print_message "Waiting for services to start..." "$YELLOW"
    sleep 30
    
    # Check container status
    print_message "Container status:" "$BLUE"
    sudo docker ps
    
    # Check if containers are actually running
    if sudo docker ps | grep -q "smart-agriculture-app"; then
        print_message "✓ Application container is running" "$GREEN"
    else
        print_message "⚠ Application container may not be running properly" "$YELLOW"
        print_message "Checking logs..." "$BLUE"
        sudo docker-compose -f $COMPOSE_FILE logs --tail=20
    fi
    
    if sudo docker ps | grep -q "postgres"; then
        print_message "✓ Database container is running" "$GREEN"
    else
        print_message "⚠ Database container may not be running properly" "$YELLOW"
    fi
    
    print_message "Application deployment attempted" "$GREEN"
}

# Configure Nginx with CORS and URL rewriting
configure_nginx() {
    print_header "Configuring Nginx with CORS and Fixes"
    
    # Get public IP
    VM_IP=$(curl -s https://api.ipify.org 2>/dev/null || curl -s ifconfig.me)
    print_message "Public IP: $VM_IP" "$BLUE"
    
    # Clean up existing configurations
    print_message "Cleaning existing Nginx configurations..." "$BLUE"
    sudo rm -f /etc/nginx/sites-enabled/* 2>/dev/null || true
    sudo rm -f /etc/nginx/snippets/swagger-headers.conf 2>/dev/null || true
    
    # Create CORS configuration
    print_message "Creating CORS configuration..." "$BLUE"
    sudo tee /etc/nginx/snippets/cors.conf > /dev/null << 'EOF'
# CORS Headers - Applied to all responses
add_header 'Access-Control-Allow-Origin' '*' always;
add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,Accept,Origin,X-Api-Key,X-Auth-Token' always;
add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range,Authorization,X-Total-Count,Link' always;
add_header 'Access-Control-Allow-Credentials' 'true' always;
add_header 'Access-Control-Max-Age' '86400' always;
EOF
    
    # Create URL rewrite configuration to fix localhost issue
    sudo tee /etc/nginx/snippets/url-rewrite.conf > /dev/null << EOF
# Rewrite localhost URLs in responses
sub_filter 'http://localhost:8080' 'http://$VM_IP';
sub_filter 'localhost:8080' '$VM_IP';
sub_filter_once off;
sub_filter_types application/json application/javascript;
EOF
    
    print_message "Creating Nginx configuration with all fixes..." "$BLUE"
    
    # Check if we have a pre-configured Nginx file in the repository
    if [ -f ~/SmartAgricultureNutrition/nginx/nginx.azure.conf ]; then
        print_message "Using pre-configured Nginx configuration from repository..." "$GREEN"
        sudo cp ~/SmartAgricultureNutrition/nginx/nginx.azure.conf /etc/nginx/sites-available/smart-agriculture
    else
        print_message "Creating Nginx configuration..." "$BLUE"
        sudo tee /etc/nginx/sites-available/smart-agriculture > /dev/null << EOF
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
    
    # API endpoints with CORS
    location /api/ {
        # Handle preflight OPTIONS requests
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,Accept,Origin,X-Api-Key,X-Auth-Token' always;
            add_header 'Access-Control-Max-Age' '86400' always;
            add_header 'Content-Type' 'text/plain; charset=utf-8' always;
            add_header 'Content-Length' '0' always;
            return 204;
        }
        
        # Include CORS headers for all other requests
        include /etc/nginx/snippets/cors.conf;
        
        # Proxy settings
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
        
        # Ensure CORS headers are not duplicated
        proxy_hide_header 'Access-Control-Allow-Origin';
        proxy_hide_header 'Access-Control-Allow-Methods';
        proxy_hide_header 'Access-Control-Allow-Headers';
        proxy_hide_header 'Access-Control-Allow-Credentials';
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
    
    # OpenAPI JSON paths
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
        # Handle preflight OPTIONS requests
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
            add_header 'Access-Control-Allow-Headers' '*' always;
            add_header 'Access-Control-Max-Age' '86400' always;
            add_header 'Content-Type' 'text/plain; charset=utf-8' always;
            add_header 'Content-Length' '0' always;
            return 204;
        }
        
        include /etc/nginx/snippets/cors.conf;
        
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Ensure CORS headers are not duplicated
        proxy_hide_header 'Access-Control-Allow-Origin';
        proxy_hide_header 'Access-Control-Allow-Methods';
        proxy_hide_header 'Access-Control-Allow-Headers';
        proxy_hide_header 'Access-Control-Allow-Credentials';
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/;
        access_log off;
    }
}
EOF
    fi
    
    # Enable the site
    sudo ln -sf /etc/nginx/sites-available/smart-agriculture /etc/nginx/sites-enabled/
    
    # Test Nginx configuration
    print_message "Testing Nginx configuration..." "$BLUE"
    if sudo nginx -t; then
        # Restart Nginx
        print_message "Restarting Nginx..." "$BLUE"
        sudo systemctl restart nginx
        sudo systemctl enable nginx
        print_message "✓ Nginx configured successfully with CORS and fixes" "$GREEN"
    else
        print_message "✗ Nginx configuration error" "$RED"
        exit 1
    fi
}

# Setup firewall
setup_firewall() {
    print_header "Configuring Firewall"
    
    # Check if ufw is installed
    if ! command -v ufw &> /dev/null; then
        print_message "Installing UFW firewall..." "$BLUE"
        sudo apt-get install -y ufw
    fi
    
    print_message "Configuring firewall rules..." "$BLUE"
    
    # Allow SSH (port 22)
    sudo ufw allow 22/tcp
    
    # Allow HTTP (port 80)
    sudo ufw allow 80/tcp
    
    # Allow HTTPS (port 443)
    sudo ufw allow 443/tcp
    
    # Allow application port (port 8080)
    sudo ufw allow 8080/tcp
    
    # Enable firewall
    print_message "Enabling firewall..." "$BLUE"
    sudo ufw --force enable
    
    # Show status
    sudo ufw status
    
    print_message "Firewall configured successfully" "$GREEN"
}

# Create systemd service for auto-start
create_systemd_service() {
    print_header "Setting Up Auto-Start Service"
    
    print_message "Creating systemd service..." "$BLUE"
    
    sudo tee /etc/systemd/system/smart-agriculture.service > /dev/null << EOF
[Unit]
Description=Smart Agriculture Nutrition API
After=docker.service
Requires=docker.service

[Service]
Type=simple
Restart=always
RestartSec=10
WorkingDirectory=/home/$USER/SmartAgricultureNutrition
ExecStart=/usr/bin/docker-compose -f docker-compose.azure.yml up
ExecStop=/usr/bin/docker-compose -f docker-compose.azure.yml down
User=$USER

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable smart-agriculture.service
    
    print_message "Auto-start service created" "$GREEN"
}

# Test application with CORS
test_application() {
    print_header "Testing Application and CORS"
    
    print_message "Testing application endpoints..." "$BLUE"
    
    # Get VM IP
    VM_IP=$(curl -s https://api.ipify.org 2>/dev/null || curl -s ifconfig.me)
    
    # Test main endpoint
    if curl -f -s http://localhost:8080/SmartAgricultureNutrition/ > /dev/null; then
        print_message "✓ Application is responding on port 8080" "$GREEN"
    else
        print_message "✗ Application is not responding on port 8080" "$RED"
    fi
    
    # Test Nginx proxy
    if curl -f -s http://localhost/api/v1/swagger > /dev/null; then
        print_message "✓ Nginx proxy is working on port 80" "$GREEN"
    else
        print_message "✗ Nginx proxy is not working on port 80" "$RED"
    fi
    
    # Test CORS headers
    print_message "Testing CORS headers..." "$BLUE"
    CORS_TEST=$(curl -s -I -X OPTIONS http://$VM_IP/api/v1/auth/users \
        -H "Origin: http://example.com" \
        -H "Access-Control-Request-Method: GET" 2>/dev/null | grep -i "access-control-allow-origin" || echo "")
    
    if [ ! -z "$CORS_TEST" ]; then
        print_message "✓ CORS headers present" "$GREEN"
    else
        print_message "⚠ CORS headers may need configuration" "$YELLOW"
    fi
    
    # Test API endpoint
    print_message "Testing API endpoint..." "$BLUE"
    API_TEST=$(curl -s -w "\n%{http_code}" http://$VM_IP/api/v1/auth/users 2>/dev/null | tail -1)
    if [ "$API_TEST" = "200" ] || [ "$API_TEST" = "403" ]; then
        print_message "✓ API endpoint responding (HTTP $API_TEST)" "$GREEN"
    else
        print_message "⚠ API endpoint returned HTTP $API_TEST" "$YELLOW"
    fi
    
    print_message "\nApplication is accessible at:" "$BLUE"
    print_message "  Swagger UI: http://$VM_IP/api/v1/swagger" "$GREEN"
    print_message "  API Base: http://$VM_IP/api/v1/" "$GREEN"
    print_message "  Health: http://$VM_IP/health" "$GREEN"
}

# Display summary
display_summary() {
    print_header "Setup Complete!"
    
    # Get VM IP
    VM_IP=$(curl -s https://api.ipify.org)
    
    print_message "Your Smart Agriculture Nutrition API is now deployed!" "$GREEN"
    echo
    print_message "Access your application at:" "$BLUE"
    print_message "  Main URL: http://$VM_IP/" "$YELLOW"
    print_message "  API Endpoints: http://$VM_IP/api/v1/" "$YELLOW"
    print_message "  Swagger UI: http://$VM_IP/api/v1/swagger" "$YELLOW"
    echo
    print_message "Important next steps:" "$BLUE"
    print_message "1. Update the .env file with your actual API keys:" "$YELLOW"
    print_message "   nano ~/SmartAgricultureNutrition/.env" "$CYAN"
    print_message "2. Restart the application after updating .env:" "$YELLOW"
    print_message "   cd ~/SmartAgricultureNutrition" "$CYAN"
    print_message "   sudo docker-compose -f docker-compose.azure.yml restart" "$CYAN"
    echo
    print_message "Useful commands:" "$BLUE"
    print_message "  View logs: sudo docker-compose -f docker-compose.azure.yml logs -f" "$CYAN"
    print_message "  Stop app: sudo docker-compose -f docker-compose.azure.yml down" "$CYAN"
    print_message "  Start app: sudo docker-compose -f docker-compose.azure.yml up -d" "$CYAN"
    print_message "  Check status: sudo docker ps" "$CYAN"
    echo
    print_message "To save costs, remember to:" "$RED"
    print_message "  - Stop the VM when not in use (Azure Portal > VM > Stop)" "$YELLOW"
    print_message "  - Set up auto-shutdown in Azure Portal" "$YELLOW"
    print_message "  - Monitor your credit usage regularly" "$YELLOW"
}

# Main execution
main() {
    print_message "Azure VM Setup Script for Smart Agriculture Nutrition API" "$GREEN"
    print_message "This script will install and configure everything needed" "$GREEN"
    echo
    
    # Check if running as root
    check_sudo
    
    # Confirm before proceeding
    read -p "Do you want to continue with the setup? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "Setup cancelled" "$YELLOW"
        exit 0
    fi
    
    # Run setup steps
    update_system
    install_docker
    install_docker_compose
    install_tools
    clone_repository
    setup_env_file
    start_application
    configure_nginx
    setup_firewall
    create_systemd_service
    test_application
    display_summary
    
    print_message "\nSetup completed successfully! 🎉" "$GREEN"
}

# Run main function
main
