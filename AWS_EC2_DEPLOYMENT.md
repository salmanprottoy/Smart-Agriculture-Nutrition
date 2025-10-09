# AWS EC2 Deployment Guide for Smart Agriculture Nutrition API

## Prerequisites
- AWS Account with EC2 access
- AWS CLI configured (optional)
- SSH key pair for EC2 instance

## Step 1: Launch EC2 Instance

### Via AWS Console:
1. Go to EC2 Dashboard
2. Click "Launch Instance"
3. Configure:
   - **Name**: SmartAgricultureNutrition
   - **AMI**: Ubuntu Server 22.04 LTS (free tier eligible)
   - **Instance Type**: t2.micro (free tier) or t2.small (recommended)
   - **Key Pair**: Create new or use existing
   - **Network Settings**:
     - Allow SSH (port 22)
     - Allow HTTP (port 80)
     - Allow HTTPS (port 443)
     - Allow Custom TCP (port 8080)
   - **Storage**: 20 GB gp3 (or gp2)

### Security Group Rules:
```
Type         Protocol  Port Range  Source
SSH          TCP       22          Your IP
HTTP         TCP       80          0.0.0.0/0
HTTPS        TCP       443         0.0.0.0/0
Custom TCP   TCP       8080        0.0.0.0/0
PostgreSQL   TCP       5432        0.0.0.0/0 (if using external DB)
```

## Step 2: Connect to EC2 Instance

```bash
# Replace with your instance details
chmod 400 your-key.pem
ssh -i your-key.pem ubuntu@your-ec2-public-ip
```

## Step 3: Install Required Software

Run these commands on your EC2 instance:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Java 17
sudo apt install openjdk-17-jdk -y
java -version

# Install Docker
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose -y

# Install Git
sudo apt install git -y

# Install PostgreSQL client (for database management)
sudo apt install postgresql-client -y

# Install Nginx (for reverse proxy)
sudo apt install nginx -y
```

## Step 4: Clone and Setup Application

```bash
# Clone repository
cd ~
git clone https://github.com/salmanprottoy/Smart-Agriculture-Nutrition.git
cd Smart-Agriculture-Nutrition

# Create .env file with your actual values
cat > .env << 'EOF'
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=smart_agriculture_nutrition
DB_USERNAME=agriculture_user
DB_PASSWORD=your_secure_password_here

# API Keys
WEATHER_API_KEY=your_weather_api_key_here
USDA_API_KEY=your_usda_api_key_here

# JWT Secret
JWT_SECRET=your-super-secure-jwt-secret-key-2024

# Application
PORT=8080
APP_ENVIRONMENT=production
EOF
```

## Step 5: Setup PostgreSQL Database

### Option A: Use Docker PostgreSQL
```bash
# Run PostgreSQL in Docker
docker run -d \
  --name postgres-agriculture \
  -e POSTGRES_DB=smart_agriculture_nutrition \
  -e POSTGRES_USER=agriculture_user \
  -e POSTGRES_PASSWORD=your_secure_password_here \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql/data \
  --restart unless-stopped \
  postgres:15

# Wait for PostgreSQL to start
sleep 10

# Initialize database
docker exec -i postgres-agriculture psql -U agriculture_user -d smart_agriculture_nutrition < database/init.sql
```

### Option B: Use AWS RDS (Recommended for Production)
1. Create RDS PostgreSQL instance in AWS Console
2. Update .env with RDS endpoint

## Step 6: Build and Run Application

### Using Docker:
```bash
# Build the application
docker build -t smart-agriculture-api .

# Run the application
docker run -d \
  --name smart-agriculture \
  --env-file .env \
  -p 8080:8080 \
  --link postgres-agriculture:postgres \
  --restart unless-stopped \
  smart-agriculture-api
```

### Using Docker Compose:
```bash
# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f
```

## Step 7: Configure Nginx Reverse Proxy

```bash
# Create Nginx configuration
sudo nano /etc/nginx/sites-available/smart-agriculture

# Add this configuration:
```

```nginx
server {
    listen 80;
    server_name your-ec2-public-ip;  # Or your domain name

    location / {
        proxy_pass http://localhost:8080/SmartAgricultureNutrition/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Enable the site
sudo ln -s /etc/nginx/sites-available/smart-agriculture /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## Step 8: Access Your Application

Your API will be available at:
- **Direct**: `http://your-ec2-public-ip:8080/SmartAgricultureNutrition/api/v1/`
- **Via Nginx**: `http://your-ec2-public-ip/api/v1/`
- **Swagger UI**: `http://your-ec2-public-ip/api/v1/swagger-ui`

## Step 9: Setup Auto-start on Reboot

```bash
# Create systemd service
sudo nano /etc/systemd/system/smart-agriculture.service
```

Add:
```ini
[Unit]
Description=Smart Agriculture Nutrition API
After=docker.service
Requires=docker.service

[Service]
Type=simple
Restart=always
RestartSec=10
ExecStart=/usr/bin/docker start -a smart-agriculture
ExecStop=/usr/bin/docker stop smart-agriculture

[Install]
WantedBy=multi-user.target
```

```bash
# Enable service
sudo systemctl enable smart-agriculture.service
sudo systemctl start smart-agriculture.service
```

## Step 10: Setup SSL (Optional but Recommended)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Get SSL certificate (replace with your domain)
sudo certbot --nginx -d your-domain.com
```

## Monitoring and Maintenance

### Check Application Status:
```bash
# Check if container is running
docker ps

# View logs
docker logs smart-agriculture

# Check system resources
htop
df -h
```

### Update Application:
```bash
cd ~/Smart-Agriculture-Nutrition
git pull origin main
docker build -t smart-agriculture-api .
docker stop smart-agriculture
docker rm smart-agriculture
docker run -d --name smart-agriculture --env-file .env -p 8080:8080 --link postgres-agriculture:postgres --restart unless-stopped smart-agriculture-api
```

## Troubleshooting

### If application doesn't start:
```bash
# Check logs
docker logs smart-agriculture

# Check if port is in use
sudo netstat -tlnp | grep 8080

# Restart Docker
sudo systemctl restart docker
```

### Database connection issues:
```bash
# Test PostgreSQL connection
docker exec -it postgres-agriculture psql -U agriculture_user -d smart_agriculture_nutrition -c "SELECT 1;"

# Check PostgreSQL logs
docker logs postgres-agriculture
```

## Cost Optimization

- Use t2.micro for testing (free tier eligible)
- Use t3.small or t3.medium for production
- Consider using AWS RDS for database (automated backups)
- Use Elastic IP to maintain consistent public IP
- Set up CloudWatch alarms for monitoring

## Security Best Practices

1. **Never commit .env file to git**
2. **Use AWS Secrets Manager for production**
3. **Enable AWS CloudWatch logging**
4. **Regular security updates**: `sudo apt update && sudo apt upgrade`
5. **Use IAM roles instead of access keys when possible**
6. **Enable AWS GuardDuty for threat detection**
