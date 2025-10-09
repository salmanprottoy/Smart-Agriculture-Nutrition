#!/bin/bash

# AWS EC2 Deployment Script for Smart Agriculture Nutrition API
# This script automates the deployment process on EC2

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Smart Agriculture Nutrition API - EC2 Deployment Script${NC}"
echo "========================================================="

# Check if running on EC2 or local
if [ -f /sys/hypervisor/uuid ] && [ `head -c 3 /sys/hypervisor/uuid` == ec2 ]; then
    echo -e "${GREEN}✅ Running on EC2 instance${NC}"
    ON_EC2=true
else
    echo -e "${YELLOW}⚠️  Not running on EC2. This script is meant to be run on your EC2 instance.${NC}"
    ON_EC2=false
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install prerequisites
install_prerequisites() {
    echo -e "\n${BLUE}📦 Installing prerequisites...${NC}"
    
    # Update system
    echo "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    
    # Install Java 17
    if ! command_exists java; then
        echo "Installing Java 17..."
        sudo apt install openjdk-17-jdk -y
    else
        echo -e "${GREEN}✓ Java already installed${NC}"
    fi
    
    # Install Docker
    if ! command_exists docker; then
        echo "Installing Docker..."
        sudo apt install docker.io -y
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        echo -e "${YELLOW}Note: You may need to log out and back in for Docker permissions${NC}"
    else
        echo -e "${GREEN}✓ Docker already installed${NC}"
    fi
    
    # Install Docker Compose
    if ! command_exists docker-compose; then
        echo "Installing Docker Compose..."
        sudo apt install docker-compose -y
    else
        echo -e "${GREEN}✓ Docker Compose already installed${NC}"
    fi
    
    # Install Git
    if ! command_exists git; then
        echo "Installing Git..."
        sudo apt install git -y
    else
        echo -e "${GREEN}✓ Git already installed${NC}"
    fi
    
    # Install PostgreSQL client
    if ! command_exists psql; then
        echo "Installing PostgreSQL client..."
        sudo apt install postgresql-client -y
    else
        echo -e "${GREEN}✓ PostgreSQL client already installed${NC}"
    fi
    
    # Install Nginx
    if ! command_exists nginx; then
        echo "Installing Nginx..."
        sudo apt install nginx -y
    else
        echo -e "${GREEN}✓ Nginx already installed${NC}"
    fi
}

# Function to clone or update repository
setup_repository() {
    echo -e "\n${BLUE}📂 Setting up repository...${NC}"
    
    cd ~
    if [ -d "Smart-Agriculture-Nutrition" ]; then
        echo "Repository exists. Pulling latest changes..."
        cd Smart-Agriculture-Nutrition
        git pull origin main
    else
        echo "Cloning repository..."
        git clone https://github.com/salmanprottoy/Smart-Agriculture-Nutrition.git
        cd Smart-Agriculture-Nutrition
    fi
}

# Function to setup environment variables
setup_environment() {
    echo -e "\n${BLUE}🔐 Setting up environment variables...${NC}"
    
    if [ -f .env ]; then
        echo -e "${YELLOW}⚠️  .env file already exists. Backing up to .env.backup${NC}"
        cp .env .env.backup
    fi
    
    # Create .env file
    cat > .env << 'EOF'
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=smart_agriculture_nutrition
DB_USERNAME=agriculture_user
DB_PASSWORD=AgriNutri2024SecurePass!

# API Keys
WEATHER_API_KEY=635fd9df515c45a087053736252609
USDA_API_KEY=hEeis1khcuBekJ1ZDYFhNbXDUP69BFH9OrBcHRYW

# JWT Secret
JWT_SECRET=your-super-secure-jwt-secret-key-2024-change-this

# Application
PORT=8080
APP_ENVIRONMENT=production

# PostgreSQL Docker
POSTGRES_DB=smart_agriculture_nutrition
POSTGRES_USER=agriculture_user
POSTGRES_PASSWORD=AgriNutri2024SecurePass!
EOF
    
    echo -e "${GREEN}✓ Environment variables configured${NC}"
    echo -e "${YELLOW}⚠️  Remember to update API keys and passwords in .env file!${NC}"
}

# Function to setup PostgreSQL database
setup_database() {
    echo -e "\n${BLUE}🗄️  Setting up PostgreSQL database...${NC}"
    
    # Check if PostgreSQL container already exists
    if docker ps -a | grep -q postgres-agriculture; then
        echo "PostgreSQL container exists. Restarting..."
        docker start postgres-agriculture
    else
        echo "Creating PostgreSQL container..."
        docker run -d \
            --name postgres-agriculture \
            -e POSTGRES_DB=smart_agriculture_nutrition \
            -e POSTGRES_USER=agriculture_user \
            -e POSTGRES_PASSWORD=AgriNutri2024SecurePass! \
            -p 5432:5432 \
            -v postgres_data:/var/lib/postgresql/data \
            --restart unless-stopped \
            postgres:15
    fi
    
    # Wait for PostgreSQL to be ready
    echo "Waiting for PostgreSQL to be ready..."
    sleep 10
    
    # Initialize database schema
    echo "Initializing database schema..."
    docker exec -i postgres-agriculture psql -U agriculture_user -d smart_agriculture_nutrition < database/init.sql || {
        echo -e "${YELLOW}Database might already be initialized${NC}"
    }
    
    echo -e "${GREEN}✓ Database setup complete${NC}"
}

# Function to build and run application
deploy_application() {
    echo -e "\n${BLUE}🚀 Deploying application...${NC}"
    
    # Stop existing container if running
    if docker ps | grep -q smart-agriculture; then
        echo "Stopping existing container..."
        docker stop smart-agriculture
        docker rm smart-agriculture
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    docker build -t smart-agriculture-api .
    
    # Run application container
    echo "Starting application container..."
    docker run -d \
        --name smart-agriculture \
        --env-file .env \
        -p 8080:8080 \
        --link postgres-agriculture:postgres \
        --restart unless-stopped \
        smart-agriculture-api
    
    echo -e "${GREEN}✓ Application deployed${NC}"
}

# Function to setup Nginx
setup_nginx() {
    echo -e "\n${BLUE}🌐 Setting up Nginx reverse proxy...${NC}"
    
    # Get public IP
    PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)
    
    # Create Nginx configuration
    sudo tee /etc/nginx/sites-available/smart-agriculture > /dev/null << EOF
server {
    listen 80;
    server_name $PUBLIC_IP;

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
    }
}
EOF
    
    # Enable site
    sudo ln -sf /etc/nginx/sites-available/smart-agriculture /etc/nginx/sites-enabled/
    
    # Remove default site if exists
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test and reload Nginx
    sudo nginx -t && sudo systemctl reload nginx
    
    echo -e "${GREEN}✓ Nginx configured${NC}"
}

# Function to create systemd service
create_systemd_service() {
    echo -e "\n${BLUE}⚙️  Creating systemd service...${NC}"
    
    sudo tee /etc/systemd/system/smart-agriculture.service > /dev/null << 'EOF'
[Unit]
Description=Smart Agriculture Nutrition API
After=docker.service
Requires=docker.service

[Service]
Type=simple
Restart=always
RestartSec=10
WorkingDirectory=/home/ubuntu/Smart-Agriculture-Nutrition
ExecStart=/usr/bin/docker start -a smart-agriculture
ExecStop=/usr/bin/docker stop smart-agriculture
User=ubuntu

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable and start service
    sudo systemctl daemon-reload
    sudo systemctl enable smart-agriculture.service
    
    echo -e "${GREEN}✓ Systemd service created${NC}"
}

# Function to check deployment status
check_status() {
    echo -e "\n${BLUE}🔍 Checking deployment status...${NC}"
    
    # Check Docker containers
    echo -e "\n${YELLOW}Docker Containers:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # Check if application is responding
    echo -e "\n${YELLOW}Testing API endpoint:${NC}"
    sleep 5
    
    PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)
    
    # Test direct access
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/SmartAgricultureNutrition/api/v1/crop-nutrition-profiles | grep -q "200"; then
        echo -e "${GREEN}✓ API is responding on port 8080${NC}"
    else
        echo -e "${RED}✗ API is not responding on port 8080${NC}"
    fi
    
    # Test Nginx proxy
    if curl -s -o /dev/null -w "%{http_code}" http://$PUBLIC_IP/api/v1/crop-nutrition-profiles | grep -q "200"; then
        echo -e "${GREEN}✓ API is accessible via Nginx${NC}"
    else
        echo -e "${YELLOW}⚠️  API might not be accessible via Nginx yet${NC}"
    fi
    
    echo -e "\n${GREEN}🎉 Deployment Complete!${NC}"
    echo "========================================="
    echo -e "${BLUE}Your API is available at:${NC}"
    echo -e "  Direct: ${GREEN}http://$PUBLIC_IP:8080/SmartAgricultureNutrition/api/v1/${NC}"
    echo -e "  Via Nginx: ${GREEN}http://$PUBLIC_IP/api/v1/${NC}"
    echo -e "  Swagger UI: ${GREEN}http://$PUBLIC_IP/api/v1/swagger-ui${NC}"
    echo "========================================="
}

# Main deployment flow
main() {
    echo -e "${YELLOW}This script will deploy the Smart Agriculture Nutrition API on your EC2 instance.${NC}"
    echo -e "${YELLOW}Make sure you're running this on your EC2 instance, not locally.${NC}"
    echo ""
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 1
    fi
    
    install_prerequisites
    setup_repository
    setup_environment
    setup_database
    deploy_application
    setup_nginx
    create_systemd_service
    check_status
    
    echo -e "\n${YELLOW}📝 Next Steps:${NC}"
    echo "1. Update the .env file with your actual API keys and passwords"
    echo "2. Configure your EC2 Security Group to allow traffic on ports 80, 443, and 8080"
    echo "3. Consider setting up a domain name and SSL certificate"
    echo "4. Monitor logs with: docker logs -f smart-agriculture"
}

# Run main function
main
