# Deployment Scripts

This directory contains essential deployment scripts for AWS and Azure cloud platforms.

## 🚀 Main Deployment Scripts

### AWS Deployment
- **`aws-deploy.sh`** - Full AWS EC2 deployment with Docker setup
- **`aws-quick-deploy.sh`** - Quick redeploy for AWS (updates only)
- **`aws-redeploy.sh`** - Complete AWS redeployment with cleanup

### Azure Deployment  
- **`azure-deploy.sh`** - Full Azure VM deployment with Docker setup
- **`azure-quick-deploy.sh`** - Quick fix and redeploy for Azure (handles Docker issues)

## 📋 Usage

### AWS EC2 Deployment
```bash
# Initial deployment
./scripts/aws-deploy.sh

# Quick update
./scripts/aws-quick-deploy.sh

# Full redeploy
./scripts/aws-redeploy.sh
```

### Azure VM Deployment
```bash
# Initial deployment (after creating VM in Azure Portal)
./scripts/azure-deploy.sh

# Fix issues and redeploy
./scripts/azure-quick-deploy.sh
```

## 📁 Archive Directory

The `archive/` directory contains additional utility scripts that may be useful but are not essential for basic deployment:
- Azure monitoring tools
- DuckDNS setup
- Nginx configuration fixes
- Advanced Azure CLI automation

## 🔧 Prerequisites

### For AWS
- AWS EC2 instance (Ubuntu 22.04)
- SSH access to the instance
- Git installed

### For Azure
- Azure VM (Ubuntu 22.04, B1s recommended)
- SSH access to the VM
- Git installed

## 💡 Tips

1. **AWS**: Use `aws-quick-deploy.sh` for fast updates without rebuilding Docker images
2. **Azure**: Use `azure-quick-deploy.sh` if you encounter Docker container issues
3. Both platforms support the same application, just with platform-specific optimizations

## 📚 Documentation

- [AWS EC2 Deployment Guide](../AWS_EC2_DEPLOYMENT.md)
- [Azure VM Deployment Guide](../AZURE_VM_DEPLOYMENT.md)
- [Azure Quick Start](../AZURE_QUICK_START.md)
