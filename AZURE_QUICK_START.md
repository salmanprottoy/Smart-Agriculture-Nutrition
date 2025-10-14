# Azure VM Quick Start Guide

## 🚀 Quick Deployment Steps

### Step 1: Initial Setup (First Time Only)

```bash
# SSH to your Azure VM
ssh azureuser@[YOUR-VM-IP]

# Clone the repository
git clone https://github.com/salmanprottoy/Smart-Agriculture-Nutrition.git
cd SmartAgricultureNutrition

# Run initial deployment (includes all fixes)
./scripts/azure-deploy.sh
# You'll be prompted for:
# - Weather API key (optional) - Get from: https://openweathermap.org/api
# - USDA API key (optional) - Get from: https://fdc.nal.usda.gov/api-key-signup.html

# Optional: Setup DuckDNS domain with HTTPS
./scripts/archive/azure-duckdns-setup.sh
```

### Step 2: Updating After Code Changes

```bash
# On your local machine
git add .
git commit -m "Your update message"
git push origin main

# On Azure VM
cd ~/SmartAgricultureNutrition
git pull origin main
./scripts/azure-quick-deploy.sh
```

### Step 3: Complete Fresh Start (If Needed)

```bash
# SSH to VM
ssh azureuser@[YOUR-VM-IP]

# Stop and clean everything
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker system prune -af
sudo rm -rf SmartAgricultureNutrition

# Start fresh
git clone https://github.com/salmanprottoy/Smart-Agriculture-Nutrition.git
cd SmartAgricultureNutrition

# Deploy (includes all fixes)
./scripts/azure-deploy.sh

# Setup domain (optional)
./scripts/archive/azure-duckdns-setup.sh
```

## 📋 Deployment Checklist

### Initial Deployment
- [ ] VM created with Ubuntu 22.04
- [ ] Ports opened: 22, 80, 443, 8080
- [ ] Repository cloned
- [ ] `azure-deploy.sh` executed (includes all fixes)
- [ ] Application accessible via IP

### Optional Setup
- [ ] DuckDNS domain configured
- [ ] HTTPS enabled with Let's Encrypt
- [ ] Port 443 opened in NSG

### After Code Updates
- [ ] Code pushed to GitHub
- [ ] Pulled latest changes on VM
- [ ] `azure-quick-deploy.sh` executed
- [ ] Application tested

## 🔧 Common Commands

### Check Status
```bash
# View running containers
sudo docker ps

# Check application logs
sudo docker-compose logs app

# Test Nginx configuration
sudo nginx -t

# Check disk space
df -h
```

### Troubleshooting
```bash
# If CORS errors persist
./scripts/archive/final-fix.sh

# If Swagger shows localhost:8080
# Clear browser cache and run:
./scripts/archive/final-fix.sh

# If DuckDNS not working
./scripts/archive/azure-duckdns-setup.sh

# If containers won't start
./scripts/azure-quick-deploy.sh
```

### Maintenance
```bash
# Clean up Docker resources
docker system prune -af

# Update system packages
sudo apt update && sudo apt upgrade -y

# Check DuckDNS updates
cat ~/duckdns/duck.log

# View cron jobs
crontab -l
```

## 📍 Access Points

### Via IP Address
- Swagger UI: `http://[YOUR-VM-IP]/api/v1/swagger`
- API Base: `http://[YOUR-VM-IP]/api/v1/`

### Via DuckDNS (After Setup)
- HTTP: `http://[your-domain].duckdns.org/api/v1/swagger`
- HTTPS: `https://[your-domain].duckdns.org/api/v1/swagger`

## 💰 Cost Optimization

### VM Size: Standard B1s
- 1 vCPU, 1 GB RAM
- ~$10-12/month
- Sufficient for API workload

### Save Money
1. **Stop VM when not in use**
   ```bash
   az vm deallocate --resource-group [YOUR-RG] --name [YOUR-VM]
   ```

2. **Start VM when needed**
   ```bash
   az vm start --resource-group [YOUR-RG] --name [YOUR-VM]
   ```

3. **Use Azure $100 credit**
   - Lasts 8-10 months with B1s

## 🔐 Security Notes

1. **Network Security Group Rules**
   - SSH (22): Your IP only
   - HTTP (80): Public
   - HTTPS (443): Public (if using SSL)
   - App (8080): Consider restricting

2. **Keep Updated**
   ```bash
   # Update packages regularly
   sudo apt update && sudo apt upgrade -y
   
   # Update Docker images
   docker-compose pull
   ```

3. **Backup Database**
   ```bash
   # Export database
   docker exec postgres-db pg_dump -U agriculture_user smart_agriculture_nutrition > backup.sql
   
   # Import database
   docker exec -i postgres-db psql -U agriculture_user smart_agriculture_nutrition < backup.sql
   ```

## 📝 Scripts Reference

### Essential Scripts
- `azure-deploy.sh` - Initial full deployment with all fixes + API key prompts
- `azure-quick-deploy.sh` - Quick updates after code changes

### Optional Scripts (in archive/)
- `azure-duckdns-setup.sh` - Sets up DuckDNS domain with HTTPS (includes all Nginx fixes)
- `final-fix.sh` - Standalone fix script (now integrated into azure-deploy.sh)

## ❓ FAQ

**Q: Application not accessible after deployment?**
A: The azure-deploy.sh script includes all fixes. Clear browser cache and try again.

**Q: CORS errors in Swagger UI?**
A: Clear browser cache completely. The deployment script already includes CORS fixes.

**Q: How to update after code changes?**
A: Push to GitHub, then run `./scripts/azure-quick-deploy.sh` on VM.

**Q: Database data lost after update?**
A: Data persists in Docker volumes. Only lost if you run `docker volume prune`.

**Q: HTTPS not working?**
A: Ensure port 443 is open in NSG, then run `./scripts/archive/azure-duckdns-setup.sh`.

## 🆘 Support

For issues, check:
1. Application logs: `sudo docker-compose logs app`
2. Nginx logs: `sudo tail -f /var/log/nginx/error.log`
3. Docker status: `sudo docker ps`

---

**Note:** The azure-deploy.sh script now includes:
- All CORS, Swagger, and routing fixes
- Interactive API key configuration
- Docker Compose 'ContainerConfig' error fixes
- Nginx syntax error fixes
- Auto-start service setup
