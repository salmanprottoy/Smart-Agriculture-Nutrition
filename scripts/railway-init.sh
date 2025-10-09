#!/bin/bash

# Railway Database Initialization Script
# This script initializes the database schema and loads sample data

echo "🚀 Starting Railway Database Initialization..."

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL environment variable is not set!"
    echo "Please ensure Railway PostgreSQL is properly configured."
    exit 1
fi

echo "📊 Database URL detected: ${DATABASE_URL:0:30}..."

# Function to run SQL file
run_sql_file() {
    local file=$1
    local description=$2
    
    echo "⏳ Running $description..."
    
    if [ -f "$file" ]; then
        psql "$DATABASE_URL" < "$file"
        if [ $? -eq 0 ]; then
            echo "✅ $description completed successfully!"
        else
            echo "⚠️  Warning: $description encountered issues"
        fi
    else
        echo "⚠️  File not found: $file"
    fi
}

# Initialize database schema
run_sql_file "database/init.sql" "Database schema initialization"

# Load sample data
run_sql_file "src/main/resources/db/migration/sample_data.sql" "Sample data loading"

# Verify data was loaded
echo "🔍 Verifying data load..."
psql "$DATABASE_URL" -c "SELECT 'Crop Profiles: ' || COUNT(*) FROM crop_nutrition_profiles;" 2>/dev/null
psql "$DATABASE_URL" -c "SELECT 'Nutrition Trackers: ' || COUNT(*) FROM personal_nutrition_trackers;" 2>/dev/null
psql "$DATABASE_URL" -c "SELECT 'Harvest Batches: ' || COUNT(*) FROM harvest_batches;" 2>/dev/null
psql "$DATABASE_URL" -c "SELECT 'Meal Sources: ' || COUNT(*) FROM meal_sources;" 2>/dev/null

echo "✅ Railway database initialization complete!"
echo ""
echo "📝 Next steps:"
echo "1. Deploy your application to Railway"
echo "2. Set environment variables (WEATHER_API_KEY, USDA_API_KEY)"
echo "3. Access your API at: https://your-app.up.railway.app/SmartAgricultureNutrition/api/v1/"
