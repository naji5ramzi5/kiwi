-- Create a function to notify via edge function when order status changes
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
  -- Get all admin user IDs (role = 'admin' or similar)
  SELECT array_agg(id) INTO admin_ids
  FROM public.profiles
  WHERE role IN ('admin', 'super_admin');

  -- On INSERT (new order): notify admins
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

  -- On UPDATE (status change): notify the customer
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

-- Create the trigger on orders table
DROP TRIGGER IF EXISTS on_order_change ON public.orders;
CREATE TRIGGER on_order_change
  AFTER INSERT OR UPDATE OF status
  ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_order_change();

-- Ensure the net extension is enabled (for HTTP requests)
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- Add default roles to profiles if they don't exist
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'customer' CHECK (role IN ('customer', 'branch_manager', 'admin', 'super_admin'));
