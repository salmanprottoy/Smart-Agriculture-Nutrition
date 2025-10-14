#!/bin/bash

# Azure VM Deployment Script for Smart Agriculture Nutrition API
# This script creates and configures an Azure VM with Docker and deploys the application

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration Variables
RESOURCE_GROUP="SmartAgricultureRG"
LOCATION="eastus"  # Change to your preferred region
VM_NAME="SmartAgricultureVM"
VM_SIZE="Standard_B1s"  # 1 vCPU, 1 GB RAM (~$10/month)
IMAGE="Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest"
ADMIN_USER="azureuser"
NSG_NAME="SmartAgricultureNSG"
VNET_NAME="SmartAgricultureVNet"
SUBNET_NAME="SmartAgricultureSubnet"
PUBLIC_IP_NAME="SmartAgriculturePublicIP"
SSH_KEY_PATH="$HOME/.ssh/azure_vm_key"
GITHUB_REPO="https://github.com/salmanprottoy/Smart-Agriculture-Nutrition.git"

# Function to print colored output
print_message() {
    echo -e "${2}${1}${NC}"
}

# Function to check if Azure CLI is installed
check_azure_cli() {
    if ! command -v az &> /dev/null; then
        print_message "Azure CLI is not installed. Please install it first:" "$RED"
        print_message "macOS: brew install azure-cli" "$YELLOW"
        print_message "Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash" "$YELLOW"
        print_message "Windows: Download from https://aka.ms/installazurecliwindows" "$YELLOW"
        exit 1
    fi
}

# Function to check Azure login
check_azure_login() {
    print_message "Checking Azure login status..." "$BLUE"
    if ! az account show &> /dev/null; then
        print_message "Not logged in to Azure. Please login:" "$YELLOW"
        az login
    else
        ACCOUNT_NAME=$(az account show --query name -o tsv)
        print_message "Logged in to Azure account: $ACCOUNT_NAME" "$GREEN"
    fi
}

# Function to create SSH key if it doesn't exist
create_ssh_key() {
    if [ ! -f "$SSH_KEY_PATH" ]; then
        print_message "Creating SSH key pair..." "$BLUE"
        ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -q
        print_message "SSH key created at: $SSH_KEY_PATH" "$GREEN"
    else
        print_message "Using existing SSH key: $SSH_KEY_PATH" "$GREEN"
    fi
}

# Function to create resource group
create_resource_group() {
    print_message "Creating resource group: $RESOURCE_GROUP..." "$BLUE"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none
    print_message "Resource group created successfully" "$GREEN"
}

# Function to create virtual network
create_network() {
    print_message "Creating virtual network..." "$BLUE"
    
    # Create VNet
    az network vnet create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$VNET_NAME" \
        --address-prefix 10.0.0.0/16 \
        --subnet-name "$SUBNET_NAME" \
        --subnet-prefix 10.0.1.0/24 \
        --output none
    
    print_message "Virtual network created successfully" "$GREEN"
}

# Function to create network security group
create_nsg() {
    print_message "Creating network security group..." "$BLUE"
    
    # Create NSG
    az network nsg create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$NSG_NAME" \
        --output none
    
    # Get current public IP for SSH access
    MY_IP=$(curl -s https://api.ipify.org)
    print_message "Your current IP: $MY_IP" "$YELLOW"
    
    # Add NSG rules
    print_message "Adding security rules..." "$BLUE"
    
    # SSH rule (restricted to your IP)
    az network nsg rule create \
        --resource-group "$RESOURCE_GROUP" \
        --nsg-name "$NSG_NAME" \
        --name AllowSSH \
        --priority 100 \
        --source-address-prefixes "$MY_IP/32" \
        --destination-port-ranges 22 \
        --protocol Tcp \
        --access Allow \
        --output none
    
    # HTTP rule
    az network nsg rule create \
        --resource-group "$RESOURCE_GROUP" \
        --nsg-name "$NSG_NAME" \
        --name AllowHTTP \
        --priority 200 \
        --source-address-prefixes "*" \
        --destination-port-ranges 80 \
        --protocol Tcp \
        --access Allow \
        --output none
    
    # HTTPS rule
    az network nsg rule create \
        --resource-group "$RESOURCE_GROUP" \
        --nsg-name "$NSG_NAME" \
        --name AllowHTTPS \
        --priority 300 \
        --source-address-prefixes "*" \
        --destination-port-ranges 443 \
        --protocol Tcp \
        --access Allow \
        --output none
    
    # Application port rule
    az network nsg rule create \
        --resource-group "$RESOURCE_GROUP" \
        --nsg-name "$NSG_NAME" \
        --name AllowApp \
        --priority 400 \
        --source-address-prefixes "*" \
        --destination-port-ranges 8080 \
        --protocol Tcp \
        --access Allow \
        --output none
    
    print_message "Network security group configured successfully" "$GREEN"
}

# Function to create public IP
create_public_ip() {
    print_message "Creating public IP address..." "$BLUE"
    
    az network public-ip create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$PUBLIC_IP_NAME" \
        --sku Basic \
        --allocation-method Static \
        --output none
    
    print_message "Public IP created successfully" "$GREEN"
}

# Function to create VM
create_vm() {
    print_message "Creating virtual machine: $VM_NAME..." "$BLUE"
    print_message "This may take a few minutes..." "$YELLOW"
    
    az vm create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$VM_NAME" \
        --image "$IMAGE" \
        --size "$VM_SIZE" \
        --admin-username "$ADMIN_USER" \
        --ssh-key-values "$SSH_KEY_PATH.pub" \
        --vnet-name "$VNET_NAME" \
        --subnet "$SUBNET_NAME" \
        --nsg "$NSG_NAME" \
        --public-ip-address "$PUBLIC_IP_NAME" \
        --storage-sku Standard_LRS \
        --output none
    
    print_message "Virtual machine created successfully" "$GREEN"
}

# Function to get VM public IP
get_vm_ip() {
    VM_IP=$(az vm show -d -g "$RESOURCE_GROUP" -n "$VM_NAME" --query publicIps -o tsv)
    print_message "VM Public IP: $VM_IP" "$GREEN"
}

# Function to setup VM with Docker and application
setup_vm() {
    print_message "Setting up VM with Docker and application..." "$BLUE"
    print_message "This will take several minutes..." "$YELLOW"
    
    # Create setup script
    cat > /tmp/vm_setup.sh << 'EOF'
#!/bin/bash
set -e

echo "Starting VM setup..."

# Update system
echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install required packages
echo "Installing required packages..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    nginx

# Install Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
rm get-docker.sh

# Install Docker Compose
echo "Installing Docker Compose..."
sudo apt-get install -y docker-compose

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Clone repository
echo "Cloning repository..."
cd ~
if [ -d "SmartAgricultureNutrition" ]; then
    rm -rf SmartAgricultureNutrition
fi
git clone GITHUB_REPO_PLACEHOLDER SmartAgricultureNutrition
cd SmartAgricultureNutrition

# Create .env file
echo "Creating .env file..."
cat > .env << 'ENVEOF'
# Database Configuration
POSTGRES_DB=smart_agriculture_nutrition
POSTGRES_USER=agriculture_user
POSTGRES_PASSWORD=AgriNutri2024SecurePass!

# API Keys (replace with your actual keys)
WEATHER_API_KEY=your_weather_api_key_here
USDA_API_KEY=your_usda_api_key_here

# JWT Secret
JWT_SECRET=your-super-secure-jwt-secret-key-2024

# Application
PORT=8080
APP_ENVIRONMENT=production
ENVEOF

# Build and start application with Docker Compose
echo "Building and starting application..."
sudo docker-compose -f docker-compose.prod.yml build
sudo docker-compose -f docker-compose.prod.yml up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# Configure Nginx reverse proxy
echo "Configuring Nginx..."
sudo tee /etc/nginx/sites-available/smart-agriculture > /dev/null << 'NGINXEOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINXEOF

# Enable Nginx site
sudo ln -sf /etc/nginx/sites-available/smart-agriculture /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# Check if services are running
echo "Checking service status..."
sudo docker ps

echo "VM setup completed successfully!"
EOF

    # Replace placeholder with actual repo URL
    sed -i "s|GITHUB_REPO_PLACEHOLDER|$GITHUB_REPO|g" /tmp/vm_setup.sh
    
    # Copy and execute setup script on VM
    print_message "Copying setup script to VM..." "$BLUE"
    scp -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no /tmp/vm_setup.sh "$ADMIN_USER@$VM_IP:/tmp/vm_setup.sh"
    
    print_message "Executing setup script on VM..." "$BLUE"
    ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$ADMIN_USER@$VM_IP" "chmod +x /tmp/vm_setup.sh && /tmp/vm_setup.sh"
    
    # Clean up
    rm /tmp/vm_setup.sh
    
    print_message "VM setup completed successfully!" "$GREEN"
}

# Function to setup auto-shutdown
setup_auto_shutdown() {
    print_message "Setting up auto-shutdown to save costs..." "$BLUE"
    
    read -p "Do you want to enable auto-shutdown at 10 PM UTC daily? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        az vm auto-shutdown \
            -g "$RESOURCE_GROUP" \
            -n "$VM_NAME" \
            --time 2200 \
            --timezone "UTC" \
            --output none
        print_message "Auto-shutdown enabled at 10 PM UTC" "$GREEN"
    fi
}

# Function to display deployment summary
display_summary() {
    print_message "\n========================================" "$GREEN"
    print_message "DEPLOYMENT COMPLETED SUCCESSFULLY!" "$GREEN"
    print_message "========================================" "$GREEN"
    print_message "\nApplication URLs:" "$BLUE"
    print_message "Main Application: http://$VM_IP/" "$YELLOW"
    print_message "API Endpoints: http://$VM_IP/api/v1/" "$YELLOW"
    print_message "Swagger UI: http://$VM_IP/api/v1/swagger" "$YELLOW"
    print_message "Direct Tomcat: http://$VM_IP:8080/SmartAgricultureNutrition/" "$YELLOW"
    print_message "\nSSH Access:" "$BLUE"
    print_message "ssh -i $SSH_KEY_PATH $ADMIN_USER@$VM_IP" "$YELLOW"
    print_message "\nResource Group: $RESOURCE_GROUP" "$BLUE"
    print_message "VM Name: $VM_NAME" "$BLUE"
    print_message "VM Size: $VM_SIZE" "$BLUE"
    print_message "Location: $LOCATION" "$BLUE"
    print_message "\nIMPORTANT:" "$RED"
    print_message "1. Update the .env file on the VM with your actual API keys" "$YELLOW"
    print_message "2. SSH rule is restricted to your current IP: $MY_IP" "$YELLOW"
    print_message "3. To save costs, the VM can be stopped when not in use:" "$YELLOW"
    print_message "   az vm deallocate -g $RESOURCE_GROUP -n $VM_NAME" "$YELLOW"
    print_message "========================================\n" "$GREEN"
}

# Main execution
main() {
    print_message "Starting Azure VM deployment for Smart Agriculture Nutrition API" "$GREEN"
    print_message "========================================\n" "$GREEN"
    
    # Check prerequisites
    check_azure_cli
    check_azure_login
    create_ssh_key
    
    # Create Azure resources
    create_resource_group
    create_network
    create_nsg
    create_public_ip
    create_vm
    get_vm_ip
    
    # Setup VM
    setup_vm
    
    # Optional configurations
    setup_auto_shutdown
    
    # Display summary
    display_summary
}

# Run main function
main
