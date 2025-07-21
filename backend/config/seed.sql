-- SebeiConnect Seed Data
-- Inserts initial crops and sample market prices

-- Insert common crops grown in Sebei region
INSERT INTO crops (name, category, unit_of_measure, seasonal_months, description) VALUES
-- Staple crops
('Maize', 'grains', 'sacks', ARRAY[3,4,5,9,10,11], 'Yellow and white maize varieties commonly grown in Sebei'),
('Beans', 'legumes', 'sacks', ARRAY[3,4,5,6,9,10,11], 'Climbing and bush beans, high protein crop'),
('Irish Potatoes', 'tubers', 'sacks', ARRAY[1,2,3,6,7,8,9,10,11,12], 'Round and long varieties, year-round production'),
('Sweet Potatoes', 'tubers', 'sacks', ARRAY[1,2,3,6,7,8,9,10,11,12], 'Orange and white flesh varieties'),

-- Vegetables
('Cabbage', 'vegetables', 'pieces', ARRAY[1,2,3,4,5,6,7,8,9,10,11,12], 'Fresh leafy vegetable, year-round production'),
('Tomatoes', 'vegetables', 'crates', ARRAY[1,2,3,4,5,6,7,8,9,10,11,12], 'Fresh tomatoes for local and urban markets'),
('Onions', 'vegetables', 'sacks', ARRAY[1,2,3,6,7,8,9,10,11,12], 'Red and white onions'),
('Carrots', 'vegetables', 'sacks', ARRAY[1,2,3,4,5,6,7,8,9,10,11,12], 'Fresh carrots for urban markets'),
('Green Peppers', 'vegetables', 'crates', ARRAY[1,2,3,4,5,6,7,8,9,10,11,12], 'Bell peppers and hot peppers'),

-- Fruits
('Bananas', 'fruits', 'bunches', ARRAY[1,2,3,4,5,6,7,8,9,10,11,12], 'Cooking and eating bananas'),
('Avocados', 'fruits', 'pieces', ARRAY[3,4,5,6,7,8,9], 'Hass and local varieties'),
('Passion Fruits', 'fruits', 'crates', ARRAY[1,2,3,10,11,12], 'Purple passion fruits'),

-- Cash crops
('Coffee', 'cash_crops', 'sacks', ARRAY[3,4,5,6,7,8], 'Arabica coffee beans'),
('Wheat', 'grains', 'sacks', ARRAY[1,2,3,7,8,9], 'Wheat for flour production');

-- Insert sample market prices for major markets
-- Kampala Market Prices
INSERT INTO market_prices (crop_id, location, min_price, max_price, average_price, price_date, source) 
SELECT 
    c.id,
    'Kampala',
    CASE c.name
        WHEN 'Maize' THEN 180000
        WHEN 'Beans' THEN 350000
        WHEN 'Irish Potatoes' THEN 250000
        WHEN 'Sweet Potatoes' THEN 180000
        WHEN 'Cabbage' THEN 1500
        WHEN 'Tomatoes' THEN 45000
        WHEN 'Onions' THEN 280000
        WHEN 'Carrots' THEN 220000
        WHEN 'Bananas' THEN 25000
        WHEN 'Coffee' THEN 7500
        ELSE 100000
    END as min_price,
    CASE c.name
        WHEN 'Maize' THEN 220000
        WHEN 'Beans' THEN 420000
        WHEN 'Irish Potatoes' THEN 320000
        WHEN 'Sweet Potatoes' THEN 230000
        WHEN 'Cabbage' THEN 2500
        WHEN 'Tomatoes' THEN 65000
        WHEN 'Onions' THEN 350000
        WHEN 'Carrots' THEN 280000
        WHEN 'Bananas' THEN 35000
        WHEN 'Coffee' THEN 9500
        ELSE 150000
    END as max_price,
    CASE c.name
        WHEN 'Maize' THEN 200000
        WHEN 'Beans' THEN 385000
        WHEN 'Irish Potatoes' THEN 285000
        WHEN 'Sweet Potatoes' THEN 205000
        WHEN 'Cabbage' THEN 2000
        WHEN 'Tomatoes' THEN 55000
        WHEN 'Onions' THEN 315000
        WHEN 'Carrots' THEN 250000
        WHEN 'Bananas' THEN 30000
        WHEN 'Coffee' THEN 8500
        ELSE 125000
    END as average_price,
    CURRENT_DATE,
    'market_survey'
FROM crops c;

-- Mbale Market Prices (slightly lower than Kampala)
INSERT INTO market_prices (crop_id, location, min_price, max_price, average_price, price_date, source) 
SELECT 
    c.id,
    'Mbale',
    CASE c.name
        WHEN 'Maize' THEN 160000
        WHEN 'Beans' THEN 320000
        WHEN 'Irish Potatoes' THEN 220000
        WHEN 'Sweet Potatoes' THEN 160000
        WHEN 'Cabbage' THEN 1200
        WHEN 'Tomatoes' THEN 40000
        WHEN 'Onions' THEN 260000
        WHEN 'Carrots' THEN 200000
        WHEN 'Bananas' THEN 22000
        WHEN 'Coffee' THEN 7000
        ELSE 90000
    END as min_price,
    CASE c.name
        WHEN 'Maize' THEN 200000
        WHEN 'Beans' THEN 390000
        WHEN 'Irish Potatoes' THEN 290000
        WHEN 'Sweet Potatoes' THEN 210000
        WHEN 'Cabbage' THEN 2200
        WHEN 'Tomatoes' THEN 58000
        WHEN 'Onions' THEN 320000
        WHEN 'Carrots' THEN 260000
        WHEN 'Bananas' THEN 32000
        WHEN 'Coffee' THEN 9000
        ELSE 140000
    END as max_price,
    CASE c.name
        WHEN 'Maize' THEN 180000
        WHEN 'Beans' THEN 355000
        WHEN 'Irish Potatoes' THEN 255000
        WHEN 'Sweet Potatoes' THEN 185000
        WHEN 'Cabbage' THEN 1700
        WHEN 'Tomatoes' THEN 49000
        WHEN 'Onions' THEN 290000
        WHEN 'Carrots' THEN 230000
        WHEN 'Bananas' THEN 27000
        WHEN 'Coffee' THEN 8000
        ELSE 115000
    END as average_price,
    CURRENT_DATE,
    'market_survey'
FROM crops c;

-- Create sample admin user
INSERT INTO users (phone_number, name, email, user_type, password_hash, is_verified, is_active, district, subcounty) 
VALUES ('+256700000000', 'SebeiConnect Admin', 'admin@sebeiconnect.com', 'admin', '$2b$12$LQv3c1yqBwkVsvGOLKRAO.w.ifsN8rHDVqf3EWIZwwqlFGxdmfhgy', TRUE, TRUE, 'Kapchorwa', 'Kapchorwa TC');

-- Create sample agent
INSERT INTO users (phone_number, name, user_type, is_verified, is_active, district, subcounty, parish, specialization) 
VALUES ('+256701000000', 'Sarah Chelangat', 'agent', TRUE, TRUE, 'Kapchorwa', 'Tegeres', 'Tegeres', ARRAY['Irish Potatoes', 'Maize', 'Beans']);

-- Create sample farmer
INSERT INTO users (phone_number, name, user_type, is_verified, is_active, district, subcounty, parish, village, farm_size) 
VALUES ('+256702000000', 'Joseph Kiplimo', 'farmer', TRUE, TRUE, 'Kapchorwa', 'Tegeres', 'Tegeres', 'Kamorok', 2.5);

-- Create sample buyer
INSERT INTO users (phone_number, name, email, user_type, is_verified, is_active, district, business_license) 
VALUES ('+256703000000', 'Fresh Foods Ltd', 'buyer@freshfoods.com', 'buyer', TRUE, TRUE, 'Kampala', 'BL2024001');

-- Create sample delivery agent
INSERT INTO users (phone_number, name, user_type, is_verified, is_active, district, vehicle_type, vehicle_registration) 
VALUES ('+256704000000', 'Moses Kiprotich', 'delivery_agent', TRUE, TRUE, 'Kapchorwa', 'pickup_truck', 'UAG123X');
