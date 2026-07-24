-- ============================================================
-- Migration 005: Order Status Notification Trigger
-- Creates a trigger that automatically inserts notifications
-- into the notifications table when an order status changes.
-- This works reliably without needing pg_net or Edge Functions.
-- ============================================================

-- Function to create notification on order status change
CREATE OR REPLACE FUNCTION public.notify_order_status_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  notification_title TEXT;
  notification_body TEXT;
  notification_type TEXT;
  order_short_id TEXT;
BEGIN
  -- Only proceed if status actually changed
  IF OLD.status IS NOT DISTINCT FROM NEW.status THEN
    RETURN NEW;
  END IF;

  -- Generate a short ID for display
  order_short_id := LEFT(NEW.id::text, 5);

  -- Determine notification content based on new status
  CASE NEW.status
    WHEN 'preparing' THEN
      notification_title := 'تم قبول طلبك';
      notification_body := 'طلبك #' || order_short_id || ' قيد التحضير الآن';
      notification_type := 'order_update';

    WHEN 'rejected' THEN
      notification_title := 'تم رفض طلبك';
      notification_body := 'نعتذر، طلبك #' || order_short_id || ' تم رفضه';
      notification_type := 'order_update';

    WHEN 'shipped' THEN
      notification_title := 'طلبك في الطريق إليك';
      notification_body := 'المندوب في طريقه إليك مع طلبك #' || order_short_id;
      notification_type := 'delivery_update';

    WHEN 'delivered' THEN
      notification_title := 'تم توصيل طلبك';
      notification_body := 'تم توصيل طلبك #' || order_short_id || ' بنجاح. شكراً لتسوقك معنا!';
      notification_type := 'order_update';

    WHEN 'cancelled' THEN
      notification_title := 'تم إلغاء طلبك';
      notification_body := 'طلبك #' || order_short_id || ' تم إلغاؤه';
      notification_type := 'order_update';

    ELSE
      -- For any other status change, create a generic notification
      notification_title := 'تحديث حالة الطلب';
      notification_body := 'تم تحديث حالة طلبك #' || order_short_id || ' إلى: ' || NEW.status;
      notification_type := 'order_update';
  END CASE;

  -- Insert notification for the customer
  IF NEW.customer_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, title, body, type, order_id, is_read, created_at)
    VALUES (NEW.customer_id, notification_title, notification_body, notification_type, NEW.id, false, now());
  END IF;

  -- If new order (status = pending), also notify branch managers
  IF NEW.status = 'pending' AND NEW.branch_id IS NOT NULL THEN
    -- Notify branch managers about new order
    INSERT INTO public.notifications (user_id, title, body, type, order_id, is_read, created_at)
    SELECT p.id, 'طلب جديد', 'طلب جديد #' || order_short_id || ' بقيمة ' || NEW.total_amount::text || ' د.ع', 'new_order', NEW.id, false, now()
    FROM public.profiles p
    WHERE p.branch_id = NEW.branch_id
    AND p.role IN ('branch_manager', 'admin');
  END IF;

  RETURN NEW;
END;
$$;

-- Drop old trigger if exists
DROP TRIGGER IF EXISTS on_order_change ON public.orders;
DROP TRIGGER IF EXISTS on_order_status_change ON public.orders;

-- Create the new trigger
CREATE TRIGGER on_order_status_change
  AFTER UPDATE OF status
  ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_order_status_change();

-- Also create trigger for new orders (INSERT)
CREATE TRIGGER on_new_order
  AFTER INSERT
  ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_order_status_change();

-- Ensure notifications table has proper columns
ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'general',
  ADD COLUMN IF NOT EXISTS order_id UUID,
  ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT false;

-- Add index for faster notification queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON public.notifications(user_id, is_read)
  WHERE is_read = false;

-- Enable RLS on notifications if not already enabled
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Policy: users can read their own notifications
DROP POLICY IF EXISTS "Users can read own notifications" ON public.notifications;
CREATE POLICY "Users can read own notifications"
  ON public.notifications
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: system can insert notifications (via trigger)
DROP POLICY IF EXISTS "System can insert notifications" ON public.notifications;
CREATE POLICY "System can insert notifications"
  ON public.notifications
  FOR INSERT
  WITH CHECK (true);

-- Policy: users can update their own notifications (mark as read)
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications"
  ON public.notifications
  FOR UPDATE
  USING (auth.uid() = user_id);
