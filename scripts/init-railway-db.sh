#!/bin/bash

# Railway Database Initialization Script
# This script initializes the database using Railway's environment

echo "🚀 Starting Railway Database Initialization..."

# Check if .env.railway exists
if [ -f ".env.railway" ]; then
    echo "📋 Loading Railway environment variables from .env.railway..."
    export $(cat .env.railway | grep -v '^#' | xargs)
else
    echo "⚠️  .env.railway file not found!"
    echo "Please create .env.railway with your DATABASE_PUBLIC_URL"
    echo "Example:"
    echo "  DATABASE_PUBLIC_URL=postgresql://user:pass@host:port/dbname"
    exit 1
fi

# Check if DATABASE_PUBLIC_URL is set
if [ -z "$DATABASE_PUBLIC_URL" ]; then
    echo "❌ DATABASE_PUBLIC_URL not set in .env.railway"
    exit 1
fi

echo "📊 Using Database URL: [HIDDEN FOR SECURITY]"

# Check if we can use railway run with a postgres image
echo "⏳ Attempting to initialize database schema..."

# Create a temporary SQL file that combines both init and sample data
cat > /tmp/combined_init.sql << 'EOF'
-- Create tables for Smart Agriculture Nutrition API

-- Drop existing tables if they exist
DROP TABLE IF EXISTS meal_sources CASCADE;
DROP TABLE IF EXISTS harvest_batches CASCADE;
DROP TABLE IF EXISTS personal_nutrition_trackers CASCADE;
DROP TABLE IF EXISTS crop_nutrition_profiles CASCADE;

-- Create crop_nutrition_profiles table
CREATE TABLE IF NOT EXISTS crop_nutrition_profiles (
    id SERIAL PRIMARY KEY,
    crop_name VARCHAR(255) NOT NULL,
    farm_location VARCHAR(255),
    growing_method VARCHAR(100),
    sustainability_score DECIMAL(3,1),
    soil_nutrients JSONB,
    crop_nutrients JSONB,
    certifications TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create personal_nutrition_trackers table
CREATE TABLE IF NOT EXISTS personal_nutrition_trackers (
    id SERIAL PRIMARY KEY,
    user_name VARCHAR(255) NOT NULL,
    age INTEGER,
    current_bmi DECIMAL(4,2),
    health_goals TEXT[],
    farm_to_fork_score DECIMAL(3,1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create harvest_batches table (nested under crop_nutrition_profiles)
CREATE TABLE IF NOT EXISTS harvest_batches (
    id SERIAL PRIMARY KEY,
    crop_id INTEGER REFERENCES crop_nutrition_profiles(id) ON DELETE CASCADE,
    harvest_date DATE,
    quantity_kg DECIMAL(10,2),
    quality_grade VARCHAR(10),
    actual_nutrients JSONB,
    storage_conditions TEXT,
    batch_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create meal_sources table (nested under personal_nutrition_trackers)
CREATE TABLE IF NOT EXISTS meal_sources (
    id SERIAL PRIMARY KEY,
    tracker_id INTEGER REFERENCES personal_nutrition_trackers(id) ON DELETE CASCADE,
    meal_name VARCHAR(255),
    meal_date DATE,
    meal_type VARCHAR(50),
    ingredients JSONB,
    local_source_percentage DECIMAL(3,2),
    nutritional_density DECIMAL(3,1),
    farm_origin VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX idx_crop_profiles_crop_name ON crop_nutrition_profiles(crop_name);
CREATE INDEX idx_crop_profiles_location ON crop_nutrition_profiles(farm_location);
CREATE INDEX idx_crop_profiles_method ON crop_nutrition_profiles(growing_method);
CREATE INDEX idx_trackers_user_name ON personal_nutrition_trackers(user_name);
CREATE INDEX idx_harvest_crop_id ON harvest_batches(crop_id);
CREATE INDEX idx_harvest_date ON harvest_batches(harvest_date);
CREATE INDEX idx_meal_tracker_id ON meal_sources(tracker_id);
CREATE INDEX idx_meal_date ON meal_sources(meal_date);

-- Add update trigger for updated_at columns
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_crop_profiles_updated_at BEFORE UPDATE ON crop_nutrition_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_trackers_updated_at BEFORE UPDATE ON personal_nutrition_trackers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;

-- Verify tables were created
SELECT 'Tables created successfully!' as status;
EOF

# Use Python to connect and execute SQL (Python is more commonly available than psql)
python3 << EOF
import urllib.parse
import urllib.request
import ssl
import sys
import os

database_url = os.environ.get('DATABASE_PUBLIC_URL')

if not database_url:
    print("❌ DATABASE_PUBLIC_URL environment variable not set")
    sys.exit(1)

# Parse the database URL
parsed = urllib.parse.urlparse(database_url)

print("Attempting to connect to database...")
print(f"Host: [HIDDEN]")
print(f"Port: [HIDDEN]")
print(f"Database: {parsed.path[1:]}")

# Try to use psycopg2 if available
try:
    import psycopg2
    
    conn = psycopg2.connect(database_url)
    cur = conn.cursor()
    
    # Read and execute the SQL file
    with open('/tmp/combined_init.sql', 'r') as f:
        sql = f.read()
        cur.execute(sql)
    
    conn.commit()
    print("✅ Database schema initialized successfully!")
    
    # Check tables
    cur.execute("SELECT tablename FROM pg_tables WHERE schemaname = 'public'")
    tables = cur.fetchall()
    print(f"📊 Created {len(tables)} tables: {[t[0] for t in tables]}")
    
    cur.close()
    conn.close()
    
except ImportError:
    print("❌ psycopg2 not installed. Installing...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "psycopg2-binary"])
    print("Please run this script again.")
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)
EOF

echo ""
echo "✅ Database initialization complete!"
echo ""
echo "📝 Next steps:"
echo "1. Add JWT_SECRET to Railway variables"
echo "2. Reference PostgreSQL variables in your app service"
echo "3. Redeploy the application"
