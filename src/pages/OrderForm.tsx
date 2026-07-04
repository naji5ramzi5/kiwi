import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { useUserZone } from '../hooks/useUserZone';
import { sendFcmNotification } from '../lib/fcm';
import { toast } from 'react-hot-toast';
import { MapPin, Truck, CheckCircle2, X } from 'lucide-react';

interface OrderFormProps {
  // Optional: if you want to pass a predefined cart or branch
  branchId?: string;
}

export default function OrderForm({ branchId }: OrderFormProps = {}) {
  const [form, setForm] = useState({
    deliveryAddress: '',
    notes: '',
    // In a real app, you would have cart items; we'll mock a total
    totalPrice: 0,
  });
  const [loading, setLoading] = useState(false);
  const [cartItems, setCartItems] = useState<Array<{ id: string; name: string; quantity: number; price: number }>>([]);

  // Geo-fence hook
  const { isInsideAnyZone, loading: zoneLoading, error: zoneError, matchingZone } = useUserZone(branchId);

  // Mock: load some fake cart items from localStorage or state
  useEffect(() => {
    const saved = localStorage.getItem('cart');
    if (saved) {
      try {
        setCartItems(JSON.parse(saved));
        // Recalculate total
        const total = JSON.parse(saved).reduce((sum: number, item: any) => sum + item.price * item.quantity, 0);
        setForm(prev => ({ ...prev, totalPrice: total }));
      } catch {}
    }
  }, []);

  // Calculate total from cart
  const totalPrice = cartItems.reduce((sum, item) => sum + item.price * item.quantity, 0);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (zoneLoading) {
      toast.error('جاري التحقق من موقعك...');
      return;
    }
    if (!isInsideAnyZone) {
      toast.error('أنت خارج منطقة التوصيل. لا يمكنك إنشاء طلب.');
      return;
    }
    if (cartItems.length === 0) {
      toast.error('سلة التسوق فارغة');
      return;
    }
    if (!form.deliveryAddress.trim()) {
      toast.error('يرجى إدخال عنوان التوصيل');
      return;
    }

    setLoading(true);
    try {
      // Get user session
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        throw new Error('غير مصدق');
      }

      // Determine branchId: from prop, or from session metadata, or default to first branch from matchingZone? We'll use the branchId from matchingZone if available.
      const effectiveBranchId = branchId || (matchingZone?.branch_id ?? null);
      if (!effectiveBranchId) {
        throw new Error('غير قادر على تحديد الفرع');
      }

      // Insert order
      const { data: orderData, error: orderError } = await supabase
        .from('orders')
        .insert({
          user_id: user.id,
          branch_id: effectiveBranchId,
          total_price: totalPrice,
          delivery_address: form.deliveryAddress,
          status: 'جديد', // According to workflow: goes directly to "Out for Delivery"? Actually they bypass "Waiting for Courier". We'll set to 'تحضير' (Preparation) as per statuses in Orders.tsx.
          // We could also store items in a separate order_items table, but for simplicity we'll just store summary.
        })
        .select()
        .single();

      if (orderError) throw orderError;

      // Optionally, clear cart after order
      localStorage.removeItem('cart');
      setCartItems([]);
      setForm({ deliveryAddress: '', notes: '', totalPrice: 0 });

      // Send FCM notification to user
      try {
        await sendFcmNotification(
          user.id,
          'تم استلام طلبك',
          `طلبك رقم ${orderData.id.substring(0, 8)} تم استلامه وجاري التحضير.`,
          { orderId: orderData.id }
        );
      } catch (fcmErr) {
        console.warn('FCM notification to user failed:', fcmErr);
      }

      // Also notify all admin users about the new order
      try {
        const { data: admins } = await supabase
          .from('profiles')
          .select('id')
          .in('role', ['admin', 'super_admin']);
        
        if (admins) {
          for (const admin of admins) {
            await sendFcmNotification(
              admin.id,
              '📦 طلب جديد',
              `تم استلام طلب جديد بقيمة ${totalPrice.toLocaleString('ar-IQ')} د.ع`,
              { orderId: orderData.id, type: 'new_order' }
            ).catch(() => {}); // Ignore individual failures
          }
        }
      } catch (adminErr) {
        console.warn('Could not notify admins:', adminErr);
      }

      toast.success('تم إنشاء الطلب بنجاح!');
      // Optionally redirect to orders page or show confirmation
      // We'll just show success and reset form.
    } catch (err: any) {
      console.error(err);
      toast.error('فشل إنشاء الطلب: ' + (err.message ?? 'خطأ غير معروف'));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-6 max-w-4xl mx-auto animate-in">
      <div className="mb-6">
        <h1 className="text-2xl font-bold">إنشاء طلب جديد</h1>
        <p className="text-gray-500">
          تأكد من أن موقعك داخل منطقة التوصيل قبل المتابعة.
        </p>
      </div>

      {/* Geo-fence status banner */}
      {zoneLoading ? (
        <div className="alert alert-info">
          <MapPin size={20} /> جارٍ التحقق من موقعك...
        </div>
      ) : !isInsideAnyZone ? (
        <div className="alert alert-error">
          <MapPin size={20} /> أنت خارج جميع مناطق التوصيل النشطة. لا يمكنك إنشاء طلب.
        </div>
      ) : matchingZone ? (
        <div className="alert alert-success">
          <MapPin size={20} /> أنت داخل منطقة التوصيل "{matchingZone.name}". رسوم التوصيل: {matchingZone.delivery_fee?.toLocaleString('ar-IQ')} د.ع
        </div>
      ) : null}

      {/* Cart summary */}
      <div className="mb-6 p-4 bg-gray-50 rounded-lg">
        <h2 className="font-semibold mb-2">عربة التسوق</h2>
        {cartItems.length === 0 ? (
          <p className="text-gray-500">عربة التسوق فارغة. أضف منتجات من الكتالوج.</p>
        ) : (
          <>
            <div className="space-y-2">
              {cartItems.map((item) => (
                <div key={item.id} className="flex justify-between text-sm">
                  <span>{item.name} × {item.quantity}</span>
                  <span>{(item.price * item.quantity).toLocaleString('ar-IQ')} د.ع</span>
                </div>
              ))}
            </div>
            <div className="mt-4 pt-2 border-t font-bold text-lg">
              <span>الإجمالي:</span>
              <span>{totalPrice.toLocaleString('ar-IQ')} د.ع</span>
            </div>
          </>
        )}
      </div>

      {/* Order form */}
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block text-sm font-medium mb-1">عنوان التوصيل *</label>
          <input
            type="text"
            value={form.deliveryAddress}
            onChange={(e) => setForm({ ...form, deliveryAddress: e.target.value })}
            className="input input-bordered w-full"
            placeholder="أدخل عنوان التوصيل التفصيلي"
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">ملاحظات (اختياري)</label>
          <textarea
            value={form.notes}
            onChange={(e) => setForm({ ...form, notes: e.target.value })}
            className="textarea textarea-bordered w-full"
            rows={3}
            placeholder="أي ملاحظات خاصة بالطلب"
          />
        </div>

        <div className="flex justify-end">
          <button
            type="submit"
            disabled={loading || zoneLoading || !isInsideAnyZone || cartItems.length === 0}
            className={`btn btn-primary ${
              loading ? 'btn-loading' : ''
            }`}
          >
            {loading ? 'جاري الإنشاء...' : 'إنشاء الطلب'}
          </button>
          <button
            type="button"
            onClick={() => {
              if (confirm('هل تريد مسح سلة التسوق؟')) {
                localStorage.removeItem('cart');
                setCartItems([]);
                setForm({ deliveryAddress: '', notes: '', totalPrice: 0 });
              }
            }}
            className="btn btn-ghost ml-2"
          >
            مسح السلة
          </button>
        </div>
      </form>

      {/* Helper: Add some fake products to cart for testing */}
      <div className="mt-6 p-4 bg-blue-50 rounded-lg">
        <h2 className="font-semibold mb-2">لتجربة الطلب (إضافة منتجات وهمية)</h2>
        <div className="flex flex-wrap gap-2">
          <button
            onClick={() => {
              const newItem = {
                id: 'fake-' + Date.now(),
                name: 'منتج تجريبي',
                quantity: 1,
                price: 1000,
              };
              setCartItems((prev) => {
                const exists = prev.find((i) => i.id === newItem.id);
                if (exists) {
                  return prev.map((i) =>
                    i.id === newItem.id
                      ? { ...i, quantity: i.quantity + 1 }
                      : i
                  );
                } else {
                  return [...prev, newItem];
                }
              });
              // Save to localStorage
              localStorage.setItem('cart', JSON.stringify([...cartItems, newItem]));
              // Update total
              const total = cartItems.reduce((sum, item) => sum + item.price * item.quantity, 0) + newItem.price;
              setForm((prev) => ({ ...prev, totalPrice: total }));
            }}
            className="btn btn-outline btn-sm"
          >
            إضافة منتج تجريبي
          </button>
          <button
            onClick={() => {
              localStorage.removeItem('cart');
              setCartItems([]);
              setForm({ deliveryAddress: '', notes: '', totalPrice: 0 });
            }}
            className="btn btn-ghost btn-sm ml-2"
          >
            مسح السلة التجريبية
          </button>
        </div>
      </div>
    </div>
  );
}