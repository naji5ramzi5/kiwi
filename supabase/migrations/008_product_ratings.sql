-- Migration: Product & Branch Ratings
-- Adds tables for customers to rate individual products and the branch
-- after an order is delivered.

-- ============================================
-- PRODUCT RATINGS
-- ============================================
CREATE TABLE IF NOT EXISTS public.product_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_product_ratings_order_id ON public.product_ratings(order_id);
CREATE INDEX IF NOT EXISTS idx_product_ratings_product_id ON public.product_ratings(product_id);
CREATE INDEX IF NOT EXISTS idx_product_ratings_user_id ON public.product_ratings(user_id);

-- ============================================
-- BRANCH RATINGS
-- ============================================
CREATE TABLE IF NOT EXISTS public.branch_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_branch_ratings_order_id ON public.branch_ratings(order_id);
CREATE INDEX IF NOT EXISTS idx_branch_ratings_branch_id ON public.branch_ratings(branch_id);
CREATE INDEX IF NOT EXISTS idx_branch_ratings_user_id ON public.branch_ratings(user_id);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================
ALTER TABLE IF EXISTS public.product_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.branch_ratings ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can read ratings
DROP POLICY IF EXISTS "Public read product ratings" ON public.product_ratings;
CREATE POLICY "Public read product ratings"
  ON public.product_ratings FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Public read branch ratings" ON public.branch_ratings;
CREATE POLICY "Public read branch ratings"
  ON public.branch_ratings FOR SELECT USING (auth.role() = 'authenticated');

-- Users can insert their own ratings
DROP POLICY IF EXISTS "Users insert own product ratings" ON public.product_ratings;
CREATE POLICY "Users insert own product ratings"
  ON public.product_ratings FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users insert own branch ratings" ON public.branch_ratings;
CREATE POLICY "Users insert own branch ratings"
  ON public.branch_ratings FOR INSERT WITH CHECK (auth.uid() = user_id);
