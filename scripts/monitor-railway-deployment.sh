#!/bin/bash

# Railway Deployment Monitoring Script
# Continuously checks the deployment status until it's ready

echo "🚂 Railway Deployment Monitor"
echo "============================="
echo ""

BASE_URL="https://smart-agriculture-nutrition-production.up.railway.app"
API_PATH="/SmartAgricultureNutrition/api/v1"
CHECK_INTERVAL=30  # Check every 30 seconds

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check deployment status
check_deployment() {
    local endpoint="${BASE_URL}${API_PATH}/crop-nutrition-profiles"
    
    # Try to get response code
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$endpoint" 2>/dev/null)
    
    return_code=$?
    
    if [ $return_code -eq 0 ]; then
        if [ "$response" = "200" ]; then
            return 0  # Success
        elif [ "$response" = "502" ] || [ "$response" = "503" ]; then
            return 1  # Still deploying
        else
            return 2  # Other error
        fi
    else
        return 3  # Connection failed
    fi
}

# Function to display status
display_status() {
    local status=$1
    local timestamp=$(date '+%H:%M:%S')
    
    case $status in
        0)
            echo -e "${GREEN}✅ [$timestamp] Deployment is LIVE!${NC}"
            echo -e "${GREEN}Your API is ready at: ${BASE_URL}${API_PATH}/${NC}"
            ;;
        1)
            echo -e "${YELLOW}⏳ [$timestamp] Still deploying... (502/503 response)${NC}"
            ;;
        2)
            echo -e "${RED}⚠️  [$timestamp] Unexpected response code${NC}"
            ;;
        3)
            echo -e "${BLUE}🔄 [$timestamp] Building/Starting up...${NC}"
            ;;
    esac
}

# Main monitoring loop
echo -e "${BLUE}Starting deployment monitoring...${NC}"
echo -e "${BLUE}Checking: ${BASE_URL}${NC}"
echo ""
echo "Press Ctrl+C to stop monitoring"
echo "--------------------------------"

attempt=1
max_attempts=20  # Maximum 10 minutes (20 * 30 seconds)

while [ $attempt -le $max_attempts ]; do
    echo -e "\n${BLUE}Check #$attempt of $max_attempts${NC}"
    
    check_deployment
    status=$?
    display_status $status
    
    if [ $status -eq 0 ]; then
        echo ""
        echo -e "${GREEN}🎉 Deployment Successful!${NC}"
        echo ""
        echo "📋 Quick Links:"
        echo "  • API Base: ${BASE_URL}${API_PATH}/"
        echo "  • Swagger UI: ${BASE_URL}${API_PATH}/swagger-ui"
        echo "  • Health Check: ${BASE_URL}${API_PATH}/crop-nutrition-profiles"
        echo ""
        echo -e "${YELLOW}💡 Next Steps:${NC}"
        echo "  1. Set environment variables in Railway (if not done)"
        echo "  2. Initialize database: railway run ./scripts/railway-init.sh"
        echo "  3. Test all endpoints: ./scripts/test-railway-deployment.sh"
        exit 0
    fi
    
    if [ $attempt -lt $max_attempts ]; then
        echo -e "${BLUE}Waiting $CHECK_INTERVAL seconds before next check...${NC}"
        sleep $CHECK_INTERVAL
    fi
    
    attempt=$((attempt + 1))
done

echo ""
echo -e "${RED}❌ Deployment monitoring timed out after 10 minutes${NC}"
echo "Please check Railway dashboard for deployment logs"
echo "URL: https://railway.app"
exit 1
