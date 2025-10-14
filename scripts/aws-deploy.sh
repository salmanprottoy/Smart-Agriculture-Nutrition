#!/bin/bash

# Simple Docker Compose Deployment Script for EC2/Server

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Smart Agriculture Nutrition - Docker Deployment${NC}"
echo "========================================================="

# Function to check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Installing Docker...${NC}"
        sudo apt update
        sudo apt install -y docker.io docker-compose
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        echo -e "${GREEN}✓ Docker installed${NC}"
        echo -e "${YELLOW}Note: You may need to log out and back in for Docker permissions${NC}"
    else
        echo -e "${GREEN}✓ Docker is installed${NC}"
    fi
}

# Function to setup project
setup_project() {
    # Clone or update repository
    if [ ! -d "Smart-Agriculture-Nutrition" ]; then
        echo -e "${BLUE}Cloning repository...${NC}"
        git clone https://github.com/salmanprottoy/Smart-Agriculture-Nutrition.git
    fi
    
    cd Smart-Agriculture-Nutrition
    
    # Pull latest changes
    echo -e "${BLUE}Pulling latest changes...${NC}"
    git pull origin main
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        echo -e "${BLUE}Creating .env file...${NC}"
        cat > .env << 'EOF'
# Database Configuration
POSTGRES_DB=smart_agriculture_nutrition
POSTGRES_USER=agriculture_user
POSTGRES_PASSWORD=ChangeThisSecurePassword2024!

# API Keys - REPLACE WITH YOUR ACTUAL KEYS
WEATHER_API_KEY=your_weather_api_key_here
USDA_API_KEY=your_usda_api_key_here

# JWT Secret
JWT_SECRET=change-this-to-a-secure-random-string

# Application
APP_ENVIRONMENT=production
EOF
        echo -e "${YELLOW}⚠️  Edit .env file to add your actual API keys and passwords!${NC}"
    fi
}

# Function to deploy with Docker Compose
deploy() {
    echo -e "${BLUE}Starting deployment...${NC}"
    
    # Stop any running containers
    docker-compose -f docker-compose.prod.yml down 2>/dev/null || true
    
    # Build and start services
    docker-compose -f docker-compose.prod.yml up -d --build
    
    # Wait for services to be ready
    echo -e "${YELLOW}Waiting for services to start...${NC}"
    sleep 15
    
    # Check status
    docker-compose -f docker-compose.prod.yml ps
}

# Function to show access URLs
show_urls() {
    # Get server IP
    SERVER_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || hostname -I | awk '{print $1}')
    
    echo -e "\n${GREEN}✅ Deployment Complete!${NC}"
    echo "========================================="
    echo -e "${BLUE}Your API is accessible at:${NC}"
    echo ""
    echo -e "  Port 80:   ${GREEN}http://${SERVER_IP}/SmartAgricultureNutrition/api/v1/${NC}"
    echo -e "  Port 8080: ${GREEN}http://${SERVER_IP}:8080/SmartAgricultureNutrition/api/v1/${NC}"
    echo ""
    echo -e "  Swagger UI: ${GREEN}http://${SERVER_IP}/SmartAgricultureNutrition/api/v1/swagger${NC}"
    echo "========================================="
    echo ""
    echo -e "${YELLOW}Note: Make sure your firewall/security group allows ports 80 and 8080${NC}"
    echo ""
    echo -e "${BLUE}Useful commands:${NC}"
    echo "  View logs:    docker-compose -f docker-compose.prod.yml logs -f"
    echo "  Stop:         docker-compose -f docker-compose.prod.yml down"
    echo "  Restart:      docker-compose -f docker-compose.prod.yml restart"
    echo "  Status:       docker-compose -f docker-compose.prod.yml ps"
}

# Main execution
main() {
    check_docker
    setup_project
    
    # Check if user wants to edit .env
    if [ ! -f .env.configured ]; then
        echo ""
        read -p "Do you want to edit .env file now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            nano .env
            touch .env.configured
        fi
    fi
    
    deploy
    show_urls
}

# Run main function
main
