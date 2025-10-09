# Multi-stage build for Smart Agriculture Nutrition REST API
FROM maven:latest AS build

# Set working directory
WORKDIR /app

# Copy pom.xml first for better layer caching
COPY pom.xml .

# Download dependencies
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# Production stage
FROM tomcat:9.0-jdk17-openjdk-slim

# Remove default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the built WAR file
COPY --from=build /app/target/SmartAgricultureNutrition.war /usr/local/tomcat/webapps/SmartAgricultureNutrition.war

# Create application properties directory
RUN mkdir -p /usr/local/tomcat/conf/agriculture

# Copy application properties
COPY src/main/resources/application.properties /usr/local/tomcat/conf/agriculture/

# Set environment variables
# Fix for CGroup v2 issues in containerized environments
ENV CATALINA_OPTS="-Xmx512m -Xms256m"
ENV JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom -Djdk.tls.client.protocols=TLSv1.2 -Dcom.sun.management.jmxremote=false"

# Expose port
EXPOSE 8080


# Start Tomcat
CMD ["catalina.sh", "run"]
