ALTER TABLE public.branches ADD COLUMN IF NOT EXISTS access_code TEXT;
UPDATE public.branches SET access_code = '1234' WHERE access_code IS NULL;
NOTIFY pgrst, 'reload schema';
