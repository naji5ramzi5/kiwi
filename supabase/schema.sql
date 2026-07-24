


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "http" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."cleanup_old_notifications"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  DELETE FROM public.notifications WHERE created_at < now() - INTERVAL '30 days';
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."cleanup_old_notifications"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_notify_order_status_change"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_message TEXT;
  v_title TEXT;
BEGIN
  IF OLD.status != NEW.status THEN
    -- رسائل الحالات الإنجليزية
    CASE NEW.status
      WHEN 'preparing' THEN
        v_title := 'تم استلام طلبك';
        v_message := 'الفرع بدأ تجهيز طلبك. سيكون جاهزاً قريباً.';
      WHEN 'shipped' THEN
        v_title := 'طلبك في الطريق';
        v_message := 'تم إسناد طلبك لسائق. سيصل قريباً.';
      WHEN 'in_delivery' THEN
        v_title := 'السائق في الطريق';
        v_message := 'السائق في طريقه إليك الآن.';
      WHEN 'delivered' THEN
        v_title := 'تم التسليم';
        v_message := 'وصل طلبك بنجاح! شكراً لك.';
      WHEN 'cancelled' THEN
        v_title := 'تم إلغاء الطلب';
        v_message := 'تم إلغاء طلبك. سيتم استرجاع أموالك.';
      WHEN 'rejected' THEN
        v_title := 'تم رفض الطلب';
        v_message := 'للأسف، الفرع غير قادر على تجهيز طلبك.';
      ELSE
        v_title := 'تحديث الطلب';
        v_message := 'تم تحديث حالة طلبك إلى: ' || NEW.status;
    END CASE;

    -- إدراج الإشعار في جدول notifications (إن وُجد)
    -- أو استدعاء Edge Function للإشعارات
    INSERT INTO notifications (user_id, title, message, order_id, created_at)
    VALUES (
      NEW.customer_id,
      v_title,
      v_message,
      NEW.id,
      NOW()
    ) ON CONFLICT DO NOTHING;

  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_notify_order_status_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_prevent_completed_order_changes"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- منع تعديل الطلبات المنتهية (delivered, cancelled, rejected)
  IF OLD.status IN ('delivered', 'cancelled', 'rejected') THEN
    RAISE EXCEPTION 'لا يمكن تعديل طلب منتهي';
  END IF;

  -- منع العميل من إلغاء طلب انطلق مع السائق (يجب على الإدارة فقط)
  IF OLD.status IN ('shipped', 'in_delivery') 
     AND NEW.status = 'cancelled'
     AND auth.uid() = OLD.customer_id THEN
    RAISE EXCEPTION 'لا يمكن إلغاء طلب في طريقه';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_prevent_completed_order_changes"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_send_fcm_on_order_update"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_fcm_token TEXT;
  v_total_amount DECIMAL;
BEGIN
  -- الحصول على FCM token والمبلغ الصحيح
  SELECT fcm_token INTO v_fcm_token
  FROM profiles
  WHERE id = NEW.customer_id;

  -- استخدام العمود الصحيح: total_amount بدل total_price
  v_total_amount := NEW.total_amount;

  -- عزل الأخطاء: إذا فشل إرسال FCM، لا نوقف الطلب
  BEGIN
    IF v_fcm_token IS NOT NULL AND NEW.status != OLD.status THEN
      -- استدعاء Edge Function لإرسال الإشعار
      -- (يتم تنفيذها بشكل غير متزامن)
      PERFORM
        net.http_post(
          url:='https://pftjlvtdzokbzuioqfug.supabase.co/functions/v1/send-fcm-notification',
          headers:='{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('request.headers')::json->>'authorization' || '"}'::jsonb,
          body:=jsonb_build_object(
            'user_id', NEW.customer_id,
            'order_id', NEW.id,
            'status', NEW.status,
            'total_amount', v_total_amount
          )
        );
    END IF;
  EXCEPTION WHEN OTHERS THEN
    -- تسجيل الخطأ ولكن لا نوقف الطلب
    RAISE WARNING 'FCM notification error: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_send_fcm_on_order_update"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_sync_driver_status"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- عندما يتم إسناد السائق (driver_id != null)
  IF NEW.driver_id IS NOT NULL AND OLD.driver_id IS NULL THEN
    UPDATE drivers
    SET current_status = 'on_delivery'
    WHERE id = NEW.driver_id;
  END IF;

  -- عندما يتم التسليم
  IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
    UPDATE drivers
    SET current_status = 'available'
    WHERE id = NEW.driver_id;
  END IF;

  -- عندما يتم إلغاء/رفض الطلب
  IF NEW.status IN ('cancelled', 'rejected') AND OLD.status != NEW.status THEN
    UPDATE drivers
    SET current_status = 'available'
    WHERE id = NEW.driver_id;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_sync_driver_status"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_update_stock_on_sale"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- خصم المخزون عند الانتقال من pending إلى أي حالة أخرى (preparing/shipped/delivered)
  IF OLD.status = 'pending' AND NEW.status != 'pending' THEN
    -- إنقاص المخزون
    UPDATE branch_inventory
    SET actual_stock = actual_stock - oi.quantity
    FROM order_items oi
    WHERE oi.order_id = NEW.id
      AND branch_inventory.product_id = oi.product_id
      AND branch_inventory.branch_id = NEW.branch_id;
  END IF;

  -- إرجاع المخزون عند الإلغاء أو الرفض (بعد الخصم)
  IF OLD.status IN ('preparing', 'shipped', 'in_delivery') 
     AND NEW.status IN ('cancelled', 'rejected') THEN
    UPDATE branch_inventory
    SET actual_stock = actual_stock + oi.quantity
    FROM order_items oi
    WHERE oi.order_id = NEW.id
      AND branch_inventory.product_id = oi.product_id
      AND branch_inventory.branch_id = NEW.branch_id;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_update_stock_on_sale"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_branch_drivers_tokens"("p_branch_id" "uuid") RETURNS TABLE("token" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT fcm_token 
    FROM public.profiles 
    WHERE branch_id = p_branch_id 
      AND role = 'driver' 
      AND fcm_token IS NOT NULL;
END;
$$;


ALTER FUNCTION "public"."get_branch_drivers_tokens"("p_branch_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_my_branch_id"() RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT COALESCE(
    (SELECT branch_id FROM public.profiles WHERE id = auth.uid()),
    (SELECT (raw_user_meta_data->>'branch_id')::UUID FROM auth.users WHERE id = auth.uid())
  );
$$;


ALTER FUNCTION "public"."get_my_branch_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_my_role"() RETURNS "text"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT COALESCE(
    (SELECT role FROM public.profiles WHERE id = auth.uid()),
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()),
    'customer'
  );
$$;


ALTER FUNCTION "public"."get_my_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."guard_order_status_transition"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_role TEXT := COALESCE(public.get_my_role(), 'customer');
BEGIN
  -- الطلب المكتمل أو الملغي حالة نهائية لا تتغير
  IF OLD.status IN ('delivered', 'cancelled', 'rejected')
     AND NEW.status IS DISTINCT FROM OLD.status THEN
    RAISE EXCEPTION 'لا يمكن تغيير حالة طلب منتهي (%).', OLD.status;
  END IF;

  -- الزبون لا يستطيع إلغاء طلب انطلق مع السائق
  IF NEW.status IN ('cancelled') AND OLD.status IN ('shipped')
     AND v_role NOT IN ('admin', 'super_admin', 'branch_manager', 'staff') THEN
    RAISE EXCEPTION 'لا يمكن إلغاء الطلب بعد انطلاقه مع المندوب.';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."guard_order_status_transition"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_product_inventory"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    -- إدخال سجل مخزون لكل فرع موجود بقيمة صفر
    INSERT INTO public.branch_inventory (branch_id, product_id, actual_stock, buffer_limit)
    SELECT id, NEW.id, 0, 2.000
    FROM public.branches;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_product_inventory"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_waste_reduction"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    UPDATE public.branch_inventory
    SET actual_stock = actual_stock - NEW.quantity
    WHERE branch_id = NEW.branch_id AND product_id = NEW.product_id;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_waste_reduction"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."initialize_branch_inventory"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  branch_id UUID;
BEGIN
  FOREACH branch_id IN ARRAY NEW.allowed_branches
  LOOP
    INSERT INTO public.branch_inventory (branch_id, product_id, actual_stock, buffer_limit)
    VALUES (branch_id, NEW.id, 0, 2.000)
    ON CONFLICT (branch_id, product_id) DO NOTHING;
  END LOOP;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."initialize_branch_inventory"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_admin"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$ SELECT public.get_my_role() IN ('admin', 'super_admin'); $$;


ALTER FUNCTION "public"."is_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_staff"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$ SELECT public.get_my_role() IN ('admin', 'super_admin', 'branch_manager'); $$;


ALTER FUNCTION "public"."is_staff"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_customer_on_status_change"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_token TEXT;
  v_title TEXT;
  v_body TEXT;
BEGIN
  -- التحقق إذا تغيرت الحالة فقط
  IF (OLD.status IS DISTINCT FROM NEW.status) THEN
    
    -- جلب توكن الزبون صاحب الطلب
    SELECT fcm_token INTO v_token 
    FROM public.profiles 
    WHERE id = NEW.user_id;

    -- تحديد نص الإشعار بناءً على الحالة الجديدة
    CASE NEW.status
      WHEN 'تحضير' THEN 
        v_title := '👨‍🍳 بدأنا بتحضير طلبك!';
        v_body := 'طلبك الآن في المطبخ/المخزن، سنخبرك فور خروجه للتوصيل.';
      WHEN 'توصيل' THEN 
        v_title := '🚚 المندوب في الطريق إليك!';
        v_body := 'خرج طلبك الآن مع المندوب، يرجى البقاء قريباً من هاتفك.';
      WHEN 'تم التوصيل' THEN 
        v_title := '✅ بالهناء والشفاء!';
        v_body := 'تم تسليم طلبك بنجاح. شكراً لثقتك بخدمة Fresh.';
      ELSE
        v_title := 'ℹ️ تحديث في حالة طلبك';
        v_body := 'تم تغيير حالة طلبك إلى: ' || NEW.status;
    END CASE;

    -- إرسال الإشعار إذا وجد التوكن
    IF v_token IS NOT NULL THEN
      PERFORM
        extensions.http_post(
          'https://pftjlvtdzokbzuioqfug.functions.supabase.co/send-notification',
          jsonb_build_object('tokens', ARRAY[v_token], 'title', v_title, 'body', v_body)::text,
          'application/json',
          '{"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODYwODQ2OCwiZXhwIjoyMDk0MTg0NDY4fQ.kEetvZsaf7xdDrwnCCMtXOd7aky92BnBayl_VUNtnQQ"}'
        );
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_customer_on_status_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_drivers_on_new_order"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_tokens TEXT[];
  v_payload JSONB;
BEGIN
  -- جلب توكنات المناديب في نفس فرع الطلب
  SELECT array_agg(fcm_token) INTO v_tokens
  FROM public.profiles
  WHERE branch_id = NEW.branch_id 
    AND role = 'driver' 
    AND fcm_token IS NOT NULL;

  -- إذا وجدنا مناديب متاحين
  IF v_tokens IS NOT NULL THEN
    v_payload := jsonb_build_object(
      'tokens', v_tokens,
      'title', '📦 طلب جديد في فرعك!',
      'body', 'لديك طلب جديد ينتظر التحضير، يرجى استلامه فوراً.'
    );

    -- استدعاء الوظيفة البرمجية
    PERFORM
      extensions.http_post(
        'https://pftjlvtdzokbzuioqfug.functions.supabase.co/send-notification',
        v_payload::text,
        'application/json',
        '{"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODYwODQ2OCwiZXhwIjoyMDk0MTg0NDY4fQ.kEetvZsaf7xdDrwnCCMtXOd7aky92BnBayl_VUNtnQQ"}'
      );
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_drivers_on_new_order"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_order_change"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  admin_id UUID;
BEGIN
  BEGIN  -- أي فشل في الإشعار يجب ألا يُفشل عملية الطلب نفسها
    IF TG_OP = 'INSERT' THEN
      FOR admin_id IN
        SELECT id FROM public.profiles WHERE role IN ('admin', 'super_admin')
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
            'body', 'تم استلام طلب جديد بقيمة ' || NEW.total_amount::text || ' د.ع',
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
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'FCM notify failed for order %: %', NEW.id, SQLERRM;
  END;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_order_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_order_created"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF NEW.customer_id IS NOT NULL AND COALESCE(NEW.order_type, 'app') = 'app' THEN
    INSERT INTO public.notifications (user_id, title, body, is_read)
    VALUES (
      NEW.customer_id,
      '🛒 تم استلام طلبك',
      'طلبك #' || UPPER(LEFT(NEW.id::text, 6)) || ' وصل للفرع وجاري مراجعته الآن',
      false
    );
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_order_created"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_order_status_change"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_title TEXT;
  v_body  TEXT;
  v_short_id TEXT;
BEGIN
  IF NEW.customer_id IS NULL OR NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  v_short_id := UPPER(LEFT(NEW.id::text, 6));

  CASE NEW.status
    WHEN 'preparing', 'جاري التحضير', 'تحضير' THEN
      v_title := '✅ تم تأكيد طلبك';
      v_body  := 'طلبك #' || v_short_id || ' قيد التجهيز في الفرع وسيتم توصيله قريباً';
    WHEN 'shipped', 'في الطريق', 'قيد التوصيل', 'في الطريق إليك' THEN
      v_title := '🛵 طلبك في الطريق!';
      v_body  := 'المندوب انطلق بطلبك #' || v_short_id || '، تجهز لاستلامه';
    WHEN 'delivered', 'تم التوصيل', 'تم التسليم', 'مكتمل' THEN
      v_title := '🎉 تم توصيل طلبك';
      v_body  := 'نتمنى لك تجربة رائعة! لا تنسَ تقييم المندوب لطلبك #' || v_short_id;
    WHEN 'cancelled', 'rejected', 'ملغي', 'مرفوض' THEN
      v_title := '❌ تم إلغاء طلبك';
      v_body  := 'نأسف، تم إلغاء طلبك #' || v_short_id || '. تواصل معنا إذا كان لديك استفسار';
    ELSE
      RETURN NEW;
  END CASE;

  INSERT INTO public.notifications (user_id, title, body, is_read)
  VALUES (NEW.customer_id, v_title, v_body, false);

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_order_status_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."record_partner_settlement"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_dev_ratio NUMERIC := 0.35;
  v_maint_ratio NUMERIC := 0.10;
  v_total NUMERIC;
  v_dev NUMERIC;
  v_maint NUMERIC;
BEGIN
  -- فقط عند الانتقال إلى حالة التوصيل النهائية
  IF NEW.status IN ('delivered', 'تم التوصيل', 'مكتمل', 'completed')
     AND (OLD.status IS DISTINCT FROM NEW.status) THEN

    -- قراءة النسب من الإعدادات مع قيم افتراضية آمنة
    BEGIN
      SELECT COALESCE(
        (SELECT value_decimal FROM public.system_settings WHERE key = 'dev_partner_ratio'),
        0.35) INTO v_dev_ratio;
      SELECT COALESCE(
        (SELECT value_decimal FROM public.system_settings WHERE key = 'system_maintenance_ratio'),
        0.10) INTO v_maint_ratio;
    EXCEPTION WHEN OTHERS THEN
      v_dev_ratio := 0.35; v_maint_ratio := 0.10;
    END;

    v_total := COALESCE(NEW.total_amount, 0);
    v_dev   := ROUND(v_total * v_dev_ratio, 2);
    v_maint := ROUND(v_total * v_maint_ratio, 2);

    INSERT INTO public.partner_settlements
      (order_id, branch_id, total_revenue, dev_partner_share, maintenance_fund, branch_profit)
    VALUES
      (NEW.id, NEW.branch_id, v_total, v_dev, v_maint, v_total - v_dev - v_maint)
    ON CONFLICT (order_id) WHERE order_id IS NOT NULL DO NOTHING;
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- عزل الأخطاء: فشل التسوية لا يفشل تحديث الطلب
  RAISE WARNING 'record_partner_settlement failed: %', SQLERRM;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."record_partner_settlement"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reduce_stock_on_order"("p_branch_id" "uuid", "p_product_id" "uuid", "p_quantity" numeric) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  UPDATE public.branch_inventory
  SET actual_stock = actual_stock - p_quantity,
      updated_at = NOW()
  WHERE branch_id = p_branch_id 
    AND product_id = p_product_id
    AND (actual_stock - p_quantity) >= 0; -- ضمان عدم نزول المخزون تحت الصفر
    
  IF NOT FOUND THEN
    RAISE EXCEPTION 'المخزون غير كافٍ لإتمام العملية';
  END IF;
END;
$$;


ALTER FUNCTION "public"."reduce_stock_on_order"("p_branch_id" "uuid", "p_product_id" "uuid", "p_quantity" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_driver_status"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  -- عند إسناد الطلب وانطلاقه: السائق "في توصيلة"
  IF NEW.driver_id IS NOT NULL AND NEW.status = 'shipped' THEN
    UPDATE public.drivers SET current_status = 'في توصيلة', updated_at = NOW()
    WHERE id = NEW.driver_id;

  -- عند التسليم أو الإلغاء: السائق يعود "متاح" إذا لا توجد طلبات أخرى بعهدته
  ELSIF NEW.driver_id IS NOT NULL
        AND NEW.status IN ('delivered', 'cancelled', 'rejected') THEN
    UPDATE public.drivers d SET current_status = 'متاح', updated_at = NOW()
    WHERE d.id = NEW.driver_id
      AND NOT EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.driver_id = d.id AND o.status = 'shipped' AND o.id <> NEW.id
      );
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."sync_driver_status"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_stock_on_damaged"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  IF NEW.type = 'damaged' THEN
    UPDATE public.inventory
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE branch_id = NEW.branch_id AND product_id = NEW.product_id;
  ELSIF NEW.type = 'return' THEN
    UPDATE public.inventory
    SET stock_quantity = stock_quantity + NEW.quantity
    WHERE branch_id = NEW.branch_id AND product_id = NEW.product_id;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_stock_on_damaged"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_stock_on_sale"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- الخصم مرة واحدة فقط: عند خروج الطلب من حالة الانتظار إلى التحضير/الشحن
  IF (OLD.status IN ('pending', 'قيد الانتظار')
      AND NEW.status IN ('preparing', 'shipped', 'تحضير')) THEN
    UPDATE public.inventory inv
    SET stock_quantity = inv.stock_quantity - COALESCE((
          SELECT SUM(oi.quantity) FROM public.order_items oi
          WHERE oi.order_id = NEW.id AND oi.product_id = inv.product_id
        ), 0),
        updated_at = NOW()
    WHERE inv.branch_id = NEW.branch_id
      AND inv.product_id IN (SELECT product_id FROM public.order_items WHERE order_id = NEW.id);

  -- الإرجاع: إذا أُلغي/رُفض طلب سبق خصم مخزونه
  ELSIF (OLD.status IN ('preparing', 'shipped', 'تحضير')
         AND NEW.status IN ('cancelled', 'rejected', 'ملغي', 'مرفوض')) THEN
    UPDATE public.inventory inv
    SET stock_quantity = inv.stock_quantity + COALESCE((
          SELECT SUM(oi.quantity) FROM public.order_items oi
          WHERE oi.order_id = NEW.id AND oi.product_id = inv.product_id
        ), 0),
        updated_at = NOW()
    WHERE inv.branch_id = NEW.branch_id
      AND inv.product_id IN (SELECT product_id FROM public.order_items WHERE order_id = NEW.id);
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_stock_on_sale"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."addresses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "label" "text" DEFAULT 'منزل'::"text" NOT NULL,
    "address" "text" NOT NULL,
    "latitude" double precision,
    "longitude" double precision,
    "is_default" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."addresses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "target_branch_id" "uuid",
    "sender_id" "uuid",
    "title" "text" NOT NULL,
    "message" "text" NOT NULL,
    "type" character varying(50) DEFAULT 'admin_note'::character varying,
    "is_read" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."admin_notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "branch_id" "uuid",
    "user_id" "uuid",
    "action_type" character varying(50) NOT NULL,
    "description" "text",
    "severity" character varying(20) DEFAULT 'info'::character varying,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."audit_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."banners" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "image_url" "text" NOT NULL,
    "link_type" character varying(50) DEFAULT 'none'::character varying,
    "link_value" "text",
    "is_active" boolean DEFAULT true,
    "sort_order" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."banners" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."branch_inventory" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "branch_id" "uuid",
    "product_id" "uuid",
    "actual_stock" numeric(12,3) DEFAULT 0.000,
    "buffer_limit" numeric(12,3) DEFAULT 2.000,
    "is_active" boolean DEFAULT true,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."branch_inventory" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."branches" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" character varying(255) NOT NULL,
    "address" "text" NOT NULL,
    "city" character varying(100) DEFAULT 'بغداد'::character varying,
    "phone" character varying(20),
    "status" character varying(20) DEFAULT 'نشط'::character varying,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "activation_code" character varying(10),
    "location_url" "text",
    "latitude" numeric(10,8),
    "longitude" numeric(11,8),
    "access_code" "text",
    "delivery_zones" "jsonb" DEFAULT '[]'::"jsonb"
);


ALTER TABLE "public"."branches" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" character varying(100) NOT NULL,
    "icon" character varying(50) DEFAULT 'tag'::character varying,
    "image_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "name_en" "text",
    "sort_order" integer DEFAULT 0,
    "is_active" boolean DEFAULT true
);


ALTER TABLE "public"."categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."daily_settlements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "branch_id" "uuid",
    "total_sales" numeric DEFAULT 0,
    "total_purchases" numeric DEFAULT 0,
    "total_damaged" numeric DEFAULT 0,
    "net_revenue" numeric DEFAULT 0,
    "date" "date" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."daily_settlements" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."damaged_goods" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "branch_id" "uuid",
    "product_id" "uuid",
    "quantity" numeric(10,2) NOT NULL,
    "loss_value" numeric(12,2) NOT NULL,
    "reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."damaged_goods" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."delivery_zones" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "delivery_fee" numeric DEFAULT 0,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"())
);


ALTER TABLE "public"."delivery_zones" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."discount_codes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" character varying(50) NOT NULL,
    "discount_amount" numeric NOT NULL,
    "type" character varying(20) DEFAULT 'percent'::character varying,
    "max_uses" integer DEFAULT 100,
    "used_count" integer DEFAULT 0,
    "is_active" boolean DEFAULT true,
    "min_order_amount" numeric,
    "expires_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."discount_codes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."driver_ratings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_id" "uuid",
    "driver_id" "uuid",
    "user_id" "uuid",
    "rating" integer,
    "comment" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "driver_ratings_rating_check" CHECK ((("rating" >= 1) AND ("rating" <= 5)))
);


ALTER TABLE "public"."driver_ratings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."drivers" (
    "id" "uuid" NOT NULL,
    "vehicle_type" character varying(100),
    "license_number" character varying(100),
    "is_active" boolean DEFAULT true,
    "current_status" character varying(50) DEFAULT 'متاح'::character varying,
    "last_location_lat" numeric(10,8),
    "last_location_lng" numeric(11,8),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."drivers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."favorites" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "customer_id" "uuid",
    "product_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"())
);


ALTER TABLE "public"."favorites" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."fcm_tokens" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "token" "text" NOT NULL,
    "user_id" "uuid",
    "platform" character varying(20) DEFAULT 'web'::character varying,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."fcm_tokens" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inventory" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "branch_id" "uuid",
    "product_id" "uuid",
    "stock_quantity" numeric(10,2) DEFAULT 0,
    "min_stock_level" numeric(10,2) DEFAULT 10,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."inventory" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."invoices" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_id" "uuid",
    "branch_id" "uuid",
    "branch_name" "text",
    "items" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "subtotal" numeric DEFAULT 0 NOT NULL,
    "discount" numeric DEFAULT 0,
    "tax" numeric DEFAULT 0,
    "total" numeric NOT NULL,
    "payment_method" "text" DEFAULT 'نقداً'::"text",
    "customer_name" "text",
    "cashier_name" "text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"())
);


ALTER TABLE "public"."invoices" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "title" "text" NOT NULL,
    "body" "text" NOT NULL,
    "type" character varying(50) DEFAULT 'general'::character varying,
    "data" "jsonb" DEFAULT '{}'::"jsonb",
    "is_read" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."order_chat" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_id" "uuid" NOT NULL,
    "sender_id" "uuid",
    "sender_role" "text" DEFAULT 'customer'::"text" NOT NULL,
    "message" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."order_chat" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."order_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_id" "uuid",
    "product_id" "uuid",
    "quantity" numeric(10,2) NOT NULL,
    "unit_price" numeric(12,2) NOT NULL,
    "total_price" numeric(12,2) NOT NULL,
    "product_name" "text",
    "image_url" "text"
);


ALTER TABLE "public"."order_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."order_status_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_id" "uuid" NOT NULL,
    "status" "text" NOT NULL,
    "note" "text",
    "changed_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."order_status_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."orders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "customer_id" "uuid",
    "branch_id" "uuid",
    "driver_id" "uuid",
    "total_amount" numeric(12,2) NOT NULL,
    "delivery_fee" numeric(12,2) DEFAULT 0,
    "status" character varying(50) DEFAULT 'قيد الانتظار'::character varying,
    "payment_method" character varying(50) DEFAULT 'كاش'::character varying,
    "delivery_address" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "proof_image" "text",
    "order_type" "text" DEFAULT 'app'::"text",
    "customer_name_manual" "text",
    "notes" "text",
    "cancelled_at" timestamp with time zone,
    "cancellation_reason" "text",
    "status_history" "jsonb" DEFAULT '[]'::"jsonb"
);


ALTER TABLE "public"."orders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."partner_settlements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_id" "uuid",
    "branch_id" "uuid",
    "total_revenue" numeric DEFAULT 0 NOT NULL,
    "dev_profit" numeric DEFAULT 0 NOT NULL,
    "maintenance_fund" numeric DEFAULT 0 NOT NULL,
    "branch_profit" numeric DEFAULT 0 NOT NULL,
    "is_settled" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."partner_settlements" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."product_ratings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "product_id" "uuid",
    "user_id" "uuid",
    "rating" integer,
    "comment" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "product_ratings_rating_check" CHECK ((("rating" >= 1) AND ("rating" <= 5)))
);


ALTER TABLE "public"."product_ratings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."products" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" character varying(255) NOT NULL,
    "category" character varying(100) NOT NULL,
    "unit" character varying(50) NOT NULL,
    "default_price" numeric(12,2) NOT NULL,
    "cost" numeric(12,2),
    "is_active" boolean DEFAULT true,
    "image_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "is_offer" boolean DEFAULT false,
    "allowed_branches" "uuid"[] DEFAULT '{}'::"uuid"[],
    "price" numeric(12,2) DEFAULT 0
);


ALTER TABLE "public"."products" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "role" character varying(50) DEFAULT 'customer'::character varying NOT NULL,
    "full_name" character varying(255),
    "phone" character varying(20),
    "branch_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "fcm_token" "text",
    "plate_number" "text",
    "avatar_url" "text",
    "is_approved" boolean DEFAULT false,
    "is_online" boolean DEFAULT false,
    "vehicle_type" character varying(50),
    "name_change_count" integer DEFAULT 0,
    "phone_changed" boolean DEFAULT false
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."purchase_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "purchase_id" "uuid",
    "product_id" "uuid" NOT NULL,
    "quantity" numeric DEFAULT 0,
    "unit_cost" numeric DEFAULT 0,
    "total_cost" numeric DEFAULT 0
);


ALTER TABLE "public"."purchase_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."purchases" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "branch_id" "uuid",
    "supplier_name" character varying(255) NOT NULL,
    "total_value" numeric(12,2) NOT NULL,
    "payment_status" character varying(50) DEFAULT 'مدفوع'::character varying,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."purchases" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."push_notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" character varying(255) NOT NULL,
    "body" "text" NOT NULL,
    "image_url" "text",
    "target_audience" character varying(50) DEFAULT 'all'::character varying,
    "sent_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."push_notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."shift_closings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "branch_id" "uuid",
    "manager_id" "uuid",
    "expected_cash" numeric(12,2) NOT NULL,
    "actual_cash" numeric(12,2) NOT NULL,
    "difference" numeric(12,2) GENERATED ALWAYS AS (("actual_cash" - "expected_cash")) STORED,
    "notes" "text",
    "status" character varying(20) DEFAULT 'closed'::character varying,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."shift_closings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."stock_entries" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "branch_id" "uuid",
    "product_id" "uuid",
    "quantity" numeric NOT NULL,
    "unit_cost" numeric DEFAULT 0,
    "total_cost" numeric DEFAULT 0,
    "entered_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"())
);


ALTER TABLE "public"."stock_entries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."story_groups" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" character varying(100) NOT NULL,
    "thumbnail_url" "text",
    "is_active" boolean DEFAULT true,
    "sort_order" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."story_groups" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."story_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "group_id" "uuid",
    "media_type" character varying(50) NOT NULL,
    "media_url" "text",
    "text_content" "text",
    "bg_color" character varying(20),
    "duration" integer DEFAULT 5,
    "sort_order" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."story_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."system_settings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "key" character varying(100) NOT NULL,
    "value_decimal" numeric DEFAULT 0.0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."system_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_fcm_tokens" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "token" "text" NOT NULL,
    "device_type" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "user_fcm_tokens_device_type_check" CHECK (("device_type" = ANY (ARRAY['web'::"text", 'android'::"text", 'ios'::"text"])))
);


ALTER TABLE "public"."user_fcm_tokens" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."waste_records" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "branch_id" "uuid",
    "product_id" "uuid",
    "quantity" numeric(12,3) NOT NULL,
    "reason" "text",
    "loss_value" numeric(12,2),
    "reported_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."waste_records" OWNER TO "postgres";


ALTER TABLE ONLY "public"."addresses"
    ADD CONSTRAINT "addresses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_notifications"
    ADD CONSTRAINT "admin_notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."banners"
    ADD CONSTRAINT "banners_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."branch_inventory"
    ADD CONSTRAINT "branch_inventory_branch_id_product_id_key" UNIQUE ("branch_id", "product_id");



ALTER TABLE ONLY "public"."branch_inventory"
    ADD CONSTRAINT "branch_inventory_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."branches"
    ADD CONSTRAINT "branches_activation_code_key" UNIQUE ("activation_code");



ALTER TABLE ONLY "public"."branches"
    ADD CONSTRAINT "branches_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."daily_settlements"
    ADD CONSTRAINT "daily_settlements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."damaged_goods"
    ADD CONSTRAINT "damaged_goods_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."delivery_zones"
    ADD CONSTRAINT "delivery_zones_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."discount_codes"
    ADD CONSTRAINT "discount_codes_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."discount_codes"
    ADD CONSTRAINT "discount_codes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."driver_ratings"
    ADD CONSTRAINT "driver_ratings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."drivers"
    ADD CONSTRAINT "drivers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "favorites_customer_id_product_id_key" UNIQUE ("customer_id", "product_id");



ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "favorites_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."fcm_tokens"
    ADD CONSTRAINT "fcm_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."fcm_tokens"
    ADD CONSTRAINT "fcm_tokens_token_key" UNIQUE ("token");



ALTER TABLE ONLY "public"."inventory"
    ADD CONSTRAINT "inventory_branch_id_product_id_key" UNIQUE ("branch_id", "product_id");



ALTER TABLE ONLY "public"."inventory"
    ADD CONSTRAINT "inventory_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."order_chat"
    ADD CONSTRAINT "order_chat_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."order_items"
    ADD CONSTRAINT "order_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."order_status_history"
    ADD CONSTRAINT "order_status_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."partner_settlements"
    ADD CONSTRAINT "partner_settlements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."product_ratings"
    ADD CONSTRAINT "product_ratings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."product_ratings"
    ADD CONSTRAINT "product_ratings_product_id_user_id_key" UNIQUE ("product_id", "user_id");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_phone_key" UNIQUE ("phone");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."purchase_items"
    ADD CONSTRAINT "purchase_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."purchases"
    ADD CONSTRAINT "purchases_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."push_notifications"
    ADD CONSTRAINT "push_notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shift_closings"
    ADD CONSTRAINT "shift_closings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stock_entries"
    ADD CONSTRAINT "stock_entries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."story_groups"
    ADD CONSTRAINT "story_groups_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."story_items"
    ADD CONSTRAINT "story_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."system_settings"
    ADD CONSTRAINT "system_settings_key_key" UNIQUE ("key");



ALTER TABLE ONLY "public"."system_settings"
    ADD CONSTRAINT "system_settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_fcm_tokens"
    ADD CONSTRAINT "user_fcm_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_fcm_tokens"
    ADD CONSTRAINT "user_fcm_tokens_token_key" UNIQUE ("token");



ALTER TABLE ONLY "public"."waste_records"
    ADD CONSTRAINT "waste_records_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_fcm_tokens_platform" ON "public"."fcm_tokens" USING "btree" ("platform");



CREATE INDEX "idx_fcm_tokens_user" ON "public"."fcm_tokens" USING "btree" ("user_id");



CREATE INDEX "idx_notifications_created_at" ON "public"."notifications" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_notifications_user_id" ON "public"."notifications" USING "btree" ("user_id");



CREATE UNIQUE INDEX "uq_partner_settlements_order" ON "public"."partner_settlements" USING "btree" ("order_id") WHERE ("order_id" IS NOT NULL);



CREATE OR REPLACE TRIGGER "notify_order_status_change" AFTER UPDATE ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."fn_notify_order_status_change"();



CREATE OR REPLACE TRIGGER "on_product_created" AFTER INSERT ON "public"."products" FOR EACH ROW EXECUTE FUNCTION "public"."handle_new_product_inventory"();



CREATE OR REPLACE TRIGGER "on_waste_reported" AFTER INSERT ON "public"."waste_records" FOR EACH ROW EXECUTE FUNCTION "public"."handle_waste_reduction"();



CREATE OR REPLACE TRIGGER "prevent_completed_order_changes" BEFORE UPDATE ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."fn_prevent_completed_order_changes"();



CREATE OR REPLACE TRIGGER "send_fcm_on_order_update" AFTER UPDATE ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."fn_send_fcm_on_order_update"();



CREATE OR REPLACE TRIGGER "sync_driver_status_on_assignment" AFTER UPDATE ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."fn_sync_driver_status"();



CREATE OR REPLACE TRIGGER "tr_notify_customer_on_status_change" AFTER UPDATE ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."notify_customer_on_status_change"();



CREATE OR REPLACE TRIGGER "tr_notify_drivers_on_order" AFTER INSERT ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."notify_drivers_on_new_order"();



CREATE OR REPLACE TRIGGER "trg_cleanup_notifications" AFTER INSERT ON "public"."notifications" FOR EACH STATEMENT EXECUTE FUNCTION "public"."cleanup_old_notifications"();



CREATE OR REPLACE TRIGGER "trg_guard_order_status" BEFORE UPDATE OF "status" ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."guard_order_status_transition"();



CREATE OR REPLACE TRIGGER "trg_notify_order_created" AFTER INSERT ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."notify_order_created"();



CREATE OR REPLACE TRIGGER "trg_notify_order_status" AFTER UPDATE OF "status" ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."notify_order_status_change"();



CREATE OR REPLACE TRIGGER "trg_record_partner_settlement" AFTER UPDATE OF "status" ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."record_partner_settlement"();



CREATE OR REPLACE TRIGGER "trg_sync_driver_status" AFTER UPDATE ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."sync_driver_status"();



CREATE OR REPLACE TRIGGER "trigger_initialize_inventory" AFTER INSERT ON "public"."products" FOR EACH ROW EXECUTE FUNCTION "public"."initialize_branch_inventory"();



CREATE OR REPLACE TRIGGER "trigger_update_stock_on_damaged" AFTER INSERT ON "public"."damaged_goods" FOR EACH ROW EXECUTE FUNCTION "public"."update_stock_on_damaged"();



CREATE OR REPLACE TRIGGER "trigger_update_stock_on_sale" AFTER UPDATE OF "status" ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."update_stock_on_sale"();



CREATE OR REPLACE TRIGGER "update_stock_on_sale" AFTER UPDATE ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."fn_update_stock_on_sale"();



ALTER TABLE ONLY "public"."addresses"
    ADD CONSTRAINT "addresses_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."admin_notifications"
    ADD CONSTRAINT "admin_notifications_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."admin_notifications"
    ADD CONSTRAINT "admin_notifications_target_branch_id_fkey" FOREIGN KEY ("target_branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."branch_inventory"
    ADD CONSTRAINT "branch_inventory_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."branch_inventory"
    ADD CONSTRAINT "branch_inventory_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."daily_settlements"
    ADD CONSTRAINT "daily_settlements_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."damaged_goods"
    ADD CONSTRAINT "damaged_goods_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."damaged_goods"
    ADD CONSTRAINT "damaged_goods_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."driver_ratings"
    ADD CONSTRAINT "driver_ratings_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."driver_ratings"
    ADD CONSTRAINT "driver_ratings_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."driver_ratings"
    ADD CONSTRAINT "driver_ratings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."drivers"
    ADD CONSTRAINT "drivers_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "favorites_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "favorites_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."fcm_tokens"
    ADD CONSTRAINT "fcm_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."inventory"
    ADD CONSTRAINT "inventory_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory"
    ADD CONSTRAINT "inventory_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."order_chat"
    ADD CONSTRAINT "order_chat_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."order_chat"
    ADD CONSTRAINT "order_chat_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."order_items"
    ADD CONSTRAINT "order_items_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."order_items"
    ADD CONSTRAINT "order_items_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."order_status_history"
    ADD CONSTRAINT "order_status_history_changed_by_fkey" FOREIGN KEY ("changed_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."order_status_history"
    ADD CONSTRAINT "order_status_history_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."drivers"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."partner_settlements"
    ADD CONSTRAINT "partner_settlements_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."partner_settlements"
    ADD CONSTRAINT "partner_settlements_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."product_ratings"
    ADD CONSTRAINT "product_ratings_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id");



ALTER TABLE ONLY "public"."product_ratings"
    ADD CONSTRAINT "product_ratings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."purchase_items"
    ADD CONSTRAINT "purchase_items_purchase_id_fkey" FOREIGN KEY ("purchase_id") REFERENCES "public"."purchases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."purchases"
    ADD CONSTRAINT "purchases_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shift_closings"
    ADD CONSTRAINT "shift_closings_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shift_closings"
    ADD CONSTRAINT "shift_closings_manager_id_fkey" FOREIGN KEY ("manager_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."stock_entries"
    ADD CONSTRAINT "stock_entries_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id");



ALTER TABLE ONLY "public"."stock_entries"
    ADD CONSTRAINT "stock_entries_entered_by_fkey" FOREIGN KEY ("entered_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."stock_entries"
    ADD CONSTRAINT "stock_entries_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id");



ALTER TABLE ONLY "public"."story_items"
    ADD CONSTRAINT "story_items_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."story_groups"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_fcm_tokens"
    ADD CONSTRAINT "user_fcm_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."waste_records"
    ADD CONSTRAINT "waste_records_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."waste_records"
    ADD CONSTRAINT "waste_records_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."waste_records"
    ADD CONSTRAINT "waste_records_reported_by_fkey" FOREIGN KEY ("reported_by") REFERENCES "auth"."users"("id");



ALTER TABLE "public"."addresses" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "admin_all_addresses" ON "public"."addresses" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_admin_notifications" ON "public"."admin_notifications" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_audit_logs" ON "public"."audit_logs" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_banners" ON "public"."banners" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_branch_inventory" ON "public"."branch_inventory" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_branches" ON "public"."branches" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_categories" ON "public"."categories" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_daily_settlements" ON "public"."daily_settlements" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_damaged_goods" ON "public"."damaged_goods" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_delivery_zones" ON "public"."delivery_zones" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_discount_codes" ON "public"."discount_codes" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_driver_ratings" ON "public"."driver_ratings" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_drivers" ON "public"."drivers" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_favorites" ON "public"."favorites" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_fcm_tokens" ON "public"."fcm_tokens" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_inventory" ON "public"."inventory" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_invoices" ON "public"."invoices" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_notifications" ON "public"."notifications" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_order_chat" ON "public"."order_chat" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_order_items" ON "public"."order_items" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_order_status_history" ON "public"."order_status_history" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_orders" ON "public"."orders" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_partner_settlements" ON "public"."partner_settlements" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_product_ratings" ON "public"."product_ratings" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_products" ON "public"."products" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_profiles" ON "public"."profiles" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_purchase_items" ON "public"."purchase_items" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_purchases" ON "public"."purchases" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_push_notifications" ON "public"."push_notifications" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_shift_closings" ON "public"."shift_closings" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_stock_entries" ON "public"."stock_entries" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_story_groups" ON "public"."story_groups" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_story_items" ON "public"."story_items" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_system_settings" ON "public"."system_settings" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_user_fcm_tokens" ON "public"."user_fcm_tokens" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "admin_all_waste_records" ON "public"."waste_records" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



ALTER TABLE "public"."admin_notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."audit_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."banners" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."branch_inventory" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "branch_orders_all" ON "public"."orders" USING ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"()))) WITH CHECK ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"())));



CREATE POLICY "branch_staff_audit_logs" ON "public"."audit_logs" USING ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"()))) WITH CHECK ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"())));



CREATE POLICY "branch_staff_branch_inventory" ON "public"."branch_inventory" USING ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"()))) WITH CHECK ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"())));



CREATE POLICY "branch_staff_daily_settlements" ON "public"."daily_settlements" USING ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"()))) WITH CHECK ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"())));



CREATE POLICY "branch_staff_damaged_goods" ON "public"."damaged_goods" USING ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"()))) WITH CHECK ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"())));



CREATE POLICY "branch_staff_inventory" ON "public"."inventory" USING ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"()))) WITH CHECK ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"())));



CREATE POLICY "branch_staff_invoices" ON "public"."invoices" USING ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"()))) WITH CHECK ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"())));



CREATE POLICY "branch_staff_partner_settlements" ON "public"."partner_settlements" USING ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"()))) WITH CHECK ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"())));



CREATE POLICY "branch_staff_purchases" ON "public"."purchases" USING ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"()))) WITH CHECK ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"())));



CREATE POLICY "branch_staff_shift_closings" ON "public"."shift_closings" USING ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"()))) WITH CHECK ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"())));



CREATE POLICY "branch_staff_stock_entries" ON "public"."stock_entries" USING ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"()))) WITH CHECK ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"())));



CREATE POLICY "branch_staff_waste_records" ON "public"."waste_records" USING ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"()))) WITH CHECK ((("public"."get_my_role"() = 'branch_manager'::"text") AND ("branch_id" = "public"."get_my_branch_id"())));



ALTER TABLE "public"."branches" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."categories" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "customer_active_driver_select" ON "public"."drivers" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."orders" "o"
  WHERE (("o"."driver_id" = "drivers"."id") AND ("o"."customer_id" = "auth"."uid"()) AND (("o"."status")::"text" = ANY ((ARRAY['shipped'::character varying, 'في الطريق'::character varying, 'preparing'::character varying, 'تحضير'::character varying])::"text"[]))))));



CREATE POLICY "customer_orders_insert" ON "public"."orders" FOR INSERT WITH CHECK (("customer_id" = "auth"."uid"()));



CREATE POLICY "customer_orders_select" ON "public"."orders" FOR SELECT USING (("customer_id" = "auth"."uid"()));



CREATE POLICY "customer_orders_update" ON "public"."orders" FOR UPDATE USING (("customer_id" = "auth"."uid"())) WITH CHECK (("customer_id" = "auth"."uid"()));



CREATE POLICY "customer_rate_own" ON "public"."driver_ratings" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."daily_settlements" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."damaged_goods" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."delivery_zones" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."discount_codes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "discount_codes_read" ON "public"."discount_codes" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "driver_orders_select" ON "public"."orders" FOR SELECT USING (("driver_id" = "auth"."uid"()));



CREATE POLICY "driver_orders_update" ON "public"."orders" FOR UPDATE USING (("driver_id" = "auth"."uid"())) WITH CHECK (("driver_id" = "auth"."uid"()));



CREATE POLICY "driver_own_select" ON "public"."drivers" FOR SELECT USING ((("id" = "auth"."uid"()) OR "public"."is_staff"()));



CREATE POLICY "driver_own_update" ON "public"."drivers" FOR UPDATE USING (("id" = "auth"."uid"())) WITH CHECK (("id" = "auth"."uid"()));



ALTER TABLE "public"."driver_ratings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."drivers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."favorites" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."fcm_tokens" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."inventory" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."invoices" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "notifications_delete_own" ON "public"."notifications" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "notifications_select_own" ON "public"."notifications" FOR SELECT USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."order_chat" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "order_chat_participants_insert" ON "public"."order_chat" FOR INSERT WITH CHECK ((("sender_id" = "auth"."uid"()) AND ("public"."is_staff"() OR (EXISTS ( SELECT 1
   FROM "public"."orders" "o"
  WHERE (("o"."id" = "order_chat"."order_id") AND (("o"."customer_id" = "auth"."uid"()) OR ("o"."driver_id" = "auth"."uid"()))))))));



CREATE POLICY "order_chat_participants_select" ON "public"."order_chat" FOR SELECT USING (("public"."is_staff"() OR (EXISTS ( SELECT 1
   FROM "public"."orders" "o"
  WHERE (("o"."id" = "order_chat"."order_id") AND (("o"."customer_id" = "auth"."uid"()) OR ("o"."driver_id" = "auth"."uid"())))))));



ALTER TABLE "public"."order_items" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "order_items_insert" ON "public"."order_items" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."orders" "o"
  WHERE (("o"."id" = "order_items"."order_id") AND (("o"."customer_id" = "auth"."uid"()) OR (("public"."get_my_role"() = 'branch_manager'::"text") AND ("o"."branch_id" = "public"."get_my_branch_id"())))))));



CREATE POLICY "order_items_select" ON "public"."order_items" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."orders" "o"
  WHERE (("o"."id" = "order_items"."order_id") AND (("o"."customer_id" = "auth"."uid"()) OR ("o"."driver_id" = "auth"."uid"()) OR (("public"."get_my_role"() = 'branch_manager'::"text") AND ("o"."branch_id" = "public"."get_my_branch_id"())))))));



CREATE POLICY "order_items_staff_mod" ON "public"."order_items" USING ((EXISTS ( SELECT 1
   FROM "public"."orders" "o"
  WHERE (("o"."id" = "order_items"."order_id") AND ("public"."get_my_role"() = 'branch_manager'::"text") AND ("o"."branch_id" = "public"."get_my_branch_id"())))));



ALTER TABLE "public"."order_status_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."orders" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "osh_select" ON "public"."order_status_history" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."orders" "o"
  WHERE (("o"."id" = "order_status_history"."order_id") AND (("o"."customer_id" = "auth"."uid"()) OR ("o"."driver_id" = "auth"."uid"()) OR (("public"."get_my_role"() = 'branch_manager'::"text") AND ("o"."branch_id" = "public"."get_my_branch_id"())))))));



CREATE POLICY "osh_staff_insert" ON "public"."order_status_history" FOR INSERT WITH CHECK ("public"."is_staff"());



CREATE POLICY "own_addresses" ON "public"."addresses" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "own_favorites" ON "public"."favorites" USING (("customer_id" = "auth"."uid"())) WITH CHECK (("customer_id" = "auth"."uid"()));



CREATE POLICY "own_fcm_tokens" ON "public"."fcm_tokens" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "own_notifications_select" ON "public"."notifications" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "own_notifications_update" ON "public"."notifications" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "own_profile_insert" ON "public"."profiles" FOR INSERT WITH CHECK (("id" = "auth"."uid"()));



CREATE POLICY "own_profile_select" ON "public"."profiles" FOR SELECT USING ((("id" = "auth"."uid"()) OR "public"."is_staff"()));



CREATE POLICY "own_profile_update" ON "public"."profiles" FOR UPDATE USING (("id" = "auth"."uid"())) WITH CHECK ((("id" = "auth"."uid"()) AND (("role")::"text" = (( SELECT "p"."role"
   FROM "public"."profiles" "p"
  WHERE ("p"."id" = "auth"."uid"())))::"text")));



CREATE POLICY "own_user_fcm_tokens" ON "public"."user_fcm_tokens" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."partner_settlements" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."product_ratings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "product_ratings_insert_own" ON "public"."product_ratings" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "product_ratings_read" ON "public"."product_ratings" FOR SELECT USING (true);



CREATE POLICY "product_ratings_update_own" ON "public"."product_ratings" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."products" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "public_read_banners" ON "public"."banners" FOR SELECT USING (true);



CREATE POLICY "public_read_branch_inventory" ON "public"."branch_inventory" FOR SELECT USING (true);



CREATE POLICY "public_read_branches" ON "public"."branches" FOR SELECT USING (true);



CREATE POLICY "public_read_categories" ON "public"."categories" FOR SELECT USING (true);



CREATE POLICY "public_read_delivery_zones" ON "public"."delivery_zones" FOR SELECT USING (true);



CREATE POLICY "public_read_products" ON "public"."products" FOR SELECT USING (true);



CREATE POLICY "public_read_story_groups" ON "public"."story_groups" FOR SELECT USING (true);



CREATE POLICY "public_read_story_items" ON "public"."story_items" FOR SELECT USING (true);



ALTER TABLE "public"."purchase_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."purchases" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."push_notifications" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "push_notifications_read" ON "public"."push_notifications" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "ratings_read" ON "public"."driver_ratings" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."shift_closings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "staff_all_admin_notifications" ON "public"."admin_notifications" USING ("public"."is_staff"()) WITH CHECK ("public"."is_staff"());



CREATE POLICY "staff_all_discount_codes" ON "public"."discount_codes" USING ("public"."is_staff"()) WITH CHECK ("public"."is_staff"());



CREATE POLICY "staff_all_purchase_items" ON "public"."purchase_items" USING ("public"."is_staff"()) WITH CHECK ("public"."is_staff"());



CREATE POLICY "staff_all_system_settings" ON "public"."system_settings" USING ("public"."is_staff"()) WITH CHECK ("public"."is_staff"());



CREATE POLICY "staff_drivers_manage" ON "public"."drivers" USING ("public"."is_staff"()) WITH CHECK ("public"."is_staff"());



CREATE POLICY "staff_notifications_insert" ON "public"."notifications" FOR INSERT WITH CHECK ("public"."is_staff"());



CREATE POLICY "staff_write_banners" ON "public"."banners" USING ("public"."is_staff"()) WITH CHECK ("public"."is_staff"());



CREATE POLICY "staff_write_branches" ON "public"."branches" USING ("public"."is_staff"()) WITH CHECK ("public"."is_staff"());



CREATE POLICY "staff_write_categories" ON "public"."categories" USING ("public"."is_staff"()) WITH CHECK ("public"."is_staff"());



CREATE POLICY "staff_write_delivery_zones" ON "public"."delivery_zones" USING ("public"."is_staff"()) WITH CHECK ("public"."is_staff"());



CREATE POLICY "staff_write_products" ON "public"."products" USING ("public"."is_staff"()) WITH CHECK ("public"."is_staff"());



CREATE POLICY "staff_write_story_groups" ON "public"."story_groups" USING ("public"."is_staff"()) WITH CHECK ("public"."is_staff"());



CREATE POLICY "staff_write_story_items" ON "public"."story_items" USING ("public"."is_staff"()) WITH CHECK ("public"."is_staff"());



ALTER TABLE "public"."stock_entries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."story_groups" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."story_items" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "super_admin_fcm" ON "public"."fcm_tokens" USING (("public"."get_my_role"() = 'super_admin'::"text"));



ALTER TABLE "public"."system_settings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "system_settings_read" ON "public"."system_settings" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."user_fcm_tokens" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "user_own_token" ON "public"."fcm_tokens" USING ((("user_id" = "auth"."uid"()) OR ("user_id" IS NULL)));



ALTER TABLE "public"."waste_records" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."drivers";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."inventory";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."notifications";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."orders";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";




































































































































































































































GRANT ALL ON FUNCTION "public"."cleanup_old_notifications"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_old_notifications"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_old_notifications"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_notify_order_status_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_notify_order_status_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_notify_order_status_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_prevent_completed_order_changes"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_prevent_completed_order_changes"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_prevent_completed_order_changes"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_send_fcm_on_order_update"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_send_fcm_on_order_update"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_send_fcm_on_order_update"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_sync_driver_status"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_sync_driver_status"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_sync_driver_status"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_update_stock_on_sale"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_update_stock_on_sale"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_update_stock_on_sale"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_branch_drivers_tokens"("p_branch_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_branch_drivers_tokens"("p_branch_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_branch_drivers_tokens"("p_branch_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_my_branch_id"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_branch_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_branch_id"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_my_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_role"() TO "service_role";



GRANT ALL ON FUNCTION "public"."guard_order_status_transition"() TO "anon";
GRANT ALL ON FUNCTION "public"."guard_order_status_transition"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."guard_order_status_transition"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_product_inventory"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_product_inventory"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_product_inventory"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_waste_reduction"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_waste_reduction"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_waste_reduction"() TO "service_role";



GRANT ALL ON FUNCTION "public"."initialize_branch_inventory"() TO "anon";
GRANT ALL ON FUNCTION "public"."initialize_branch_inventory"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."initialize_branch_inventory"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_staff"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_staff"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_staff"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_customer_on_status_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_customer_on_status_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_customer_on_status_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_drivers_on_new_order"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_drivers_on_new_order"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_drivers_on_new_order"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_order_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_order_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_order_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_order_created"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_order_created"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_order_created"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_order_status_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_order_status_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_order_status_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."record_partner_settlement"() TO "anon";
GRANT ALL ON FUNCTION "public"."record_partner_settlement"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."record_partner_settlement"() TO "service_role";



GRANT ALL ON FUNCTION "public"."reduce_stock_on_order"("p_branch_id" "uuid", "p_product_id" "uuid", "p_quantity" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."reduce_stock_on_order"("p_branch_id" "uuid", "p_product_id" "uuid", "p_quantity" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."reduce_stock_on_order"("p_branch_id" "uuid", "p_product_id" "uuid", "p_quantity" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_driver_status"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_driver_status"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_driver_status"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_stock_on_damaged"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_stock_on_damaged"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_stock_on_damaged"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_stock_on_sale"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_stock_on_sale"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_stock_on_sale"() TO "service_role";
























GRANT ALL ON TABLE "public"."addresses" TO "anon";
GRANT ALL ON TABLE "public"."addresses" TO "authenticated";
GRANT ALL ON TABLE "public"."addresses" TO "service_role";



GRANT ALL ON TABLE "public"."admin_notifications" TO "anon";
GRANT ALL ON TABLE "public"."admin_notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_notifications" TO "service_role";



GRANT ALL ON TABLE "public"."audit_logs" TO "anon";
GRANT ALL ON TABLE "public"."audit_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_logs" TO "service_role";



GRANT ALL ON TABLE "public"."banners" TO "anon";
GRANT ALL ON TABLE "public"."banners" TO "authenticated";
GRANT ALL ON TABLE "public"."banners" TO "service_role";



GRANT ALL ON TABLE "public"."branch_inventory" TO "anon";
GRANT ALL ON TABLE "public"."branch_inventory" TO "authenticated";
GRANT ALL ON TABLE "public"."branch_inventory" TO "service_role";



GRANT ALL ON TABLE "public"."branches" TO "anon";
GRANT ALL ON TABLE "public"."branches" TO "authenticated";
GRANT ALL ON TABLE "public"."branches" TO "service_role";



GRANT ALL ON TABLE "public"."categories" TO "anon";
GRANT ALL ON TABLE "public"."categories" TO "authenticated";
GRANT ALL ON TABLE "public"."categories" TO "service_role";



GRANT ALL ON TABLE "public"."daily_settlements" TO "anon";
GRANT ALL ON TABLE "public"."daily_settlements" TO "authenticated";
GRANT ALL ON TABLE "public"."daily_settlements" TO "service_role";



GRANT ALL ON TABLE "public"."damaged_goods" TO "anon";
GRANT ALL ON TABLE "public"."damaged_goods" TO "authenticated";
GRANT ALL ON TABLE "public"."damaged_goods" TO "service_role";



GRANT ALL ON TABLE "public"."delivery_zones" TO "anon";
GRANT ALL ON TABLE "public"."delivery_zones" TO "authenticated";
GRANT ALL ON TABLE "public"."delivery_zones" TO "service_role";



GRANT ALL ON TABLE "public"."discount_codes" TO "anon";
GRANT ALL ON TABLE "public"."discount_codes" TO "authenticated";
GRANT ALL ON TABLE "public"."discount_codes" TO "service_role";



GRANT ALL ON TABLE "public"."driver_ratings" TO "anon";
GRANT ALL ON TABLE "public"."driver_ratings" TO "authenticated";
GRANT ALL ON TABLE "public"."driver_ratings" TO "service_role";



GRANT ALL ON TABLE "public"."drivers" TO "anon";
GRANT ALL ON TABLE "public"."drivers" TO "authenticated";
GRANT ALL ON TABLE "public"."drivers" TO "service_role";



GRANT ALL ON TABLE "public"."favorites" TO "anon";
GRANT ALL ON TABLE "public"."favorites" TO "authenticated";
GRANT ALL ON TABLE "public"."favorites" TO "service_role";



GRANT ALL ON TABLE "public"."fcm_tokens" TO "anon";
GRANT ALL ON TABLE "public"."fcm_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."fcm_tokens" TO "service_role";



GRANT ALL ON TABLE "public"."inventory" TO "anon";
GRANT ALL ON TABLE "public"."inventory" TO "authenticated";
GRANT ALL ON TABLE "public"."inventory" TO "service_role";



GRANT ALL ON TABLE "public"."invoices" TO "anon";
GRANT ALL ON TABLE "public"."invoices" TO "authenticated";
GRANT ALL ON TABLE "public"."invoices" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."order_chat" TO "anon";
GRANT ALL ON TABLE "public"."order_chat" TO "authenticated";
GRANT ALL ON TABLE "public"."order_chat" TO "service_role";



GRANT ALL ON TABLE "public"."order_items" TO "anon";
GRANT ALL ON TABLE "public"."order_items" TO "authenticated";
GRANT ALL ON TABLE "public"."order_items" TO "service_role";



GRANT ALL ON TABLE "public"."order_status_history" TO "anon";
GRANT ALL ON TABLE "public"."order_status_history" TO "authenticated";
GRANT ALL ON TABLE "public"."order_status_history" TO "service_role";



GRANT ALL ON TABLE "public"."orders" TO "anon";
GRANT ALL ON TABLE "public"."orders" TO "authenticated";
GRANT ALL ON TABLE "public"."orders" TO "service_role";



GRANT ALL ON TABLE "public"."partner_settlements" TO "anon";
GRANT ALL ON TABLE "public"."partner_settlements" TO "authenticated";
GRANT ALL ON TABLE "public"."partner_settlements" TO "service_role";



GRANT ALL ON TABLE "public"."product_ratings" TO "anon";
GRANT ALL ON TABLE "public"."product_ratings" TO "authenticated";
GRANT ALL ON TABLE "public"."product_ratings" TO "service_role";



GRANT ALL ON TABLE "public"."products" TO "anon";
GRANT ALL ON TABLE "public"."products" TO "authenticated";
GRANT ALL ON TABLE "public"."products" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."purchase_items" TO "anon";
GRANT ALL ON TABLE "public"."purchase_items" TO "authenticated";
GRANT ALL ON TABLE "public"."purchase_items" TO "service_role";



GRANT ALL ON TABLE "public"."purchases" TO "anon";
GRANT ALL ON TABLE "public"."purchases" TO "authenticated";
GRANT ALL ON TABLE "public"."purchases" TO "service_role";



GRANT ALL ON TABLE "public"."push_notifications" TO "anon";
GRANT ALL ON TABLE "public"."push_notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."push_notifications" TO "service_role";



GRANT ALL ON TABLE "public"."shift_closings" TO "anon";
GRANT ALL ON TABLE "public"."shift_closings" TO "authenticated";
GRANT ALL ON TABLE "public"."shift_closings" TO "service_role";



GRANT ALL ON TABLE "public"."stock_entries" TO "anon";
GRANT ALL ON TABLE "public"."stock_entries" TO "authenticated";
GRANT ALL ON TABLE "public"."stock_entries" TO "service_role";



GRANT ALL ON TABLE "public"."story_groups" TO "anon";
GRANT ALL ON TABLE "public"."story_groups" TO "authenticated";
GRANT ALL ON TABLE "public"."story_groups" TO "service_role";



GRANT ALL ON TABLE "public"."story_items" TO "anon";
GRANT ALL ON TABLE "public"."story_items" TO "authenticated";
GRANT ALL ON TABLE "public"."story_items" TO "service_role";



GRANT ALL ON TABLE "public"."system_settings" TO "anon";
GRANT ALL ON TABLE "public"."system_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."system_settings" TO "service_role";



GRANT ALL ON TABLE "public"."user_fcm_tokens" TO "anon";
GRANT ALL ON TABLE "public"."user_fcm_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."user_fcm_tokens" TO "service_role";



GRANT ALL ON TABLE "public"."waste_records" TO "anon";
GRANT ALL ON TABLE "public"."waste_records" TO "authenticated";
GRANT ALL ON TABLE "public"."waste_records" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































