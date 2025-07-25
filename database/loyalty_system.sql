-- =====================================================
-- House of Tailors - Loyalty System Database Schema
-- 6th Order Free Loyalty Program
-- =====================================================

-- Drop existing functions first to avoid conflicts
DROP FUNCTION IF EXISTS get_loyalty_progress(UUID);
DROP FUNCTION IF EXISTS increment_loyalty_progress(UUID);
DROP FUNCTION IF EXISTS sync_loyalty_progress_with_orders(UUID);
DROP FUNCTION IF EXISTS reset_loyalty_progress(UUID);
DROP FUNCTION IF EXISTS is_eligible_for_free_order(UUID);

-- Create loyalty_progress table
CREATE TABLE IF NOT EXISTS loyalty_progress (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    completed_orders INTEGER NOT NULL DEFAULT 0,
    lifetime_orders INTEGER NOT NULL DEFAULT 0,
    total_free_orders_claimed INTEGER NOT NULL DEFAULT 0,
    last_free_order_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT loyalty_progress_completed_orders_check CHECK (completed_orders >= 0 AND completed_orders <= 5),
    CONSTRAINT loyalty_progress_unique_user UNIQUE (user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_loyalty_progress_user_id ON loyalty_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_progress_completed_orders ON loyalty_progress(completed_orders);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_loyalty_progress_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger (drop first if exists)
DROP TRIGGER IF EXISTS trigger_loyalty_progress_updated_at ON loyalty_progress;
CREATE TRIGGER trigger_loyalty_progress_updated_at
    BEFORE UPDATE ON loyalty_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_loyalty_progress_updated_at();

-- Enable Row Level Security
ALTER TABLE loyalty_progress ENABLE ROW LEVEL SECURITY;

-- RLS Policies (drop first if they exist)
DROP POLICY IF EXISTS "Users can view own loyalty progress" ON loyalty_progress;
DROP POLICY IF EXISTS "Users can insert own loyalty progress" ON loyalty_progress;
DROP POLICY IF EXISTS "Users can update own loyalty progress" ON loyalty_progress;

CREATE POLICY "Users can view own loyalty progress" ON loyalty_progress
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own loyalty progress" ON loyalty_progress
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own loyalty progress" ON loyalty_progress
    FOR UPDATE USING (auth.uid() = user_id);

-- =====================================================
-- LOYALTY FUNCTIONS
-- =====================================================

-- Function: Get loyalty progress for user
CREATE OR REPLACE FUNCTION get_loyalty_progress(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'completed_orders', COALESCE(lp.completed_orders, 0),
        'lifetime_orders', COALESCE(lp.lifetime_orders, 0),
        'total_free_orders_claimed', COALESCE(lp.total_free_orders_claimed, 0),
        'eligible_for_free', COALESCE(lp.completed_orders, 0) >= 5,
        'last_free_order_date', lp.last_free_order_date
    ) INTO result
    FROM loyalty_progress lp
    WHERE lp.user_id = p_user_id;
    
    -- If no record exists, return default values
    IF result IS NULL THEN
        result := json_build_object(
            'completed_orders', 0,
            'lifetime_orders', 0,
            'total_free_orders_claimed', 0,
            'eligible_for_free', false,
            'last_free_order_date', null
        );
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Increment loyalty progress after order
CREATE OR REPLACE FUNCTION increment_loyalty_progress(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
    was_eligible BOOLEAN := false;
BEGIN
    -- Check if user was already eligible (at 5 orders)
    SELECT completed_orders >= 5 INTO was_eligible
    FROM loyalty_progress
    WHERE user_id = p_user_id;
    
    -- Insert or update loyalty progress
    INSERT INTO loyalty_progress (user_id, completed_orders, lifetime_orders)
    VALUES (p_user_id, 1, 1)
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        completed_orders = CASE 
            WHEN loyalty_progress.completed_orders >= 5 THEN 1  -- Reset to 1 if was at 5+
            ELSE loyalty_progress.completed_orders + 1 
        END,
        lifetime_orders = loyalty_progress.lifetime_orders + 1,
        total_free_orders_claimed = CASE 
            WHEN loyalty_progress.completed_orders >= 5 THEN loyalty_progress.total_free_orders_claimed + 1
            ELSE loyalty_progress.total_free_orders_claimed
        END,
        last_free_order_date = CASE 
            WHEN loyalty_progress.completed_orders >= 5 THEN NOW()
            ELSE loyalty_progress.last_free_order_date
        END,
        updated_at = NOW();

    -- Return updated values
    SELECT json_build_object(
        'completed_orders', lp.completed_orders,
        'lifetime_orders', lp.lifetime_orders,
        'total_free_orders_claimed', lp.total_free_orders_claimed,
        'eligible_for_free', lp.completed_orders >= 5,
        'was_eligible_before', COALESCE(was_eligible, false),
        'just_became_eligible', lp.completed_orders >= 5 AND NOT COALESCE(was_eligible, false)
    ) INTO result
    FROM loyalty_progress lp 
    WHERE lp.user_id = p_user_id;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Sync loyalty progress with existing orders
CREATE OR REPLACE FUNCTION sync_loyalty_progress_with_orders(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    order_count INTEGER;
    current_progress INTEGER := 0;
    result JSON;
BEGIN
    -- Count all orders for the user (all statuses count as completed orders)
    SELECT COUNT(*) INTO order_count
    FROM orders
    WHERE user_id = p_user_id;

    -- Get current progress if exists
    SELECT COALESCE(completed_orders, 0) INTO current_progress
    FROM loyalty_progress
    WHERE user_id = p_user_id;

    -- Calculate proper loyalty progress
    -- Every 6 orders = 1 cycle (5 regular + 1 free)
    -- So for loyalty progress: orders % 6, but cap at 5
    INSERT INTO loyalty_progress (user_id, completed_orders, lifetime_orders)
    VALUES (p_user_id, LEAST(order_count % 6, 5), order_count)
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        completed_orders = LEAST(order_count % 6, 5),
        lifetime_orders = GREATEST(loyalty_progress.lifetime_orders, order_count),
        total_free_orders_claimed = order_count / 6,  -- Number of complete cycles
        updated_at = NOW();

    -- Return sync results
    SELECT json_build_object(
        'completed_orders', lp.completed_orders,
        'lifetime_orders', lp.lifetime_orders,
        'total_free_orders_claimed', lp.total_free_orders_claimed,
        'orders_synced', order_count,
        'eligible_for_free', lp.completed_orders >= 5
    ) INTO result
    FROM loyalty_progress lp
    WHERE lp.user_id = p_user_id;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Reset loyalty progress (when free order is used)
CREATE OR REPLACE FUNCTION reset_loyalty_progress(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    UPDATE loyalty_progress 
    SET 
        completed_orders = 0,
        total_free_orders_claimed = total_free_orders_claimed + 1,
        last_free_order_date = NOW(),
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Return updated values
    SELECT json_build_object(
        'completed_orders', lp.completed_orders,
        'lifetime_orders', lp.lifetime_orders,
        'total_free_orders_claimed', lp.total_free_orders_claimed,
        'eligible_for_free', false,
        'last_free_order_date', lp.last_free_order_date
    ) INTO result
    FROM loyalty_progress lp
    WHERE lp.user_id = p_user_id;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Check if user is eligible for free order
CREATE OR REPLACE FUNCTION is_eligible_for_free_order(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    eligible BOOLEAN := false;
BEGIN
    SELECT completed_orders >= 5 INTO eligible
    FROM loyalty_progress
    WHERE user_id = p_user_id;
    
    RETURN COALESCE(eligible, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TABLE COMMENTS
-- =====================================================

COMMENT ON TABLE loyalty_progress IS 'Tracks user progress in 6th order free loyalty program';
COMMENT ON COLUMN loyalty_progress.user_id IS 'Reference to auth.users';
COMMENT ON COLUMN loyalty_progress.completed_orders IS 'Orders completed towards next free order (0-5)';
COMMENT ON COLUMN loyalty_progress.lifetime_orders IS 'Total orders placed by user';
COMMENT ON COLUMN loyalty_progress.total_free_orders_claimed IS 'Number of free orders claimed';
COMMENT ON COLUMN loyalty_progress.last_free_order_date IS 'When last free order was claimed';

-- =====================================================
-- FUNCTION COMMENTS
-- =====================================================

COMMENT ON FUNCTION get_loyalty_progress(UUID) IS 'Returns current loyalty progress as JSON';
COMMENT ON FUNCTION increment_loyalty_progress(UUID) IS 'Increments progress after order, returns updated state';
COMMENT ON FUNCTION sync_loyalty_progress_with_orders(UUID) IS 'Syncs loyalty with existing orders';
COMMENT ON FUNCTION reset_loyalty_progress(UUID) IS 'Resets progress after free order is used';
COMMENT ON FUNCTION is_eligible_for_free_order(UUID) IS 'Quick check if user is eligible for free order';