#!/bin/bash

# Script to fix port conflicts and complete deployment

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Fixing Port Conflicts and Completing Deployment${NC}"
echo "========================================================="

# Check what's using port 80
echo -e "\n${YELLOW}Checking what's using port 80...${NC}"
sudo lsof -i :80 || sudo netstat -tlnp | grep :80

# Stop system nginx if running
echo -e "\n${YELLOW}Stopping system nginx if running...${NC}"
sudo systemctl stop nginx 2>/dev/null || true
sudo systemctl disable nginx 2>/dev/null || true

# Check if Apache is running and stop it
echo -e "\n${YELLOW}Checking for Apache...${NC}"
sudo systemctl stop apache2 2>/dev/null || true
sudo systemctl disable apache2 2>/dev/null || true

# Remove the failed nginx container
echo -e "\n${YELLOW}Cleaning up failed containers...${NC}"
docker rm -f agriculture-nginx 2>/dev/null || true

# Option 1: Use different port for Nginx
echo -e "\n${BLUE}Updating docker-compose to use port 8081 for Nginx...${NC}"

# Update docker-compose.prod.yml to use port 8081
cat > ~/Smart-Agriculture-Nutrition/docker-compose.prod.yml << 'EOF'
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

networks:
  agriculture-network:
    driver: bridge

volumes:
  postgres_data:
    driver: local
EOF

echo -e "${GREEN}✓ Updated docker-compose.prod.yml to run without Nginx${NC}"

# Restart the deployment without Nginx
echo -e "\n${BLUE}Starting services without Nginx...${NC}"
cd ~/Smart-Agriculture-Nutrition
docker-compose -f docker-compose.prod.yml up -d

# Wait for services to start
echo -e "\n${YELLOW}Waiting for services to start...${NC}"
sleep 15

# Check status
echo -e "\n${BLUE}Checking deployment status...${NC}"
docker-compose -f docker-compose.prod.yml ps

# Test the application
echo -e "\n${YELLOW}Testing application endpoints...${NC}"

# Get server IP
SERVER_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || echo "localhost")

# Test direct app access
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/SmartAgricultureNutrition/ | grep -q "200\|302"; then
    echo -e "${GREEN}✓ Application is running successfully on port 8080${NC}"
else
    echo -e "${RED}✗ Application is not responding on port 8080${NC}"
    echo "Checking logs..."
    docker-compose -f docker-compose.prod.yml logs --tail=20 app
fi

echo -e "\n${GREEN}🎉 Deployment Fixed!${NC}"
echo "========================================="
echo -e "${BLUE}Your API is now available at:${NC}"
echo -e "  API Endpoint: ${GREEN}http://${SERVER_IP}:8080/SmartAgricultureNutrition/api/v1/${NC}"
echo -e "  Swagger UI: ${GREEN}http://${SERVER_IP}:8080/SmartAgricultureNutrition/api/v1/swagger-ui${NC}"
echo "========================================="
echo ""
echo -e "${YELLOW}Note: Since port 80 was in use, we're running the app directly on port 8080${NC}"
echo -e "${YELLOW}Make sure your EC2 Security Group allows traffic on port 8080${NC}"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "  View logs:     docker-compose -f docker-compose.prod.yml logs -f"
echo "  View app logs: docker-compose -f docker-compose.prod.yml logs app"
echo "  View DB logs:  docker-compose -f docker-compose.prod.yml logs postgres"
echo "  Stop services: docker-compose -f docker-compose.prod.yml down"
echo "  Restart:       docker-compose -f docker-compose.prod.yml restart"
