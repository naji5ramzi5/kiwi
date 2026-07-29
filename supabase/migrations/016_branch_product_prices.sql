-- Create branch_product_prices table for per-branch pricing overrides
CREATE TABLE IF NOT EXISTS public.branch_product_prices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    price numeric(12,2) NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT branch_product_prices_pkey PRIMARY KEY (id),
    CONSTRAINT branch_product_prices_branch_id_product_id_key UNIQUE (branch_id, product_id)
);

ALTER TABLE public.branch_product_prices OWNER TO postgres;

-- RLS
ALTER TABLE public.branch_product_prices ENABLE ROW LEVEL SECURITY;

-- Admin full access
CREATE POLICY "admin_all_branch_product_prices" ON public.branch_product_prices
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- Branch staff: SELECT + INSERT + UPDATE for their own branch
CREATE POLICY "branch_staff_branch_product_prices_select" ON public.branch_product_prices
    FOR SELECT
    USING ((public.get_my_role() = 'branch_manager'::text) AND (branch_id = public.get_my_branch_id()));

CREATE POLICY "branch_staff_branch_product_prices_insert" ON public.branch_product_prices
    FOR INSERT
    WITH CHECK ((public.get_my_role() = 'branch_manager'::text) AND (branch_id = public.get_my_branch_id()));

CREATE POLICY "branch_staff_branch_product_prices_update" ON public.branch_product_prices
    FOR UPDATE
    USING ((public.get_my_role() = 'branch_manager'::text) AND (branch_id = public.get_my_branch_id()))
    WITH CHECK ((public.get_my_role() = 'branch_manager'::text) AND (branch_id = public.get_my_branch_id()));

-- Public read
CREATE POLICY "public_read_branch_product_prices" ON public.branch_product_prices
    FOR SELECT USING (true);

-- Grants
GRANT ALL ON TABLE public.branch_product_prices TO anon;
GRANT ALL ON TABLE public.branch_product_prices TO authenticated;
GRANT ALL ON TABLE public.branch_product_prices TO service_role;

-- Updated_at trigger
CREATE OR REPLACE FUNCTION public.update_branch_product_prices_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_branch_product_prices_updated_at
    BEFORE UPDATE ON public.branch_product_prices
    FOR EACH ROW
    EXECUTE FUNCTION public.update_branch_product_prices_updated_at();
