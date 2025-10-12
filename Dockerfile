# Multi-stage build for Smart Agriculture Nutrition REST API
# Stage 1: Build stage
FROM maven:3.9-eclipse-temurin-17 AS build

# Set working directory
WORKDIR /app

# Copy pom.xml first for better layer caching
COPY pom.xml .

# Download dependencies (cached if pom.xml hasn't changed)
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application with optimizations
RUN mvn clean package -DskipTests \
    && mv target/SmartAgricultureNutrition.war target/app.war

# Stage 2: Runtime stage - Using JRE image
FROM tomcat:9.0-jre17-temurin

# Add non-root user for security
RUN groupadd -r tomcat && useradd -r -g tomcat tomcat

# Remove default webapps and unnecessary files to reduce size
RUN rm -rf /usr/local/tomcat/webapps/* \
    && rm -rf /usr/local/tomcat/webapps.dist \
    && rm -rf /usr/local/tomcat/temp/* \
    && rm -rf /usr/local/tomcat/logs/*

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy the built WAR file from build stage
COPY --from=build --chown=tomcat:tomcat /app/target/app.war /usr/local/tomcat/webapps/SmartAgricultureNutrition.war

# Create application properties directory
RUN mkdir -p /usr/local/tomcat/conf/agriculture \
    && chown -R tomcat:tomcat /usr/local/tomcat/conf/agriculture

# Copy application properties
COPY --chown=tomcat:tomcat src/main/resources/application.properties /usr/local/tomcat/conf/agriculture/

# Optimize Tomcat configuration
RUN echo "org.apache.catalina.mbeans.JmxRemoteLifecycleListener.skip=true" >> /usr/local/tomcat/conf/catalina.properties \
    && echo "tomcat.util.scan.StandardJarScanFilter.jarsToSkip=*.jar" >> /usr/local/tomcat/conf/catalina.properties \
    && echo "org.apache.catalina.startup.ContextConfig.jarsToSkip=*.jar" >> /usr/local/tomcat/conf/catalina.properties \
    && echo "tomcat.util.scan.DefaultJarScanner.jarsToSkip=*.jar" >> /usr/local/tomcat/conf/catalina.properties

# Set optimized JVM options for container environment
ENV CATALINA_OPTS="-Xmx512m -Xms256m \
    -XX:MaxMetaspaceSize=256m \
    -XX:+UseG1GC \
    -XX:+UseStringDeduplication \
    -XX:+ExitOnOutOfMemoryError \
    -Djava.security.egd=file:/dev/./urandom \
    -Dfile.encoding=UTF-8"

# Set additional Java options
ENV JAVA_OPTS="-Djava.awt.headless=true \
    -Duser.timezone=UTC"

# Create volume for logs (optional)
VOLUME ["/usr/local/tomcat/logs"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/SmartAgricultureNutrition/ || exit 1

# Change ownership of Tomcat directories
RUN chown -R tomcat:tomcat /usr/local/tomcat/webapps \
    && chown -R tomcat:tomcat /usr/local/tomcat/logs \
    && chown -R tomcat:tomcat /usr/local/tomcat/temp \
    && chown -R tomcat:tomcat /usr/local/tomcat/work

# Switch to non-root user
USER tomcat

# Expose port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
