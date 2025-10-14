#!/bin/bash

# Azure Monitoring Script for Smart Agriculture Nutrition API
# This script provides monitoring, cost tracking, and management utilities

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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

# Function to print section header
print_header() {
    echo
    print_message "========================================" "$CYAN"
    print_message "$1" "$CYAN"
    print_message "========================================" "$CYAN"
}

# Function to check Azure CLI
check_azure_cli() {
    if ! command -v az &> /dev/null; then
        print_message "Azure CLI is not installed. Please install it first." "$RED"
        exit 1
    fi
    
    if ! az account show &> /dev/null; then
        print_message "Not logged in to Azure. Please login:" "$YELLOW"
        az login
    fi
}

# Function to get VM status
get_vm_status() {
    print_header "VM Status"
    
    # Get VM details
    VM_STATUS=$(az vm show -g "$RESOURCE_GROUP" -n "$VM_NAME" --query "{Name:name, Status:powerState, Size:hardwareProfile.vmSize, Location:location}" -o json 2>/dev/null)
    
    if [ -z "$VM_STATUS" ]; then
        print_message "VM not found or error getting status" "$RED"
        return 1
    fi
    
    echo "$VM_STATUS" | python3 -m json.tool
    
    # Get public IP
    VM_IP=$(az vm show -d -g "$RESOURCE_GROUP" -n "$VM_NAME" --query publicIps -o tsv 2>/dev/null)
    print_message "\nPublic IP: $VM_IP" "$GREEN"
    
    # Get VM size details
    VM_SIZE=$(echo "$VM_STATUS" | python3 -c "import sys, json; print(json.load(sys.stdin)['Size'])")
    print_message "\nVM Size Details:" "$BLUE"
    az vm list-sizes --location eastus --query "[?name=='$VM_SIZE']" -o table
}

# Function to check resource usage
check_resource_usage() {
    print_header "Resource Usage"
    
    VM_IP=$(az vm show -d -g "$RESOURCE_GROUP" -n "$VM_NAME" --query publicIps -o tsv 2>/dev/null)
    
    if [ -z "$VM_IP" ]; then
        print_message "Could not get VM IP address" "$RED"
        return 1
    fi
    
    print_message "Fetching resource usage from VM..." "$BLUE"
    
    # Create monitoring script
    cat > /tmp/check_resources.sh << 'EOF'
#!/bin/bash

echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime)"
echo ""

echo "=== CPU Usage ==="
top -bn1 | head -5
echo ""

echo "=== Memory Usage ==="
free -h
echo ""

echo "=== Disk Usage ==="
df -h
echo ""

echo "=== Docker Containers ==="
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"
echo ""

echo "=== Docker Resource Usage ==="
sudo docker stats --no-stream
echo ""

echo "=== Network Connections ==="
ss -tuln | grep LISTEN
EOF

    # Execute on VM
    scp -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no /tmp/check_resources.sh "$ADMIN_USER@$VM_IP:/tmp/check_resources.sh" 2>/dev/null
    ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$ADMIN_USER@$VM_IP" "chmod +x /tmp/check_resources.sh && /tmp/check_resources.sh"
    
    rm /tmp/check_resources.sh
}

# Function to check costs
check_costs() {
    print_header "Cost Analysis"
    
    # Get subscription ID
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    
    print_message "Fetching cost data for resource group: $RESOURCE_GROUP" "$BLUE"
    
    # Get current month dates
    START_DATE=$(date -u +"%Y-%m-01")
    END_DATE=$(date -u +"%Y-%m-%d")
    
    print_message "\nCost period: $START_DATE to $END_DATE" "$YELLOW"
    
    # Check if Cost Management API is available
    print_message "\nResource costs in the current billing period:" "$BLUE"
    
    # Get resource costs
    az consumption usage list \
        --subscription "$SUBSCRIPTION_ID" \
        --start-date "$START_DATE" \
        --end-date "$END_DATE" \
        --query "[?contains(instanceId, '$RESOURCE_GROUP')]" \
        --output table 2>/dev/null || {
            print_message "Note: Detailed cost data may not be available for all subscription types" "$YELLOW"
            print_message "You can view costs in the Azure Portal: https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/overview" "$YELLOW"
        }
    
    # Calculate estimated monthly cost based on VM size
    print_message "\nEstimated Monthly Costs (based on VM size):" "$BLUE"
    
    VM_SIZE=$(az vm show -g "$RESOURCE_GROUP" -n "$VM_NAME" --query "hardwareProfile.vmSize" -o tsv 2>/dev/null)
    
    case "$VM_SIZE" in
        "Standard_B1s")
            print_message "VM (B1s): ~\$10-12/month" "$GREEN"
            print_message "Storage (30GB): ~\$1-2/month" "$GREEN"
            print_message "Bandwidth: ~\$0-5/month (depends on usage)" "$GREEN"
            print_message "Total Estimate: ~\$11-19/month" "$CYAN"
            ;;
        "Standard_B1ms")
            print_message "VM (B1ms): ~\$20/month" "$GREEN"
            print_message "Storage (30GB): ~\$1-2/month" "$GREEN"
            print_message "Bandwidth: ~\$0-5/month" "$GREEN"
            print_message "Total Estimate: ~\$21-27/month" "$CYAN"
            ;;
        "Standard_B2s")
            print_message "VM (B2s): ~\$35/month" "$GREEN"
            print_message "Storage (30GB): ~\$1-2/month" "$GREEN"
            print_message "Bandwidth: ~\$0-5/month" "$GREEN"
            print_message "Total Estimate: ~\$36-42/month" "$CYAN"
            ;;
        *)
            print_message "VM Size: $VM_SIZE" "$YELLOW"
            print_message "Check Azure Pricing Calculator for detailed costs" "$YELLOW"
            ;;
    esac
    
    print_message "\nWith \$100 credit, you can run for:" "$MAGENTA"
    print_message "- B1s: ~5-9 months" "$GREEN"
    print_message "- B1ms: ~3-4 months" "$GREEN"
    print_message "- B2s: ~2-3 months" "$GREEN"
}

# Function to manage VM power state
manage_vm_power() {
    print_header "VM Power Management"
    
    CURRENT_STATUS=$(az vm show -g "$RESOURCE_GROUP" -n "$VM_NAME" --query "powerState" -o tsv 2>/dev/null)
    print_message "Current status: $CURRENT_STATUS" "$BLUE"
    
    echo
    echo "1) Start VM"
    echo "2) Stop VM (deallocate - no compute charges)"
    echo "3) Restart VM"
    echo "4) Back to main menu"
    
    read -p "Select an option (1-4): " option
    
    case $option in
        1)
            print_message "Starting VM..." "$BLUE"
            az vm start -g "$RESOURCE_GROUP" -n "$VM_NAME" --output none
            print_message "VM started successfully" "$GREEN"
            ;;
        2)
            print_message "Stopping and deallocating VM..." "$BLUE"
            az vm deallocate -g "$RESOURCE_GROUP" -n "$VM_NAME" --output none
            print_message "VM stopped and deallocated (no compute charges)" "$GREEN"
            ;;
        3)
            print_message "Restarting VM..." "$BLUE"
            az vm restart -g "$RESOURCE_GROUP" -n "$VM_NAME" --output none
            print_message "VM restarted successfully" "$GREEN"
            ;;
        4)
            return
            ;;
        *)
            print_message "Invalid option" "$RED"
            ;;
    esac
}

# Function to setup budget alert
setup_budget_alert() {
    print_header "Budget Alert Setup"
    
    print_message "Setting up budget alert for \$100..." "$BLUE"
    
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    
    # Create budget
    az consumption budget create \
        --budget-name "SmartAgricultureBudget" \
        --amount 100 \
        --time-grain Monthly \
        --start-date $(date -u +"%Y-%m-01") \
        --end-date $(date -u -d "+1 year" +"%Y-%m-%d") \
        --category Cost \
        --time-period Monthly \
        --notifications-enabled true \
        --notifications-threshold 50 \
        --notifications-threshold 75 \
        --notifications-threshold 90 \
        --notifications-threshold 100 \
        --notifications-contact-emails "your-email@example.com" \
        --resource-group "$RESOURCE_GROUP" 2>/dev/null || {
            print_message "Note: Budget alerts may require specific permissions or subscription type" "$YELLOW"
            print_message "You can set up budget alerts manually in Azure Portal" "$YELLOW"
        }
    
    print_message "Budget alert configured (if supported by your subscription)" "$GREEN"
}

# Function to check auto-shutdown status
check_auto_shutdown() {
    print_header "Auto-Shutdown Configuration"
    
    # Check if auto-shutdown is configured
    AUTO_SHUTDOWN=$(az vm show -g "$RESOURCE_GROUP" -n "$VM_NAME" --query "scheduledEventsProfile" -o json 2>/dev/null)
    
    if [ "$AUTO_SHUTDOWN" == "null" ] || [ -z "$AUTO_SHUTDOWN" ]; then
        print_message "Auto-shutdown is not configured" "$YELLOW"
        
        read -p "Do you want to enable auto-shutdown at 10 PM UTC? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            az vm auto-shutdown -g "$RESOURCE_GROUP" -n "$VM_NAME" --time 2200 --timezone "UTC" --output none
            print_message "Auto-shutdown enabled at 10 PM UTC" "$GREEN"
        fi
    else
        print_message "Auto-shutdown is configured" "$GREEN"
        echo "$AUTO_SHUTDOWN" | python3 -m json.tool
    fi
}

# Function to create backup
create_backup() {
    print_header "Create Backup"
    
    print_message "Creating VM disk snapshot..." "$BLUE"
    
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    SNAPSHOT_NAME="SmartAgricultureVM-snapshot-$TIMESTAMP"
    
    # Get OS disk ID
    OS_DISK_ID=$(az vm show -g "$RESOURCE_GROUP" -n "$VM_NAME" --query "storageProfile.osDisk.managedDisk.id" -o tsv)
    
    if [ -z "$OS_DISK_ID" ]; then
        print_message "Could not get OS disk ID" "$RED"
        return 1
    fi
    
    # Create snapshot
    az snapshot create \
        -g "$RESOURCE_GROUP" \
        --name "$SNAPSHOT_NAME" \
        --source "$OS_DISK_ID" \
        --output none
    
    print_message "Snapshot created: $SNAPSHOT_NAME" "$GREEN"
    
    # Also backup database
    print_message "\nBacking up database..." "$BLUE"
    
    VM_IP=$(az vm show -d -g "$RESOURCE_GROUP" -n "$VM_NAME" --query publicIps -o tsv 2>/dev/null)
    
    if [ ! -z "$VM_IP" ]; then
        ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$ADMIN_USER@$VM_IP" \
            "cd ~/SmartAgricultureNutrition && sudo docker exec agriculture-postgres pg_dump -U agriculture_user smart_agriculture_nutrition > backup-$TIMESTAMP.sql"
        
        print_message "Database backup created: backup-$TIMESTAMP.sql" "$GREEN"
    fi
}

# Function to show application logs
show_app_logs() {
    print_header "Application Logs"
    
    VM_IP=$(az vm show -d -g "$RESOURCE_GROUP" -n "$VM_NAME" --query publicIps -o tsv 2>/dev/null)
    
    if [ -z "$VM_IP" ]; then
        print_message "Could not get VM IP address" "$RED"
        return 1
    fi
    
    print_message "Fetching application logs..." "$BLUE"
    ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$ADMIN_USER@$VM_IP" \
        "cd ~/SmartAgricultureNutrition && sudo docker-compose -f docker-compose.prod.yml logs --tail=100"
}

# Main menu
show_menu() {
    print_header "Azure Monitoring Dashboard"
    
    echo "1) Check VM Status"
    echo "2) Check Resource Usage"
    echo "3) Check Costs & Budget"
    echo "4) Manage VM Power State"
    echo "5) Setup Budget Alert"
    echo "6) Check Auto-Shutdown"
    echo "7) Create Backup"
    echo "8) Show Application Logs"
    echo "9) Exit"
    
    read -p "Select an option (1-9): " option
    
    case $option in
        1) get_vm_status ;;
        2) check_resource_usage ;;
        3) check_costs ;;
        4) manage_vm_power ;;
        5) setup_budget_alert ;;
        6) check_auto_shutdown ;;
        7) create_backup ;;
        8) show_app_logs ;;
        9) 
            print_message "Exiting..." "$GREEN"
            exit 0
            ;;
        *)
            print_message "Invalid option" "$RED"
            ;;
    esac
}

# Handle command line arguments
handle_args() {
    case "$1" in
        "status")
            get_vm_status
            ;;
        "usage")
            check_resource_usage
            ;;
        "costs")
            check_costs
            ;;
        "logs")
            show_app_logs
            ;;
        *)
            # Show interactive menu
            while true; do
                show_menu
                echo
                read -p "Press Enter to continue..."
            done
            ;;
    esac
}

# Main execution
main() {
    print_message "Azure Smart Agriculture Monitoring Tool" "$GREEN"
    
    # Check prerequisites
    check_azure_cli
    
    # Handle arguments or show menu
    handle_args "$1"
}

# Run main function
main "$@"
