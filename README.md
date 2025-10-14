# 🌱 Smart Agriculture Nutrition API

> **From Farm to Fork to Fitness** - A comprehensive REST API connecting smart agriculture data with personal nutrition tracking.

[![Java](https://img.shields.io/badge/Java-17-orange.svg)](https://openjdk.java.net/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://docs.docker.com/compose/)
[![AWS](https://img.shields.io/badge/AWS-EC2-orange.svg)](https://aws.amazon.com/ec2/)
[![Azure](https://img.shields.io/badge/Azure-VM-blue.svg)](https://azure.microsoft.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://www.postgresql.org/)

## 🌐 Live Demo

**Access the API:** http://smart-agriculture-nutrition.duckdns.org

- **Swagger UI:** http://smart-agriculture-nutrition.duckdns.org/SmartAgricultureNutrition/api/v1/swagger
- **API Base:** http://smart-agriculture-nutrition.duckdns.org/SmartAgricultureNutrition/api/v1/

## 🚀 Quick Start

### Local Development

```bash
# Clone repository
git clone https://github.com/salmanprottoy/Smart-Agriculture-Nutrition.git
cd Smart-Agriculture-Nutrition

# Start with Docker Compose
docker-compose up -d --build

# Access locally
open http://localhost/SmartAgricultureNutrition/api/v1/swagger
```

### Production Deployment

#### AWS EC2
```bash
# SSH to EC2
ssh -i your-key.pem ubuntu@ec2-ip

# Clone and deploy
git clone https://github.com/salmanprottoy/Smart-Agriculture-Nutrition.git
cd Smart-Agriculture-Nutrition
./scripts/aws-deploy.sh

# For updates
./scripts/aws-quick-deploy.sh
```

#### Azure VM
```bash
# SSH to Azure VM
ssh -i azure-key.pem azureuser@vm-ip

# Clone and deploy (includes all fixes)
git clone https://github.com/salmanprottoy/Smart-Agriculture-Nutrition.git
cd SmartAgricultureNutrition
./scripts/azure-deploy.sh

# For updates after code changes
./scripts/azure-quick-deploy.sh
```

## 📖 API Endpoints

### Core Resources

| Resource               | Endpoint                            | Description                      |
| ---------------------- | ----------------------------------- | -------------------------------- |
| **Crop Profiles**      | `/api/v1/crop-nutrition-profiles`   | Agricultural crop nutrition data |
| **Nutrition Trackers** | `/api/v1/nutrition-trackers`        | Personal nutrition tracking      |
| **Weather**            | `/api/v1/weather/current/{city}`    | Real-time weather data           |
| **USDA Nutrition**     | `/api/v1/nutrition/food/{foodName}` | Food nutrition database          |

### Authentication

```bash
# Register
curl -X POST http://localhost/SmartAgricultureNutrition/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"Test123!","email":"test@test.com"}'

# Login (returns JWT token)
curl -X POST http://localhost/SmartAgricultureNutrition/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"Test123!"}'

# Use token
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost/SmartAgricultureNutrition/api/v1/crop-nutrition-profiles
```

## 🏗️ Architecture

### Technology Stack
- **Backend:** Java 17, JAX-RS, Jersey
- **Database:** PostgreSQL 15
- **Containerization:** Docker & Docker Compose
- **Documentation:** OpenAPI 3.0, Swagger UI
- **Cloud:** AWS EC2, Azure VM
- **Domain:** DuckDNS (Dynamic DNS)
- **SSL/TLS:** Let's Encrypt (Free HTTPS)

### Project Structure
```
SmartAgricultureNutrition/
├── src/                    # Java source code
├── docker-compose.yml      # Development setup
├── docker-compose.prod.yml # Production setup
├── Dockerfile             # Optimized multi-stage build
├── scripts/
│   ├── deploy.sh          # Initial deployment
│   ├── redeploy.sh        # Full redeployment
│   └── quick-redeploy.sh  # Quick updates
└── database/              # SQL schemas
```

## 🔧 Configuration

### Environment Variables (.env)
```env
# Database
POSTGRES_DB=smart_agriculture_nutrition
POSTGRES_USER=agriculture_user
POSTGRES_PASSWORD=your_secure_password

# API Keys (optional)
WEATHER_API_KEY=your_weather_api_key
USDA_API_KEY=your_usda_api_key

# Security
JWT_SECRET=your_secure_jwt_secret
```

## 🚀 Deployment Guide

### AWS EC2 Setup

1. **Launch EC2 Instance**
   - Ubuntu 22.04 LTS
   - t2.small or larger
   - Security Group: Open ports 22, 80, 8080

2. **Initial Deployment**
   ```bash
   ssh -i your-key.pem ubuntu@ec2-ip
   git clone https://github.com/salmanprottoy/Smart-Agriculture-Nutrition.git
   cd Smart-Agriculture-Nutrition
   ./scripts/aws-deploy.sh
   ```

### Azure VM Setup - Step by Step

#### Step 1: Create Azure VM
1. **Login to Azure Portal** (https://portal.azure.com)
2. **Create a Virtual Machine:**
   - Click "Create a resource" → "Virtual Machine"
   - **Basics:**
     - Resource Group: Create new or use existing
     - VM Name: `SmartAgricultureVM`
     - Region: Choose nearest to you
     - Image: `Ubuntu Server 22.04 LTS`
     - Size: `Standard B1s` (1 vCPU, 1GB RAM) - ~$10-12/month
     - Authentication: SSH public key (recommended)
   - **Networking:**
     - Create new Virtual Network (default is fine)
     - Public IP: Yes (Basic)
   - **Review + Create** → Click "Create"

3. **Configure Network Security Group (NSG):**
   - Go to VM → Networking → Add inbound port rule
   - Add these ports:
     - SSH (22) - Source: Your IP only
     - HTTP (80) - Source: Any
     - HTTPS (443) - Source: Any
     - App (8080) - Source: Any

#### Step 2: Connect to VM
```bash
# Download the private key from Azure Portal
# Set correct permissions
chmod 400 your-key.pem

# Connect via SSH
ssh -i your-key.pem azureuser@YOUR_VM_PUBLIC_IP
```

#### Step 3: Deploy Application
```bash
# Clone the repository
git clone https://github.com/salmanprottoy/Smart-Agriculture-Nutrition.git
cd SmartAgricultureNutrition

# Run the deployment script (includes all fixes)
chmod +x scripts/azure-deploy.sh
./scripts/azure-deploy.sh

# The script will:
# - Install Docker and Docker Compose
# - Install Nginx
# - Configure CORS and URL rewriting
# - Start the application
# - Set up auto-start on reboot
```

#### Step 4: Verify Deployment
After deployment completes, access your application:
- **Swagger UI:** `http://YOUR_VM_PUBLIC_IP/api/v1/swagger`
- **API Base:** `http://YOUR_VM_PUBLIC_IP/api/v1/`

#### Step 5: Setup Custom Domain (Optional)
```bash
# Run DuckDNS setup for free domain + HTTPS
./scripts/archive/azure-duckdns-setup.sh

# You'll need:
# 1. DuckDNS account (free at duckdns.org)
# 2. Choose subdomain
# 3. Enter your DuckDNS token
# 4. Optionally enable HTTPS with Let's Encrypt
```

After DuckDNS setup:
- **HTTPS:** `https://your-domain.duckdns.org/api/v1/swagger`
- **HTTP:** `http://your-domain.duckdns.org/api/v1/swagger`

#### Step 6: Configure API Keys
```bash
# Edit the .env file
nano ~/SmartAgricultureNutrition/.env

# Add your actual API keys:
# - WEATHER_API_KEY
# - USDA_API_KEY

# Restart application
cd ~/SmartAgricultureNutrition
sudo docker-compose -f docker-compose.azure.yml restart
```

### Updating Code (After Changes)

#### AWS EC2
```bash
# On local machine
git add . && git commit -m "Update" && git push

# On EC2
cd ~/Smart-Agriculture-Nutrition
git pull origin main
./scripts/aws-quick-deploy.sh
```

#### Azure VM
```bash
# On local machine
git add . && git commit -m "Update" && git push

# On Azure VM
cd ~/SmartAgricultureNutrition
git pull origin main
./scripts/azure-quick-deploy.sh
```

### Complete Redeployment (If Starting Fresh)

#### Azure VM - From Scratch
```bash
# 1. SSH to VM
ssh -i azure-key.pem azureuser@vm-ip

# 2. Clean everything (optional)
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker system prune -af

# 3. Clone fresh code
rm -rf SmartAgricultureNutrition
git clone https://github.com/salmanprottoy/Smart-Agriculture-Nutrition.git
cd SmartAgricultureNutrition

# 4. Deploy (includes all fixes)
./scripts/azure-deploy.sh

# 5. Setup DuckDNS (optional)
./scripts/archive/azure-duckdns-setup.sh
```

**Note:** Database data persists across redeployments!

## 📊 Features

- ✅ **RESTful API** with HATEOAS navigation
- ✅ **JWT Authentication** for security
- ✅ **Swagger UI** for interactive documentation
- ✅ **Docker Containerization** for easy deployment
- ✅ **PostgreSQL Database** with persistent storage
- ✅ **External API Integration** (Weather, USDA)
- ✅ **CORS Support** for web clients
- ✅ **Health Checks** for monitoring
- ✅ **Optimized Docker Images** (multi-stage build)

## 🧪 Testing

```bash
# Run unit tests
mvn test

# Test with curl
curl http://localhost/SmartAgricultureNutrition/api/v1/crop-nutrition-profiles

# Load testing with JMeter
mvn jmeter:jmeter
```

## 💰 Cost Management

**AWS EC2 Costs:**
- Running: ~$19/month (t2.small)
- Stopped: ~$2/month (storage only)

**Azure VM Costs:**
- Running: ~$10-12/month (B1s)
- Stopped: ~$1/month (storage only)
- **$100 credit**: Lasts 8-10 months

**Save money:** Stop instances when not in use via cloud console

## 📝 Documentation

- **API Documentation:** [Swagger UI](http://smart-agriculture-nutrition.duckdns.org/SmartAgricultureNutrition/api/v1/swagger)
- **AWS Deployment:** [AWS_EC2_DEPLOYMENT.md](AWS_EC2_DEPLOYMENT.md)
- **Azure Deployment:** [AZURE_VM_DEPLOYMENT.md](AZURE_VM_DEPLOYMENT.md)
- **Azure Quick Start:** [AZURE_QUICK_START.md](AZURE_QUICK_START.md)
- **Management Guide:** [EC2_MANAGEMENT_GUIDE.md](EC2_MANAGEMENT_GUIDE.md)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file.

## 👨‍💻 Author

**Md. Salman Hossan Prottoy**
- GitHub: [@salmanprottoy](https://github.com/salmanprottoy)

---

**Live Demo:** http://smart-agriculture-nutrition.duckdns.org
