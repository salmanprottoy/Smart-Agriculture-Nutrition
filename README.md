# 🌱 Smart Agriculture Nutrition

> **From Farm to Fork to Fitness** - A comprehensive REST API connecting smart agriculture data with personal nutrition tracking, creating a complete food-to-health ecosystem.

[![Java](https://img.shields.io/badge/Java-21-orange.svg)](https://openjdk.java.net/projects/jdk/21/)
[![Maven](https://img.shields.io/badge/Maven-3.6+-blue.svg)](https://maven.apache.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://docs.docker.com/compose/)
[![JAX-RS](https://img.shields.io/badge/JAX--RS-3.1-green.svg)](https://jakarta.ee/specifications/restful-ws/)
[![OpenAPI](https://img.shields.io/badge/OpenAPI-3.0-green.svg)](https://swagger.io/specification/)

## 🚀 Overview

The Smart Agriculture Nutrition bridges the gap between agricultural production and personal health outcomes. It integrates with smart farming platforms, weather services, and nutrition databases to provide comprehensive insights into the food-to-health journey.

### 🎯 Key Features

- **🌾 Crop Nutrition Profiles** - Track nutritional content from smart farms with sustainability scoring
- **👤 Personal Nutrition Tracking** - Monitor individual nutrition with BMI integration and health analytics
- **🌤️ Weather Integration** - Real-time weather data from WeatherAPI.com for agricultural analysis
- **🥗 USDA Nutrition Database** - Comprehensive food nutrition data from FoodData Central
- **📊 Advanced Analytics** - Weather-nutrition correlations and health pattern analysis
- **🔗 HATEOAS Navigation** - Fully navigable API with hypermedia links
- **📖 Interactive Documentation** - Swagger UI with "Try it out" functionality
- **🗄️ Visual Database Management** - pgAdmin and Adminer for data visualization

## 🏗️ Architecture

### REST API Design
- **2 Upper-level Resources**: Crop Nutrition Profiles, Personal Nutrition Trackers
- **4+ Nested Resources**: Harvest Batches, Meal Sources, Health Correlations, BMI Analysis
- **All HTTP Methods**: GET, POST, PUT, DELETE with proper status codes
- **JSON Format**: Consistent JSON responses with content negotiation
- **Query Parameters**: Advanced filtering, sorting, and pagination
- **Path Variables**: Dynamic routing with {id} parameters
- **Custom Exception Handling**: Specific error responses with meaningful messages

### Technology Stack
- **Backend**: Java 21, JAX-RS 3.1, Jersey
- **Database**: PostgreSQL 15 with JDBC
- **Documentation**: OpenAPI 3.0, Swagger UI
- **External APIs**: WeatherAPI.com, USDA FoodData Central
- **Testing**: JUnit 5, Testcontainers, JMeter
- **Deployment**: Docker Compose, Maven WAR packaging
- **Database Tools**: pgAdmin, Adminer

## 🚀 Quick Start

### Prerequisites
- Java 21 or higher
- Maven 3.6+
- Docker & Docker Compose
- Application Server (Tomcat, WildFly, etc.)

### 1. Clone/Extract Project
```bash
# Navigate to the project directory
cd SmartAgricultureNutrition
```

### 2. Start Database Services
```bash
# Start PostgreSQL, pgAdmin, and Adminer
docker-compose up -d

# Verify services are running
docker-compose ps
```

### 3. Populate Database with Sample Data
```bash
# Run the sample data migration (includes 97 comprehensive records)
docker exec -i smart-agriculture-db psql -U agriculture_user -d smart_agriculture_nutrition < "src/main/resources/db/migration/sample_data.sql"

# Verify data population
docker exec smart-agriculture-db psql -U agriculture_user -d smart_agriculture_nutrition -c "SELECT COUNT(*) FROM crop_nutrition_profiles; SELECT COUNT(*) FROM personal_nutrition_trackers; SELECT COUNT(*) FROM harvest_batches; SELECT COUNT(*) FROM meal_sources;"
```

**Expected Results:**
- 20 crop_nutrition_profiles
- 22 personal_nutrition_trackers  
- 21 harvest_batches
- 34 meal_sources

### 4. Build and Deploy Application
```bash
# Build the project
mvn clean package -Dmaven.test.skip=true

# Deploy to your application server (example for Eclipse/Tomcat)
# Copy target/SmartAgricultureNutrition.war to your server's webapps directory
# Or use your IDE's deployment features
```

### 5. Access the Application
- **Main Application**: `http://localhost:8080/SmartAgricultureNutrition/`
- **API Base URL**: `http://localhost:8080/SmartAgricultureNutrition/api/v1/`
- **Swagger UI**: `http://localhost:8080/SmartAgricultureNutrition/api/v1/swagger-ui`
- **OpenAPI Spec**: `http://localhost:8080/SmartAgricultureNutrition/api/v1/openapi.json`
- **pgAdmin**: `http://localhost:5050` (admin@agriculture.com / admin123)
- **Adminer**: `http://localhost:8081`

### 6. Test the API
```bash
# Test crop profiles endpoint
curl -s "http://localhost:8080/SmartAgricultureNutrition/api/v1/crop-nutrition-profiles" | jq 'length'
# Should return: 20

# Test nutrition trackers endpoint  
curl -s "http://localhost:8080/SmartAgricultureNutrition/api/v1/nutrition-trackers" | jq 'length'
# Should return: 22

# Test search functionality
curl -s "http://localhost:8080/SmartAgricultureNutrition/api/v1/crop-nutrition-profiles/search/region?region=Finland" | jq 'length'
# Should return: 20
```

## 📖 API Documentation

### Core Resources

#### 🌾 Crop Nutrition Profiles
```http
GET    /api/v1/crop-nutrition-profiles              # List all profiles
GET    /api/v1/crop-nutrition-profiles?crop_type=tomato&growing_method=organic
POST   /api/v1/crop-nutrition-profiles              # Create new profile
GET    /api/v1/crop-nutrition-profiles/{id}         # Get specific profile
PUT    /api/v1/crop-nutrition-profiles/{id}         # Update profile
DELETE /api/v1/crop-nutrition-profiles/{id}         # Delete profile

# Search Endpoints
GET    /api/v1/crop-nutrition-profiles/search/crop-type?cropType=tomato
GET    /api/v1/crop-nutrition-profiles/search/growing-method?method=organic
GET    /api/v1/crop-nutrition-profiles/search/region?region=Finland

# Nested Resources
GET    /api/v1/crop-nutrition-profiles/{id}/harvest-batches
POST   /api/v1/crop-nutrition-profiles/{id}/harvest-batches
GET    /api/v1/crop-nutrition-profiles/{id}/soil-impact
```

#### 👤 Personal Nutrition Trackers
```http
GET    /api/v1/nutrition-trackers                   # List all trackers
GET    /api/v1/nutrition-trackers?bmi_range=20-25&health_goal=Weight+Maintenance
POST   /api/v1/nutrition-trackers                   # Create new tracker
GET    /api/v1/nutrition-trackers/{id}              # Get specific tracker
PUT    /api/v1/nutrition-trackers/{id}              # Update tracker

# Nested Resources
GET    /api/v1/nutrition-trackers/{id}/meal-sources
POST   /api/v1/nutrition-trackers/{id}/meal-sources
GET    /api/v1/nutrition-trackers/{id}/health-correlations
GET    /api/v1/nutrition-trackers/{id}/bmi-analysis
```

#### 🌤️ External API Integrations
```http
GET    /api/v1/weather/current/{city}               # Real-time weather data
GET    /api/v1/nutrition/crop/{cropName}            # USDA nutrition data
GET    /api/v1/correlations/crop-weather-nutrition/{city}/{crop}  # Advanced analytics
```

### Sample API Calls
Try these endpoints to explore the API:
- [View all crop profiles](http://localhost:8080/SmartAgricultureNutrition/api/v1/crop-nutrition-profiles)
- [View specific crop with HATEOAS](http://localhost:8080/SmartAgricultureNutrition/api/v1/crop-nutrition-profiles/1)
- [Search by crop type](http://localhost:8080/SmartAgricultureNutrition/api/v1/crop-nutrition-profiles/search/crop-type?cropType=tomato)
- [Search by growing method](http://localhost:8080/SmartAgricultureNutrition/api/v1/crop-nutrition-profiles/search/growing-method?method=organic)
- [Search by region](http://localhost:8080/SmartAgricultureNutrition/api/v1/crop-nutrition-profiles/search/region?region=Finland)
- [View harvest batches](http://localhost:8080/SmartAgricultureNutrition/api/v1/crop-nutrition-profiles/1/harvest-batches)
- [Soil impact analysis](http://localhost:8080/SmartAgricultureNutrition/api/v1/crop-nutrition-profiles/1/soil-impact)
- [View nutrition trackers](http://localhost:8080/SmartAgricultureNutrition/api/v1/nutrition-trackers)
- [BMI analysis](http://localhost:8080/SmartAgricultureNutrition/api/v1/nutrition-trackers/1/bmi-analysis)

## 🗄️ Database Management

### Visual Database Tools

#### pgAdmin (Recommended)
- **URL**: `http://localhost:5050`
- **Login**: admin@agriculture.com / admin123
- **Features**: Full PostgreSQL management, visual query builder, schema explorer

#### Adminer (Lightweight)
- **URL**: `http://localhost:8081`
- **Connection**: PostgreSQL, Server: `postgres`, User: `agriculture_user`, Password: `nutrition_pass_2024`, Database: `smart_agriculture_nutrition`

### Database Schema
- `crop_nutrition_profiles` - Agricultural crop data with sustainability metrics (20 records)
- `personal_nutrition_trackers` - User health tracking with BMI integration (22 records)
- `harvest_batches` - Harvest information linked to crop profiles (21 records)
- `meal_sources` - Meal tracking with farm-to-fork scoring (34 records)

### Sample Data Overview
The project includes comprehensive sample data with **97 total records**:

#### 🌾 Crop Nutrition Profiles (20 records)
- **Organic Crops**: Tomatoes, Spinach, Blueberries, Kale, Cabbage, Broccoli, Beets
- **Hydroponic Crops**: Carrots, Lettuce, Cucumbers, Strawberries, Peppers, Radishes, Herbs
- **Traditional Crops**: Wheat, Potatoes, Barley, Rye, Oats, Turnips
- **Locations**: 20 different Finnish cities
- **Growing Methods**: Organic, Hydroponic, Traditional
- **Sustainability Scores**: Range 6.5 to 9.3

#### 👤 Personal Nutrition Trackers (22 records)
Real user names from your class including:
- Alejandro Fernandez Armas, Arsalan Vosough, Hassan Syed, Zoltan Papp
- Muhammad Feroz, Haben Eyasu, Ke Qiu, Danial Farooq, Javeria Kanwal
- Sofiia Mikhailova, João Moreira, Luca Stoian, Sufian Embark Aomar
- Md. Salman Hossan Prottoy, Elham Pournouri, Md Ariful Islam
- Jakub Formánek, Muhammad Hassan Ali, Talha Bin Nayyar
- Sibrah Rahim, Sana Mazhar, Asma Sikandar

#### 🌾 Harvest Batches (21 records)
- Quality grades: A+, A, B+, B
- Quantities: 12.7kg to 245.7kg
- Detailed storage conditions and batch notes

#### 🍽️ Meal Sources (34 records)
- Diverse meal types: breakfast, lunch, dinner, snacks
- Ingredients with detailed JSONB data
- Local sourcing percentages: 75-100%
- Farm origins and nutritional density scores

### Sample Database Operations
```sql
-- View all crop profiles
SELECT * FROM crop_nutrition_profiles;

-- Get nutrition trackers with BMI info
SELECT user_name, age, current_bmi, health_goals 
FROM personal_nutrition_trackers;

-- Join tables for comprehensive view
SELECT 
    cp.crop_name,
    cp.farm_location,
    hb.harvest_date,
    hb.quantity_kg
FROM crop_nutrition_profiles cp
LEFT JOIN harvest_batches hb ON cp.id = hb.crop_id;
```

## 🧪 Testing

### Run Tests
```bash
# Unit tests
mvn test

# Integration tests (requires Docker)
mvn verify -P integration-tests

# Load testing with JMeter
mvn jmeter:jmeter
```

### Test Coverage
- **Unit Tests**: Service layer, business logic, utilities
- **Integration Tests**: Database operations, API endpoints
- **Load Tests**: Performance testing with JMeter scenarios

## 🚀 Deployment

### Development
```bash
# Start all services
docker-compose up -d

# Build and deploy
mvn clean compile war:war
# Deploy target/SmartAgricultureNutrition.war to your server
```

### Production
```bash
# Production build
mvn clean compile war:war -P production

# Use nginx configuration for load balancing
# See nginx/nginx.conf for configuration
```

### Docker Services
- **PostgreSQL**: Port 5432 (Database)
- **pgAdmin**: Port 5050 (Database Management)
- **Adminer**: Port 8081 (Alternative DB Tool)
- **Nginx**: Port 80 (Load Balancer - when enabled)

## 🔧 Configuration

### Environment Variables (.env)
```bash
# Database Configuration
POSTGRES_DB=smart_agriculture_nutrition
POSTGRES_USER=agriculture_user
POSTGRES_PASSWORD=nutrition_pass_2024

# External API Keys (Optional)
WEATHER_API_KEY=your_weatherapi_key
USDA_API_KEY=your_usda_key

# Application Settings
API_BASE_URL=http://localhost:8080/SmartAgricultureNutrition
```

### Application Properties
Key configurations in `src/main/java/com/agriculture/nutrition/config/`:
- **DatabaseConfig.java**: PostgreSQL connection settings
- **SwaggerConfig.java**: OpenAPI documentation configuration

## 📊 Features Checklist

### ✅ REST API Requirements
- [x] **2 Upper-level Resources**: Crop Nutrition Profiles, Personal Nutrition Trackers
- [x] **2+ Nested Resources**: Harvest Batches, Meal Sources, Health Correlations, BMI Analysis
- [x] **All HTTP Methods**: GET, POST, PUT, DELETE
- [x] **JSON Format**: Consistent JSON responses
- [x] **Path Variables**: Dynamic routing with {id} parameters
- [x] **Query Parameters**: Filtering, sorting, pagination
- [x] **Status Codes**: Proper HTTP status codes (200, 201, 204, 404, 500)
- [x] **Custom Exception Handling**: Specific error responses
- [x] **HATEOAS**: Hypermedia links for API navigation
- [x] **Rich Sample Data**: Comprehensive in-memory data for demonstration

### ✅ Advanced Features
- [x] **PostgreSQL Integration**: Full database persistence
- [x] **External API Integration**: WeatherAPI.com, USDA FoodData Central
- [x] **Interactive Documentation**: Swagger UI with "Try it out"
- [x] **Visual Database Management**: pgAdmin, Adminer
- [x] **Comprehensive Testing**: Unit, Integration, Load tests
- [x] **Production Ready**: Docker, Nginx, environment configuration
- [x] **Advanced Analytics**: Weather-nutrition correlations

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **WeatherAPI.com** for real-time weather data
- **USDA FoodData Central** for comprehensive nutrition database
- **PostgreSQL** for robust database management
- **Swagger/OpenAPI** for excellent API documentation tools

---

**🎯 This REST Web Service demonstrates modern API design patterns, database integration, external API consumption, comprehensive testing, and production-ready deployment configuration.**

For questions or support, please open an issue in the repository.
