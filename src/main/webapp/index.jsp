<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
  <head>
    <title>Smart Agriculture Nutrition</title>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style>
      body {
        font-family: Arial, sans-serif;
        margin: 0;
        padding: 20px;
        background-color: #f5f5f5;
      }
      .container {
        max-width: 1200px;
        margin: 0 auto;
        background-color: white;
        padding: 30px;
        border-radius: 10px;
        box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
      }
      h1 {
        color: #2c5530;
        text-align: center;
        margin-bottom: 10px;
      }
      .subtitle {
        text-align: center;
        color: #666;
        margin-bottom: 30px;
        font-style: italic;
      }
      .section {
        margin-bottom: 30px;
      }
      .section h2 {
        color: #4a7c59;
        border-bottom: 2px solid #4a7c59;
        padding-bottom: 5px;
      }
      .endpoint {
        background-color: #f8f9fa;
        border-left: 4px solid #4a7c59;
        padding: 15px;
        margin: 10px 0;
        border-radius: 5px;
      }
      .method {
        font-weight: bold;
        color: white;
        padding: 3px 8px;
        border-radius: 3px;
        font-size: 12px;
        margin-right: 10px;
      }
      .get {
        background-color: #28a745;
      }
      .post {
        background-color: #007bff;
      }
      .put {
        background-color: #ffc107;
        color: black;
      }
      .delete {
        background-color: #dc3545;
      }
      .url {
        font-family: monospace;
        background-color: #e9ecef;
        padding: 2px 5px;
        border-radius: 3px;
      }
      .description {
        margin-top: 5px;
        color: #666;
      }
      .story {
        background-color: #e8f5e8;
        padding: 20px;
        border-radius: 8px;
        margin-bottom: 30px;
        border-left: 5px solid #28a745;
      }
      .features {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
        gap: 20px;
        margin-top: 20px;
      }
      .feature {
        background-color: #f8f9fa;
        padding: 15px;
        border-radius: 8px;
        border: 1px solid #dee2e6;
      }
      .feature h3 {
        color: #2c5530;
        margin-top: 0;
      }
      .task-integration {
        background-color: #fff3cd;
        border: 1px solid #ffeaa7;
        padding: 15px;
        border-radius: 8px;
        margin: 20px 0;
      }
      .task-integration h3 {
        color: #856404;
        margin-top: 0;
      }
    </style>
  </head>
  <body>
    <div class="container">
      <h1>🌱 Smart Agriculture Nutrition</h1>
      <p class="subtitle">
        From Farm to Fork to Fitness - Connecting Smart Agriculture with
        Personal Nutrition
      </p>

      <div class="story">
        <h2>🚀 Our Story</h2>
        <p>
          <strong
            >What if we could track the nutritional journey of food from
            agricultural production to personal health outcomes?</strong
          >
        </p>
        <p>
          This API bridges the gap between smart agriculture data and
          personalized nutrition, creating a complete food-to-health ecosystem.
          It integrates with smart farming platforms and health analytics
          systems to provide a comprehensive solution for sustainable nutrition
          tracking.
        </p>
      </div>

      <div class="task-integration">
        <h3>🔗 System Integration</h3>
        <ul>
          <li>
            <strong>Smart Agriculture Platform:</strong> Leverages agricultural
            data from intelligent farming systems
          </li>
          <li>
            <strong>Health Analytics:</strong> Integrates BMI data for
            personalized nutrition recommendations
          </li>
          <li>
            <strong>REST API Framework:</strong> Complete RESTful web service
            with comprehensive functionality
          </li>
        </ul>
      </div>

      <div class="features">
        <div class="feature">
          <h3>🌾 Crop Nutrition Profiles</h3>
          <p>
            Track nutritional content of crops from smart farms, including soil
            nutrients, growing methods, and sustainability scores.
          </p>
        </div>
        <div class="feature">
          <h3>📊 Personal Nutrition Tracking</h3>
          <p>
            Monitor individual nutrition intake with BMI integration and
            farm-to-fork scoring for sustainable eating.
          </p>
        </div>
        <div class="feature">
          <h3>🔗 HATEOAS Navigation</h3>
          <p>
            Fully navigable API with hypermedia links for seamless resource
            discovery and interaction.
          </p>
        </div>
        <div class="feature">
          <h3>⚡ Smart Analytics</h3>
          <p>
            Automated calculation of sustainability scores, nutritional density,
            and health correlations.
          </p>
        </div>
      </div>

      <div class="section">
        <h2>🌾 Crop Nutrition Profiles API</h2>

        <div class="endpoint">
          <span class="method get">GET</span>
          <span class="url">api/v1/crop-nutrition-profiles</span>
          <div class="description">
            List all crop nutrition profiles with optional filtering
          </div>
        </div>

        <div class="endpoint">
          <span class="method get">GET</span>
          <span class="url"
            >api/v1/crop-nutrition-profiles?crop_type=tomato&growing_method=organic</span
          >
          <div class="description">Filter crops by type and growing method</div>
        </div>

        <div class="endpoint">
          <span class="method post">POST</span>
          <span class="url">api/v1/crop-nutrition-profiles</span>
          <div class="description">
            Create new crop nutrition profile with automatic sustainability
            scoring
          </div>
        </div>

        <div class="endpoint">
          <span class="method get">GET</span>
          <span class="url">api/v1/crop-nutrition-profiles/{id}</span>
          <div class="description">
            Get specific crop profile with HATEOAS navigation links
          </div>
        </div>

        <div class="endpoint">
          <span class="method put">PUT</span>
          <span class="url">api/v1/crop-nutrition-profiles/{id}</span>
          <div class="description">Update crop profile information</div>
        </div>

        <div class="endpoint">
          <span class="method delete">DELETE</span>
          <span class="url">api/v1/crop-nutrition-profiles/{id}</span>
          <div class="description">Remove crop profile and associated data</div>
        </div>

        <h3>🌱 Nested Resources - Harvest Batches</h3>

        <div class="endpoint">
          <span class="method get">GET</span>
          <span class="url"
            >api/v1/crop-nutrition-profiles/{id}/harvest-batches</span
          >
          <div class="description">Get harvest batches for specific crop</div>
        </div>

        <div class="endpoint">
          <span class="method post">POST</span>
          <span class="url"
            >api/v1/crop-nutrition-profiles/{id}/harvest-batches</span
          >
          <div class="description">
            Add new harvest batch with nutrient analysis
          </div>
        </div>

        <div class="endpoint">
          <span class="method get">GET</span>
          <span class="url"
            >api/v1/crop-nutrition-profiles/{id}/soil-impact</span
          >
          <div class="description">Analyze soil impact on crop nutrition</div>
        </div>
      </div>

      <div class="section">
        <h2>👤 Personal Nutrition Tracking API</h2>

        <div class="endpoint">
          <span class="method get">GET</span>
          <span class="url">api/v1/nutrition-trackers</span>
          <div class="description">List all personal nutrition trackers</div>
        </div>

        <div class="endpoint">
          <span class="method get">GET</span>
          <span class="url"
            >api/v1/nutrition-trackers?bmi_range=20-25&health_goal=Weight
            Maintenance</span
          >
          <div class="description">
            Filter trackers by BMI range and health goals
          </div>
        </div>

        <div class="endpoint">
          <span class="method post">POST</span>
          <span class="url">api/v1/nutrition-trackers</span>
          <div class="description">
            Create nutrition tracker with BMI integration and recommendations
          </div>
        </div>

        <div class="endpoint">
          <span class="method get">GET</span>
          <span class="url">api/v1/nutrition-trackers/{id}</span>
          <div class="description">
            Get specific nutrition tracker with HATEOAS links
          </div>
        </div>

        <div class="endpoint">
          <span class="method put">PUT</span>
          <span class="url">api/v1/nutrition-trackers/{id}</span>
          <div class="description">Update nutrition tracker information</div>
        </div>

        <h3>🍽️ Nested Resources - Meal Sources</h3>

        <div class="endpoint">
          <span class="method get">GET</span>
          <span class="url">api/v1/nutrition-trackers/{id}/meal-sources</span>
          <div class="description">Track meal sources and farm origins</div>
        </div>

        <div class="endpoint">
          <span class="method post">POST</span>
          <span class="url">api/v1/nutrition-trackers/{id}/meal-sources</span>
          <div class="description">
            Add meal with local sourcing percentage calculation
          </div>
        </div>

        <div class="endpoint">
          <span class="method get">GET</span>
          <span class="url"
            >api/v1/nutrition-trackers/{id}/health-correlations</span
          >
          <div class="description">
            Analyze health correlations and patterns
          </div>
        </div>

        <div class="endpoint">
          <span class="method get">GET</span>
          <span class="url">api/v1/nutrition-trackers/{id}/bmi-analysis</span>
          <div class="description">
            BMI analysis with personalized recommendations
          </div>
        </div>
      </div>

      <div class="section">
        <h2>🛠️ Technical Features</h2>
        <ul>
          <li>
            <strong>✅ 2 Upper-level Resources:</strong> Crop Nutrition
            Profiles, Personal Nutrition Trackers
          </li>
          <li>
            <strong>✅ 2+ Nested Resources:</strong> Harvest Batches, Meal
            Sources, Health Correlations
          </li>
          <li><strong>✅ All HTTP Methods:</strong> GET, POST, PUT, DELETE</li>
          <li>
            <strong>✅ JSON Format:</strong> All responses in JSON with proper
            content negotiation
          </li>
          <li>
            <strong>✅ Path Variables:</strong> Dynamic routing with {id}
            parameters
          </li>
          <li>
            <strong>✅ Query Parameters:</strong> Filtering, sorting, and
            pagination support
          </li>
          <li>
            <strong>✅ Status Codes:</strong> Proper HTTP status codes (200,
            201, 204, 404, 500)
          </li>
          <li>
            <strong>✅ Custom Exception Handling:</strong> Specific exception
            mappers with error messages
          </li>
          <li>
            <strong>✅ HATEOAS:</strong> Hypermedia links for API navigation
          </li>
          <li>
            <strong>✅ In-Memory Data:</strong> Rich sample data for
            demonstration
          </li>
        </ul>
      </div>

      <div class="section">
        <h2>🧪 Sample API Calls</h2>
        <p>Try these endpoints to explore the API:</p>
        <ul>
          <li>
            <a href="api/v1/crop-nutrition-profiles" target="_blank"
              >api/v1/crop-nutrition-profiles</a
            >
            - View all crop profiles
          </li>
          <li>
            <a href="api/v1/crop-nutrition-profiles/1" target="_blank"
              >api/v1/crop-nutrition-profiles/1</a
            >
            - View specific crop with HATEOAS
          </li>
          <li>
            <a
              href="api/v1/crop-nutrition-profiles/1/harvest-batches"
              target="_blank"
              >api/v1/crop-nutrition-profiles/1/harvest-batches</a
            >
            - View harvest batches
          </li>
          <li>
            <a href="api/v1/nutrition-trackers" target="_blank"
              >api/v1/nutrition-trackers</a
            >
            - View nutrition trackers
          </li>
          <li>
            <a href="api/v1/nutrition-trackers/1" target="_blank"
              >api/v1/nutrition-trackers/1</a
            >
            - View specific tracker
          </li>
          <li>
            <a href="api/v1/nutrition-trackers/1/bmi-analysis" target="_blank"
              >api/v1/nutrition-trackers/1/bmi-analysis</a
            >
            - BMI analysis with personalized recommendations
          </li>
        </ul>
      </div>

      <div class="section">
        <h2>🌐 API Documentation</h2>
        <div class="endpoint">
          <span class="method get">GET</span>
          <span class="url"><a href="swagger" target="_blank">swagger</a></span>
          <div class="description">
            Interactive Swagger UI documentation with "Try it out" functionality
          </div>
        </div>

        <div class="endpoint">
          <span class="method get">GET</span>
          <span class="url"
            ><a href="openapi.json" target="_blank">openapi.json</a></span
          >
          <div class="description">
            OpenAPI 3.0 specification in JSON format
          </div>
        </div>
      </div>

      <div class="section">
        <h2>🌤️ External API Integrations</h2>

        <div class="endpoint">
          <span class="method get">GET</span>
          <span class="url">api/v1/weather/current/{city}</span>
          <div class="description">
            Real-time weather data from WeatherAPI.com for agricultural analysis
          </div>
        </div>

        <div class="endpoint">
          <span class="method get">GET</span>
          <span class="url">api/v1/nutrition/crop/{cropName}</span>
          <div class="description">
            Comprehensive nutrition data from USDA FoodData Central database
          </div>
        </div>

        <div class="endpoint">
          <span class="method get">GET</span>
          <span class="url"
            >api/v1/correlations/crop-weather-nutrition/{city}/{crop}</span
          >
          <div class="description">
            Advanced correlation analysis between weather conditions and crop
            nutritional outcomes
          </div>
        </div>
      </div>

      <div class="section">
        <h2>🗄️ Database Management</h2>
        <div class="endpoint">
          <span class="method get">GET</span>
          <span class="url"
            ><a href="http://localhost:5050" target="_blank"
              >pgAdmin (Port 5050)</a
            ></span
          >
          <div class="description">
            Visual PostgreSQL database management interface (like Prisma Studio)
          </div>
        </div>

        <div class="endpoint">
          <span class="method get">GET</span>
          <span class="url"
            ><a href="http://localhost:8081" target="_blank"
              >Adminer (Port 8081)</a
            ></span
          >
          <div class="description">
            Lightweight database administration tool
          </div>
        </div>
      </div>

      <div class="section">
        <h2>🚀 Getting Started</h2>
        <h3>📋 Prerequisites</h3>
        <ul>
          <li>Java 21 or higher</li>
          <li>Maven 3.6+</li>
          <li>Docker & Docker Compose</li>
          <li>Application Server (Tomcat, WildFly, etc.)</li>
        </ul>

        <h3>⚡ Quick Start</h3>
        <ol>
          <li>
            <strong>Start Database:</strong>
            <code>docker-compose up -d postgres</code>
          </li>
          <li>
            <strong>Build Project:</strong>
            <code>mvn clean compile war:war</code>
          </li>
          <li>
            <strong>Deploy WAR:</strong> Deploy
            <code>target/SmartAgricultureNutritionAPI.war</code>
          </li>
          <li>
            <strong>Access API:</strong> Visit the endpoints above or use
            Swagger UI
          </li>
        </ol>

        <h3>🔧 Development Setup</h3>
        <ol>
          <li>
            <strong>Clone & Setup:</strong> Extract project and navigate to
            directory
          </li>
          <li>
            <strong>Environment:</strong> Copy <code>.env.example</code> to
            <code>.env</code> and configure API keys
          </li>
          <li>
            <strong>Database:</strong>
            <code>docker-compose up -d postgres pgadmin</code>
          </li>
          <li><strong>Build & Test:</strong> <code>mvn clean test</code></li>
          <li><strong>Run:</strong> Deploy WAR to your application server</li>
        </ol>

        <p>
          <strong>🎯 This REST Web Service demonstrates:</strong> Modern API
          design patterns, PostgreSQL integration, external API consumption,
          comprehensive testing, and production-ready deployment configuration.
        </p>
      </div>
    </div>
  </body>
</html>
