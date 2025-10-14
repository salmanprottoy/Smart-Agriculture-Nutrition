#!/bin/bash

# Azure VM Redeploy Script for Smart Agriculture Nutrition API
# This script updates the application on an existing Azure VM

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration Variables (must match azure-deploy.sh)
RESOURCE_GROUP="SmartAgricultureRG"
VM_NAME="SmartAgricultureVM"
ADMIN_USER="azureuser"
SSH_KEY_PATH="$HOME/.ssh/azure_vm_key"

# Function to print colored output
print_message() {
    echo -e "${2}${1}${NC}"
}

# Function to check if Azure CLI is installed
check_azure_cli() {
    if ! command -v az &> /dev/null; then
        print_message "Azure CLI is not installed. Please install it first:" "$RED"
        exit 1
    fi
}

# Function to check Azure login
check_azure_login() {
    print_message "Checking Azure login status..." "$BLUE"
    if ! az account show &> /dev/null; then
        print_message "Not logged in to Azure. Please login:" "$YELLOW"
        az login
    fi
}

# Function to get VM public IP
get_vm_ip() {
    print_message "Getting VM public IP..." "$BLUE"
    VM_IP=$(az vm show -d -g "$RESOURCE_GROUP" -n "$VM_NAME" --query publicIps -o tsv 2>/dev/null)
    
    if [ -z "$VM_IP" ]; then
        print_message "Error: Could not find VM or get its IP address" "$RED"
        print_message "Make sure the VM exists and is running" "$YELLOW"
        exit 1
    fi
    
    print_message "VM Public IP: $VM_IP" "$GREEN"
}

# Function to check VM status
check_vm_status() {
    print_message "Checking VM status..." "$BLUE"
    VM_STATUS=$(az vm show -g "$RESOURCE_GROUP" -n "$VM_NAME" --query "powerState" -o tsv 2>/dev/null)
    
    if [[ "$VM_STATUS" != "VM running" ]]; then
        print_message "VM is not running. Starting VM..." "$YELLOW"
        az vm start -g "$RESOURCE_GROUP" -n "$VM_NAME" --output none
        print_message "Waiting for VM to start..." "$YELLOW"
        sleep 30
    else
        print_message "VM is running" "$GREEN"
    fi
}

# Function to redeploy application
redeploy_application() {
    print_message "Starting application redeployment..." "$BLUE"
    
    # Create redeploy script
    cat > /tmp/vm_redeploy.sh << 'EOF'
#!/bin/bash
set -e

echo "========================================="
echo "Starting application redeployment..."
echo "========================================="

# Navigate to application directory
cd ~/SmartAgricultureNutrition

# Save current .env file
echo "Backing up .env file..."
cp .env .env.backup

# Pull latest changes from git
echo "Pulling latest changes from repository..."
git fetch origin
git reset --hard origin/main

# Restore .env file
echo "Restoring .env file..."
cp .env.backup .env

# Stop current containers
echo "Stopping current containers..."
sudo docker-compose -f docker-compose.prod.yml down

# Remove old images to force rebuild
echo "Removing old Docker images..."
sudo docker rmi smart-agriculture-app:latest 2>/dev/null || true

# Rebuild and start containers
echo "Building new Docker image..."
sudo docker-compose -f docker-compose.prod.yml build --no-cache

echo "Starting updated containers..."
sudo docker-compose -f docker-compose.prod.yml up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# Check container status
echo "Checking container status..."
sudo docker ps

# Test application health
echo "Testing application health..."
curl -f http://localhost:8080/SmartAgricultureNutrition/ || echo "Warning: Health check failed"

# Restart Nginx to ensure proper proxy
echo "Restarting Nginx..."
sudo systemctl restart nginx

echo "========================================="
echo "Redeployment completed successfully!"
echo "========================================="

# Show logs
echo "Recent application logs:"
sudo docker-compose -f docker-compose.prod.yml logs --tail=50
EOF

    # Copy and execute redeploy script on VM
    print_message "Copying redeploy script to VM..." "$BLUE"
    scp -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no /tmp/vm_redeploy.sh "$ADMIN_USER@$VM_IP:/tmp/vm_redeploy.sh"
    
    print_message "Executing redeploy script on VM..." "$BLUE"
    ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$ADMIN_USER@$VM_IP" "chmod +x /tmp/vm_redeploy.sh && /tmp/vm_redeploy.sh"
    
    # Clean up
    rm /tmp/vm_redeploy.sh
    
    print_message "Application redeployed successfully!" "$GREEN"
}

# Function to display summary
display_summary() {
    print_message "\n========================================" "$GREEN"
    print_message "REDEPLOYMENT COMPLETED SUCCESSFULLY!" "$GREEN"
    print_message "========================================" "$GREEN"
    print_message "\nApplication URLs:" "$BLUE"
    print_message "Main Application: http://$VM_IP/" "$YELLOW"
    print_message "API Endpoints: http://$VM_IP/api/v1/" "$YELLOW"
    print_message "Swagger UI: http://$VM_IP/api/v1/swagger" "$YELLOW"
    print_message "\nSSH Access:" "$BLUE"
    print_message "ssh -i $SSH_KEY_PATH $ADMIN_USER@$VM_IP" "$YELLOW"
    print_message "\nTo view logs:" "$BLUE"
    print_message "ssh -i $SSH_KEY_PATH $ADMIN_USER@$VM_IP 'cd ~/SmartAgricultureNutrition && sudo docker-compose -f docker-compose.prod.yml logs -f'" "$YELLOW"
    print_message "========================================\n" "$GREEN"
}

# Function to offer additional options
offer_options() {
    print_message "\nAdditional Options:" "$BLUE"
    echo "1) View application logs"
    echo "2) Restart containers"
    echo "3) Check container status"
    echo "4) Update environment variables"
    echo "5) Exit"
    
    read -p "Select an option (1-5): " option
    
    case $option in
        1)
            print_message "Viewing application logs..." "$BLUE"
            ssh -i "$SSH_KEY_PATH" "$ADMIN_USER@$VM_IP" "cd ~/SmartAgricultureNutrition && sudo docker-compose -f docker-compose.prod.yml logs --tail=100"
            ;;
        2)
            print_message "Restarting containers..." "$BLUE"
            ssh -i "$SSH_KEY_PATH" "$ADMIN_USER@$VM_IP" "cd ~/SmartAgricultureNutrition && sudo docker-compose -f docker-compose.prod.yml restart"
            print_message "Containers restarted" "$GREEN"
            ;;
        3)
            print_message "Checking container status..." "$BLUE"
            ssh -i "$SSH_KEY_PATH" "$ADMIN_USER@$VM_IP" "sudo docker ps"
            ;;
        4)
            print_message "To update environment variables:" "$YELLOW"
            print_message "1. SSH into the VM: ssh -i $SSH_KEY_PATH $ADMIN_USER@$VM_IP" "$YELLOW"
            print_message "2. Edit the .env file: nano ~/SmartAgricultureNutrition/.env" "$YELLOW"
            print_message "3. Restart containers: cd ~/SmartAgricultureNutrition && sudo docker-compose -f docker-compose.prod.yml restart" "$YELLOW"
            ;;
        5)
            print_message "Exiting..." "$GREEN"
            exit 0
            ;;
        *)
            print_message "Invalid option" "$RED"
            ;;
    esac
}

# Main execution
main() {
    print_message "Azure VM Application Redeployment" "$GREEN"
    print_message "========================================\n" "$GREEN"
    
    # Check prerequisites
    check_azure_cli
    check_azure_login
    
    # Get VM information
    get_vm_ip
    check_vm_status
    
    # Redeploy application
    redeploy_application
    
    # Display summary
    display_summary
    
    # Offer additional options
    while true; do
        offer_options
    done
}

# Run main function
main
