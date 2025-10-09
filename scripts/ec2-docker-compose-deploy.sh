#!/bin/bash

# EC2 Docker Compose Deployment Script
# Generic script for any EC2 instance

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get EC2 public IP dynamically
get_ec2_ip() {
    # Try to get EC2 public IP
    EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
    
    # If not on EC2, try alternative method
    if [ -z "$EC2_IP" ]; then
        EC2_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null)
    fi
    
    # If still no IP, ask user
    if [ -z "$EC2_IP" ]; then
        read -p "Enter your server's public IP address: " EC2_IP
    fi
    
    echo "$EC2_IP"
}

echo -e "${BLUE}🚀 Smart Agriculture Nutrition - Docker Compose Deployment${NC}"
echo "========================================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install prerequisites
install_prerequisites() {
    echo -e "\n${BLUE}📦 Installing prerequisites...${NC}"
    
    # Update system
    sudo apt update
    
    # Install Docker if not present
    if ! command_exists docker; then
        echo "Installing Docker..."
        sudo apt install -y docker.io
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        echo -e "${YELLOW}Note: You may need to log out and back in for Docker permissions${NC}"
    else
        echo -e "${GREEN}✓ Docker already installed${NC}"
    fi
    
    # Install Docker Compose if not present
    if ! command_exists docker-compose; then
        echo "Installing Docker Compose..."
        sudo apt install -y docker-compose
    else
        echo -e "${GREEN}✓ Docker Compose already installed${NC}"
    fi
    
    # Install Git if not present
    if ! command_exists git; then
        echo "Installing Git..."
        sudo apt install -y git
    else
        echo -e "${GREEN}✓ Git already installed${NC}"
    fi
}

# Clone or update repository
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

# Create production environment file
create_env_file() {
    echo -e "\n${BLUE}🔐 Creating production .env file...${NC}"
    
    if [ -f .env ]; then
        echo -e "${YELLOW}Backing up existing .env to .env.backup${NC}"
        cp .env .env.backup
    fi
    
    # Get server IP
    SERVER_IP=$(get_ec2_ip)
    
    cat > .env << EOF
# Production Environment Configuration

# Server Configuration
SERVER_IP=${SERVER_IP}
SERVER_PORT=80

# Database Configuration
POSTGRES_DB=smart_agriculture_nutrition
POSTGRES_USER=agriculture_user
POSTGRES_PASSWORD=AgriNutri2024SecurePass!
DB_HOST=postgres
DB_PORT=5432
DB_NAME=smart_agriculture_nutrition
DB_USERNAME=agriculture_user
DB_PASSWORD=AgriNutri2024SecurePass!

# API Keys - REPLACE WITH YOUR ACTUAL KEYS
WEATHER_API_KEY=your_weather_api_key_here
USDA_API_KEY=your_usda_api_key_here

# JWT Configuration
JWT_SECRET=your-super-secure-jwt-secret-key-2024-change-this

# Application Settings
PORT=8080
APP_ENVIRONMENT=production

# Docker Network
DOCKER_NETWORK=agriculture-network
EOF
    
    echo -e "${GREEN}✓ Environment file created${NC}"
    echo -e "${YELLOW}⚠️  IMPORTANT: Edit .env file to add your actual API keys!${NC}"
}

# Update docker-compose for production
update_docker_compose() {
    echo -e "\n${BLUE}📝 Creating production docker-compose.yml...${NC}"
    
    # Backup original docker-compose.yml if exists
    if [ -f docker-compose.yml ]; then
        cp docker-compose.yml docker-compose.yml.backup
    fi
    
    # Create production docker-compose
    cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: agriculture-postgres
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    networks:
      - agriculture-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: agriculture-app
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      - DB_HOST=${DB_HOST}
      - DB_PORT=${DB_PORT}
      - DB_NAME=${DB_NAME}
      - DB_USERNAME=${DB_USERNAME}
      - DB_PASSWORD=${DB_PASSWORD}
      - WEATHER_API_KEY=${WEATHER_API_KEY}
      - USDA_API_KEY=${USDA_API_KEY}
      - JWT_SECRET=${JWT_SECRET}
      - PORT=${PORT}
      - APP_ENVIRONMENT=${APP_ENVIRONMENT}
    ports:
      - "8080:8080"
    networks:
      - agriculture-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/SmartAgricultureNutrition/"]
      interval: 30s
      timeout: 10s
      retries: 3

  nginx:
    image: nginx:alpine
    container_name: agriculture-nginx
    depends_on:
      - app
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    ports:
      - "80:80"
      - "443:443"
    networks:
      - agriculture-network
    restart: unless-stopped
    environment:
      - SERVER_IP=${SERVER_IP}

networks:
  agriculture-network:
    driver: bridge

volumes:
  postgres_data:
    driver: local
EOF
    
    echo -e "${GREEN}✓ docker-compose.prod.yml created${NC}"
}

# Create Nginx configuration
create_nginx_config() {
    echo -e "\n${BLUE}🌐 Creating Nginx configuration...${NC}"
    
    mkdir -p nginx
    
    # Get server IP from .env
    source .env
    
    cat > nginx/nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    upstream app {
        server app:8080;
    }

    server {
        listen 80;
        server_name ${SERVER_IP} localhost;

        location / {
            proxy_pass http://app/SmartAgricultureNutrition/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            proxy_cache_bypass \$http_upgrade;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        location /api/ {
            proxy_pass http://app/SmartAgricultureNutrition/api/;
            proxy_http_version 1.1;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF
    
    echo -e "${GREEN}✓ Nginx configuration created${NC}"
}

# Deploy with Docker Compose
deploy_application() {
    echo -e "\n${BLUE}🚀 Deploying with Docker Compose...${NC}"
    
    # Stop any existing containers
    echo "Stopping existing containers (if any)..."
    docker-compose -f docker-compose.prod.yml down 2>/dev/null || true
    
    # Build and start containers
    echo "Building and starting containers..."
    docker-compose -f docker-compose.prod.yml up -d --build
    
    echo -e "${GREEN}✓ Application deployed with Docker Compose${NC}"
}

# Check deployment status
check_status() {
    echo -e "\n${BLUE}🔍 Checking deployment status...${NC}"
    
    # Wait for services to start
    echo "Waiting for services to start..."
    sleep 15
    
    # Show running containers
    echo -e "\n${YELLOW}Running Containers:${NC}"
    docker-compose -f docker-compose.prod.yml ps
    
    # Test endpoints
    echo -e "\n${YELLOW}Testing endpoints:${NC}"
    
    # Test direct app access
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/SmartAgricultureNutrition/ | grep -q "200\|302"; then
        echo -e "${GREEN}✓ App is running on port 8080${NC}"
    else
        echo -e "${RED}✗ App is not responding on port 8080${NC}"
    fi
    
    # Test Nginx proxy
    if curl -s -o /dev/null -w "%{http_code}" http://localhost/ | grep -q "200\|302"; then
        echo -e "${GREEN}✓ Nginx proxy is working on port 80${NC}"
    else
        echo -e "${YELLOW}⚠️  Nginx might need more time to start${NC}"
    fi
    
    # Get server IP from .env
    source .env
    
    echo -e "\n${GREEN}🎉 Deployment Complete!${NC}"
    echo "========================================="
    echo -e "${BLUE}Your API is available at:${NC}"
    echo -e "  Direct App: ${GREEN}http://${SERVER_IP}:8080/SmartAgricultureNutrition/api/v1/${NC}"
    echo -e "  Via Nginx: ${GREEN}http://${SERVER_IP}/api/v1/${NC}"
    echo -e "  Swagger UI: ${GREEN}http://${SERVER_IP}/api/v1/swagger-ui${NC}"
    echo "========================================="
}

# View logs
show_logs_info() {
    echo -e "\n${YELLOW}📝 Useful Commands:${NC}"
    echo "  View all logs:        docker-compose -f docker-compose.prod.yml logs"
    echo "  View app logs:        docker-compose -f docker-compose.prod.yml logs app"
    echo "  View database logs:   docker-compose -f docker-compose.prod.yml logs postgres"
    echo "  Follow logs:          docker-compose -f docker-compose.prod.yml logs -f"
    echo "  Stop services:        docker-compose -f docker-compose.prod.yml down"
    echo "  Restart services:     docker-compose -f docker-compose.prod.yml restart"
    echo "  View container status: docker-compose -f docker-compose.prod.yml ps"
}

# Main deployment flow
main() {
    echo -e "${YELLOW}This script will deploy the application using Docker Compose${NC}"
    echo ""
    
    # Detect if running on EC2
    if [ -f /sys/hypervisor/uuid ] && [ `head -c 3 /sys/hypervisor/uuid` == ec2 ]; then
        echo -e "${GREEN}✓ Running on EC2 instance${NC}"
    else
        echo -e "${YELLOW}⚠️  Not running on EC2. Make sure you're on your server.${NC}"
    fi
    
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 1
    fi
    
    install_prerequisites
    setup_repository
    create_env_file
    update_docker_compose
    create_nginx_config
    
    echo -e "\n${YELLOW}⚠️  Before continuing:${NC}"
    echo "1. Edit the .env file to add your actual API keys"
    echo "   nano .env"
    echo "2. Make sure your EC2 Security Group allows:"
    echo "   - Port 80 (HTTP)"
    echo "   - Port 8080 (Direct App Access)"
    echo "   - Port 22 (SSH)"
    echo ""
    read -p "Have you updated the .env file with your API keys? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Please update .env file first, then run:${NC}"
        echo "  docker-compose -f docker-compose.prod.yml up -d"
        exit 0
    fi
    
    deploy_application
    check_status
    show_logs_info
}

# Run main function
main
