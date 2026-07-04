-- Create delivery_zones table
CREATE TABLE IF NOT EXISTS public.delivery_zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT DEFAULT '#10b981',
  delivery_fee NUMERIC DEFAULT 0,
  min_order NUMERIC DEFAULT 5000,
  max_delivery_time INTEGER DEFAULT 45,
  is_active BOOLEAN DEFAULT true,
  geojson JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS policies
ALTER TABLE public.delivery_zones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to delivery_zones" 
ON public.delivery_zones FOR SELECT 
USING (true);

CREATE POLICY "Allow authenticated full access to delivery_zones" 
ON public.delivery_zones FOR ALL 
USING (auth.role() = 'authenticated');

-- Reload schema cache
NOTIFY pgrst, 'reload schema';
