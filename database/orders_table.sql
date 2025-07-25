-- Create orders table for House of Tailors
-- This table stores all customer orders with their details

CREATE TABLE IF NOT EXISTS orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    payment_intent_id VARCHAR(255) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'gbp',
    status VARCHAR(50) NOT NULL DEFAULT 'pickup',
    delivery_method VARCHAR(50) NOT NULL DEFAULT 'pickup',
    delivery_info JSONB, -- Stores pickup dates, times, costs, and other delivery details
    billing_address JSONB,
    customer_name VARCHAR(255),
    customer_email VARCHAR(255),
    customer_phone VARCHAR(50),
    order_items JSONB NOT NULL, -- Complete cart items with all service details, notes, questions, etc.
    cart_metadata JSONB, -- Additional cart information like discounts, loyalty info, etc.
    service_summary JSONB, -- Summary of all services for quick filtering/reporting
    delivery_summary JSONB, -- Summary of delivery methods and costs across all items
    customer_notes TEXT, -- Any additional customer notes or special instructions
    loyalty_discount DECIMAL(10, 2) DEFAULT 0.00, -- Applied loyalty discount amount
    subtotal DECIMAL(10, 2) NOT NULL, -- Subtotal before discounts
    discount_codes JSONB, -- Array of applied discount codes
    ordered_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add new columns if they don't exist (for existing tables)
DO $$ 
BEGIN 
    -- Add delivery_info column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'delivery_info') THEN
        ALTER TABLE orders ADD COLUMN delivery_info JSONB;
    END IF;
    
    -- Add cart_metadata column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'cart_metadata') THEN
        ALTER TABLE orders ADD COLUMN cart_metadata JSONB;
    END IF;
    
    -- Add service_summary column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'service_summary') THEN
        ALTER TABLE orders ADD COLUMN service_summary JSONB;
    END IF;
    
    -- Add delivery_summary column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'delivery_summary') THEN
        ALTER TABLE orders ADD COLUMN delivery_summary JSONB;
    END IF;
    
    -- Add customer_notes column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'customer_notes') THEN
        ALTER TABLE orders ADD COLUMN customer_notes TEXT;
    END IF;
    
    -- Add loyalty_discount column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'loyalty_discount') THEN
        ALTER TABLE orders ADD COLUMN loyalty_discount DECIMAL(10, 2) DEFAULT 0.00;
    END IF;
    
    -- Add subtotal column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'subtotal') THEN
        ALTER TABLE orders ADD COLUMN subtotal DECIMAL(10, 2) NOT NULL DEFAULT 0.00;
    END IF;
    
    -- Add discount_codes column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'discount_codes') THEN
        ALTER TABLE orders ADD COLUMN discount_codes JSONB;
    END IF;
END $$;


-- Create index for efficient queries
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_payment_intent_id ON orders(payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_orders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_orders_updated_at ON orders;
CREATE TRIGGER trigger_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_orders_updated_at();

-- Add Row Level Security (RLS) for user data protection
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their own orders
DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own orders" ON orders;
CREATE POLICY "Users can insert their own orders" ON orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
CREATE POLICY "Users can update their own orders" ON orders
    FOR UPDATE USING (auth.uid() = user_id);

-- Note: Delete policy intentionally omitted for data retention
-- Orders should not be deleted by users for business records

-- Add some helpful comments
COMMENT ON TABLE orders IS 'Stores customer orders with payment details and item information';
COMMENT ON COLUMN orders.payment_intent_id IS 'Stripe payment intent ID for tracking payments';
COMMENT ON COLUMN orders.order_items IS 'JSON array containing detailed item and service information';
COMMENT ON COLUMN orders.billing_address IS 'JSON object containing customer billing address from Stripe';
COMMENT ON COLUMN orders.delivery_info IS 'JSON object containing delivery details: pickup_date, pickup_time, pickup_cost';
COMMENT ON COLUMN orders.status IS 'Order status: pickup, processing, completed';
COMMENT ON COLUMN orders.delivery_method IS 'Delivery method: pickup (default), post';