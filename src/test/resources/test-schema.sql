-- Test schema for integration tests
-- This file is loaded by Testcontainers for integration testing

-- Create the main table for crop nutrition profiles
CREATE TABLE IF NOT EXISTS crop_nutrition_profiles (
    id SERIAL PRIMARY KEY,
    crop_name VARCHAR(100) NOT NULL,
    scientific_name VARCHAR(150),
    category VARCHAR(50),
    calories_per_100g DECIMAL(8,2),
    protein_g DECIMAL(8,2),
    carbs_g DECIMAL(8,2),
    fiber_g DECIMAL(8,2),
    fat_g DECIMAL(8,2),
    vitamin_c_mg DECIMAL(8,2),
    vitamin_a_iu DECIMAL(10,2),
    calcium_mg DECIMAL(8,2),
    iron_mg DECIMAL(8,2),
    potassium_mg DECIMAL(10,2),
    magnesium_mg DECIMAL(8,2),
    phosphorus_mg DECIMAL(8,2),
    zinc_mg DECIMAL(8,2),
    folate_mcg DECIMAL(8,2),
    water_content_percent DECIMAL(5,2),
    growing_season VARCHAR(50),
    harvest_time VARCHAR(50),
    storage_requirements TEXT,
    nutritional_benefits TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create table for food nutrition data
CREATE TABLE IF NOT EXISTS food_nutrition_data (
    id SERIAL PRIMARY KEY,
    food_name VARCHAR(100) NOT NULL,
    food_group VARCHAR(50),
    serving_size VARCHAR(50),
    calories DECIMAL(8,2),
    protein_g DECIMAL(8,2),
    carbs_g DECIMAL(8,2),
    fat_g DECIMAL(8,2),
    fiber_g DECIMAL(8,2),
    sugar_g DECIMAL(8,2),
    sodium_mg DECIMAL(8,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create table for personal nutrition tracking
CREATE TABLE IF NOT EXISTS personal_nutrition_tracker (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    date_recorded DATE NOT NULL,
    meal_type VARCHAR(20),
    food_item VARCHAR(100),
    quantity DECIMAL(8,2),
    unit VARCHAR(20),
    calories_consumed DECIMAL(8,2),
    protein_consumed DECIMAL(8,2),
    carbs_consumed DECIMAL(8,2),
    fat_consumed DECIMAL(8,2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert some test data for integration tests
INSERT INTO crop_nutrition_profiles (
    crop_name, scientific_name, category, calories_per_100g, protein_g, carbs_g, 
    fiber_g, fat_g, vitamin_c_mg, vitamin_a_iu, calcium_mg, iron_mg, 
    potassium_mg, magnesium_mg, phosphorus_mg, zinc_mg, folate_mcg, 
    water_content_percent, growing_season, harvest_time, storage_requirements, 
    nutritional_benefits
) VALUES 
('Test Tomato', 'Solanum lycopersicum', 'Vegetable', 18.0, 0.9, 3.9, 
 1.2, 0.2, 13.7, 833.0, 10.0, 0.3, 
 237.0, 11.0, 24.0, 0.2, 15.0, 
 94.5, 'Spring-Summer', 'July-September', 'Cool, dry place', 
 'Rich in lycopene and vitamin C');

INSERT INTO food_nutrition_data (
    food_name, food_group, serving_size, calories, protein_g, carbs_g, 
    fat_g, fiber_g, sugar_g, sodium_mg
) VALUES 
('Test Apple', 'Fruits', '1 medium (182g)', 95.0, 0.5, 25.0, 
 0.3, 4.0, 19.0, 2.0);

INSERT INTO personal_nutrition_tracker (
    user_id, date_recorded, meal_type, food_item, quantity, unit, 
    calories_consumed, protein_consumed, carbs_consumed, fat_consumed, notes
) VALUES 
('test_user', CURRENT_DATE, 'breakfast', 'Test Oatmeal', 1.0, 'cup', 
 150.0, 5.0, 27.0, 3.0, 'Integration test meal');
