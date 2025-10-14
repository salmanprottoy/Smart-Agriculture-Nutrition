# Azure VM Quick Start Guide 🚀

## Create VM in Azure Portal (5 minutes)

### 1️⃣ Go to Azure Portal
👉 https://portal.azure.com

### 2️⃣ Create Virtual Machine
- Click **"Create a resource"** → **"Virtual Machine"**

### 3️⃣ Basic Configuration
```
✅ Resource Group: Create new → "SmartAgricultureRG"
✅ VM Name: SmartAgricultureVM
✅ Region: East US (or closest to you)
✅ Image: Ubuntu Server 22.04 LTS
✅ Size: Standard_B1s (1 vCPU, 1GB RAM) 💰 ~$10/month
✅ Authentication: SSH public key
✅ Username: azureuser
```

### 4️⃣ Networking
```
✅ Allow ports: SSH (22), HTTP (80), HTTPS (443)
```

### 5️⃣ Create & Download Key
- Click **"Review + Create"** → **"Create"**
- **⚠️ DOWNLOAD THE PRIVATE KEY WHEN PROMPTED!**

---

## Deploy Application (10 minutes)

### 1️⃣ Connect to VM
```bash
# Mac/Linux
chmod 400 ~/Downloads/azure_vm_key.pem
ssh -i ~/Downloads/azure_vm_key.pem azureuser@YOUR_VM_IP

# Windows PowerShell
ssh -i C:\Users\YourName\Downloads\azure_vm_key.pem azureuser@YOUR_VM_IP
```

### 2️⃣ Run Setup Script
```bash
# Download and run setup script
wget https://raw.githubusercontent.com/salmanprottoy/Smart-Agriculture-Nutrition/main/scripts/azure-vm-setup.sh
chmod +x azure-vm-setup.sh
./azure-vm-setup.sh
```

### 3️⃣ Configure API Keys
```bash
# Edit environment file
nano ~/SmartAgricultureNutrition/.env

# Add your API keys:
WEATHER_API_KEY=your_actual_key_here
USDA_API_KEY=your_actual_key_here

# Save: Ctrl+X, Y, Enter

# Restart application
cd ~/SmartAgricultureNutrition
sudo docker-compose -f docker-compose.prod.yml restart
```

---

## 🎉 Access Your Application

```
🌐 Main App: http://YOUR_VM_IP/
📊 API: http://YOUR_VM_IP/api/v1/
📚 Swagger: http://YOUR_VM_IP/api/v1/swagger
```

---

## 💰 Cost Management Tips

### Save Money with Auto-Shutdown
In Azure Portal → Your VM → Auto-shutdown → Enable
- Set time: 10 PM (or when you don't need it)
- Saves ~50% of costs!

### Stop VM When Not Using
```bash
# Via Azure Portal
VM → Stop (Deallocate)

# Via Azure CLI
az vm deallocate -g SmartAgricultureRG -n SmartAgricultureVM
```

### Budget Tracking
- B1s VM: ~$10-12/month
- Your $100 credit = ~8-10 months of usage
- Monitor usage in Azure Portal → Cost Management

---

## 🛠️ Useful Commands

### Check Application Status
```bash
# SSH into VM first
ssh -i ~/Downloads/azure_vm_key.pem azureuser@YOUR_VM_IP

# Check containers
sudo docker ps

# View logs
cd ~/SmartAgricultureNutrition
sudo docker-compose -f docker-compose.prod.yml logs -f
```

### Restart Application
```bash
cd ~/SmartAgricultureNutrition
sudo docker-compose -f docker-compose.prod.yml restart
```

### Update Application
```bash
cd ~/SmartAgricultureNutrition
git pull origin main
sudo docker-compose -f docker-compose.prod.yml down
sudo docker-compose -f docker-compose.prod.yml build
sudo docker-compose -f docker-compose.prod.yml up -d
```

---

## 🆘 Troubleshooting

### Can't Connect to VM?
1. Check VM is running in Azure Portal
2. Check your IP in Network Security Group
3. Verify SSH key permissions: `chmod 400 your_key.pem`

### Application Not Working?
```bash
# Check if containers are running
sudo docker ps

# Restart containers
cd ~/SmartAgricultureNutrition
sudo docker-compose -f docker-compose.prod.yml restart

# Check logs for errors
sudo docker-compose -f docker-compose.prod.yml logs
```

### Need to Free Up Resources?
```bash
# Remove unused Docker images
sudo docker system prune -a

# Check disk space
df -h
```

---

## 📞 Get API Keys

### Weather API (Free)
1. Go to: https://openweathermap.org/api
2. Sign up for free account
3. Get your API key

### USDA Food Data API (Free)
1. Go to: https://fdc.nal.usda.gov/api-key-signup.html
2. Fill the form
3. Get your API key via email

---

## 🎯 Next Steps

1. **Set up auto-shutdown** to save costs
2. **Add your API keys** to make the app fully functional
3. **Set up budget alerts** in Azure Portal
4. **Consider adding a domain name** (optional)

---

## 📚 Full Documentation

For detailed instructions and advanced configurations:
- [Complete Azure Deployment Guide](AZURE_VM_DEPLOYMENT.md)
- [AWS EC2 Deployment Guide](AWS_EC2_DEPLOYMENT.md)
- [Project README](README.md)

---

**Need Help?** Check the full documentation or create an issue on GitHub!
