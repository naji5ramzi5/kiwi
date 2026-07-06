-- ============================================================================
-- اختبار الإصلاحات: تحقق من جميع الإصلاحات
-- ============================================================================
-- شغّل هذه الاستعلامات في Supabase SQL Editor للتحقق من الإصلاحات

-- ============================================================================
-- 1️⃣ التحقق من التريغرات المنشأة
-- ============================================================================
SELECT 
  trigger_name,
  event_object_table,
  action_timing,
  event_manipulation
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table = 'orders'
ORDER BY trigger_name;

-- النتيجة المتوقعة:
-- ✅ update_stock_on_sale
-- ✅ notify_order_status_change
-- ✅ sync_driver_status_on_assignment
-- ✅ prevent_completed_order_changes
-- ✅ send_fcm_on_order_update

-- ============================================================================
-- 2️⃣ التحقق من جدول notifications
-- ============================================================================
SELECT 
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'notifications'
ORDER BY ordinal_position;

-- النتيجة المتوقعة:
-- ✅ id (uuid)
-- ✅ user_id (uuid)
-- ✅ title (text)
-- ✅ message (text)
-- ✅ order_id (uuid)
-- ✅ read (boolean)
-- ✅ created_at (timestamp with time zone)

-- ============================================================================
-- 3️⃣ اختبار خصم المخزون - تحقق من البيانات الموجودة أولاً
-- ============================================================================

-- أ) انظر المخزون الحالي
SELECT 
  p.id,
  p.name,
  bi.actual_stock,
  bi.branch_id
FROM products p
LEFT JOIN branch_inventory bi ON p.id = bi.product_id
LIMIT 5;

-- ب) انظر الطلبات الموجودة
SELECT 
  id,
  status,
  customer_id,
  branch_id,
  total_amount
FROM orders
ORDER BY created_at DESC
LIMIT 5;

-- ============================================================================
-- 4️⃣ اختبار الإشعارات
-- ============================================================================

SELECT 
  id,
  user_id,
  title,
  message,
  order_id,
  read,
  created_at
FROM notifications
ORDER BY created_at DESC
LIMIT 5;

-- ============================================================================
-- 5️⃣ اختبار تزامن حالة السائق
-- ============================================================================

-- انظر حالات السائقين
SELECT 
  id,
  full_name,
  current_status
FROM drivers
LIMIT 5;

-- انظر الطلبات المُسندة لسائقين
SELECT 
  id,
  driver_id,
  status,
  customer_id
FROM orders
WHERE driver_id IS NOT NULL
LIMIT 5;

-- ============================================================================
-- 6️⃣ تحقق من RLS على جدول notifications
-- ============================================================================

-- هذا يعرض الإشعارات للمستخدم الحالي فقط
SELECT 
  id,
  title,
  message,
  order_id,
  read,
  created_at
FROM notifications
ORDER BY created_at DESC;

-- ============================================================================
-- 7️⃣ تحقق من جميع الحالات في الطلبات
-- ============================================================================

SELECT 
  status,
  COUNT(*) as count
FROM orders
GROUP BY status
ORDER BY status;

-- النتيجة المتوقعة (الحالات المدعومة):
-- cancelled
-- delivered
-- in_delivery
-- pending
-- preparing
-- rejected
-- shipped

-- ============================================================================
-- 8️⃣ تحقق من وظائف (Functions) المنشأة
-- ============================================================================

SELECT 
  routine_name,
  routine_type,
  data_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE 'fn_%'
ORDER BY routine_name;

-- النتيجة المتوقعة:
-- ✅ fn_update_stock_on_sale
-- ✅ fn_notify_order_status_change
-- ✅ fn_sync_driver_status
-- ✅ fn_prevent_completed_order_changes
-- ✅ fn_send_fcm_on_order_update

-- ============================================================================
-- 9️⃣ تحقق من سياسات RLS
-- ============================================================================

SELECT 
  schemaname,
  tablename,
  policyname,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'notifications'
ORDER BY policyname;

-- النتيجة المتوقعة:
-- ✅ notifications_delete_own
-- ✅ notifications_select_own

-- ============================================================================
-- 🔟 حساب إجمالي الإصلاحات
-- ============================================================================

SELECT 
  COUNT(*) as total_triggers
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table = 'orders';

SELECT 
  COUNT(*) as total_functions
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE 'fn_%';

SELECT 
  COUNT(*) as total_rows
FROM notifications;

SELECT 
  COUNT(*) as total_policies
FROM pg_policies
WHERE tablename = 'notifications';

-- ============================================================================
-- ملخص الاختبارات
-- ============================================================================
/*
✅ التريغرات:
   - update_stock_on_sale: خصم المخزون
   - notify_order_status_change: إرسال الإشعارات
   - sync_driver_status_on_assignment: تزامن حالة السائق
   - prevent_completed_order_changes: حماية الطلبات المنتهية
   - send_fcm_on_order_update: إرسال FCM (معزول من الأخطاء)

✅ جدول notifications:
   - تم إنشاؤه بنجاح
   - 7 أعمدة: id, user_id, title, message, order_id, read, created_at
   - مع RLS محمي

✅ حالات الطلبات الموحدة:
   - pending (قيد الانتظار)
   - preparing (التحضير)
   - shipped (جاهز)
   - in_delivery (في الطريق)
   - delivered (مسلم)
   - cancelled (ملغى)
   - rejected (مرفوض)

✅ الإصلاحات الكاملة:
   - 5 تريغرات جديدة/محدّثة
   - 5 functions جديدة/محدّثة
   - جدول notifications مع RLS
   - حماية البيانات والخصوصية

إذا رأيت جميع هذه النتائج، فالإصلاحات تعمل بنجاح! ✅
*/
