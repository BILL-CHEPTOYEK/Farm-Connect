-- SebeiConnect Database Schema
-- Creates all necessary tables for the platform

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (Farmers, Agents, Buyers, Delivery Agents, Admins)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('farmer', 'agent', 'buyer', 'delivery_agent', 'admin')),
    password_hash VARCHAR(255),
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    profile_image_url TEXT,
    
    -- Location information
    district VARCHAR(50),
    subcounty VARCHAR(50),
    parish VARCHAR(50),
    village VARCHAR(50),
    gps_coordinates POINT,
    
    -- User-specific information
    farm_size DECIMAL(10,2), -- For farmers (in acres)
    specialization TEXT[], -- For agents (crops they handle)
    business_license VARCHAR(100), -- For buyers and delivery agents
    vehicle_type VARCHAR(50), -- For delivery agents
    vehicle_registration VARCHAR(50), -- For delivery agents
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crops/Produce table
CREATE TABLE crops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL, -- vegetables, grains, fruits, etc.
    unit_of_measure VARCHAR(20) NOT NULL, -- kg, sacks, pieces, etc.
    seasonal_months INTEGER[], -- Array of months when crop is in season
    description TEXT,
    image_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Market prices table (dynamic pricing)
CREATE TABLE market_prices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    crop_id UUID REFERENCES crops(id) ON DELETE CASCADE,
    location VARCHAR(100) NOT NULL, -- Kampala, Mbale, Jinja, etc.
    min_price DECIMAL(10,2) NOT NULL,
    max_price DECIMAL(10,2) NOT NULL,
    average_price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'UGX',
    price_date DATE NOT NULL,
    source VARCHAR(50), -- market_survey, user_reported, etc.
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Farmer listings (produce available for sale)
CREATE TABLE farmer_listings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    agent_id UUID REFERENCES users(id), -- Agent handling this listing
    crop_id UUID REFERENCES crops(id) ON DELETE CASCADE,
    quantity DECIMAL(10,2) NOT NULL,
    unit_price DECIMAL(10,2),
    total_value DECIMAL(10,2),
    quality_grade VARCHAR(20) DEFAULT 'standard', -- premium, standard, basic
    harvest_date DATE,
    expiry_date DATE,
    description TEXT,
    images TEXT[], -- Array of image URLs
    status VARCHAR(20) DEFAULT 'available' CHECK (status IN ('available', 'reserved', 'sold', 'expired')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Buyer orders
CREATE TABLE buyer_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    buyer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    agent_id UUID REFERENCES users(id), -- Agent handling this order
    crop_id UUID REFERENCES crops(id) ON DELETE CASCADE,
    quantity_requested DECIMAL(10,2) NOT NULL,
    max_price_per_unit DECIMAL(10,2),
    total_budget DECIMAL(10,2),
    delivery_location TEXT NOT NULL,
    delivery_date DATE,
    special_requirements TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'matched', 'confirmed', 'in_transit', 'delivered', 'completed', 'cancelled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order matches (linking farmer listings with buyer orders)
CREATE TABLE order_matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    buyer_order_id UUID REFERENCES buyer_orders(id) ON DELETE CASCADE,
    farmer_listing_id UUID REFERENCES farmer_listings(id) ON DELETE CASCADE,
    agent_id UUID REFERENCES users(id), -- Agent facilitating the match
    quantity_matched DECIMAL(10,2) NOT NULL,
    agreed_price_per_unit DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    farmer_commission DECIMAL(10,2), -- What farmer gets
    agent_commission DECIMAL(10,2), -- Agent's commission
    platform_fee DECIMAL(10,2), -- Platform's fee
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'in_delivery', 'delivered', 'completed', 'disputed', 'cancelled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Delivery assignments
CREATE TABLE deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_match_id UUID REFERENCES order_matches(id) ON DELETE CASCADE,
    delivery_agent_id UUID REFERENCES users(id),
    pickup_location TEXT NOT NULL,
    delivery_location TEXT NOT NULL,
    pickup_contact VARCHAR(15),
    delivery_contact VARCHAR(15),
    estimated_distance DECIMAL(10,2), -- in kilometers
    delivery_fee DECIMAL(10,2) NOT NULL,
    pickup_time TIMESTAMP,
    delivery_time TIMESTAMP,
    estimated_delivery_time TIMESTAMP,
    delivery_notes TEXT,
    proof_of_pickup TEXT[], -- Image URLs
    proof_of_delivery TEXT[], -- Image URLs
    status VARCHAR(20) DEFAULT 'assigned' CHECK (status IN ('assigned', 'picked_up', 'in_transit', 'delivered', 'failed', 'cancelled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payments and transactions
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_match_id UUID REFERENCES order_matches(id) ON DELETE CASCADE,
    delivery_id UUID REFERENCES deliveries(id),
    payer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    payee_id UUID REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'UGX',
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('payment', 'commission', 'delivery_fee', 'platform_fee', 'refund')),
    payment_method VARCHAR(20) CHECK (payment_method IN ('mobile_money', 'bank_transfer', 'cash', 'escrow')),
    payment_provider VARCHAR(20), -- MTN, Airtel, etc.
    external_transaction_id VARCHAR(100), -- From payment provider
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'reversed')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- USSD sessions (for farmers without smartphones)
CREATE TABLE ussd_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(15) NOT NULL,
    user_id UUID REFERENCES users(id),
    current_menu VARCHAR(50),
    session_data JSONB, -- Store session state
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(20) NOT NULL CHECK (notification_type IN ('order', 'payment', 'delivery', 'price_alert', 'system')),
    related_entity_type VARCHAR(20), -- order, delivery, transaction, etc.
    related_entity_id UUID,
    is_read BOOLEAN DEFAULT FALSE,
    sent_via VARCHAR(20) DEFAULT 'app' CHECK (sent_via IN ('app', 'sms', 'email', 'ussd')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Price alerts (users can set alerts for specific crops/prices)
CREATE TABLE price_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    crop_id UUID REFERENCES crops(id) ON DELETE CASCADE,
    location VARCHAR(100),
    target_price DECIMAL(10,2) NOT NULL,
    alert_condition VARCHAR(10) CHECK (alert_condition IN ('above', 'below', 'equal')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Reviews and ratings
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reviewer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    reviewee_id UUID REFERENCES users(id) ON DELETE CASCADE,
    order_match_id UUID REFERENCES order_matches(id),
    delivery_id UUID REFERENCES deliveries(id),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    review_type VARCHAR(20) CHECK (review_type IN ('farmer', 'buyer', 'agent', 'delivery')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_users_phone_number ON users(phone_number);
CREATE INDEX idx_users_user_type ON users(user_type);
CREATE INDEX idx_users_location ON users(district, subcounty);
CREATE INDEX idx_farmer_listings_status ON farmer_listings(status);
CREATE INDEX idx_farmer_listings_crop ON farmer_listings(crop_id);
CREATE INDEX idx_buyer_orders_status ON buyer_orders(status);
CREATE INDEX idx_order_matches_status ON order_matches(status);
CREATE INDEX idx_deliveries_status ON deliveries(status);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_market_prices_date ON market_prices(price_date);
CREATE INDEX idx_market_prices_crop_location ON market_prices(crop_id, location);

-- Create functions for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_farmer_listings_updated_at BEFORE UPDATE ON farmer_listings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_buyer_orders_updated_at BEFORE UPDATE ON buyer_orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_order_matches_updated_at BEFORE UPDATE ON order_matches FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_deliveries_updated_at BEFORE UPDATE ON deliveries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_ussd_sessions_updated_at BEFORE UPDATE ON ussd_sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
