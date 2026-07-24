-- Database Performance Indexes
-- Created for the Fresh Enterprise System
-- Run this migration in Supabase SQL Editor

-- ============================================
-- REQUIRED EXTENSION (must be created before trigram index)
-- ============================================
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ============================================
-- ORDERS TABLE INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_orders_branch_id ON orders(branch_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_driver_id ON orders(driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_branch_status ON orders(branch_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_created_branch ON orders(created_at DESC, branch_id);

-- ============================================
-- ORDER ITEMS TABLE INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- ============================================
-- PRODUCTS TABLE INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_products_branch_id ON products(branch_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_products_branch_active ON products(branch_id, is_active);

-- ============================================
-- INVENTORY TABLE INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_inventory_branch_id ON inventory(branch_id);
CREATE INDEX IF NOT EXISTS idx_inventory_product_id ON inventory(product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_branch_product ON inventory(branch_id, product_id);

-- ============================================
-- PROFILES TABLE INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_branch_id ON profiles(branch_id);
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON profiles(phone);

-- ============================================
-- BRANCHES TABLE INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_branches_is_active ON branches(is_active);

-- ============================================
-- CATEGORIES TABLE INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_categories_branch_id ON categories(branch_id);

-- ============================================
-- FCM TOKENS TABLE INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_token ON user_fcm_tokens(token);

-- ============================================
-- DELIVERY ZONES TABLE INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_delivery_zones_branch_id ON delivery_zones(branch_id);

-- ============================================
-- NOTIFICATIONS TABLE INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- ============================================
-- FINANCE / DAILY SETTLEMENTS INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_daily_settlements_branch_id ON daily_settlements(branch_id);
CREATE INDEX IF NOT EXISTS idx_daily_settlements_created_at ON daily_settlements(created_at DESC);

-- ============================================
-- MARKETING / DISCOUNT CODES INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_discount_codes_branch_id ON discount_codes(branch_id);
CREATE INDEX IF NOT EXISTS idx_discount_codes_code ON discount_codes(code);
CREATE INDEX IF NOT EXISTS idx_discount_codes_active ON discount_codes(is_active);

-- ============================================
-- COMPOSITE INDEXES FOR COMMON QUERIES
-- ============================================
-- For fetching active orders per branch (used in POS and driver app)
CREATE INDEX IF NOT EXISTS idx_orders_branch_status_created ON orders(branch_id, status, created_at DESC);

-- For fetching driver's active deliveries
CREATE INDEX IF NOT EXISTS idx_orders_driver_status ON orders(driver_id, status) WHERE driver_id IS NOT NULL;

-- For product search by name within a branch (requires pg_trgm extension)
CREATE INDEX IF NOT EXISTS idx_products_branch_name_trgm ON products USING gin (name gin_trgm_ops);
