-- ============================================================
-- naji.sql — تعديلات الجداول لقاعدة بيانات Kiwi
-- تاريخ الإنشاء: 26 يونيو 2026
-- ============================================================
-- هذا الملف يحتوي على جميع التعديلات المطلوبة على قاعدة البيانات
-- لتفعيل دورة حياة الطلب المتكاملة، العناوين المحفوظة،
-- الدردشة الداخلية، وتقييد تحرير الملف الشخصي.
-- ============================================================

-- ─── 1. تحديث جدول الطلبات (orders) ──────────────────────────
ALTER TABLE IF EXISTS public.orders
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS cancellation_reason TEXT,
  ADD COLUMN IF NOT EXISTS status_history JSONB DEFAULT '[]'::jsonb;

-- ضبط قيم الحالة الجديدة (إذا كان الجدول يستخدم نصاً عربياً قديماً)
UPDATE public.orders SET status = 'pending' WHERE status = 'قيد الانتظار';

-- ─── 2. تحديث جدول تفاصيل الطلبات (order_items) ──────────────
ALTER TABLE IF EXISTS public.order_items
  ADD COLUMN IF NOT EXISTS product_name TEXT,
  ADD COLUMN IF NOT EXISTS image_url TEXT;

-- تحديث اسم المنتج من جدول المنتجات للطلبات القديمة
UPDATE public.order_items oi
SET product_name = p.name, image_url = p.image_url
FROM public.products p
WHERE oi.product_id = p.id::text::uuid
  AND (oi.product_name IS NULL OR oi.product_name = '');

-- ─── 3. تحديث جدول الملفات الشخصية (profiles) ───────────────
ALTER TABLE IF EXISTS public.profiles
  ADD COLUMN IF NOT EXISTS name_change_count INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS phone_changed BOOLEAN DEFAULT FALSE;

-- ─── 4. إنشاء جدول العناوين المحفوظة (addresses) ────────────
CREATE TABLE IF NOT EXISTS public.addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  label TEXT NOT NULL DEFAULT 'منزل',
  address TEXT NOT NULL,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─── 5. إنشاء جدول سجل حالة الطلب (order_status_history) ─────
CREATE TABLE IF NOT EXISTS public.order_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL,
  note TEXT,
  changed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─── 6. إنشاء جدول الدردشة الداخلية (order_chat) ────────────
CREATE TABLE IF NOT EXISTS public.order_chat (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  sender_role TEXT NOT NULL DEFAULT 'customer', -- customer, driver, admin
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─── 7. تفعيل Row Level Security ──────────────────────────────
ALTER TABLE IF EXISTS public.addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.order_chat ENABLE ROW LEVEL SECURITY;

-- ─── 8. سياسات RLS للعناوين ──────────────────────────────────
CREATE POLICY "Users can manage their own addresses"
  ON public.addresses
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── 9. سياسات RLS لسجل الحالة ───────────────────────────────
CREATE POLICY "Users can view their order history"
  ON public.order_status_history
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.orders
    WHERE orders.id = order_status_history.order_id
      AND orders.customer_id = auth.uid()
  ));

-- ─── 10. سياسات RLS للدردشة ──────────────────────────────────
CREATE POLICY "Users can view their order chat"
  ON public.order_chat
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.orders
    WHERE orders.id = order_chat.order_id
      AND orders.customer_id = auth.uid()
  ));

CREATE POLICY "Users can send messages to their orders"
  ON public.order_chat
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_chat.order_id
        AND orders.customer_id = auth.uid()
    )
    AND auth.uid() = sender_id
    AND sender_role = 'customer'
  );
