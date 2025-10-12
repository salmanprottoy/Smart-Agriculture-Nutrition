# 🌱 Smart Agriculture Nutrition API

> **From Farm to Fork to Fitness** - A comprehensive REST API connecting smart agriculture data with personal nutrition tracking.

[![Java](https://img.shields.io/badge/Java-17-orange.svg)](https://openjdk.java.net/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://docs.docker.com/compose/)
[![AWS](https://img.shields.io/badge/AWS-EC2-orange.svg)](https://aws.amazon.com/ec2/)
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

### Production Deployment (AWS EC2)

```bash
# SSH to EC2
ssh -i your-key.pem ubuntu@ec2-ip

# Clone and deploy
git clone https://github.com/salmanprottoy/Smart-Agriculture-Nutrition.git
cd Smart-Agriculture-Nutrition
./scripts/deploy.sh

# For updates
./scripts/quick-redeploy.sh
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
- **Cloud:** AWS EC2
- **Domain:** DuckDNS (Dynamic DNS)

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
   curl -O https://raw.githubusercontent.com/salmanprottoy/Smart-Agriculture-Nutrition/main/scripts/deploy.sh
   chmod +x deploy.sh
   ./deploy.sh
   ```

3. **Setup DuckDNS (Free Domain)**
   - Register at https://www.duckdns.org
   - Create subdomain
   - Run on EC2:
   ```bash
   # Replace with your token
   TOKEN="your-duckdns-token"
   echo "curl -s 'https://www.duckdns.org/update?domains=your-domain&token=$TOKEN&ip=\$(curl -s ifconfig.me)'" > ~/update-duckdns.sh
   chmod +x ~/update-duckdns.sh
   (crontab -l 2>/dev/null; echo "*/5 * * * * ~/update-duckdns.sh") | crontab -
   ```

### Updating Code

```bash
# On local machine
git add . && git commit -m "Update" && git push

# On EC2
cd ~/Smart-Agriculture-Nutrition
./scripts/quick-redeploy.sh
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

**Save money:** Stop instance when not in use via AWS Console

## 📝 Documentation

- **API Documentation:** [Swagger UI](http://smart-agriculture-nutrition.duckdns.org/SmartAgricultureNutrition/api/v1/swagger)
- **Deployment Guide:** [AWS_EC2_DEPLOYMENT.md](AWS_EC2_DEPLOYMENT.md)
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
