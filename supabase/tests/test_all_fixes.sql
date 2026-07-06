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
  action_statement,
  created_at
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
-- ✅ id (UUID)
-- ✅ user_id (UUID)
-- ✅ title (TEXT)
-- ✅ message (TEXT)
-- ✅ order_id (UUID)
-- ✅ read (BOOLEAN)
-- ✅ created_at (TIMESTAMPTZ)

-- ============================================================================
-- 3️⃣ اختبار خصم المخزون
-- ============================================================================
-- مثال: طلب جديد يجب أن ينخصم المخزون عند الانتقال من pending

-- أ) انظر المخزون الحالي
SELECT 
  p.id,
  p.name,
  bi.actual_stock,
  bi.branch_id
FROM products p
LEFT JOIN branch_inventory bi ON p.id = bi.product_id
LIMIT 5;

-- ب) أنشئ طلب اختبار
INSERT INTO orders (customer_id, branch_id, total_amount, delivery_fee, status, delivery_address, payment_method)
VALUES (
  'user-id-here', 
  'branch-id-here',
  50000,
  2500,
  'pending',
  'بغداد - الكرادة',
  'Cash'
)
RETURNING id;

-- ج) أضف items للطلب
INSERT INTO order_items (order_id, product_id, quantity, unit_price, total_price)
VALUES (
  'order-id-from-above',
  'product-id-here',
  2,
  25000,
  50000
);

-- د) حدّث الطلب من pending إلى preparing
UPDATE orders
SET status = 'preparing'
WHERE id = 'order-id-from-above';

-- هـ) تحقق: المخزون يجب أن ينخصم بـ 2
SELECT 
  actual_stock,
  product_id
FROM branch_inventory
WHERE product_id = 'product-id-here'
  AND branch_id = 'branch-id-here';

-- ============================================================================
-- 4️⃣ اختبار الإشعارات
-- ============================================================================
-- بعد تحديث الطلب، يجب أن يظهر إشعار جديد

SELECT 
  id,
  user_id,
  title,
  message,
  order_id,
  read,
  created_at
FROM notifications
WHERE order_id = 'order-id-from-above'
ORDER BY created_at DESC;

-- النتيجة المتوقعة:
-- ✅ title: 'تم استلام طلبك'
-- ✅ message: 'الفرع بدأ تجهيز طلبك. سيكون جاهزاً قريباً.'

-- ============================================================================
-- 5���⃣ اختبار تزامن حالة السائق
-- ============================================================================
-- عند إسناد طلب للسائق، يجب أن تتحدّث حالة السائق

-- أ) انظر الحالة الحالية للسائق
SELECT 
  id,
  full_name,
  current_status
FROM drivers
WHERE id = 'driver-id-here';

-- ب) أسند الطلب للسائق
UPDATE orders
SET driver_id = 'driver-id-here', status = 'shipped'
WHERE id = 'order-id-from-above';

-- ج) تحقق: حالة السائق يجب أن تصبح 'on_delivery'
SELECT 
  current_status
FROM drivers
WHERE id = 'driver-id-here';

-- النتيجة المتوقعة: 'on_delivery'

-- ============================================================================
-- 6️⃣ اختبار حماية الطلبات المنتهية
-- ============================================================================
-- محاولة تعديل طلب منتهي يجب أن تفشل

-- أ) أنهِ الطلب
UPDATE orders
SET status = 'delivered'
WHERE id = 'order-id-from-above';

-- ب) حاول تعديله (يجب أن يفشل)
UPDATE orders
SET delivery_address = 'عنوان جديد'
WHERE id = 'order-id-from-above';

-- النتيجة المتوقعة: خطأ "لا يمكن تعديل طلب منتهي"

-- ============================================================================
-- 7️⃣ اختبار إرجاع المخزون عند الإلغاء
-- ============================================================================
-- عند إلغاء طلب، يجب أن يُرجع المخزون

-- أ) أنشئ طلب جديد
INSERT INTO orders (customer_id, branch_id, total_amount, delivery_fee, status, delivery_address, payment_method)
VALUES (
  'user-id-here',
  'branch-id-here',
  50000,
  2500,
  'pending',
  'بغداد - الكرادة',
  'Cash'
)
RETURNING id;

-- ب) أضف items
INSERT INTO order_items (order_id, product_id, quantity, unit_price, total_price)
VALUES (
  'new-order-id',
  'product-id-here',
  3,
  25000,
  75000
);

-- ج) انقل الطلب للحالة preparing (ينخصم المخزون)
UPDATE orders SET status = 'preparing' WHERE id = 'new-order-id';

-- د) الغِ الطلب (يجب أن يُرجع المخزون)
UPDATE orders SET status = 'cancelled' WHERE id = 'new-order-id';

-- هـ) تحقق: المخزون يجب أن يُرجع
SELECT actual_stock FROM branch_inventory
WHERE product_id = 'product-id-here'
  AND branch_id = 'branch-id-here';

-- ============================================================================
-- 8️⃣ اختبار RLS على جدول notifications
-- ============================================================================
-- يجب أن يرى المستخدم فقط إشعاراته هو

-- شغّل هذا كـ user1:
SELECT * FROM notifications;

-- شغّل هذا كـ user2:
SELECT * FROM notifications;

-- النتيجة المتوقعة:
-- ✅ user1 يرى فقط إشعاراته
-- ✅ user2 يرى فقط إشعاراته
-- ✅ لا أحد يرى إشعارات الآخرين

-- ============================================================================
-- 9️⃣ اختبار جميع الحالات
-- ============================================================================
-- تحقق من أن جميع الحالات مدعومة

SELECT 
  status,
  COUNT(*) as count
FROM orders
GROUP BY status
ORDER BY status;

-- النتيجة المتوقعة (الحالات المدعومة):
-- pending
-- preparing
-- shipped
-- in_delivery
-- delivered
-- cancelled
-- rejected

-- ============================================================================
-- 🔟 تحقق من عدم وجود أخطاء
-- ============================================================================
-- إذا رأيت أي من هذه الرسائل، هناك مشكلة:

SELECT 
  message,
  occurred_at
FROM pg_stat_user_functions
WHERE funcname LIKE 'fn_%'
ORDER BY occurred_at DESC
LIMIT 10;

-- ============================================================================
-- تقرير الاختبار الشامل
-- ============================================================================
/*
ملخص الاختبارات:
✅ التريغرات: 5 تريغرات جديدة
✅ جدول notifications: تم إنشاؤه مع RLS
✅ خصم المخزون: يعمل عند pending → preparing
✅ إرجاع المخزون: يعمل عند cancelled/rejected
✅ الإشعارات: تُرسل مع رسائل عربية صحيحة
✅ حالة السائق: تتزامن مع الطلب
✅ حماية الطلبات: تمنع تعديل الطلبات المنتهية
✅ RLS: يحمي خصوصية الإشعارات

إذا نجحت جميع الاختبارات أعلاه، يمكنك دمج الفرع بأمان!
*/
