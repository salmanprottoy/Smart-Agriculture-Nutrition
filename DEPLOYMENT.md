# Smart Agriculture Nutrition - Docker Deployment Guide

## 🚀 Complete Docker Deployment

This guide explains how to run the entire Smart Agriculture Nutrition application stack using Docker.

## 📋 Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 4GB RAM available
- Ports 80, 443, 5432, 5050, 8080, 8081 available

## 🏗️ Architecture Overview

The complete stack includes:
- **Java Application** (Tomcat + REST API)
- **PostgreSQL Database** (with sample data)
- **Nginx Reverse Proxy** (load balancing, SSL termination)
- **pgAdmin** (database management)
- **Adminer** (lightweight database access)

## 🔧 Configuration Files

### Local Development (Database Only)
```bash
# Use docker-compose.yml for local development
# Runs only PostgreSQL, pgAdmin, and Adminer
docker-compose up -d
```

### Full Production Stack
```bash
# Use docker-compose.prod.yml for complete deployment
# Runs all services including Java app and nginx
docker-compose -f docker-compose.prod.yml up -d
```

## 🚀 Quick Start - Full Stack Deployment

### 1. Clone and Navigate
```bash
git clone https://github.com/salmanprottoy/Smart-Agriculture-Nutrition.git
cd Smart-Agriculture-Nutrition
```

### 2. Set Environment Variables (Optional)
```bash
# Copy environment template
cp .env.example .env

# Edit .env file with your API keys
WEATHER_API_KEY=your_weather_api_key_here
USDA_API_KEY=your_usda_api_key_here
```

### 3. Build and Start All Services
```bash
# Build and start the complete stack
docker-compose -f docker-compose.prod.yml up -d --build
```

### 4. Monitor Startup
```bash
# Watch logs for all services
docker-compose -f docker-compose.prod.yml logs -f

# Check service health
docker-compose -f docker-compose.prod.yml ps
```

## 🌐 Access Points

Once deployed, access the application at:

| Service        | URL                                                   | Description                                            |
| -------------- | ----------------------------------------------------- | ------------------------------------------------------ |
| **Main API**   | http://localhost                                      | Landing page with API links                            |
| **Swagger UI** | http://localhost/SmartAgricultureNutrition/swagger-ui | Interactive API documentation                          |
| **REST API**   | http://localhost/SmartAgricultureNutrition/api/v1/    | Direct API access                                      |
| **pgAdmin**    | http://localhost:5050                                 | Database management (admin@agriculture.com / admin123) |
| **Adminer**    | http://localhost:8081                                 | Lightweight DB access                                  |
| **Direct App** | http://localhost:8080                                 | Direct access to Java application                      |

## 📊 Service Details

### Java Application Service
- **Container**: `smart-agriculture-app`
- **Port**: 8080
- **Health Check**: `/SmartAgricultureNutrition/api/v1/crops`
- **Build**: Multi-stage Maven build with Tomcat runtime

### Nginx Reverse Proxy
- **Container**: `smart-agriculture-nginx`
- **Ports**: 80 (HTTP), 443 (HTTPS ready)
- **Features**: Rate limiting, CORS, compression, caching
- **Config**: `nginx/nginx.conf`

### PostgreSQL Database
- **Container**: `smart-agriculture-db`
- **Port**: 5432
- **Database**: `smart_agriculture_nutrition`
- **User**: `agriculture_user`
- **Password**: `nutrition_pass_2024`
- **Sample Data**: 97 records loaded automatically

### Database Management
- **pgAdmin**: Full-featured web interface
- **Adminer**: Lightweight alternative
- **Direct Connection**: Host: localhost, Port: 5432

## 🔍 Health Monitoring

### Check Service Status
```bash
# View all service status
docker-compose -f docker-compose.prod.yml ps

# Check specific service logs
docker-compose -f docker-compose.prod.yml logs app
docker-compose -f docker-compose.prod.yml logs nginx
docker-compose -f docker-compose.prod.yml logs postgres
```

### Health Check Endpoints
```bash
# Nginx health check
curl http://localhost/health

# Application health check
curl http://localhost:8080/SmartAgricultureNutrition/api/v1/crops

# Database health check
docker-compose -f docker-compose.prod.yml exec postgres pg_isready -U agriculture_user
```

## 🛠️ Development Workflow

### Local Development (Database Only)
```bash
# Start only database services
docker-compose up -d

# Run Java application locally
mvn clean package
# Deploy to local Tomcat or run with embedded server
```

### Full Stack Development
```bash
# Start complete stack
docker-compose -f docker-compose.prod.yml up -d --build

# Make code changes and rebuild
docker-compose -f docker-compose.prod.yml build app
docker-compose -f docker-compose.prod.yml up -d app
```

### Testing
```bash
# Run unit tests
mvn test

# Run integration tests
mvn verify

# Run load tests
mvn jmeter:jmeter -Dthreads=10 -Dduration=30
```

## 🔧 Troubleshooting

### Common Issues

#### Port Conflicts
```bash
# Check port usage
lsof -i :80
lsof -i :8080
lsof -i :5432

# Stop conflicting services
sudo systemctl stop nginx  # If system nginx is running
sudo systemctl stop postgresql  # If system postgres is running
```

#### Build Failures
```bash
# Clean Docker cache
docker system prune -a

# Rebuild without cache
docker-compose -f docker-compose.prod.yml build --no-cache
```

#### Database Connection Issues
```bash
# Check database logs
docker-compose -f docker-compose.prod.yml logs postgres

# Connect to database directly
docker-compose -f docker-compose.prod.yml exec postgres psql -U agriculture_user -d smart_agriculture_nutrition
```

#### Application Startup Issues
```bash
# Check application logs
docker-compose -f docker-compose.prod.yml logs app

# Check Java application health
curl -v http://localhost:8080/SmartAgricultureNutrition/api/v1/crops
```

### Performance Tuning

#### Java Application
```bash
# Increase memory limits in docker-compose.prod.yml
environment:
  - CATALINA_OPTS=-Xmx1024m -Xms512m
```

#### Database
```bash
# Tune PostgreSQL settings
# Edit postgresql.conf in container or mount custom config
```

#### Nginx
```bash
# Adjust worker processes and connections in nginx.conf
worker_processes auto;
worker_connections 2048;
```

## 🔒 Security Considerations

### Production Deployment
1. **Change default passwords** in docker-compose.prod.yml
2. **Use environment variables** for sensitive data
3. **Enable HTTPS** by adding SSL certificates to nginx
4. **Restrict database access** to application network only
5. **Update base images** regularly for security patches

### SSL/HTTPS Setup
```bash
# Add SSL certificates to nginx/ssl/
# Update nginx.conf with SSL configuration
# Redirect HTTP to HTTPS
```

## 📈 Scaling

### Horizontal Scaling
```bash
# Scale application instances
docker-compose -f docker-compose.prod.yml up -d --scale app=3

# Update nginx upstream configuration for load balancing
```

### Resource Limits
```yaml
# Add resource limits to docker-compose.prod.yml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
        reservations:
          cpus: '1.0'
          memory: 512M
```

## 🧹 Cleanup

### Stop Services
```bash
# Stop all services
docker-compose -f docker-compose.prod.yml down

# Stop and remove volumes (WARNING: deletes data)
docker-compose -f docker-compose.prod.yml down -v
```

### Complete Cleanup
```bash
# Remove all containers, networks, and images
docker-compose -f docker-compose.prod.yml down --rmi all -v
docker system prune -a
```

## 📞 Support

For issues and questions:
- **GitHub Issues**: https://github.com/salmanprottoy/Smart-Agriculture-Nutrition/issues
- **Documentation**: Check PROJECT_DOCUMENTATION.md
- **API Documentation**: Access Swagger UI at http://localhost/SmartAgricultureNutrition/swagger-ui

---

**Developed by**: Md. Salman Hossan Prottoy, Elham Pournouri, Md Ariful Islam, Jakub Formánek  
**University of Jyväskylä** - TIES 4560 Service-Oriented Architecture and Cloud Computing
