# Azure VM Deployment Guide for Smart Agriculture Nutrition API

## Prerequisites
- Azure Account with active subscription ($100 credit)
- SSH client (built-in on Mac/Linux, use PuTTY on Windows)

## Deployment Options

### Option 1: Manual VM Creation (Recommended for Beginners)
Follow the manual setup steps below to create your VM through Azure Portal.

### Option 2: Automated Deployment with Azure CLI
Use the provided scripts for automated deployment (requires Azure CLI).

---

## Option 1: Manual VM Creation Through Azure Portal

### Step 1: Create VM in Azure Portal

1. **Login to Azure Portal**: https://portal.azure.com

2. **Navigate to Virtual Machines**:
   - Click "Create a resource" or search for "Virtual Machines"
   - Click "Create" → "Virtual Machine"

3. **Configure Basic Settings**:
   - **Subscription**: Select your subscription
   - **Resource Group**: Create new → "SmartAgricultureRG"
   - **Virtual Machine Name**: "SmartAgricultureVM"
   - **Region**: Choose closest to you (e.g., East US)
   - **Availability Options**: No infrastructure redundancy required
   - **Image**: Ubuntu Server 22.04 LTS - x64 Gen2
   - **Size**: Standard_B1s (1 vcpu, 1 GB memory) - ~$10/month
   - **Authentication Type**: SSH public key
   - **Username**: azureuser (or your preference)
   - **SSH public key source**: Generate new key pair
   - **Key pair name**: azure_vm_key

4. **Configure Networking**:
   - Click "Next: Disks" then "Next: Networking"
   - **Virtual Network**: Create new (default)
   - **Subnet**: default
   - **Public IP**: Create new
   - **NIC network security group**: Basic
   - **Public inbound ports**: Allow selected ports
   - **Select inbound ports**: HTTP (80), HTTPS (443), SSH (22)

5. **Configure Management**:
   - Click "Next: Management"
   - **Auto-shutdown**: Enable (set time to save costs)
   - **Backup**: Disable (to save costs)

6. **Review and Create**:
   - Click "Review + create"
   - Review the configuration
   - Click "Create"
   - **Download the private key** when prompted (IMPORTANT!)

### Step 2: Connect to Your VM

**For Mac/Linux:**
```bash
# Set permissions for the key file
chmod 400 ~/Downloads/azure_vm_key.pem

# Connect to VM (replace with your VM's public IP)
ssh -i ~/Downloads/azure_vm_key.pem azureuser@<your-vm-public-ip>
```

**For Windows (using PowerShell):**
```powershell
# Connect to VM
ssh -i C:\Users\YourName\Downloads\azure_vm_key.pem azureuser@<your-vm-public-ip>
```

### Step 3: Run the Setup Script

Once connected to your VM, run these commands:

```bash
# Clone the repository
git clone https://github.com/salmanprottoy/Smart-Agriculture-Nutrition.git
cd SmartAgricultureNutrition

# Run the deployment script
./scripts/azure-deploy.sh
```

The script will:
- Update the system
- Install Docker and Docker Compose
- Prompt for API keys (optional)
- Set up the application with all fixes
- Configure Nginx with CORS and URL rewriting
- Start all services
- Create auto-start service

### Step 4: Configure API Keys (If Skipped During Setup)

The deployment script now prompts for API keys. If you skipped them:

```bash
# Edit the environment file
nano ~/SmartAgricultureNutrition/.env

# Update these values with your actual API keys:
# WEATHER_API_KEY=your_actual_weather_api_key  # Get from: https://openweathermap.org/api
# USDA_API_KEY=your_actual_usda_api_key        # Get from: https://fdc.nal.usda.gov/api-key-signup.html

# Save and exit (Ctrl+X, then Y, then Enter)

# Restart the application
cd ~/SmartAgricultureNutrition
sudo docker-compose -f docker-compose.azure.yml restart
```

### Step 5: Access Your Application

Your application is now available at:
- **Swagger UI**: `http://<your-vm-public-ip>/api/v1/swagger`
- **API Endpoints**: `http://<your-vm-public-ip>/api/v1/`
- **Health Check**: `http://<your-vm-public-ip>/health`

### Step 6: Optional - Setup Custom Domain with HTTPS

```bash
# Run DuckDNS setup for free domain + SSL
./scripts/archive/azure-duckdns-setup.sh

# Follow prompts for:
# - DuckDNS subdomain
# - DuckDNS token (from duckdns.org)
# - HTTPS setup with Let's Encrypt
```

---

## Option 2: Automated Deployment with Azure CLI

### Prerequisites
- Azure CLI installed locally
- SSH key pair for VM access

### Quick Start

### Step 1: Install Azure CLI (if not installed)

**macOS:**
```bash
brew update && brew install azure-cli
```

**Linux:**
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Windows:**
Download from: https://aka.ms/installazurecliwindows

### Step 2: Login to Azure

```bash
az login
# Follow the browser instructions to authenticate
```

### Step 3: Create SSH Key (if you don't have one)

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_vm_key
```

### Step 4: Run Deployment Script

```bash
# Clone repository (if not already done)
git clone https://github.com/salmanprottoy/Smart-Agriculture-Nutrition.git
cd Smart-Agriculture-Nutrition

# Run Azure deployment
./scripts/azure-deploy.sh
```

## VM Specifications & Pricing

### Recommended: B1s (Within $100/year budget)
- **vCPUs**: 1
- **RAM**: 1 GB
- **Storage**: 30 GB Premium SSD
- **Cost**: ~$10-12/month (~$120-144/year)
- **Good for**: Development, testing, light production

### Alternative Options:
- **B1ms**: 1 vCPU, 2 GB RAM (~$20/month)
- **B2s**: 2 vCPUs, 4 GB RAM (~$35/month)
- **B2ms**: 2 vCPUs, 8 GB RAM (~$70/month)

## Architecture Overview

```
Azure Resource Group
├── Virtual Machine (Ubuntu 22.04)
│   ├── Docker
│   ├── Docker Compose
│   ├── PostgreSQL (Container)
│   └── Java App (Container)
├── Network Security Group
│   ├── SSH (22) - Your IP only
│   ├── HTTP (80)
│   ├── HTTPS (443)
│   └── App (8080)
├── Public IP Address
└── Virtual Network & Subnet
```

## Network Security Rules

| Priority | Name  | Port | Protocol | Source  | Destination | Action |
| -------- | ----- | ---- | -------- | ------- | ----------- | ------ |
| 100      | SSH   | 22   | TCP      | Your IP | Any         | Allow  |
| 200      | HTTP  | 80   | TCP      | Any     | Any         | Allow  |
| 300      | HTTPS | 443  | TCP      | Any     | Any         | Allow  |
| 400      | App   | 8080 | TCP      | Any     | Any         | Allow  |

## Environment Configuration

Create `.env` file on the VM:

```bash
# Database Configuration
POSTGRES_DB=smart_agriculture_nutrition
POSTGRES_USER=agriculture_user
POSTGRES_PASSWORD=<your-secure-password>

# API Keys
WEATHER_API_KEY=<your-weather-api-key>
USDA_API_KEY=<your-usda-api-key>

# JWT Secret
JWT_SECRET=<your-jwt-secret>

# Application
PORT=8080
APP_ENVIRONMENT=production
```

## Accessing Your Application

After deployment, your application will be available at:

- **Swagger UI**: `http://<vm-public-ip>/api/v1/swagger` (No localhost:8080 issues!)
- **API Endpoints**: `http://<vm-public-ip>/api/v1/`
- **Direct Application**: `http://<vm-public-ip>:8080/SmartAgricultureNutrition/`

With DuckDNS (optional):
- **HTTPS**: `https://your-domain.duckdns.org/api/v1/swagger`
- **HTTP**: `http://your-domain.duckdns.org/api/v1/swagger`

## Management Commands

### SSH into VM:
```bash
ssh -i ~/.ssh/azure_vm_key azureuser@<vm-public-ip>
```

### Check Application Status:
```bash
# SSH into VM first, then:
docker ps
docker logs smart-agriculture-app
docker logs agriculture-postgres
```

### Restart Application:
```bash
# SSH into VM first, then:
cd ~/SmartAgricultureNutrition
sudo docker-compose -f docker-compose.azure.yml restart
```

### Update Application After Code Changes:
```bash
# Pull latest code
cd ~/SmartAgricultureNutrition
git pull origin main

# Quick redeploy
./scripts/azure-quick-deploy.sh
```

### View Logs:
```bash
# SSH into VM first, then:
sudo docker-compose -f docker-compose.azure.yml logs -f
```

## Cost Management

### Enable Auto-Shutdown (Save ~50% costs):
```bash
# Set auto-shutdown at 10 PM daily
az vm auto-shutdown -g SmartAgricultureRG -n SmartAgricultureVM \
  --time 2200 --timezone "UTC"
```

### Monitor Costs:
```bash
# Check current month's costs
./scripts/azure-monitor.sh costs

# Check VM usage
./scripts/azure-monitor.sh usage
```

### Cost Optimization Tips:
1. **Use B-series VMs**: Burstable performance, lower cost
2. **Enable auto-shutdown**: For non-production hours
3. **Use Standard SSD**: Instead of Premium for dev/test
4. **Set up budget alerts**: Get notified at 50%, 75%, 90% of budget
5. **Deallocate when not in use**: `az vm deallocate`

## Backup & Recovery

### Create VM Snapshot:
```bash
az snapshot create -g SmartAgricultureRG \
  --source SmartAgricultureVM_OsDisk \
  --name SmartAgricultureVM-snapshot-$(date +%Y%m%d)
```

### Backup Database:
```bash
# SSH into VM first, then:
docker exec agriculture-postgres pg_dump -U agriculture_user \
  smart_agriculture_nutrition > backup-$(date +%Y%m%d).sql
```

## Monitoring & Alerts

### Enable Azure Monitor:
```bash
# Enable diagnostics
az vm diagnostics set --resource-group SmartAgricultureRG \
  --vm-name SmartAgricultureVM --settings @azure-diagnostics-config.json
```

### Set Up Alerts:
```bash
# CPU usage alert
az monitor metrics alert create -n high-cpu -g SmartAgricultureRG \
  --scopes /subscriptions/<sub-id>/resourceGroups/SmartAgricultureRG/providers/Microsoft.Compute/virtualMachines/SmartAgricultureVM \
  --condition "avg Percentage CPU > 80" \
  --description "Alert when CPU usage is over 80%"
```

## Troubleshooting

### VM Won't Start:
```bash
# Check VM status
az vm show -g SmartAgricultureRG -n SmartAgricultureVM --query "provisioningState"

# Start VM
az vm start -g SmartAgricultureRG -n SmartAgricultureVM
```

### Can't Connect via SSH:
```bash
# Check Network Security Group rules
az network nsg rule list -g SmartAgricultureRG --nsg-name SmartAgricultureNSG

# Reset SSH configuration
az vm user reset-ssh -g SmartAgricultureRG -n SmartAgricultureVM
```

### Application Not Responding:
```bash
# SSH into VM and check Docker
ssh -i ~/.ssh/azure_vm_key azureuser@<vm-public-ip>
docker ps
docker logs smart-agriculture-app
docker-compose -f docker-compose.prod.yml restart
```

### Database Connection Issues:
```bash
# SSH into VM and test connection
docker exec -it agriculture-postgres psql -U agriculture_user -d smart_agriculture_nutrition
```

## Security Best Practices

1. **Use Azure Key Vault** for secrets management
2. **Enable Azure Security Center** for threat detection
3. **Regular OS updates**: `sudo apt update && sudo apt upgrade`
4. **Use managed identities** instead of passwords where possible
5. **Enable Azure Backup** for disaster recovery
6. **Implement network segmentation** with subnets
7. **Use Azure Firewall** for advanced protection

## Clean Up Resources

To avoid charges when not using:

```bash
# Stop (deallocate) VM - No charges except storage
az vm deallocate -g SmartAgricultureRG -n SmartAgricultureVM

# Delete everything (when completely done)
az group delete -n SmartAgricultureRG --yes
```

## Support & Resources

- **Azure Portal**: https://portal.azure.com
- **Azure Status**: https://status.azure.com
- **Azure Pricing Calculator**: https://azure.microsoft.com/pricing/calculator/
- **Azure Free Account FAQ**: https://azure.microsoft.com/free/free-account-faq/

## Next Steps

1. **Add Custom Domain**: Configure Azure DNS
2. **Enable HTTPS**: Use Azure Application Gateway or Let's Encrypt
3. **Set up CI/CD**: Use Azure DevOps or GitHub Actions
4. **Add Monitoring**: Application Insights for detailed metrics
5. **Scale Out**: Use VM Scale Sets for auto-scaling
