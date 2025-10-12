#!/bin/bash

# Quick Redeployment Script - No prompts, just redeploy!

set -e

# Configuration
PROJECT_DIR="$HOME/Smart-Agriculture-Nutrition"
COMPOSE_FILE="docker-compose.prod.yml"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Quick Redeploy - Smart Agriculture Nutrition${NC}"
echo "================================================"

# Navigate to project
cd "$PROJECT_DIR"

# Pull latest code
echo -e "${YELLOW}📥 Pulling latest code...${NC}"
git pull origin main

# Rebuild and restart
echo -e "${YELLOW}🔄 Rebuilding and restarting...${NC}"
docker-compose -f "$COMPOSE_FILE" down
docker-compose -f "$COMPOSE_FILE" up -d --build

# Wait for services
echo -e "${YELLOW}⏳ Waiting for services...${NC}"
sleep 20

# Update DuckDNS if available
if [ -f "$HOME/update-duckdns.sh" ]; then
    $HOME/update-duckdns.sh
fi

# Show status
echo ""
docker-compose -f "$COMPOSE_FILE" ps
echo ""
echo -e "${GREEN}✅ Redeployment complete!${NC}"
echo -e "${GREEN}🌐 Access at: http://smart-agriculture-nutrition.duckdns.org${NC}"
