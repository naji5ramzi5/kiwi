-- ==========================================
-- FIX: Inventory RLS Policy for Branch POS
-- ==========================================
-- Execute this in Supabase SQL Editor
-- https://supabase.com/dashboard/project/pftjlvtdzokbzuioqfug/sql/new

-- Drop ALL existing policies on inventory
DROP POLICY IF EXISTS "Anyone can view inventory" ON public.inventory;
DROP POLICY IF EXISTS "Branch managers can update inventory" ON public.inventory;
DROP POLICY IF EXISTS "super_admin_all_inventory" ON public.inventory;
DROP POLICY IF EXISTS "manager_own_inventory" ON public.inventory;
DROP POLICY IF EXISTS "inventory_all_authenticated" ON public.inventory;
DROP POLICY IF EXISTS "inventory_read_all_authenticated" ON public.inventory;
DROP POLICY IF EXISTS "Enable read for all users" ON public.inventory;
DROP POLICY IF EXISTS "Enable insert for all users" ON public.inventory;
DROP POLICY IF EXISTS "Enable update for all users" ON public.inventory;

-- Enable RLS
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users (branch managers, admins) to manage inventory
CREATE POLICY "inventory_all_authenticated"
  ON public.inventory
  FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');
