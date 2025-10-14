#!/bin/bash

# Smart Agriculture Nutrition - EC2 Redeployment Script
# Use this script to redeploy after code updates

set -e  # Exit on error

# Configuration
PROJECT_DIR="$HOME/Smart-Agriculture-Nutrition"
COMPOSE_FILE="docker-compose.prod.yml"
DUCKDNS_DOMAIN="smart-agriculture-nutrition.duckdns.org"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${2}${1}${NC}"
}

# Header
clear
print_message "========================================" "$BLUE"
print_message "   Smart Agriculture Nutrition" "$GREEN"
print_message "   Redeployment Script" "$GREEN"
print_message "========================================" "$BLUE"
echo ""

# Check if running on EC2
if [ ! -d "$PROJECT_DIR" ]; then
    print_message "Error: Project directory not found at $PROJECT_DIR" "$RED"
    print_message "Please run this script on your EC2 instance" "$RED"
    exit 1
fi

# Navigate to project directory
cd "$PROJECT_DIR"
print_message "📂 Working in: $(pwd)" "$BLUE"
echo ""

# Step 1: Show current status
print_message "📊 Current Status:" "$YELLOW"
docker-compose -f "$COMPOSE_FILE" ps --format "table {{.Name}}\t{{.Status}}"
echo ""

# Step 2: Pull latest code from GitHub
print_message "📥 Pulling latest code from GitHub..." "$YELLOW"
git fetch origin
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    print_message "ℹ️  Already up to date" "$BLUE"
    read -p "Do you want to continue with redeployment anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "Deployment cancelled" "$YELLOW"
        exit 0
    fi
else
    git pull origin main
    print_message "✅ Code updated" "$GREEN"
    echo "Recent commits:"
    git log --oneline -3
fi
echo ""

# Step 3: Stop current containers
print_message "🛑 Stopping current containers..." "$YELLOW"
docker-compose -f "$COMPOSE_FILE" down
print_message "✅ Containers stopped" "$GREEN"
echo ""

# Step 4: Clean up old images (optional)
read -p "Clean up old Docker images to save space? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_message "🧹 Cleaning Docker images..." "$YELLOW"
    docker image prune -f
    print_message "✅ Cleanup complete" "$GREEN"
    echo ""
fi

# Step 5: Build new images
print_message "🔨 Building new Docker images..." "$YELLOW"
print_message "This may take 2-3 minutes..." "$BLUE"
docker-compose -f "$COMPOSE_FILE" build --no-cache

if [ $? -eq 0 ]; then
    print_message "✅ Build successful" "$GREEN"
else
    print_message "❌ Build failed" "$RED"
    exit 1
fi
echo ""

# Step 6: Start new containers
print_message "🚀 Starting new containers..." "$YELLOW"
docker-compose -f "$COMPOSE_FILE" up -d

if [ $? -eq 0 ]; then
    print_message "✅ Containers started" "$GREEN"
else
    print_message "❌ Failed to start containers" "$RED"
    exit 1
fi
echo ""

# Step 7: Wait for services to be healthy
print_message "⏳ Waiting for services to be healthy..." "$YELLOW"
RETRIES=30
while [ $RETRIES -gt 0 ]; do
    if docker-compose -f "$COMPOSE_FILE" ps | grep -q "healthy"; then
        print_message "✅ Services are healthy!" "$GREEN"
        break
    fi
    printf "."
    sleep 2
    RETRIES=$((RETRIES-1))
done
echo ""

# Step 8: Show final status
print_message "📊 Final Status:" "$GREEN"
docker-compose -f "$COMPOSE_FILE" ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Step 9: Test the API
print_message "🧪 Testing API endpoint..." "$YELLOW"
sleep 3

if curl -f -s http://localhost/SmartAgricultureNutrition/ > /dev/null; then
    print_message "✅ API is responding!" "$GREEN"
else
    print_message "⚠️  API not responding yet. Check logs with:" "$YELLOW"
    print_message "docker-compose -f $COMPOSE_FILE logs app" "$NC"
fi
echo ""

# Step 10: Update DuckDNS (if configured)
if [ -f "$HOME/update-duckdns.sh" ]; then
    print_message "🦆 Updating DuckDNS..." "$YELLOW"
    $HOME/update-duckdns.sh
    print_message "✅ DuckDNS updated" "$GREEN"
    echo ""
fi

# Step 11: Show access information
print_message "========================================" "$BLUE"
print_message "   ✅ Redeployment Complete!" "$GREEN"
print_message "========================================" "$BLUE"
echo ""
print_message "🌐 Access your application at:" "$GREEN"
echo ""

# Show DuckDNS URL if available
if [ -n "$DUCKDNS_DOMAIN" ]; then
    print_message "   DuckDNS URL:" "$BLUE"
    print_message "   http://$DUCKDNS_DOMAIN/SmartAgricultureNutrition/" "$GREEN"
    print_message "   http://$DUCKDNS_DOMAIN/SmartAgricultureNutrition/api/v1/swagger" "$GREEN"
    echo ""
fi

# Show IP-based URLs
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "your-ec2-ip")
print_message "   Direct IP Access:" "$BLUE"
print_message "   http://$PUBLIC_IP/SmartAgricultureNutrition/" "$NC"
print_message "   http://$PUBLIC_IP/SmartAgricultureNutrition/api/v1/swagger" "$NC"
echo ""

# Show useful commands
print_message "📝 Useful commands:" "$YELLOW"
print_message "   View logs:     docker-compose -f $COMPOSE_FILE logs -f app" "$NC"
print_message "   Check status:  docker-compose -f $COMPOSE_FILE ps" "$NC"
print_message "   Stop all:      docker-compose -f $COMPOSE_FILE down" "$NC"
print_message "   Restart app:   docker-compose -f $COMPOSE_FILE restart app" "$NC"
echo ""

# Show recent logs
read -p "View recent application logs? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_message "📜 Recent logs:" "$YELLOW"
    docker-compose -f "$COMPOSE_FILE" logs --tail 20 app
fi

print_message "✨ Redeployment completed successfully!" "$GREEN"
print_message "Time: $(date)" "$BLUE"
