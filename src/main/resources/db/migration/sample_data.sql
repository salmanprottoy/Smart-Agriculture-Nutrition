-- Smart Agriculture Nutrition - Complete Sample Data Migration
-- This file contains comprehensive sample data for all tables
-- Run this after the initial database schema setup

-- Clear existing data and reset sequences
TRUNCATE TABLE meal_sources, harvest_batches, personal_nutrition_trackers, crop_nutrition_profiles RESTART IDENTITY CASCADE;

-- Insert sample data for crop_nutrition_profiles table
INSERT INTO crop_nutrition_profiles (
    crop_name, farm_location, growing_method, soil_nutrients, crop_nutrients, 
    expected_harvest_date, sustainability_score, certifications, created_at, updated_at
) VALUES 
('Organic Cherry Tomatoes', 'Jyväskylä, Finland', 'organic', 
 '{"Nitrogen": 45.2, "Phosphorus": 23.1, "Potassium": 180.5, "pH": 6.8}',
 '{"Vitamin C": 28.7, "Potassium": 237.0, "Lycopene": 2.6, "Folate": 15.0}',
 '2024-08-30', 8.7, ARRAY['Organic Certified', 'EU Organic', 'Carbon Neutral'], NOW(), NOW()),

('Hydroponic Carrots', 'Tampere, Finland', 'hydroponic',
 '{"Nitrogen": 38.5, "Phosphorus": 18.2, "Potassium": 165.3, "pH": 6.2}',
 '{"Beta-carotene": 8285.0, "Vitamin A": 835.0, "Fiber": 2.8, "Potassium": 320.0}',
 '2024-07-15', 7.2, ARRAY['Hydroponic Certified', 'Pesticide Free'], NOW(), NOW()),

('Heritage Wheat', 'Turku, Finland', 'traditional',
 '{"Nitrogen": 52.1, "Phosphorus": 28.4, "Potassium": 195.7, "pH": 7.1}',
 '{"Protein": 13.2, "Fiber": 12.2, "Iron": 3.6, "Magnesium": 126.0}',
 '2024-09-20', 6.8, ARRAY['Heritage Variety', 'Non-GMO'], NOW(), NOW()),

('Organic Spinach', 'Helsinki, Finland', 'organic',
 '{"Nitrogen": 48.3, "Phosphorus": 25.7, "Potassium": 188.2, "pH": 6.9, "Calcium": 120.5}',
 '{"Iron": 2.7, "Vitamin K": 483.0, "Folate": 194.0, "Vitamin A": 469.0, "Calcium": 99.0}',
 '2024-06-15', 9.1, ARRAY['Organic Certified', 'Local Farm', 'Sustainable'], NOW(), NOW()),

('Hydroponic Lettuce', 'Oulu, Finland', 'hydroponic',
 '{"Nitrogen": 42.1, "Phosphorus": 20.3, "Potassium": 172.8, "pH": 6.4}',
 '{"Vitamin A": 370.0, "Folate": 38.0, "Vitamin K": 126.0, "Potassium": 194.0}',
 '2024-05-20', 7.8, ARRAY['Hydroponic Certified', 'Year-round Production'], NOW(), NOW()),

('Traditional Potatoes', 'Kuopio, Finland', 'traditional',
 '{"Nitrogen": 35.8, "Phosphorus": 22.1, "Potassium": 210.4, "pH": 6.6}',
 '{"Vitamin C": 19.7, "Potassium": 425.0, "Vitamin B6": 0.3, "Fiber": 2.2}',
 '2024-09-10', 6.5, ARRAY['Traditional Variety', 'Local Heritage'], NOW(), NOW()),

('Organic Blueberries', 'Rovaniemi, Finland', 'organic',
 '{"Nitrogen": 28.5, "Phosphorus": 15.2, "Potassium": 145.3, "pH": 5.2, "Organic_Matter": 8.5}',
 '{"Anthocyanins": 163.0, "Vitamin C": 9.7, "Vitamin K": 19.3, "Manganese": 0.3}',
 '2024-08-05', 9.3, ARRAY['Organic Certified', 'Wild Variety', 'Antioxidant Rich'], NOW(), NOW()),

('Greenhouse Cucumbers', 'Lahti, Finland', 'hydroponic',
 '{"Nitrogen": 40.2, "Phosphorus": 18.8, "Potassium": 168.5, "pH": 6.3}',
 '{"Vitamin K": 16.4, "Potassium": 147.0, "Magnesium": 13.0, "Vitamin C": 2.8}',
 '2024-07-25', 7.6, ARRAY['Greenhouse Grown', 'Pesticide Free', 'Controlled Environment'], NOW(), NOW()),

('Organic Kale', 'Vaasa, Finland', 'organic',
 '{"Nitrogen": 51.7, "Phosphorus": 27.3, "Potassium": 192.1, "pH": 6.8}',
 '{"Vitamin K": 704.8, "Vitamin A": 681.0, "Vitamin C": 120.0, "Calcium": 150.0}',
 '2024-06-30', 9.0, ARRAY['Organic Certified', 'Superfood', 'High Nutrition'], NOW(), NOW()),

('Traditional Barley', 'Joensuu, Finland', 'traditional',
 '{"Nitrogen": 46.8, "Phosphorus": 24.6, "Potassium": 185.7, "pH": 7.0}',
 '{"Fiber": 17.3, "Protein": 12.5, "Manganese": 1.9, "Selenium": 37.7}',
 '2024-08-20', 6.9, ARRAY['Traditional Grain', 'Ancient Variety'], NOW(), NOW()),

('Hydroponic Strawberries', 'Pori, Finland', 'hydroponic',
 '{"Nitrogen": 44.5, "Phosphorus": 21.2, "Potassium": 175.8, "pH": 6.1}',
 '{"Vitamin C": 58.8, "Folate": 24.0, "Potassium": 153.0, "Anthocyanins": 45.2}',
 '2024-06-10', 8.2, ARRAY['Hydroponic Certified', 'Premium Quality', 'Extended Season'], NOW(), NOW()),

('Organic Cabbage', 'Mikkeli, Finland', 'organic',
 '{"Nitrogen": 39.6, "Phosphorus": 19.8, "Potassium": 162.4, "pH": 6.7}',
 '{"Vitamin C": 36.6, "Vitamin K": 76.0, "Folate": 43.0, "Fiber": 2.5}',
 '2024-09-05', 8.4, ARRAY['Organic Certified', 'Cold Hardy', 'Storage Variety'], NOW(), NOW()),

('Traditional Rye', 'Seinäjoki, Finland', 'traditional',
 '{"Nitrogen": 49.3, "Phosphorus": 26.1, "Potassium": 189.6, "pH": 6.9}',
 '{"Fiber": 15.1, "Protein": 10.3, "Magnesium": 110.0, "Phosphorus": 332.0}',
 '2024-08-15', 7.1, ARRAY['Traditional Grain', 'Nordic Variety'], NOW(), NOW()),

('Greenhouse Peppers', 'Kokkola, Finland', 'hydroponic',
 '{"Nitrogen": 43.8, "Phosphorus": 20.7, "Potassium": 174.2, "pH": 6.2}',
 '{"Vitamin C": 127.7, "Vitamin A": 157.0, "Vitamin B6": 0.3, "Folate": 26.0}',
 '2024-07-30', 7.9, ARRAY['Greenhouse Grown', 'High Vitamin C', 'Colorful Varieties'], NOW(), NOW()),

('Organic Broccoli', 'Hämeenlinna, Finland', 'organic',
 '{"Nitrogen": 47.2, "Phosphorus": 23.8, "Potassium": 181.5, "pH": 6.8}',
 '{"Vitamin C": 89.2, "Vitamin K": 101.6, "Folate": 63.0, "Fiber": 2.6}',
 '2024-06-25', 8.8, ARRAY['Organic Certified', 'Cruciferous', 'Cancer Fighting'], NOW(), NOW()),

('Traditional Oats', 'Kajaani, Finland', 'traditional',
 '{"Nitrogen": 45.1, "Phosphorus": 22.9, "Potassium": 178.3, "pH": 6.8}',
 '{"Fiber": 10.6, "Protein": 16.9, "Manganese": 4.9, "Phosphorus": 523.0}',
 '2024-08-25', 7.3, ARRAY['Traditional Grain', 'Heart Healthy', 'Nordic Oats'], NOW(), NOW()),

('Hydroponic Radishes', 'Kotka, Finland', 'hydroponic',
 '{"Nitrogen": 36.4, "Phosphorus": 17.2, "Potassium": 158.7, "pH": 6.0}',
 '{"Vitamin C": 14.8, "Folate": 25.0, "Potassium": 233.0, "Fiber": 1.6}',
 '2024-05-15', 7.4, ARRAY['Fast Growing', 'Hydroponic Certified', 'Spicy Variety'], NOW(), NOW()),

('Organic Beets', 'Lappeenranta, Finland', 'organic',
 '{"Nitrogen": 41.7, "Phosphorus": 21.5, "Potassium": 169.8, "pH": 6.5}',
 '{"Folate": 109.0, "Manganese": 0.3, "Potassium": 325.0, "Nitrates": 250.0}',
 '2024-09-15', 8.6, ARRAY['Organic Certified', 'Blood Sugar Friendly', 'Natural Nitrates'], NOW(), NOW()),

('Traditional Turnips', 'Iisalmi, Finland', 'traditional',
 '{"Nitrogen": 33.2, "Phosphorus": 16.8, "Potassium": 152.4, "pH": 6.4}',
 '{"Vitamin C": 21.0, "Fiber": 1.8, "Potassium": 191.0, "Calcium": 30.0}',
 '2024-10-01', 6.7, ARRAY['Traditional Root', 'Cold Storage', 'Nordic Heritage'], NOW(), NOW()),

('Greenhouse Herbs Mix', 'Rauma, Finland', 'hydroponic',
 '{"Nitrogen": 38.9, "Phosphorus": 19.1, "Potassium": 164.6, "pH": 6.3}',
 '{"Essential_Oils": 2.5, "Vitamin K": 310.0, "Iron": 3.7, "Calcium": 138.0}',
 '2024-12-31', 8.1, ARRAY['Year-round Production', 'Culinary Herbs', 'Aromatic'], NOW(), NOW());

-- Insert sample data for personal_nutrition_trackers table
INSERT INTO personal_nutrition_trackers (
    user_name, age, current_bmi, health_goals, dietary_restrictions, 
    daily_nutrient_intake, farm_to_fork_score, created_at, updated_at
) VALUES 
('Alejandro Fernandez Armas', 29, 23.7, ARRAY['Athletic Performance'], ARRAY['High Protein'], 
 '{"calories": 2600, "protein": 130, "carbs": 325, "fat": 87}', 8.5, NOW(), NOW()),

('Arsalan Vosough', 31, 23.1, ARRAY['Weight Maintenance'], ARRAY['Halal'], 
 '{"calories": 2300, "protein": 115, "carbs": 288, "fat": 77}', 8.2, NOW(), NOW()),

('Hassan Syed', 26, 23.8, ARRAY['Muscle Gain'], ARRAY['High Protein', 'Halal'], 
 '{"calories": 2800, "protein": 140, "carbs": 350, "fat": 93}', 8.8, NOW(), NOW()),

('Zoltan Papp', 38, 24.8, ARRAY['Weight Loss'], ARRAY['Low Carb'], 
 '{"calories": 2000, "protein": 150, "carbs": 100, "fat": 111}', 7.9, NOW(), NOW()),

('Muhammad Feroz', 33, 24.4, ARRAY['General Health'], ARRAY['Halal', 'Organic Preferred'], 
 '{"calories": 2400, "protein": 120, "carbs": 300, "fat": 80}', 9.1, NOW(), NOW()),

('Haben Eyasu', 27, 23.1, ARRAY['Weight Gain'], ARRAY['Vegetarian', 'High Calorie'], 
 '{"calories": 2700, "protein": 108, "carbs": 405, "fat": 90}', 8.7, NOW(), NOW()),

('Ke Qiu', 24, 21.9, ARRAY['General Health'], ARRAY['Low Sodium', 'Heart Healthy'], 
 '{"calories": 2100, "protein": 105, "carbs": 263, "fat": 70}', 8.4, NOW(), NOW()),

('Danial Farooq', 30, 24.1, ARRAY['Athletic Performance'], ARRAY['Halal', 'High Protein'], 
 '{"calories": 2650, "protein": 133, "carbs": 331, "fat": 88}', 8.6, NOW(), NOW()),

('Javeria Kanwal', 25, 21.6, ARRAY['Weight Maintenance'], ARRAY['Halal', 'Vegetarian'], 
 '{"calories": 2000, "protein": 80, "carbs": 300, "fat": 67}', 9.0, NOW(), NOW()),

('Sofiia Mikhailova', 28, 21.9, ARRAY['Fitness Goals'], ARRAY['Gluten Free', 'High Protein'], 
 '{"calories": 2350, "protein": 118, "carbs": 294, "fat": 78}', 8.3, NOW(), NOW()),

('João Moreira', 32, 24.2, ARRAY['Athletic Performance'], ARRAY['High Protein', 'Sports Nutrition'], 
 '{"calories": 2900, "protein": 145, "carbs": 363, "fat": 97}', 8.9, NOW(), NOW()),

('Luca Stoian', 29, 23.5, ARRAY['General Health'], ARRAY['Mediterranean Diet'], 
 '{"calories": 2250, "protein": 113, "carbs": 281, "fat": 75}', 8.7, NOW(), NOW()),

('Sufian Embark Aomar', 34, 24.3, ARRAY['Weight Loss'], ARRAY['Halal', 'Low Carb'], 
 '{"calories": 2100, "protein": 158, "carbs": 105, "fat": 117}', 8.1, NOW(), NOW()),

('Elham Pournouri', 26, 21.9, ARRAY['General Health'], ARRAY['Vegetarian', 'Organic Preferred'], 
 '{"calories": 2150, "protein": 86, "carbs": 323, "fat": 72}', 9.2, NOW(), NOW()),

('Md Ariful Islam', 31, 23.7, ARRAY['Muscle Gain'], ARRAY['Halal', 'High Protein'], 
 '{"calories": 2550, "protein": 128, "carbs": 319, "fat": 85}', 8.4, NOW(), NOW()),

('Md. Salman Hossan Prottoy', 23, 22.3, ARRAY['Athletic Performance'], ARRAY['Halal', 'Sports Nutrition'], 
 '{"calories": 2750, "protein": 138, "carbs": 344, "fat": 92}', 8.8, NOW(), NOW()),

('Jakub Formánek', 35, 25.8, ARRAY['Weight Loss'], ARRAY['Low Carb', 'High Protein'], 
 '{"calories": 1950, "protein": 146, "carbs": 98, "fat": 108}', 7.8, NOW(), NOW()),

('Muhammad Hassan Ali', 28, 23.4, ARRAY['General Health'], ARRAY['Halal', 'Balanced Diet'], 
 '{"calories": 2400, "protein": 120, "carbs": 300, "fat": 80}', 8.5, NOW(), NOW()),

('Talha Bin Nayyar', 27, 23.5, ARRAY['Weight Maintenance'], ARRAY['Halal'], 
 '{"calories": 2300, "protein": 115, "carbs": 288, "fat": 77}', 8.3, NOW(), NOW()),

('Sibrah Rahim', 26, 22.1, ARRAY['Fitness Goals'], ARRAY['Halal', 'High Protein'], 
 '{"calories": 2200, "protein": 110, "carbs": 275, "fat": 73}', 8.6, NOW(), NOW()),

('Sana Mazhar', 24, 21.8, ARRAY['General Health'], ARRAY['Halal', 'Vegetarian'], 
 '{"calories": 2000, "protein": 80, "carbs": 300, "fat": 67}', 9.1, NOW(), NOW()),

('Asma Sikandar', 29, 22.5, ARRAY['Weight Maintenance'], ARRAY['Halal', 'Organic Preferred'], 
 '{"calories": 2100, "protein": 84, "carbs": 315, "fat": 70}', 8.9, NOW(), NOW());

-- Insert sample data for harvest_batches table
INSERT INTO harvest_batches (
    crop_profile_id, harvest_date, quantity_kg, quality_grade, 
    actual_nutrients, storage_conditions, batch_notes, created_at, updated_at
) VALUES 
(1, '2024-08-30', 125.5, 'A', 
 '{"Vitamin C": 30.2, "Potassium": 245.0, "Lycopene": 2.8, "Sugar": 4.2}',
 'Cold Room at 12°C, 85% humidity', 'Premium quality tomatoes', NOW(), NOW()),

(1, '2024-09-05', 98.3, 'A+', 
 '{"Vitamin C": 32.1, "Potassium": 252.0, "Lycopene": 3.1, "Sugar": 4.5}',
 'Cold Room at 12°C, 85% humidity', 'Exceptional quality batch', NOW(), NOW()),

(2, '2024-07-15', 87.2, 'A', 
 '{"Beta-carotene": 8500.0, "Vitamin A": 850.0, "Fiber": 3.0, "Sugar": 4.7}',
 'Refrigerated at 4°C, 95% humidity', 'Fresh hydroponic carrots', NOW(), NOW()),

(3, '2024-09-20', 245.7, 'B+', 
 '{"Protein": 13.5, "Fiber": 12.5, "Iron": 3.8, "Gluten": 11.2}',
 'Grain Silo at 15°C, 12% humidity', 'Heritage wheat variety', NOW(), NOW()),

(4, '2024-06-15', 45.3, 'A+', 
 '{"Iron": 2.9, "Vitamin K": 495.0, "Folate": 200.0, "Nitrates": 180.0}',
 'Hydro Cooling at 2°C, 95% humidity', 'Organic spinach premium grade', NOW(), NOW()),

(5, '2024-05-20', 38.7, 'A', 
 '{"Vitamin A": 380.0, "Folate": 40.0, "Vitamin K": 130.0, "Water": 95.6}',
 'Mist Cooling at 4°C, 98% humidity', 'Fresh hydroponic lettuce', NOW(), NOW()),

(6, '2024-09-10', 189.4, 'B', 
 '{"Vitamin C": 18.5, "Potassium": 420.0, "Starch": 17.5, "Fiber": 2.1}',
 'Root Cellar at 8°C, 85% humidity', 'Traditional potato variety', NOW(), NOW()),

(7, '2024-08-05', 23.8, 'A+', 
 '{"Anthocyanins": 170.0, "Vitamin C": 10.2, "Antioxidants": 9621.0, "Sugar": 10.0}',
 'Flash Frozen at 0°C, 90% humidity', 'Wild organic blueberries', NOW(), NOW()),

(8, '2024-07-25', 67.9, 'A', 
 '{"Vitamin K": 17.0, "Potassium": 150.0, "Water": 96.7, "Silica": 7.0}',
 'Controlled Atmosphere at 10°C, 95% humidity', 'Greenhouse cucumbers', NOW(), NOW()),

(9, '2024-06-30', 41.2, 'A+', 
 '{"Vitamin K": 720.0, "Vitamin A": 690.0, "Vitamin C": 125.0, "Calcium": 155.0}',
 'Hydro Cooling at 2°C, 95% humidity', 'Superfood organic kale', NOW(), NOW()),

(10, '2024-08-20', 167.3, 'B+', 
 '{"Fiber": 17.8, "Protein": 12.8, "Beta-glucan": 4.2, "Selenium": 40.0}',
 'Grain Silo at 15°C, 12% humidity', 'Traditional barley grain', NOW(), NOW()),

(11, '2024-06-10', 28.5, 'A+', 
 '{"Vitamin C": 62.0, "Folate": 26.0, "Anthocyanins": 48.0, "Sugar": 4.9}',
 'Quick Cooling at 2°C, 90% humidity', 'Premium strawberries', NOW(), NOW()),

(12, '2024-09-05', 156.8, 'A', 
 '{"Vitamin C": 38.0, "Vitamin K": 78.0, "Folate": 45.0, "Sulfur": 680.0}',
 'Cold Storage at 4°C, 95% humidity', 'Organic cabbage storage variety', NOW(), NOW()),

(13, '2024-08-15', 198.2, 'B+', 
 '{"Fiber": 15.5, "Protein": 10.6, "Manganese": 2.6, "Lignans": 95.0}',
 'Grain Silo at 15°C, 12% humidity', 'Nordic rye grain', NOW(), NOW()),

(14, '2024-07-30', 73.4, 'A', 
 '{"Vitamin C": 130.0, "Vitamin A": 160.0, "Capsaicin": 0.01, "Water": 92.0}',
 'Controlled Atmosphere at 8°C, 90% humidity', 'Colorful bell peppers', NOW(), NOW()),

(15, '2024-06-25', 89.6, 'A+', 
 '{"Vitamin C": 92.0, "Vitamin K": 105.0, "Sulforaphane": 73.0, "Folate": 65.0}',
 'Hydro Cooling at 2°C, 95% humidity', 'Cancer-fighting broccoli', NOW(), NOW()),

(16, '2024-08-25', 134.7, 'A', 
 '{"Fiber": 10.9, "Protein": 17.2, "Beta-glucan": 4.0, "Avenanthramides": 20.0}',
 'Grain Silo at 15°C, 12% humidity', 'Heart-healthy Nordic oats', NOW(), NOW()),

(17, '2024-05-15', 15.3, 'A', 
 '{"Vitamin C": 15.5, "Folate": 26.0, "Isothiocyanates": 25.0, "Water": 95.3}',
 'Cold Storage at 4°C, 95% humidity', 'Spicy radish variety', NOW(), NOW()),

(18, '2024-09-15', 112.4, 'A', 
 '{"Folate": 115.0, "Manganese": 0.35, "Nitrates": 260.0, "Betalains": 300.0}',
 'Root Storage at 4°C, 95% humidity', 'Blood sugar friendly beets', NOW(), NOW()),

(19, '2024-10-01', 78.9, 'B', 
 '{"Vitamin C": 22.0, "Fiber": 1.9, "Glucosinolates": 120.0, "Calcium": 32.0}',
 'Root Cellar at 4°C, 95% humidity', 'Traditional turnip variety', NOW(), NOW()),

(20, '2024-12-31', 12.7, 'A+', 
 '{"Essential_Oils": 2.8, "Vitamin K": 320.0, "Antioxidants": 1250.0, "Volatile_Compounds": 45.0}',
 'Herb Cooler at 4°C, 85% humidity', 'Aromatic culinary herbs', NOW(), NOW());

-- Insert sample data for meal_sources table
INSERT INTO meal_sources (
    tracker_id, meal_name, meal_date, ingredients, local_source_percentage, 
    nutritional_density, farm_origins, meal_notes, created_at, updated_at
) VALUES 
-- Meals for Alejandro Fernandez Armas (tracker_id: 1)
(1, 'Organic Tomato Salad', '2024-09-01', 
 '{"tomatoes": "150g", "olive_oil": "15ml", "basil": "5g", "salt": "2g"}',
 95.5, 8.7, ARRAY['Jyväskylä Farm', 'Local Herb Garden'], 
 'Fresh organic tomatoes with local herbs', NOW(), NOW()),

(1, 'Power Smoothie', '2024-09-01', 
 '{"spinach": "100g", "strawberries": "120g", "protein_powder": "30g"}',
 85.2, 9.1, ARRAY['Helsinki Organic Farm', 'Pori Hydroponic'], 
 'High protein breakfast smoothie', NOW(), NOW()),

-- Meals for Arsalan Vosough (tracker_id: 2)
(2, 'Hydroponic Carrot Soup', '2024-09-01', 
 '{"carrots": "200g", "ginger": "10g", "coconut_milk": "100ml"}',
 90.3, 8.2, ARRAY['Tampere Hydroponic Farm'], 
 'Halal-certified hydroponic carrots', NOW(), NOW()),

(2, 'Heritage Wheat Bread', '2024-09-02', 
 '{"wheat_flour": "80g", "yeast": "5g", "water": "50ml", "salt": "3g"}',
 100.0, 7.8, ARRAY['Turku Heritage Farm'], 
 'Traditional bread from heritage wheat', NOW(), NOW()),

-- Meals for Hassan Syed (tracker_id: 3)
(3, 'Muscle Building Kale Bowl', '2024-09-01', 
 '{"kale": "150g", "quinoa": "100g", "chickpeas": "80g", "tahini": "20g"}',
 88.7, 9.3, ARRAY['Vaasa Organic Farm'], 
 'High protein halal meal for muscle gain', NOW(), NOW()),

(3, 'Barley Protein Porridge', '2024-09-02', 
 '{"barley": "120g", "almond_milk": "200ml", "dates": "30g"}',
 92.1, 8.5, ARRAY['Joensuu Traditional Farm'], 
 'Ancient grain breakfast for athletes', NOW(), NOW()),

-- Meals for Zoltan Papp (tracker_id: 4)
(4, 'Low-Carb Cucumber Salad', '2024-09-01', 
 '{"cucumbers": "180g", "feta_cheese": "50g", "olive_oil": "10ml"}',
 75.8, 7.9, ARRAY['Lahti Greenhouse'], 
 'Low-carb meal for weight loss', NOW(), NOW()),

(4, 'Radish and Herb Mix', '2024-09-02', 
 '{"radishes": "100g", "herbs": "20g", "lemon": "15ml"}',
 95.2, 8.1, ARRAY['Kotka Hydroponic', 'Rauma Herb Farm'], 
 'Spicy low-carb snack', NOW(), NOW()),

-- Meals for Muhammad Feroz (tracker_id: 5)
(5, 'Organic Blueberry Bowl', '2024-09-01', 
 '{"blueberries": "150g", "oats": "80g", "honey": "15g"}',
 98.5, 9.2, ARRAY['Rovaniemi Organic Farm', 'Kajaani Traditional Farm'], 
 'Halal organic breakfast with antioxidants', NOW(), NOW()),

(5, 'Traditional Potato Curry', '2024-09-02', 
 '{"potatoes": "200g", "turmeric": "5g", "coconut_oil": "15ml"}',
 89.3, 7.6, ARRAY['Kuopio Traditional Farm'], 
 'Halal traditional potato dish', NOW(), NOW()),

-- Meals for Haben Eyasu (tracker_id: 6)
(6, 'High-Calorie Lettuce Wraps', '2024-09-01', 
 '{"lettuce": "120g", "avocado": "100g", "nuts": "50g", "olive_oil": "20ml"}',
 82.4, 8.9, ARRAY['Oulu Hydroponic Farm'], 
 'Vegetarian high-calorie meal for weight gain', NOW(), NOW()),

(6, 'Cabbage and Bean Stew', '2024-09-02', 
 '{"cabbage": "180g", "beans": "100g", "vegetable_broth": "200ml"}',
 91.7, 8.2, ARRAY['Mikkeli Organic Farm'], 
 'Hearty vegetarian stew', NOW(), NOW()),

-- Meals for Ke Qiu (tracker_id: 7)
(7, 'Heart-Healthy Oat Bowl', '2024-09-01', 
 '{"oats": "100g", "berries": "80g", "almonds": "20g"}',
 94.3, 8.8, ARRAY['Kajaani Traditional Farm', 'Rovaniemi Organic'], 
 'Low sodium breakfast for heart health', NOW(), NOW()),

(7, 'Steamed Broccoli', '2024-09-02', 
 '{"broccoli": "150g", "lemon": "10ml", "herbs": "5g"}',
 96.8, 9.1, ARRAY['Hämeenlinna Organic Farm'], 
 'Simple steamed vegetables', NOW(), NOW()),

-- Meals for Danial Farooq (tracker_id: 8)
(8, 'Athletic Performance Bowl', '2024-09-01', 
 '{"rye_bread": "100g", "peppers": "120g", "protein_powder": "40g"}',
 87.5, 8.4, ARRAY['Seinäjoki Traditional', 'Kokkola Greenhouse'], 
 'Halal high-protein meal for athletes', NOW(), NOW()),

(8, 'Beet and Turnip Salad', '2024-09-02', 
 '{"beets": "100g", "turnips": "80g", "olive_oil": "15ml"}',
 93.2, 8.7, ARRAY['Lappeenranta Organic', 'Iisalmi Traditional'], 
 'Nutrient-dense root vegetable salad', NOW(), NOW()),

-- Meals for Javeria Kanwal (tracker_id: 9)
(9, 'Halal Vegetarian Wrap', '2024-09-01', 
 '{"lettuce": "100g", "tomatoes": "80g", "hummus": "30g"}',
 88.9, 8.6, ARRAY['Oulu Hydroponic', 'Jyväskylä Organic'], 
 'Halal vegetarian meal', NOW(), NOW()),

(9, 'Herb-Infused Water', '2024-09-02', 
 '{"herbs": "10g", "water": "500ml", "lemon": "20ml"}',
 100.0, 7.8, ARRAY['Rauma Herb Farm'], 
 'Refreshing herbal drink', NOW(), NOW()),

-- Meals for Sofiia Mikhailova (tracker_id: 10)
(10, 'Gluten-Free Power Salad', '2024-09-01', 
 '{"spinach": "120g", "strawberries": "100g", "seeds": "25g"}',
 91.4, 9.0, ARRAY['Helsinki Organic', 'Pori Hydroponic'], 
 'Gluten-free high-protein salad', NOW(), NOW()),

(10, 'Cucumber Smoothie', '2024-09-02', 
 '{"cucumbers": "150g", "mint": "10g", "protein_powder": "30g"}',
 85.7, 8.3, ARRAY['Lahti Greenhouse'], 
 'Refreshing protein smoothie', NOW(), NOW()),

-- Meals for João Moreira (tracker_id: 11)
(11, 'Sports Nutrition Bowl', '2024-09-01', 
 '{"kale": "140g", "barley": "100g", "protein_powder": "50g"}',
 89.6, 9.2, ARRAY['Vaasa Organic', 'Joensuu Traditional'], 
 'High-protein sports nutrition meal', NOW(), NOW()),

(11, 'Recovery Smoothie', '2024-09-02', 
 '{"blueberries": "120g", "oats": "80g", "protein_powder": "40g"}',
 92.8, 9.0, ARRAY['Rovaniemi Organic', 'Kajaani Traditional'], 
 'Post-workout recovery drink', NOW(), NOW()),

-- Meals for Luca Stoian (tracker_id: 12)
(12, 'Mediterranean Salad', '2024-09-01', 
 '{"tomatoes": "120g", "cucumbers": "100g", "olive_oil": "20ml"}',
 87.3, 8.5, ARRAY['Jyväskylä Organic', 'Lahti Greenhouse'], 
 'Mediterranean diet inspired salad', NOW(), NOW()),

(12, 'Herb-Crusted Vegetables', '2024-09-02', 
 '{"peppers": "150g", "herbs": "15g", "olive_oil": "10ml"}',
 94.1, 8.8, ARRAY['Kokkola Greenhouse', 'Rauma Herb Farm'], 
 'Mediterranean herb vegetables', NOW(), NOW()),

-- Additional meals for remaining users (13-22)
(13, 'Low-Carb Radish Salad', '2024-09-01', 
 '{"radishes": "120g", "lettuce": "80g", "olive_oil": "15ml"}',
 92.5, 8.2, ARRAY['Kotka Hydroponic', 'Oulu Hydroponic'], 
 'Halal low-carb weight loss meal', NOW(), NOW()),

(14, 'Organic Vegetarian Bowl', '2024-09-01', 
 '{"spinach": "100g", "beets": "120g", "nuts": "30g"}',
 96.7, 9.3, ARRAY['Helsinki Organic', 'Lappeenranta Organic'], 
 'Organic vegetarian nutrition', NOW(), NOW()),

(15, 'Muscle Gain Smoothie', '2024-09-01', 
 '{"kale": "100g", "strawberries": "150g", "protein_powder": "45g"}',
 88.4, 9.1, ARRAY['Vaasa Organic', 'Pori Hydroponic'], 
 'Halal high-protein muscle building', NOW(), NOW()),

(16, 'Athletic Breakfast', '2024-09-01', 
 '{"oats": "120g", "blueberries": "100g", "protein_powder": "35g"}',
 93.6, 8.9, ARRAY['Kajaani Traditional', 'Rovaniemi Organic'], 
 'Halal sports nutrition breakfast', NOW(), NOW()),

(17, 'Weight Loss Salad', '2024-09-01', 
 '{"lettuce": "150g", "tomatoes": "100g", "herbs": "10g"}',
 91.8, 8.1, ARRAY['Oulu Hydroponic', 'Jyväskylä Organic'], 
 'Low-carb high-protein meal', NOW(), NOW()),

(18, 'Balanced Health Bowl', '2024-09-01', 
 '{"spinach": "120g", "carrots": "100g", "olive_oil": "15ml"}',
 89.7, 8.6, ARRAY['Helsinki Organic', 'Tampere Hydroponic'], 
 'Halal balanced nutrition', NOW(), NOW()),

(19, 'Maintenance Meal', '2024-09-01', 
 '{"cabbage": "130g", "herbs": "15g", "olive_oil": "10ml"}',
 94.2, 8.4, ARRAY['Mikkeli Organic', 'Rauma Herb Farm'], 
 'Halal weight maintenance', NOW(), NOW()),

(20, 'Fitness Smoothie', '2024-09-01', 
 '{"kale": "110g", "strawberries": "120g", "protein_powder": "40g"}',
 90.3, 8.8, ARRAY['Vaasa Organic', 'Pori Hydroponic'], 
 'Halal high-protein fitness meal', NOW(), NOW()),

(21, 'Vegetarian Health Bowl', '2024-09-01', 
 '{"spinach": "100g", "beets": "100g", "nuts": "25g"}',
 95.1, 9.0, ARRAY['Helsinki Organic', 'Lappeenranta Organic'], 
 'Halal vegetarian nutrition', NOW(), NOW()),

(22, 'Organic Maintenance Salad', '2024-09-01', 
 '{"lettuce": "120g", "tomatoes": "90g", "olive_oil": "12ml"}',
 92.8, 8.7, ARRAY['Oulu Hydroponic', 'Jyväskylä Organic'], 
 'Halal organic preferred meal', NOW(), NOW());

-- End of migration file
-- Total records inserted:
-- - 20 crop_nutrition_profiles 
-- - 22 personal_nutrition_trackers 
-- - 20 harvest_batches 
-- - 22 meal_sources
-- Total: 84 comprehensive sample records
