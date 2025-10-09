# 🚂 Railway Deployment Guide for Smart Agriculture Nutrition

This guide provides step-by-step instructions for deploying the Smart Agriculture Nutrition API to Railway.

## 📋 Prerequisites

- GitHub account with your project repository
- Railway account (sign up at [railway.app](https://railway.app))
- Your API keys for WeatherAPI.com and USDA FoodData Central

## 🚀 Quick Deployment Steps

### Step 1: Prepare Your Repository

Ensure your GitHub repository includes all the Railway configuration files:
- ✅ `railway.json` - Railway deployment configuration
- ✅ `railway.toml` - Alternative configuration format
- ✅ `Dockerfile` - Container configuration
- ✅ Updated `DatabaseConfig.java` with Railway environment variable support

### Step 2: Deploy to Railway

#### Option A: Deploy via GitHub (Recommended)

1. **Login to Railway**
   ```
   https://railway.app/login
   ```

2. **Create New Project**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Authorize Railway to access your GitHub account
   - Select your `Smart-Agriculture-Nutrition` repository

3. **Add PostgreSQL Database**
   - In your Railway project, click "New Service"
   - Select "Database" → "Add PostgreSQL"
   - Railway automatically provisions the database and sets environment variables

4. **Configure Environment Variables**
   - Click on your app service
   - Go to "Variables" tab
   - Add the following variables:
   ```
   WEATHER_API_KEY=your_actual_weather_api_key
   USDA_API_KEY=your_actual_usda_api_key
   PORT=8080
   ```

5. **Deploy**
   - Railway automatically builds and deploys your application
   - Monitor the deployment logs in the Railway dashboard

#### Option B: Deploy via Railway CLI

1. **Install Railway CLI**
   ```bash
   npm install -g @railway/cli
   ```

2. **Login to Railway**
   ```bash
   railway login
   ```

3. **Initialize Project**
   ```bash
   railway init
   ```

4. **Add PostgreSQL**
   ```bash
   railway add postgresql
   ```

5. **Deploy**
   ```bash
   railway up
   ```

### Step 3: Initialize Database

After deployment, initialize your database with schema and sample data:

#### Option A: Using Railway CLI
```bash
# Connect to Railway shell
railway run bash

# Run initialization script
chmod +x scripts/railway-init.sh
./scripts/railway-init.sh
```

#### Option B: Manual Database Setup
```bash
# Get your DATABASE_URL from Railway dashboard
export DATABASE_URL="postgresql://..."

# Run schema initialization
psql $DATABASE_URL < database/init.sql

# Load sample data
psql $DATABASE_URL < src/main/resources/db/migration/sample_data.sql
```

### Step 4: Verify Deployment

Your API should now be accessible at:
```
https://[your-app-name].up.railway.app/SmartAgricultureNutrition/api/v1/
```

Test endpoints:
- **Health Check**: `https://[your-app-name].up.railway.app/SmartAgricultureNutrition/api/v1/crop-nutrition-profiles`
- **Swagger UI**: `https://[your-app-name].up.railway.app/SmartAgricultureNutrition/api/v1/swagger-ui`
- **OpenAPI Spec**: `https://[your-app-name].up.railway.app/SmartAgricultureNutrition/api/v1/openapi.json`

## 🔧 Configuration Details

### Railway Environment Variables

Railway automatically provides these PostgreSQL variables:
- `DATABASE_URL` - Full connection string
- `PGHOST` - Database host
- `PGPORT` - Database port (5432)
- `PGDATABASE` - Database name
- `PGUSER` - Database username
- `PGPASSWORD` - Database password

### Application Configuration

The application automatically detects and uses Railway's environment variables through the updated `DatabaseConfig.java`:

1. **Primary**: Checks for `DATABASE_URL`
2. **Secondary**: Falls back to individual `PG*` variables
3. **Tertiary**: Uses standard `DB_*` variables
4. **Default**: Falls back to localhost configuration

### Health Check Configuration

Railway uses the health check endpoint configured in `railway.json`:
```json
{
  "deploy": {
    "healthcheckPath": "/SmartAgricultureNutrition/api/v1/crop-nutrition-profiles",
    "healthcheckTimeout": 300
  }
}
```

## 📊 Monitoring & Logs

### View Application Logs
```bash
# Using Railway CLI
railway logs

# Or view in Railway dashboard
# Project → Service → Logs tab
```

### Database Management

Access your PostgreSQL database:
```bash
# Connect via Railway CLI
railway connect postgresql

# Or get connection string
railway variables
```

## 🔄 Continuous Deployment

Railway automatically deploys when you push to your GitHub repository:

1. **Push changes to GitHub**
   ```bash
   git add .
   git commit -m "Update application"
   git push origin main
   ```

2. **Railway auto-deploys**
   - Monitors your repository
   - Builds new Docker image
   - Deploys with zero downtime

## 🛠️ Troubleshooting

### Common Issues and Solutions

#### 1. Database Connection Failed
**Problem**: Application can't connect to PostgreSQL
**Solution**: 
- Verify DATABASE_URL is set in Railway variables
- Check if PostgreSQL service is running
- Ensure database initialization completed

#### 2. Port Binding Error
**Problem**: Application fails to bind to port
**Solution**:
- Ensure PORT environment variable is set to 8080
- Check Dockerfile EXPOSE directive

#### 3. Build Failures
**Problem**: Docker build fails
**Solution**:
- Check build logs in Railway dashboard
- Verify all dependencies in pom.xml
- Ensure Dockerfile syntax is correct

#### 4. API Keys Not Working
**Problem**: External API calls failing
**Solution**:
- Verify WEATHER_API_KEY and USDA_API_KEY are set
- Check API key validity
- Monitor application logs for specific errors

### Debug Commands

```bash
# Check environment variables
railway variables

# View deployment status
railway status

# Connect to service shell
railway run bash

# Test database connection
railway run psql $DATABASE_URL -c "SELECT 1;"

# View recent logs
railway logs --tail 100
```

## 📈 Scaling & Performance

### Scaling Options

1. **Vertical Scaling**
   - Upgrade to higher Railway plan
   - Increases CPU and memory limits

2. **Horizontal Scaling**
   - Modify `railway.json`:
   ```json
   {
     "deploy": {
       "numReplicas": 3
     }
   }
   ```

3. **Database Optimization**
   - Use connection pooling (already configured)
   - Add database indices for frequently queried fields
   - Monitor slow queries

### Performance Monitoring

- Use Railway's built-in metrics dashboard
- Monitor response times
- Track database query performance
- Set up alerts for high resource usage

## 🔐 Security Best Practices

1. **Never commit sensitive data**
   - Use environment variables for all secrets
   - Keep `.env` files out of version control

2. **Use Railway's private networking**
   - Database connections use internal network
   - Not exposed to public internet

3. **Regular updates**
   - Keep dependencies updated
   - Monitor security advisories
   - Use Railway's automatic security updates

4. **API Security**
   - Consider adding API key authentication
   - Implement rate limiting
   - Use HTTPS (automatically provided by Railway)

## 📚 Additional Resources

- [Railway Documentation](https://docs.railway.app)
- [Railway CLI Reference](https://docs.railway.app/develop/cli)
- [PostgreSQL on Railway](https://docs.railway.app/databases/postgresql)
- [Environment Variables](https://docs.railway.app/develop/variables)
- [Deployment Triggers](https://docs.railway.app/deploy/deployments)

## 💡 Tips for Production

1. **Set up monitoring alerts** for downtime
2. **Configure automatic backups** for PostgreSQL
3. **Use custom domain** for professional appearance
4. **Enable auto-scaling** for traffic spikes
5. **Set up staging environment** for testing

## 🆘 Support

- **Railway Support**: [railway.app/help](https://railway.app/help)
- **Community Discord**: [discord.gg/railway](https://discord.gg/railway)
- **Project Issues**: Open issue on GitHub repository

---

## ✅ Deployment Checklist

- [ ] GitHub repository prepared with Railway configs
- [ ] Railway account created
- [ ] Project created in Railway
- [ ] PostgreSQL database added
- [ ] Environment variables configured
- [ ] Application deployed successfully
- [ ] Database initialized with schema
- [ ] Sample data loaded
- [ ] API endpoints tested
- [ ] Swagger UI accessible
- [ ] Monitoring configured
- [ ] Custom domain setup (optional)

---

**Last Updated**: January 2025
**Deployment Time**: ~5-10 minutes
**Cost**: Free tier available, paid plans for production
