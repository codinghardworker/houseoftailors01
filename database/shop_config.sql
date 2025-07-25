-- =====================================================
-- House of Tailors - Simplified Shop Configuration Database Schema
-- Configuration for pickup and post delivery only
-- =====================================================

-- Drop existing functions and tables
DROP FUNCTION IF EXISTS get_shop_config();
DROP FUNCTION IF EXISTS update_shop_config(TEXT, JSONB);
DROP FUNCTION IF EXISTS get_pickup_availability(DATE);
DROP FUNCTION IF EXISTS get_available_pickup_dates();
DROP FUNCTION IF EXISTS generate_pickup_time_slots(DATE);

-- Create shop_config table
CREATE TABLE IF NOT EXISTS shop_config (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    config_key VARCHAR(100) NOT NULL UNIQUE,
    config_value JSONB NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_shop_config_key ON shop_config(config_key);
CREATE INDEX IF NOT EXISTS idx_shop_config_active ON shop_config(is_active);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_shop_config_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_shop_config_updated_at ON shop_config;
CREATE TRIGGER trigger_shop_config_updated_at
    BEFORE UPDATE ON shop_config
    FOR EACH ROW
    EXECUTE FUNCTION update_shop_config_updated_at();

-- Enable Row Level Security
ALTER TABLE shop_config ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Anyone can view active shop config" ON shop_config;
DROP POLICY IF EXISTS "Only service role can modify shop config" ON shop_config;

CREATE POLICY "Anyone can view active shop config" ON shop_config
    FOR SELECT USING (is_active = true);

CREATE POLICY "Only service role can modify shop config" ON shop_config
    FOR ALL USING (auth.role() = 'service_role');

-- =====================================================
-- INSERT SIMPLIFIED CONFIGURATION VALUES
-- =====================================================

INSERT INTO shop_config (config_key, config_value, description, is_active)
VALUES 
    -- Shop basic information
    ('shop_info', 
     '{
        "name": "House of Tailors",
        "address_line1": "123 Tailor Street",
        "address_line2": "Suite 456",
        "city": "London",
        "postal_code": "SW1A 1AA",
        "country": "United Kingdom",
        "phone": "+44 20 1234 5678",
        "email": "info@houseoftailors.com"
     }', 
     'Basic shop information and address',
     true),

    -- Delivery options and charges
    ('delivery_options', 
     '{
        "pickup_charge_pence": 1000,
        "post_delivery_charge_pence": 0,
        "free_delivery_threshold_pence": 5000,
        "currency": "GBP",
        "available_methods": ["pickup", "post"]
     }', 
     'Available delivery methods and charges in pence',
     true),

    -- Pickup time slots
    ('pickup_slots', 
     '{
        "monday": {"available_slots": ["10:00 AM - 11:00 AM", "11:00 AM - 12:00 PM", "12:00 PM - 1:00 PM", "2:00 PM - 3:00 PM", "3:00 PM - 4:00 PM", "4:00 PM - 5:00 PM"]},
        "tuesday": {"available_slots": ["10:00 AM - 11:00 AM", "11:00 AM - 12:00 PM", "12:00 PM - 1:00 PM", "2:00 PM - 3:00 PM", "3:00 PM - 4:00 PM", "4:00 PM - 5:00 PM"]},
        "wednesday": {"available_slots": ["10:00 AM - 11:00 AM", "11:00 AM - 12:00 PM", "12:00 PM - 1:00 PM", "2:00 PM - 3:00 PM", "3:00 PM - 4:00 PM", "4:00 PM - 5:00 PM"]},
        "thursday": {"available_slots": ["10:00 AM - 11:00 AM", "11:00 AM - 12:00 PM", "12:00 PM - 1:00 PM", "2:00 PM - 3:00 PM", "3:00 PM - 4:00 PM", "4:00 PM - 5:00 PM"]},
        "friday": {"available_slots": ["10:00 AM - 11:00 AM", "11:00 AM - 12:00 PM", "12:00 PM - 1:00 PM", "2:00 PM - 3:00 PM", "3:00 PM - 4:00 PM", "4:00 PM - 5:00 PM"]},
        "saturday": {"available_slots": ["10:00 AM - 11:00 AM", "11:00 AM - 12:00 PM", "12:00 PM - 1:00 PM", "2:00 PM - 3:00 PM"]},
        "sunday": {"available_slots": []}
     }', 
     'Available pickup time slots by day with 12-hour format',
     true),

    -- Available locations (cities and towns)
    ('available_locations', 
     '{
        "cities": [
          {
            "id": "london",
            "name": "London",
            "towns": [
              "Westminster", "Camden", "Islington", "Hackney", "Tower Hamlets",
              "Greenwich", "Lewisham", "Southwark", "Lambeth", "Wandsworth",
              "Hammersmith and Fulham", "Kensington and Chelsea", "Brent",
              "Ealing", "Hounslow", "Richmond upon Thames", "Kingston upon Thames",
              "Merton", "Sutton", "Croydon", "Bromley", "Bexley", "Havering",
              "Barking and Dagenham", "Redbridge", "Newham", "Waltham Forest",
              "Haringey", "Enfield", "Barnet", "Harrow", "Hillingdon"
            ]
          },
          {
            "id": "newcastle",
            "name": "Newcastle",
            "towns": [
              "City Centre", "Gosforth", "Jesmond", "Heaton", "Walker",
              "Byker", "Felling", "Gateshead", "Low Fell", "Whickham",
              "Blaydon", "Ryton", "Crawcrook", "Prudhoe", "Hexham",
              "Corbridge", "Ponteland", "Cramlington", "Blyth", "Ashington",
              "Morpeth", "Alnwick", "Berwick-upon-Tweed"
            ]
          }
        ]
     }', 
     'Available cities and their towns for location selection',
     true)

ON CONFLICT (config_key) 
DO UPDATE SET 
    config_value = EXCLUDED.config_value,
    description = EXCLUDED.description,
    is_active = EXCLUDED.is_active,
    updated_at = NOW();

-- =====================================================
-- SIMPLIFIED SHOP CONFIGURATION FUNCTIONS
-- =====================================================

-- Function: Get all shop configuration as JSON
CREATE OR REPLACE FUNCTION get_shop_config()
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_object_agg(config_key, config_value) INTO result
    FROM shop_config
    WHERE is_active = true;
    
    RETURN COALESCE(result, '{}'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Update specific shop configuration
CREATE OR REPLACE FUNCTION update_shop_config(p_config_key TEXT, p_config_value JSONB)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    -- Update the configuration
    UPDATE shop_config 
    SET 
        config_value = p_config_value,
        updated_at = NOW()
    WHERE config_key = p_config_key AND is_active = true;
    
    -- Return the updated configuration
    SELECT json_build_object(
        'config_key', config_key,
        'config_value', config_value,
        'updated_at', updated_at,
        'success', true
    ) INTO result
    FROM shop_config
    WHERE config_key = p_config_key AND is_active = true;
    
    -- If no rows were updated, return error
    IF result IS NULL THEN
        result := json_build_object(
            'config_key', p_config_key,
            'error', 'Configuration key not found or inactive',
            'success', false
        );
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE shop_config IS 'Simplified configuration storage for shop settings';
COMMENT ON COLUMN shop_config.config_key IS 'Unique identifier for configuration setting';
COMMENT ON COLUMN shop_config.config_value IS 'JSON configuration data';
COMMENT ON COLUMN shop_config.description IS 'Human-readable description of the configuration';
COMMENT ON COLUMN shop_config.is_active IS 'Whether this configuration is currently active';

COMMENT ON FUNCTION get_shop_config() IS 'Returns all active shop configuration as JSON object';
COMMENT ON FUNCTION update_shop_config(TEXT, JSONB) IS 'Updates specific configuration key with new value';