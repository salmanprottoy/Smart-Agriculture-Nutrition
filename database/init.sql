-- Smart Agriculture Nutrition Database Schema
-- PostgreSQL initialization script

-- Create database (already created by Docker, but keeping for reference)
-- CREATE DATABASE smart_agriculture_nutrition;

-- Connect to the database
\c smart_agriculture_nutrition;

-- Create tables for Crop Nutrition Profiles
CREATE TABLE crop_nutrition_profiles (
    id BIGSERIAL PRIMARY KEY,
    crop_name VARCHAR(255) NOT NULL,
    farm_location VARCHAR(255) NOT NULL,
    growing_method VARCHAR(100) NOT NULL,
    planting_date DATE,
    expected_harvest_date DATE,
    soil_nutrients JSONB,
    crop_nutrients JSONB,
    sustainability_score DECIMAL(3,1),
    certifications TEXT[],
    weather_conditions JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create tables for Harvest Batches
CREATE TABLE harvest_batches (
    id BIGSERIAL PRIMARY KEY,
    crop_profile_id BIGINT NOT NULL REFERENCES crop_nutrition_profiles(id) ON DELETE CASCADE,
    harvest_date DATE NOT NULL,
    quantity_kg DECIMAL(10,2),
    quality_grade VARCHAR(50),
    actual_nutrients JSONB,
    storage_conditions VARCHAR(255),
    batch_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create tables for Personal Nutrition Trackers
CREATE TABLE personal_nutrition_trackers (
    id BIGSERIAL PRIMARY KEY,
    user_name VARCHAR(255) NOT NULL,
    age INTEGER,
    current_bmi DECIMAL(4,1),
    health_goals TEXT[],
    dietary_restrictions TEXT[],
    daily_nutrient_intake JSONB,
    farm_to_fork_score DECIMAL(3,1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create tables for Meal Sources
CREATE TABLE meal_sources (
    id BIGSERIAL PRIMARY KEY,
    tracker_id BIGINT NOT NULL REFERENCES personal_nutrition_trackers(id) ON DELETE CASCADE,
    meal_name VARCHAR(255) NOT NULL,
    meal_date DATE NOT NULL,
    ingredients JSONB,
    local_source_percentage DECIMAL(5,2),
    nutritional_density DECIMAL(5,2),
    farm_origins TEXT[],
    meal_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_crop_profiles_crop_name ON crop_nutrition_profiles(crop_name);
CREATE INDEX idx_crop_profiles_location ON crop_nutrition_profiles(farm_location);
CREATE INDEX idx_crop_profiles_method ON crop_nutrition_profiles(growing_method);
CREATE INDEX idx_harvest_batches_crop_id ON harvest_batches(crop_profile_id);
CREATE INDEX idx_harvest_batches_date ON harvest_batches(harvest_date);
CREATE INDEX idx_nutrition_trackers_user ON personal_nutrition_trackers(user_name);
CREATE INDEX idx_meal_sources_tracker_id ON meal_sources(tracker_id);
CREATE INDEX idx_meal_sources_date ON meal_sources(meal_date);

-- Insert sample data for Crop Nutrition Profiles
INSERT INTO crop_nutrition_profiles (
    crop_name, farm_location, growing_method, planting_date, expected_harvest_date,
    soil_nutrients, crop_nutrients, sustainability_score, certifications, weather_conditions
) VALUES 
(
    'Organic Cherry Tomatoes',
    'Jyväskylä, Finland',
    'Organic',
    '2024-05-15',
    '2024-08-30',
    '{"nitrogen": 45, "phosphorus": 25, "potassium": 180, "pH": 6.8, "organic_matter": 4.2}',
    '{"vitamin_c": 28, "lycopene": 3.2, "potassium": 237, "folate": 15, "vitamin_k": 7.9}',
    8.7,
    ARRAY['EU Organic', 'Carbon Neutral', 'Fair Trade'],
    '{"temperature_avg": 18.5, "rainfall_mm": 65, "sunshine_hours": 180, "humidity": 72}'
),
(
    'Hydroponic Carrots',
    'Tampere, Finland',
    'Hydroponic',
    '2024-04-20',
    '2024-07-15',
    '{"nitrogen": 120, "phosphorus": 40, "potassium": 200, "pH": 6.2, "ec_level": 1.8}',
    '{"beta_carotene": 8285, "vitamin_a": 835, "fiber": 2.8, "potassium": 320, "vitamin_k": 13.2}',
    7.2,
    ARRAY['Sustainable Farming', 'Water Efficient'],
    '{"temperature_avg": 20.2, "humidity": 68, "co2_ppm": 400, "light_hours": 16}'
),
(
    'Heritage Wheat',
    'Turku, Finland',
    'Traditional',
    '2024-04-10',
    '2024-09-20',
    '{"nitrogen": 80, "phosphorus": 35, "potassium": 150, "pH": 7.1, "organic_matter": 3.8}',
    '{"protein": 14.2, "fiber": 12.2, "iron": 3.6, "magnesium": 126, "zinc": 2.7}',
    6.8,
    ARRAY['Heritage Variety', 'Non-GMO'],
    '{"temperature_avg": 16.8, "rainfall_mm": 58, "sunshine_hours": 165, "humidity": 75}'
);

-- Insert sample data for Harvest Batches
INSERT INTO harvest_batches (
    crop_profile_id, harvest_date, quantity_kg, quality_grade, actual_nutrients, storage_conditions, batch_notes
) VALUES 
(
    1,
    '2024-08-28',
    125.5,
    'Premium',
    '{"vitamin_c": 32, "lycopene": 3.8, "potassium": 245, "folate": 18, "vitamin_k": 8.2}',
    'Cold storage at 4°C, 85% humidity',
    'Excellent harvest quality, slightly higher nutrient content than expected'
),
(
    1,
    '2024-09-05',
    98.2,
    'Grade A',
    '{"vitamin_c": 26, "lycopene": 2.9, "potassium": 230, "folate": 14, "vitamin_k": 7.5}',
    'Cold storage at 4°C, 85% humidity',
    'Second harvest, good quality but slightly lower nutrients'
),
(
    2,
    '2024-07-12',
    200.8,
    'Premium',
    '{"beta_carotene": 9100, "vitamin_a": 910, "fiber": 3.1, "potassium": 335, "vitamin_k": 14.1}',
    'Refrigerated at 2°C, 90% humidity',
    'Exceptional hydroponic harvest with enhanced nutrient density'
);

-- Insert sample data for Personal Nutrition Trackers
INSERT INTO personal_nutrition_trackers (
    user_name, age, current_bmi, health_goals, dietary_restrictions, daily_nutrient_intake, farm_to_fork_score
) VALUES 
(
    'John Farmer',
    34,
    24.5,
    ARRAY['Weight Maintenance', 'Increase Antioxidants', 'Support Local Farms'],
    ARRAY['Gluten Sensitive'],
    '{"calories": 2200, "protein": 85, "carbs": 275, "fat": 73, "fiber": 28, "vitamin_c": 95, "iron": 12}',
    8.2
),
(
    'Maria Sustainable',
    28,
    22.1,
    ARRAY['Increase Vegetable Intake', 'Reduce Carbon Footprint', 'Improve Gut Health'],
    ARRAY['Vegetarian'],
    '{"calories": 1950, "protein": 65, "carbs": 245, "fat": 65, "fiber": 35, "vitamin_c": 120, "iron": 15}',
    7.5
),
(
    'Erik Wellness',
    42,
    26.8,
    ARRAY['Weight Loss', 'Lower Cholesterol', 'Increase Energy'],
    ARRAY['Dairy Free', 'Low Sodium'],
    '{"calories": 1800, "protein": 95, "carbs": 180, "fat": 60, "fiber": 32, "vitamin_c": 85, "iron": 14}',
    6.9
);

-- Insert sample data for Meal Sources
INSERT INTO meal_sources (
    tracker_id, meal_name, meal_date, ingredients, local_source_percentage, nutritional_density, farm_origins, meal_notes
) VALUES 
(
    1,
    'Farm Fresh Tomato Salad',
    '2024-09-01',
    '{"tomatoes": "200g", "cucumber": "100g", "olive_oil": "15ml", "herbs": "mixed basil and oregano"}',
    85.50,
    92.3,
    ARRAY['Jyväskylä Organic Farm', 'Local Greenhouse Co-op'],
    'Delicious lunch with tomatoes from our partner farm'
),
(
    1,
    'Roasted Root Vegetables',
    '2024-09-02',
    '{"carrots": "150g", "potatoes": "200g", "onions": "80g", "herbs": "rosemary and thyme"}',
    72.30,
    88.7,
    ARRAY['Tampere Hydroponic Center', 'Regional Potato Farm'],
    'Hearty dinner featuring hydroponic carrots'
),
(
    2,
    'Green Power Bowl',
    '2024-09-01',
    '{"spinach": "100g", "quinoa": "80g", "avocado": "half", "seeds": "pumpkin and sunflower"}',
    45.20,
    95.8,
    ARRAY['Local Organic Greens', 'Fair Trade Quinoa'],
    'Nutrient-dense lunch focusing on plant-based proteins'
),
(
    3,
    'Grilled Vegetable Medley',
    '2024-09-01',
    '{"zucchini": "120g", "bell_peppers": "100g", "eggplant": "80g", "olive_oil": "10ml"}',
    68.90,
    87.4,
    ARRAY['Regional Vegetable Cooperative'],
    'Low-calorie dinner supporting weight loss goals'
);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update the updated_at column
CREATE TRIGGER update_crop_nutrition_profiles_updated_at 
    BEFORE UPDATE ON crop_nutrition_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_harvest_batches_updated_at 
    BEFORE UPDATE ON harvest_batches 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_personal_nutrition_trackers_updated_at 
    BEFORE UPDATE ON personal_nutrition_trackers 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_meal_sources_updated_at 
    BEFORE UPDATE ON meal_sources 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create a view for comprehensive crop information
CREATE VIEW crop_summary AS
SELECT 
    cp.id,
    cp.crop_name,
    cp.farm_location,
    cp.growing_method,
    cp.sustainability_score,
    cp.certifications,
    COUNT(hb.id) as harvest_count,
    COALESCE(SUM(hb.quantity_kg), 0) as total_harvest_kg,
    AVG(hb.quantity_kg) as avg_harvest_kg
FROM crop_nutrition_profiles cp
LEFT JOIN harvest_batches hb ON cp.id = hb.crop_profile_id
GROUP BY cp.id, cp.crop_name, cp.farm_location, cp.growing_method, cp.sustainability_score, cp.certifications;

-- Create a view for nutrition tracker summary
CREATE VIEW nutrition_summary AS
SELECT 
    pnt.id,
    pnt.user_name,
    pnt.current_bmi,
    pnt.farm_to_fork_score,
    COUNT(ms.id) as meal_count,
    AVG(ms.local_source_percentage) as avg_local_percentage,
    AVG(ms.nutritional_density) as avg_nutritional_density
FROM personal_nutrition_trackers pnt
LEFT JOIN meal_sources ms ON pnt.id = ms.tracker_id
GROUP BY pnt.id, pnt.user_name, pnt.current_bmi, pnt.farm_to_fork_score;

-- Grant permissions (if needed for specific user)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO agriculture_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO agriculture_user;

-- Display success message
SELECT 'Smart Agriculture Nutrition Database initialized successfully!' as status;
