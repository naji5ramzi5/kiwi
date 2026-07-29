-- Add unit_type to products (kg/piece)
ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS unit_type varchar(10) NOT NULL DEFAULT 'kg';

-- Add unit and unit_type to order_items for display in order history
ALTER TABLE public.order_items
ADD COLUMN IF NOT EXISTS unit varchar(50),
ADD COLUMN IF NOT EXISTS unit_type varchar(10) NOT NULL DEFAULT 'kg';

-- Update existing order_items with product data
UPDATE public.order_items oi
SET unit = p.unit, unit_type = COALESCE(p.unit_type, 'kg')
FROM public.products p
WHERE oi.product_id = p.id;

-- Update all existing products that have Arabic unit names
UPDATE public.products
SET unit_type = 'kg'
WHERE unit = 'كيلو' AND unit_type IS NULL;

UPDATE public.products
SET unit_type = 'piece'
WHERE unit = 'حبة' AND unit_type IS NULL;

UPDATE public.products
SET unit_type = 'piece'
WHERE unit = 'ربطة' AND unit_type IS NULL;
