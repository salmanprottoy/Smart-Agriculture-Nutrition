# Smart Agriculture Nutrition REST API

Welcome to the Smart Agriculture Nutrition REST API documentation. This API provides comprehensive endpoints for managing crop nutrition data, personal nutrition tracking, and agricultural insights.

## 🌟 Features

- **Crop Nutrition Management**: Complete CRUD operations for crop nutrition profiles
- **Personal Nutrition Tracking**: Monitor individual nutrition intake and goals
- **Weather Integration**: Access weather data for agricultural planning
- **Data Correlation**: Analyze relationships between nutrition and environmental factors
- **Interactive Documentation**: Swagger UI for API testing

## 🚀 Quick Start

### Using GitHub Codespaces (Recommended)

1. **Open in Codespaces**: Click the "Code" button → "Codespaces" → "Create codespace on main"
2. **Wait for Setup**: Codespaces will automatically set up Java 17, Maven, and Docker
3. **Start Services**: The database will start automatically
4. **Build & Run**: 
   ```bash
   mvn clean package
   # Deploy to local Tomcat or run with embedded server
   ```

### Local Development

1. **Clone Repository**:
   ```bash
   git clone https://github.com/salmanprottoy/Smart-Agriculture-Nutrition.git
   cd Smart-Agriculture-Nutrition
   ```

2. **Start Database**:
   ```bash
   docker-compose up -d
   ```

3. **Build Application**:
   ```bash
   mvn clean package
   ```

4. **Deploy to Tomcat** or run with your preferred Java server

## 📊 API Endpoints

### Base URL
- **Local Development**: `http://localhost:8080/SmartAgricultureNutrition/api/v1/`
- **Production**: `https://your-domain.com/SmartAgricultureNutrition/api/v1/`

### Core Endpoints

#### Crop Nutrition Profiles
- `GET /crop-nutrition-profiles` - List all crop profiles
- `GET /crop-nutrition-profiles/{id}` - Get specific crop profile
- `POST /crop-nutrition-profiles` - Create new crop profile
- `PUT /crop-nutrition-profiles/{id}` - Update crop profile
- `DELETE /crop-nutrition-profiles/{id}` - Delete crop profile

#### Nutrition Data
- `GET /nutrition-data` - List nutrition data
- `GET /nutrition-data/{id}` - Get specific nutrition data
- `POST /nutrition-data` - Create nutrition data
- `PUT /nutrition-data/{id}` - Update nutrition data
- `DELETE /nutrition-data/{id}` - Delete nutrition data

#### Personal Nutrition Tracker
- `GET /personal-nutrition-tracker` - List tracking records
- `GET /personal-nutrition-tracker/{id}` - Get specific record
- `POST /personal-nutrition-tracker` - Create tracking record
- `PUT /personal-nutrition-tracker/{id}` - Update record
- `DELETE /personal-nutrition-tracker/{id}` - Delete record

#### Weather Data
- `GET /weather` - Get weather information
- `GET /weather/{location}` - Get weather for specific location

#### Correlation Analysis
- `GET /correlation/nutrition-weather` - Analyze nutrition-weather correlations
- `GET /correlation/crop-yield` - Analyze crop yield correlations

## 🔧 Development

### GitHub Actions CI/CD

Every push to `main` or `develop` triggers:
- **Automated Testing**: Unit and integration tests
- **Build Verification**: Maven build and Docker image creation
- **Demo Deployment**: Temporary deployment for testing
- **Test Reports**: Comprehensive test coverage reports

### Testing

```bash
# Run unit tests
mvn test

# Run integration tests
mvn verify

# Run load tests
mvn jmeter:jmeter
```

### Docker Deployment

```bash
# Development (database only)
docker-compose up -d

# Production (full stack)
docker-compose -f docker-compose.prod.yml up -d
```

## 📖 Interactive Documentation

Access the Swagger UI for interactive API testing:
- **Local**: `http://localhost:8080/SmartAgricultureNutrition/api/v1/swagger-ui`
- **Production**: `https://your-domain.com/SmartAgricultureNutrition/api/v1/swagger-ui`

## 🌐 Deployment Options

### GitHub Codespaces
- **Instant Setup**: Pre-configured development environment
- **Zero Installation**: Everything runs in the browser
- **Full Feature Access**: Complete API functionality

### Traditional Cloud Platforms
- **Heroku**: Java-friendly with PostgreSQL add-ons
- **Google Cloud Run**: Excellent container support
- **AWS App Runner**: Simple Docker deployment
- **Azure Container Instances**: Microsoft's container service

## 📊 Sample Data

The API comes with 97 pre-loaded crop nutrition records including:
- Common vegetables (tomatoes, carrots, lettuce)
- Grains (wheat, rice, corn)
- Fruits (apples, oranges, bananas)
- Legumes (beans, peas, lentils)

## 🔒 Security Features

- **Input Validation**: Comprehensive data validation
- **Error Handling**: Proper HTTP status codes and error messages
- **CORS Support**: Cross-origin resource sharing
- **Rate Limiting**: Protection against abuse (in production deployment)

## 🤝 Contributing

1. **Fork the Repository**
2. **Create Feature Branch**: `git checkout -b feature/amazing-feature`
3. **Commit Changes**: `git commit -m 'Add amazing feature'`
4. **Push to Branch**: `git push origin feature/amazing-feature`
5. **Open Pull Request**

## 📞 Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/salmanprottoy/Smart-Agriculture-Nutrition/issues)
- **Documentation**: Check the comprehensive guides in the repository
- **API Testing**: Use the interactive Swagger UI

## 👥 Team

**Developed by**: Md. Salman Hossan Prottoy, Elham Pournouri, Md Ariful Islam, Jakub Formánek  
**University of Jyväskylä** - TIES 4560 Service-Oriented Architecture and Cloud Computing

---

## 🎯 Academic Project

This project demonstrates:
- **RESTful API Design**: Proper HTTP methods and status codes
- **Service-Oriented Architecture**: Modular, scalable design
- **Cloud-Ready Deployment**: Docker containerization
- **Comprehensive Testing**: Unit, integration, and load testing
- **Professional Documentation**: Complete API documentation
- **Modern DevOps**: CI/CD with GitHub Actions

**License**: MIT License - see [LICENSE](../LICENSE) file for details.
