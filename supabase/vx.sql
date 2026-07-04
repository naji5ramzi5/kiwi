-- ============================================
-- vx.sql — DB fixes for Kiwi Delivery App
-- ============================================

-- 1. Fix notify_order_change() trigger — use customer_id not user_id
CREATE OR REPLACE FUNCTION public.notify_order_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  admin_ids uuid[];
  admin_id uuid;
BEGIN
  SELECT array_agg(id) INTO admin_ids
  FROM public.profiles
  WHERE role IN ('admin', 'super_admin');

  IF TG_OP = 'INSERT' THEN
    FOREACH admin_id IN ARRAY admin_ids
    LOOP
      PERFORM net.http_post(
        url := current_setting('app.settings.edge_function_url') || '/send-fcm-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
        ),
        body := jsonb_build_object(
          'userId', admin_id,
          'title', 'طلب جديد',
          'body', 'تم استلام طلب جديد بقيمة ' || NEW.total_price::text || ' د.ع',
          'data', jsonb_build_object('orderId', NEW.id, 'type', 'new_order')
        )::text
      );
    END LOOP;

  ELSIF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
    PERFORM net.http_post(
      url := current_setting('app.settings.edge_function_url') || '/send-fcm-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := jsonb_build_object(
        'userId', NEW.customer_id,
        'title', 'تحديث حالة الطلب',
        'body', 'تم تغيير حالة طلبك إلى: ' || NEW.status,
        'data', jsonb_build_object('orderId', NEW.id, 'type', 'status_update', 'status', NEW.status)
      )::text
    );
  END IF;

  RETURN NEW;
END;
$$;

-- 2. Enable RLS on tables that are missing it
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shift_closings ENABLE ROW LEVEL SECURITY;

-- 3. Add RLS for audit_logs — only super_admin can read
DROP POLICY IF EXISTS audit_logs_admin ON public.audit_logs;
CREATE POLICY audit_logs_admin ON public.audit_logs
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- 4. Add RLS for shift_closings — branch managers own, super_admin all
DROP POLICY IF EXISTS shift_closings_policy ON public.shift_closings;
CREATE POLICY shift_closings_policy ON public.shift_closings
  FOR ALL
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- 5. Ensure orders table has cancelled_at and cancellation_reason columns
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;
