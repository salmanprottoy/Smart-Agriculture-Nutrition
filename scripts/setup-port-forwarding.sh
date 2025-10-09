#!/bin/bash

# Script to setup port forwarding from 80 to 8080 on EC2

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Setting up Port Forwarding (80 → 8080)${NC}"
echo "========================================================="

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}This script needs sudo privileges. Re-running with sudo...${NC}"
    sudo "$0" "$@"
    exit
fi

# Function to stop system services on port 80
stop_port_80_services() {
    echo -e "\n${BLUE}1. Stopping services on port 80...${NC}"
    
    # Stop nginx if running
    if systemctl is-active --quiet nginx; then
        echo "Stopping nginx..."
        systemctl stop nginx
        systemctl disable nginx
        echo -e "${GREEN}✓ Nginx stopped and disabled${NC}"
    fi
    
    # Stop apache if running
    if systemctl is-active --quiet apache2; then
        echo "Stopping apache2..."
        systemctl stop apache2
        systemctl disable apache2
        echo -e "${GREEN}✓ Apache stopped and disabled${NC}"
    fi
    
    # Check if port 80 is still in use
    if netstat -tlnp | grep -q :80; then
        echo -e "${YELLOW}⚠️  Port 80 is still in use:${NC}"
        netstat -tlnp | grep :80
        echo "Attempting to free port 80..."
        fuser -k 80/tcp 2>/dev/null || true
    else
        echo -e "${GREEN}✓ Port 80 is free${NC}"
    fi
}

# Function to setup iptables forwarding
setup_iptables_forwarding() {
    echo -e "\n${BLUE}2. Setting up iptables port forwarding...${NC}"
    
    # Enable IP forwarding
    echo "Enabling IP forwarding..."
    echo 1 > /proc/sys/net/ipv4/ip_forward
    
    # Make it permanent
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
        sysctl -p
    fi
    
    # Remove any existing NAT rules for port 80
    echo "Removing existing port 80 rules..."
    iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080 2>/dev/null || true
    iptables -D INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || true
    iptables -D INPUT -p tcp --dport 8080 -j ACCEPT 2>/dev/null || true
    
    # Add new forwarding rules
    echo "Adding port forwarding rules..."
    
    # Allow incoming traffic on port 80
    iptables -I INPUT -p tcp --dport 80 -j ACCEPT
    
    # Allow incoming traffic on port 8080
    iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
    
    # Forward port 80 to 8080
    iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
    
    # For local connections (optional)
    iptables -t nat -A OUTPUT -p tcp --dport 80 -o lo -j REDIRECT --to-port 8080
    
    echo -e "${GREEN}✓ Port forwarding rules added${NC}"
    
    # Display current rules
    echo -e "\n${YELLOW}Current NAT rules:${NC}"
    iptables -t nat -L PREROUTING -n -v | grep -E "dpt:80|dpt:8080" || echo "No rules found"
}

# Function to make iptables rules persistent
make_rules_persistent() {
    echo -e "\n${BLUE}3. Making iptables rules persistent...${NC}"
    
    # Install iptables-persistent if not installed
    if ! dpkg -l | grep -q iptables-persistent; then
        echo "Installing iptables-persistent..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
    fi
    
    # Save current rules
    echo "Saving iptables rules..."
    iptables-save > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6
    
    echo -e "${GREEN}✓ Rules saved and will persist after reboot${NC}"
}

# Function to test the forwarding
test_forwarding() {
    echo -e "\n${BLUE}4. Testing port forwarding...${NC}"
    
    # Get public IP
    PUBLIC_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || echo "your-ec2-ip")
    
    # Test port 8080 directly
    echo -n "Testing port 8080: "
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/SmartAgricultureNutrition/ | grep -q "200\|302"; then
        echo -e "${GREEN}✓ Working${NC}"
    else
        echo -e "${RED}✗ Not responding${NC}"
    fi
    
    # Test port 80 (forwarded)
    echo -n "Testing port 80 (forwarded): "
    if curl -s -o /dev/null -w "%{http_code}" http://localhost/SmartAgricultureNutrition/ | grep -q "200\|302"; then
        echo -e "${GREEN}✓ Forwarding working${NC}"
    else
        echo -e "${YELLOW}⚠️  Forwarding might need a moment to activate${NC}"
    fi
}

# Function to create systemd service for port forwarding
create_systemd_service() {
    echo -e "\n${BLUE}5. Creating systemd service for port forwarding...${NC}"
    
    cat > /etc/systemd/system/port-forwarding.service << 'EOF'
[Unit]
Description=Port Forwarding 80 to 8080
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
ExecStart=/sbin/iptables -I INPUT -p tcp --dport 80 -j ACCEPT
ExecStart=/sbin/iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable port-forwarding.service
    systemctl start port-forwarding.service
    
    echo -e "${GREEN}✓ Systemd service created and enabled${NC}"
}

# Main function
main() {
    echo -e "${YELLOW}This will configure port forwarding from 80 to 8080${NC}"
    echo -e "${YELLOW}Your app will remain on 8080, but be accessible via port 80${NC}"
    echo ""
    
    # Run setup steps
    stop_port_80_services
    setup_iptables_forwarding
    make_rules_persistent
    create_systemd_service
    test_forwarding
    
    # Get public IP
    PUBLIC_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || echo "13.203.219.244")
    
    echo -e "\n${GREEN}✅ Port Forwarding Setup Complete!${NC}"
    echo "========================================="
    echo -e "${BLUE}Your API is now accessible via:${NC}"
    echo ""
    echo -e "  Via Port 80:   ${GREEN}http://${PUBLIC_IP}/SmartAgricultureNutrition/api/v1/${NC}"
    echo -e "  Via Port 8080: ${GREEN}http://${PUBLIC_IP}:8080/SmartAgricultureNutrition/api/v1/${NC}"
    echo ""
    echo -e "  Swagger UI:    ${GREEN}http://${PUBLIC_IP}/SmartAgricultureNutrition/api/v1/swagger-ui${NC}"
    echo "========================================="
    echo ""
    echo -e "${YELLOW}⚠️  Important: Update your AWS Security Group to allow:${NC}"
    echo "  - Port 80 (HTTP) from 0.0.0.0/0"
    echo "  - Port 22 (SSH) from your IP"
    echo "  - Port 8080 is now optional (only if you want direct access)"
    echo ""
    echo -e "${BLUE}Useful commands:${NC}"
    echo "  View NAT rules:     sudo iptables -t nat -L -n -v"
    echo "  View INPUT rules:   sudo iptables -L INPUT -n -v"
    echo "  Test forwarding:    curl http://localhost/"
    echo "  Remove forwarding:  sudo iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080"
}

# Run main function
main
