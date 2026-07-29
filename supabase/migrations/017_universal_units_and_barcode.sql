-- Add barcode column if not exists (referenced by index in 004 but never created)
ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS barcode varchar(100);

-- Add description column for richer product info
ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS description text;

-- Increase unit_type size to fit all unit names (e.g. 'milliliter' is 10 chars)
ALTER TABLE public.products
ALTER COLUMN unit_type TYPE varchar(30);

ALTER TABLE public.order_items
ALTER COLUMN unit_type TYPE varchar(30);

-- Add index for barcode lookups (used by Price Checker)
CREATE INDEX IF NOT EXISTS idx_products_barcode_lookup ON public.products(barcode) WHERE barcode IS NOT NULL;
