#!/bin/bash

# EC2 Security Group and Connectivity Fix Script

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 EC2 Connectivity Troubleshooting Guide${NC}"
echo "========================================================="

echo -e "\n${YELLOW}This script will help diagnose and fix connectivity issues${NC}"

# Function to check if running on EC2
check_ec2() {
    if [ -f /sys/hypervisor/uuid ] && [ `head -c 3 /sys/hypervisor/uuid` == ec2 ]; then
        echo -e "${GREEN}✓ Running on EC2 instance${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Not running on EC2${NC}"
        return 1
    fi
}

# Function to check services
check_services() {
    echo -e "\n${BLUE}1. Checking Docker Services Status...${NC}"
    
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✓ Docker is installed${NC}"
        
        # Check if containers are running
        if docker ps | grep -q agriculture-app; then
            echo -e "${GREEN}✓ Application container is running${NC}"
            
            # Get container details
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep agriculture
        else
            echo -e "${RED}✗ Application container is not running${NC}"
            echo "  Run: docker-compose -f docker-compose.prod.yml up -d"
        fi
    else
        echo -e "${RED}✗ Docker is not installed${NC}"
    fi
}

# Function to check ports
check_ports() {
    echo -e "\n${BLUE}2. Checking Port Availability...${NC}"
    
    # Check port 8080
    if sudo netstat -tlnp | grep -q :8080; then
        echo -e "${GREEN}✓ Port 8080 is listening${NC}"
        sudo netstat -tlnp | grep :8080
    else
        echo -e "${RED}✗ Port 8080 is not listening${NC}"
        echo "  The application may not be running"
    fi
    
    # Check port 80
    if sudo netstat -tlnp | grep -q :80; then
        echo -e "${YELLOW}⚠️  Port 80 is in use${NC}"
        sudo netstat -tlnp | grep :80
    fi
}

# Function to test local connectivity
test_local() {
    echo -e "\n${BLUE}3. Testing Local Connectivity...${NC}"
    
    # Test localhost
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/SmartAgricultureNutrition/ | grep -q "200\|302"; then
        echo -e "${GREEN}✓ Application responds on localhost:8080${NC}"
    else
        echo -e "${RED}✗ Application not responding on localhost:8080${NC}"
        echo "  Checking application logs..."
        docker logs agriculture-app --tail 10 2>/dev/null || echo "  Container not found"
    fi
}

# Function to check firewall
check_firewall() {
    echo -e "\n${BLUE}4. Checking System Firewall...${NC}"
    
    # Check iptables
    if sudo iptables -L -n | grep -q "ACCEPT.*8080"; then
        echo -e "${GREEN}✓ Port 8080 is allowed in iptables${NC}"
    else
        echo -e "${YELLOW}⚠️  Port 8080 might be blocked by iptables${NC}"
        echo "  Adding iptables rule..."
        sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
        echo -e "${GREEN}✓ Added iptables rule for port 8080${NC}"
    fi
    
    # Check ufw if installed
    if command -v ufw &> /dev/null; then
        if sudo ufw status | grep -q "8080"; then
            echo -e "${GREEN}✓ Port 8080 is allowed in UFW${NC}"
        else
            echo -e "${YELLOW}⚠️  Adding UFW rule for port 8080${NC}"
            sudo ufw allow 8080/tcp
            echo -e "${GREEN}✓ Added UFW rule${NC}"
        fi
    fi
}

# Function to display AWS Security Group instructions
aws_security_instructions() {
    echo -e "\n${BLUE}5. AWS Security Group Configuration${NC}"
    echo "========================================="
    echo -e "${YELLOW}IMPORTANT: You must configure your EC2 Security Group in AWS Console${NC}"
    echo ""
    echo "Steps to fix Security Group:"
    echo "1. Go to AWS Console → EC2 → Instances"
    echo "2. Select your instance"
    echo "3. Click on the 'Security' tab"
    echo "4. Click on the Security Group link"
    echo "5. Click 'Edit inbound rules'"
    echo "6. Add these rules:"
    echo ""
    echo "   Type              Port    Source"
    echo "   ─────────────────────────────────"
    echo "   Custom TCP Rule   8080    0.0.0.0/0"
    echo "   HTTP              80      0.0.0.0/0"
    echo "   SSH               22      Your IP"
    echo ""
    echo "7. Click 'Save rules'"
    echo ""
    echo -e "${GREEN}After updating Security Group, your API will be accessible at:${NC}"
    
    # Get public IP
    PUBLIC_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || echo "your-ec2-ip")
    echo -e "  ${BLUE}http://${PUBLIC_IP}:8080/SmartAgricultureNutrition/api/v1/${NC}"
}

# Function to restart services
restart_services() {
    echo -e "\n${BLUE}6. Restarting Docker Services...${NC}"
    
    cd ~/Smart-Agriculture-Nutrition 2>/dev/null || {
        echo -e "${RED}✗ Project directory not found${NC}"
        return 1
    }
    
    if [ -f docker-compose.prod.yml ]; then
        echo "Restarting containers..."
        docker-compose -f docker-compose.prod.yml restart
        echo -e "${GREEN}✓ Services restarted${NC}"
    else
        echo -e "${RED}✗ docker-compose.prod.yml not found${NC}"
    fi
}

# Main diagnostic flow
main() {
    echo -e "${YELLOW}Running connectivity diagnostics...${NC}\n"
    
    # Run checks
    check_ec2
    check_services
    check_ports
    test_local
    check_firewall
    aws_security_instructions
    
    echo -e "\n${BLUE}Quick Fix Commands:${NC}"
    echo "────────────────────────────────"
    echo "# If app is not running:"
    echo "cd ~/Smart-Agriculture-Nutrition"
    echo "docker-compose -f docker-compose.prod.yml up -d"
    echo ""
    echo "# View logs:"
    echo "docker-compose -f docker-compose.prod.yml logs -f"
    echo ""
    echo "# Restart services:"
    echo "docker-compose -f docker-compose.prod.yml restart"
    echo ""
    echo "# Check container status:"
    echo "docker ps"
    echo ""
    echo -e "${YELLOW}⚠️  Most likely issue: AWS Security Group needs port 8080 opened${NC}"
}

# Run main function
main
