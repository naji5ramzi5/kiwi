-- ============================================================
-- fix_security_rls.sql — تأمين قاعدة البيانات بسياسات مبنية على الأدوار
-- شغّل هذا الملف في Supabase SQL Editor مرة واحدة (بعد fix_order_lifecycle.sql)
--
-- المشكلة الجذرية: السياسات القديمة (auth.role() = 'authenticated')
-- تسمح لأي زبون مسجّل بقراءة وتعديل كل الجداول: الفواتير، المخزون،
-- طلبات الآخرين، التسويات المالية، وبيانات كل المستخدمين.
--
-- الأدوار المعتمدة (من profiles.role):
--   super_admin / admin  → كل شيء
--   branch_manager       → بيانات فرعه فقط
--   driver               → طلباته المسندة وبياناته فقط
--   customer             → طلباته وبياناته فقط
-- ============================================================

-- ─── 1. دوال المساعدة (تقرأ الدور من profiles أولاً ثم من metadata) ───
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE SQL STABLE SECURITY DEFINER
SET search_path = 'public'
AS $$
  SELECT COALESCE(
    (SELECT role FROM public.profiles WHERE id = auth.uid()),
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()),
    'customer'
  );
$$;

CREATE OR REPLACE FUNCTION public.get_my_branch_id()
RETURNS UUID
LANGUAGE SQL STABLE SECURITY DEFINER
SET search_path = 'public'
AS $$
  SELECT COALESCE(
    (SELECT branch_id FROM public.profiles WHERE id = auth.uid()),
    (SELECT (raw_user_meta_data->>'branch_id')::UUID FROM auth.users WHERE id = auth.uid())
  );
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER
SET search_path = 'public'
AS $$ SELECT public.get_my_role() IN ('admin', 'super_admin'); $$;

-- موظف = أدمن أو مدير فرع
CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER
SET search_path = 'public'
AS $$ SELECT public.get_my_role() IN ('admin', 'super_admin', 'branch_manager'); $$;

-- ─── 2. حذف كل السياسات القديمة (المفتوحة بشكل خطير) ───────
DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN (SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public') LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, pol.tablename);
  END LOOP;
END $$;

-- ─── 3. تفعيل RLS على جميع الجداول ──────────────────────────
DO $$
DECLARE tbl TEXT;
BEGIN
  FOR tbl IN (
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public'
    AND tablename NOT IN ('schema_migrations', 'spatial_ref_sys')
  ) LOOP
    EXECUTE format('ALTER TABLE IF EXISTS public.%I ENABLE ROW LEVEL SECURITY', tbl);
  END LOOP;
END $$;

-- ─── 4. الأدمن: صلاحية كاملة على كل الجداول ─────────────────
DO $$
DECLARE tbl TEXT;
BEGIN
  FOR tbl IN (
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public'
    AND tablename NOT IN ('schema_migrations', 'spatial_ref_sys')
  ) LOOP
    EXECUTE format(
      'CREATE POLICY "admin_all_%s" ON public.%I FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin())',
      tbl, tbl);
  END LOOP;
END $$;

-- ─── 5. القراءة العامة (الكتالوج) — للجميع حتى قبل تسجيل الدخول ─
DO $$
DECLARE tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'products','branches','categories','banners','delivery_zones',
    'story_groups','story_items','branch_inventory'
  ] LOOP
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename=tbl) THEN
      EXECUTE format('CREATE POLICY "public_read_%s" ON public.%I FOR SELECT USING (true)', tbl, tbl);
    END IF;
  END LOOP;
END $$;

-- ─── 6. profiles ─────────────────────────────────────────────
CREATE POLICY "own_profile_select" ON public.profiles
  FOR SELECT USING (id = auth.uid() OR public.is_staff());
CREATE POLICY "own_profile_insert" ON public.profiles
  FOR INSERT WITH CHECK (id = auth.uid());
CREATE POLICY "own_profile_update" ON public.profiles
  FOR UPDATE USING (id = auth.uid())
  WITH CHECK (id = auth.uid() AND role = (SELECT p.role FROM public.profiles p WHERE p.id = auth.uid()));
-- ملاحظة: منع المستخدم من ترقية دوره بنفسه (WITH CHECK يثبت الدور)

-- ─── 7. orders ───────────────────────────────────────────────
-- الزبون: يرى طلباته، ينشئ طلب باسمه فقط، يعدّل طلبه (الإلغاء يحرسه تريغر الحالات)
CREATE POLICY "customer_orders_select" ON public.orders
  FOR SELECT USING (customer_id = auth.uid());
CREATE POLICY "customer_orders_insert" ON public.orders
  FOR INSERT WITH CHECK (customer_id = auth.uid());
CREATE POLICY "customer_orders_update" ON public.orders
  FOR UPDATE USING (customer_id = auth.uid()) WITH CHECK (customer_id = auth.uid());

-- السائق: يرى ويحدّث الطلبات المسندة له فقط
CREATE POLICY "driver_orders_select" ON public.orders
  FOR SELECT USING (driver_id = auth.uid());
CREATE POLICY "driver_orders_update" ON public.orders
  FOR UPDATE USING (driver_id = auth.uid()) WITH CHECK (driver_id = auth.uid());

-- مدير الفرع: كل طلبات فرعه (POS يشمل البيع المحلي بدون زبون)
CREATE POLICY "branch_orders_all" ON public.orders
  FOR ALL USING (public.get_my_role() = 'branch_manager' AND branch_id = public.get_my_branch_id())
  WITH CHECK (public.get_my_role() = 'branch_manager' AND branch_id = public.get_my_branch_id());

-- ─── 8. order_items (يرث صلاحية الطلب الأب) ─────────────────
CREATE POLICY "order_items_select" ON public.order_items
  FOR SELECT USING (EXISTS (
    SELECT 1 FROM public.orders o WHERE o.id = order_id
    AND (o.customer_id = auth.uid() OR o.driver_id = auth.uid()
         OR (public.get_my_role() = 'branch_manager' AND o.branch_id = public.get_my_branch_id()))
  ));
CREATE POLICY "order_items_insert" ON public.order_items
  FOR INSERT WITH CHECK (EXISTS (
    SELECT 1 FROM public.orders o WHERE o.id = order_id
    AND (o.customer_id = auth.uid()
         OR (public.get_my_role() = 'branch_manager' AND o.branch_id = public.get_my_branch_id()))
  ));
CREATE POLICY "order_items_staff_mod" ON public.order_items
  FOR ALL USING (EXISTS (
    SELECT 1 FROM public.orders o WHERE o.id = order_id
    AND public.get_my_role() = 'branch_manager' AND o.branch_id = public.get_my_branch_id()
  ));

-- ─── 9. order_status_history ────────────────────────────────
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='order_status_history') THEN
    EXECUTE 'CREATE POLICY "osh_select" ON public.order_status_history FOR SELECT USING (
      EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_id
        AND (o.customer_id = auth.uid() OR o.driver_id = auth.uid()
             OR (public.get_my_role() = ''branch_manager'' AND o.branch_id = public.get_my_branch_id())))
    )';
    EXECUTE 'CREATE POLICY "osh_staff_insert" ON public.order_status_history FOR INSERT WITH CHECK (public.is_staff())';
  END IF;
END $$;

-- ─── 10. notifications (المستخدم يرى إشعاراته فقط) ──────────
CREATE POLICY "own_notifications_select" ON public.notifications
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "own_notifications_update" ON public.notifications
  FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "staff_notifications_insert" ON public.notifications
  FOR INSERT WITH CHECK (public.is_staff());

-- ─── 11. favorites (خاصة بصاحبها) ───────────────────────────
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='favorites') THEN
    EXECUTE 'CREATE POLICY "own_favorites" ON public.favorites FOR ALL
      USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid())';
  END IF;
END $$;

-- ─── 12. drivers ─────────────────────────────────────────────
-- السائق يحدّث موقعه وحالته؛ الموظفون يقرؤون؛ POS يسند عبر orders لا drivers
CREATE POLICY "driver_own_select" ON public.drivers
  FOR SELECT USING (id = auth.uid() OR public.is_staff());
CREATE POLICY "driver_own_update" ON public.drivers
  FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE POLICY "staff_drivers_manage" ON public.drivers
  FOR ALL USING (public.is_staff()) WITH CHECK (public.is_staff());
-- الزبون يرى اسم/موقع سائق طلبه النشط فقط
CREATE POLICY "customer_active_driver_select" ON public.drivers
  FOR SELECT USING (EXISTS (
    SELECT 1 FROM public.orders o WHERE o.driver_id = drivers.id
    AND o.customer_id = auth.uid()
    AND o.status IN ('shipped','في الطريق','preparing','تحضير')
  ));

-- ─── 13. driver_ratings ──────────────────────────────────────
CREATE POLICY "ratings_read" ON public.driver_ratings
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "customer_rate_own" ON public.driver_ratings
  FOR INSERT WITH CHECK (customer_id = auth.uid());

-- ─── 14. جداول التشغيل والمالية: الموظفون فقط ───────────────
-- (مدير الفرع مقيّد بفرعه إن وُجد عمود branch_id)
DO $$
DECLARE tbl TEXT; has_branch BOOLEAN;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'inventory','branch_inventory','invoices','purchases','purchase_items',
    'stock_entries','damaged_goods','waste_records','daily_settlements',
    'shift_closings','audit_logs','partner_settlements','discount_codes',
    'system_settings','admin_notifications'
  ] LOOP
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename=tbl) THEN
      SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name=tbl AND column_name='branch_id'
      ) INTO has_branch;
      IF has_branch THEN
        EXECUTE format(
          'CREATE POLICY "branch_staff_%s" ON public.%I FOR ALL
           USING (public.get_my_role() = ''branch_manager'' AND branch_id = public.get_my_branch_id())
           WITH CHECK (public.get_my_role() = ''branch_manager'' AND branch_id = public.get_my_branch_id())',
          tbl, tbl);
      ELSE
        EXECUTE format(
          'CREATE POLICY "staff_all_%s" ON public.%I FOR ALL
           USING (public.is_staff()) WITH CHECK (public.is_staff())',
          tbl, tbl);
      END IF;
    END IF;
  END LOOP;
END $$;

-- ─── 15. كتابة الكتالوج: الموظفون فقط (القراءة عامة من القسم 5) ─
DO $$
DECLARE tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'products','branches','categories','banners','delivery_zones',
    'story_groups','story_items'
  ] LOOP
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename=tbl) THEN
      EXECUTE format(
        'CREATE POLICY "staff_write_%s" ON public.%I FOR ALL
         USING (public.is_staff()) WITH CHECK (public.is_staff())', tbl, tbl);
    END IF;
  END LOOP;
END $$;

-- ─── 16. fcm_tokens: كل مستخدم يدير رموزه فقط ────────────────
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='fcm_tokens') THEN
    EXECUTE 'CREATE POLICY "own_fcm_tokens" ON public.fcm_tokens FOR ALL
      USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid())';
  END IF;
END $$;

-- ─── 17. جعل دوال التريغرات SECURITY DEFINER ─────────────────
-- ضروري: تريغر خصم المخزون/الإشعارات يعمل عند تحديث الزبون أو السائق
-- للطلب، وهؤلاء ليس لهم صلاحية مباشرة على inventory/notifications.
DO $$
DECLARE fn TEXT;
BEGIN
  FOREACH fn IN ARRAY ARRAY[
    'handle_order_inventory','notify_order_status','sync_driver_status',
    'guard_order_status_transitions','handle_inventory_on_status_change',
    'notify_customer_on_status_change'
  ] LOOP
    IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
               WHERE n.nspname='public' AND p.proname = fn) THEN
      EXECUTE format('ALTER FUNCTION public.%I() SECURITY DEFINER SET search_path = public', fn);
    END IF;
  END LOOP;
END $$;

-- ─── 18. تحقق نهائي: اعرض السياسات الجديدة ──────────────────
SELECT tablename, COUNT(*) AS policies
FROM pg_policies WHERE schemaname = 'public'
GROUP BY tablename ORDER BY tablename;
