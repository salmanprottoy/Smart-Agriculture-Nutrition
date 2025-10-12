# 🌱 Smart Agriculture Nutrition - AWS Deployment

> **From Farm to Fork to Fitness** - A comprehensive REST API connecting smart agriculture data with personal nutrition tracking, deployed on AWS EC2.

[![Java](https://img.shields.io/badge/Java-17-orange.svg)](https://openjdk.java.net/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://docs.docker.com/compose/)
[![AWS](https://img.shields.io/badge/AWS-EC2-orange.svg)](https://aws.amazon.com/ec2/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://www.postgresql.org/)

## 🚀 AWS EC2 Deployment

### Prerequisites
- AWS Account with EC2 access
- SSH key pair (.pem file)
- EC2 instance (Ubuntu 22.04 LTS recommended)

### 🎯 Quick Deployment

#### 1. Connect to Your EC2 Instance
```bash
ssh -i ~/Documents/your-key.pem ubuntu@your-ec2-ip
```

#### 2. Run Deployment Script
```bash
# Download and run the deployment script
curl -O https://raw.githubusercontent.com/salmanprottoy/Smart-Agriculture-Nutrition/main/scripts/deploy.sh
chmod +x deploy.sh
./deploy.sh
```

#### 3. Access Your Application
- **API Base**: `http://your-ec2-ip/SmartAgricultureNutrition/api/v1/`
- **Swagger UI**: `http://your-ec2-ip/SmartAgricultureNutrition/api/v1/swagger`
- **Port 80**: Mapped to internal port 8080 via Docker

### 📋 EC2 Security Group Settings
Ensure these ports are open in your Security Group:
- **Port 22**: SSH access
- **Port 80**: HTTP traffic
- **Port 8080**: Direct application access (optional)

## 🔄 Managing Your Deployment

### Update Application Code
```bash
# SSH into EC2
ssh -i ~/Documents/your-key.pem ubuntu@your-ec2-ip

# Navigate to project
cd ~/Smart-Agriculture-Nutrition

# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build

# Check status
docker-compose -f docker-compose.prod.yml ps
```

### View Logs
```bash
# All logs
docker-compose -f docker-compose.prod.yml logs -f

# Application logs only
docker-compose -f docker-compose.prod.yml logs app

# Database logs
docker-compose -f docker-compose.prod.yml logs postgres
```

### Stop/Start Services
```bash
# Stop all services
docker-compose -f docker-compose.prod.yml down

# Start all services
docker-compose -f docker-compose.prod.yml up -d

# Restart specific service
docker-compose -f docker-compose.prod.yml restart app
```

## 💰 Cost Management

### Stop EC2 Instance When Not in Use
1. **AWS Console**: EC2 → Instances → Select → Instance State → **Stop**
2. **Saves**: ~$17/month for t2.small
3. **Note**: IP will change unless using Elastic IP

### Restart After Stopping
1. **Start Instance**: AWS Console → EC2 → Start Instance
2. **Get New IP**: Check in AWS Console
3. **Restart App**:
```bash
ssh -i ~/Documents/your-key.pem ubuntu@new-ip
cd ~/Smart-Agriculture-Nutrition
docker-compose -f docker-compose.prod.yml up -d
```

## 🔌 VS Code Remote Development

### Connect VS Code to EC2
1. Install "Remote - SSH" extension in VS Code
2. Add to `~/.ssh/config`:
```ssh
Host smart-agriculture-ec2
    HostName YOUR_EC2_IP
    User ubuntu
    IdentityFile ~/Documents/your-key.pem
    Port 22
```
3. Connect: `Cmd+Shift+P` → "Remote-SSH: Connect to Host" → Select `smart-agriculture-ec2`

## 🐳 Docker Services

### Production Stack (`docker-compose.prod.yml`)
- **PostgreSQL**: Database on port 5432
- **Application**: Java app on ports 80 & 8080
- **Networks**: Internal Docker network for security
- **Volumes**: Persistent data storage

### Environment Variables (.env)
```bash
# Database
POSTGRES_DB=smart_agriculture_nutrition
POSTGRES_USER=agriculture_user
POSTGRES_PASSWORD=your_secure_password

# API Keys
WEATHER_API_KEY=your_weather_api_key
USDA_API_KEY=your_usda_api_key

# JWT
JWT_SECRET=your_secure_jwt_secret
```

## 📖 API Documentation

### Core Endpoints
- **Crop Profiles**: `/api/v1/crop-nutrition-profiles`
- **Nutrition Trackers**: `/api/v1/nutrition-trackers`
- **Weather Data**: `/api/v1/weather/current/{city}`
- **USDA Nutrition**: `/api/v1/nutrition/food/{foodName}`

### Interactive Documentation
Access Swagger UI at: `http://your-ec2-ip/SmartAgricultureNutrition/api/v1/swagger`

## 🛠️ Troubleshooting

### Docker Container Issues
```bash
# Clean and rebuild
docker-compose -f docker-compose.prod.yml down
docker system prune -a -f
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d
```

### Can't Access Application
1. Check Security Group allows port 80
2. Verify containers are running: `docker ps`
3. Check logs: `docker-compose -f docker-compose.prod.yml logs`

### After EC2 Restart
The IP changes after stop/start. Always:
1. Get new IP from AWS Console
2. SSH with new IP
3. Restart Docker containers

## 📁 Project Structure
```
SmartAgricultureNutrition/
├── docker-compose.prod.yml    # Production Docker config
├── Dockerfile                 # Application container
├── scripts/
│   └── deploy.sh             # Deployment script
├── src/                      # Java source code
├── database/                 # SQL schemas
└── .env                      # Environment variables (create on server)
```

## 📊 Quick Commands Reference

| Action            | Command                                                               |
| ----------------- | --------------------------------------------------------------------- |
| **SSH to EC2**    | `ssh -i ~/Documents/your-key.pem ubuntu@ec2-ip`                       |
| **Update Code**   | `git pull && docker-compose -f docker-compose.prod.yml up -d --build` |
| **View Logs**     | `docker-compose -f docker-compose.prod.yml logs -f`                   |
| **Stop Services** | `docker-compose -f docker-compose.prod.yml down`                      |
| **Check Status**  | `docker-compose -f docker-compose.prod.yml ps`                        |

## 📄 License

This project is licensed under the MIT License.

---

**Deployed on AWS EC2** | [GitHub Repository](https://github.com/salmanprottoy/Smart-Agriculture-Nutrition)
