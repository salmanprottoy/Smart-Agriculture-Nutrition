#!/bin/bash

# Railway Deployment Test Script
# Tests the deployed Smart Agriculture Nutrition API

echo "🧪 Testing Railway Deployment..."
echo "================================"

BASE_URL="https://smart-agriculture-nutrition-production.up.railway.app"
API_PATH="/SmartAgricultureNutrition/api/v1"

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to test endpoint
test_endpoint() {
    local endpoint=$1
    local description=$2
    local full_url="${BASE_URL}${API_PATH}${endpoint}"
    
    echo -e "\n${YELLOW}Testing:${NC} $description"
    echo "URL: $full_url"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$full_url")
    
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✅ Success${NC} - HTTP $response"
    else
        echo -e "${RED}❌ Failed${NC} - HTTP $response"
    fi
}

# Test main endpoints
echo -e "\n${YELLOW}🌐 Testing API Endpoints${NC}"
echo "------------------------"

test_endpoint "/crop-nutrition-profiles" "Crop Nutrition Profiles"
test_endpoint "/nutrition-trackers" "Personal Nutrition Trackers"
test_endpoint "/openapi.json" "OpenAPI Specification"

# Test Swagger UI
echo -e "\n${YELLOW}📖 Testing Documentation${NC}"
echo "------------------------"
echo "Swagger UI URL: ${BASE_URL}${API_PATH}/swagger-ui"
swagger_response=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}${API_PATH}/swagger-ui")
if [ "$swagger_response" = "200" ] || [ "$swagger_response" = "302" ]; then
    echo -e "${GREEN}✅ Swagger UI is accessible${NC}"
else
    echo -e "${RED}❌ Swagger UI not accessible${NC} - HTTP $swagger_response"
fi

# Test data retrieval
echo -e "\n${YELLOW}📊 Testing Data Retrieval${NC}"
echo "------------------------"
echo "Fetching crop profiles count..."
count=$(curl -s "${BASE_URL}${API_PATH}/crop-nutrition-profiles" | grep -o '"id"' | wc -l)
if [ "$count" -gt 0 ]; then
    echo -e "${GREEN}✅ Retrieved $count crop profiles${NC}"
else
    echo -e "${YELLOW}⚠️  No data retrieved (database may need initialization)${NC}"
fi

echo -e "\n================================"
echo -e "${GREEN}🎉 Deployment Test Complete!${NC}"
echo ""
echo "📝 Access your API at:"
echo "   ${BASE_URL}${API_PATH}/"
echo ""
echo "🔗 Quick Links:"
echo "   - Swagger UI: ${BASE_URL}${API_PATH}/swagger-ui"
echo "   - OpenAPI: ${BASE_URL}${API_PATH}/openapi.json"
echo "   - Crop Profiles: ${BASE_URL}${API_PATH}/crop-nutrition-profiles"
echo ""

# Check if database needs initialization
if [ "$count" -eq 0 ]; then
    echo -e "${YELLOW}💡 Tip:${NC} If no data is showing, initialize your database:"
    echo "   railway run ./scripts/railway-init.sh"
fi
