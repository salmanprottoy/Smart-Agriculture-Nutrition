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

# Setup environment file
setup_env_file() {
    print_header "Setting Up Environment Configuration"
    
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
    
    print_message ".env file created" "$GREEN"
    print_message "IMPORTANT: Edit the .env file to add your actual API keys:" "$RED"
    print_message "  nano ~/SmartAgricultureNutrition/.env" "$YELLOW"
}

# Build and start application
start_application() {
    print_header "Starting Application with Docker Compose"
    
    print_message "Building Docker images..." "$BLUE"
    sudo docker-compose -f docker-compose.prod.yml build
    
    print_message "Starting containers..." "$BLUE"
    sudo docker-compose -f docker-compose.prod.yml up -d
    
    print_message "Waiting for services to start..." "$YELLOW"
    sleep 30
    
    # Check container status
    print_message "Container status:" "$BLUE"
    sudo docker ps
    
    print_message "Application started successfully" "$GREEN"
}

# Configure Nginx
configure_nginx() {
    print_header "Configuring Nginx Reverse Proxy"
    
    print_message "Creating Nginx configuration..." "$BLUE"
    
    sudo tee /etc/nginx/sites-available/smart-agriculture > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;
    
    client_max_body_size 10M;
    
    location / {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/;
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
}
EOF
    
    # Enable the site
    sudo ln -sf /etc/nginx/sites-available/smart-agriculture /etc/nginx/sites-enabled/
    
    # Remove default site if it exists
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test Nginx configuration
    print_message "Testing Nginx configuration..." "$BLUE"
    sudo nginx -t
    
    # Restart Nginx
    print_message "Restarting Nginx..." "$BLUE"
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    
    print_message "Nginx configured successfully" "$GREEN"
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
ExecStart=/usr/bin/docker-compose -f docker-compose.prod.yml up
ExecStop=/usr/bin/docker-compose -f docker-compose.prod.yml down
User=$USER

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable smart-agriculture.service
    
    print_message "Auto-start service created" "$GREEN"
}

# Test application
test_application() {
    print_header "Testing Application"
    
    print_message "Testing application endpoints..." "$BLUE"
    
    # Get VM IP
    VM_IP=$(curl -s https://api.ipify.org)
    
    # Test main endpoint
    if curl -f http://localhost:8080/SmartAgricultureNutrition/ &> /dev/null; then
        print_message "✓ Application is responding on port 8080" "$GREEN"
    else
        print_message "✗ Application is not responding on port 8080" "$RED"
    fi
    
    # Test Nginx proxy
    if curl -f http://localhost/ &> /dev/null; then
        print_message "✓ Nginx proxy is working on port 80" "$GREEN"
    else
        print_message "✗ Nginx proxy is not working on port 80" "$RED"
    fi
    
    print_message "\nApplication should be accessible at:" "$BLUE"
    print_message "  http://$VM_IP/" "$GREEN"
    print_message "  http://$VM_IP/api/v1/" "$GREEN"
    print_message "  http://$VM_IP/api/v1/swagger" "$GREEN"
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
    print_message "   sudo docker-compose -f docker-compose.prod.yml restart" "$CYAN"
    echo
    print_message "Useful commands:" "$BLUE"
    print_message "  View logs: sudo docker-compose -f docker-compose.prod.yml logs -f" "$CYAN"
    print_message "  Stop app: sudo docker-compose -f docker-compose.prod.yml down" "$CYAN"
    print_message "  Start app: sudo docker-compose -f docker-compose.prod.yml up -d" "$CYAN"
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
