import { useEffect, useState } from 'react';
import {
  CheckCircle2,
  Clock,
  MapPin,
  MoreVertical,
  Package,
  Phone,
  Printer,
  Truck,
  User,
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { sendFcmNotification } from '../lib/fcm';

interface Order {
  id: string;
  created_at: string;
  status: string;
  total_price: number;
  delivery_address: string;
  user_id: string;
  branch_id: string;
  customer_name?: string;
  customer_phone?: string;
  branch_name?: string;
}

const STATUS_ALL = 'الكل';
const STATUS_NEW = 'جديد';
const STATUS_PREPARING = 'تحضير';
const STATUS_DELIVERING = 'توصيل';
const STATUS_DELIVERED = 'تم التوصيل';
const STATUSES = [STATUS_ALL, STATUS_NEW, STATUS_PREPARING, STATUS_DELIVERING, STATUS_DELIVERED];

export default function Orders() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState(STATUS_ALL);

  async function fetchOrders() {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('orders')
        .select(`
          *,
          profiles:user_id (full_name, phone),
          branches:branch_id (name)
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;

      const formattedOrders = (data || []).map((order: any) => ({
        ...order,
        customer_name: order.profiles?.full_name || 'زبون مجهول',
        customer_phone: order.profiles?.phone || 'غير مسجل',
        branch_name: order.branches?.name || 'فرع غير معروف',
      }));

      setOrders(formattedOrders);
    } catch (err) {
      console.error('Error fetching orders:', err);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    fetchOrders();

    const channel = supabase
      .channel('orders-channel')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'orders' }, () => {
        fetchOrders();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  async function updateOrderStatus(orderId: string, newStatus: string) {
    const previousOrders = orders;
    setOrders(current =>
      current.map(order => (order.id === orderId ? { ...order, status: newStatus } : order)),
    );

    const { error } = await supabase.from('orders').update({ status: newStatus }).eq('id', orderId);

    if (error) {
      setOrders(previousOrders);
      alert('فشل في تحديث حالة الطلب');
    } else {
      // Send FCM notification to the customer about status change
      try {
        const order = orders.find(o => o.id === orderId);
        if (order?.user_id) {
          await sendFcmNotification(
            order.user_id,
            'تحديث حالة الطلب',
            `تم تغيير حالة طلبك رقم ${orderId.substring(0, 8)} إلى "${newStatus}"`,
            { orderId, status: newStatus }
          );
        }
      } catch (notifErr) {
        console.warn('Could not send notification:', notifErr);
      }
      
      // Notify admin/drivers for certain status changes
      if (newStatus === 'توصيل') {
        // In a full implementation, notify available drivers
        console.log('Order ready for delivery, would notify drivers');
      }
    }
  }

  function getStatusColor(status: string) {
    switch (status) {
      case STATUS_NEW:
        return 'bg-blue-100 text-blue-600 border-blue-200';
      case STATUS_PREPARING:
        return 'bg-orange-100 text-orange-600 border-orange-200';
      case STATUS_DELIVERING:
        return 'bg-purple-100 text-purple-600 border-purple-200';
      case STATUS_DELIVERED:
        return 'bg-emerald-100 text-emerald-600 border-emerald-200';
      default:
        return 'bg-gray-100 text-gray-600 border-gray-200';
    }
  }

  function getStatusIcon(status: string) {
    switch (status) {
      case STATUS_NEW:
        return <Package size={16} />;
      case STATUS_PREPARING:
        return <Clock size={16} />;
      case STATUS_DELIVERING:
        return <Truck size={16} />;
      case STATUS_DELIVERED:
        return <CheckCircle2 size={16} />;
      default:
        return <Package size={16} />;
    }
  }

  function printOrder(order: Order) {
    const popupWin = window.open('', '_blank', 'top=0,left=0,height=100%,width=auto');
    if (!popupWin) return;

    popupWin.document.open();
    popupWin.document.write(`
      <html dir="rtl">
        <head>
          <title>طلب رقم ${order.id}</title>
          <style>
            body { font-family: Tahoma, Arial, sans-serif; direction: rtl; padding: 20px; }
            .header { text-align: center; margin-bottom: 20px; }
            .details { margin-bottom: 20px; line-height: 1.8; }
            .total { font-size: 1.5em; font-weight: bold; text-align: right; margin-top: 20px; }
          </style>
        </head>
        <body>
          <div class="header">
            <h1>Kiwi - طلب رقم ${order.id.substring(0, 8)}</h1>
            <p>${new Date(order.created_at).toLocaleString('ar-IQ')}</p>
          </div>
          <div class="details">
            <p><strong>الفرع:</strong> ${order.branch_name || '-'}</p>
            <p><strong>اسم الزبون:</strong> ${order.customer_name || '-'}</p>
            <p><strong>رقم الهاتف:</strong> ${order.customer_phone || '-'}</p>
            <p><strong>عنوان التوصيل:</strong> ${order.delivery_address || '-'}</p>
            <p><strong>الحالة:</strong> ${order.status || '-'}</p>
          </div>
          <div class="total">
            الإجمالي: ${(order.total_price || 0).toLocaleString('ar-IQ')} د.ع
          </div>
        </body>
      </html>
    `);
    popupWin.document.close();
    popupWin.focus();
    popupWin.print();
    popupWin.close();
  }

  const filteredOrders = filter === STATUS_ALL ? orders : orders.filter(order => order.status === filter);

  return (
    <div className="p-6 max-w-7xl mx-auto animate-in fade-in duration-500">
      <div className="flex flex-col md:flex-row md:items-center justify-between mb-8 gap-4">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 mb-1">إدارة الطلبات</h1>
          <p className="text-gray-500">متابعة وتحديث حالات الطلبات لجميع الفروع</p>
        </div>

        <div className="flex items-center gap-3 bg-white p-1 rounded-xl border border-gray-100 shadow-sm">
          {STATUSES.map(status => (
            <button
              key={status}
              onClick={() => setFilter(status)}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${
                filter === status ? 'bg-emerald-500 text-white shadow-md' : 'text-gray-500 hover:bg-gray-50'
              }`}
            >
              {status}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <div className="flex justify-center items-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-emerald-500" />
        </div>
      ) : (
        <div className="grid gap-6">
          {filteredOrders.length === 0 ? (
            <div className="bg-white rounded-2xl p-12 text-center border border-dashed border-gray-200">
              <Package size={48} className="mx-auto text-gray-300 mb-4" />
              <p className="text-gray-500">لا توجد طلبات في هذا القسم حاليًا</p>
            </div>
          ) : (
            filteredOrders.map(order => (
              <div
                key={order.id}
                className="bg-white rounded-2xl border border-gray-100 shadow-sm hover:shadow-md transition-all overflow-hidden group"
              >
                <div className="p-6">
                  <div className="flex flex-col lg:flex-row justify-between gap-6">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-4">
                        <span className="text-sm font-mono text-gray-400 bg-gray-50 px-2 py-1 rounded">
                          #{order.id.substring(0, 8)}
                        </span>
                        <div className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold border ${getStatusColor(order.status)}`}>
                          {getStatusIcon(order.status)}
                          {order.status}
                        </div>
                        <span className="text-xs text-gray-400">
                          {new Date(order.created_at).toLocaleTimeString('ar-IQ', { hour: '2-digit', minute: '2-digit' })}
                        </span>
                      </div>

                      <div className="grid md:grid-cols-2 gap-4">
                        <div className="flex items-start gap-3">
                          <div className="w-10 h-10 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-600">
                            <User size={20} />
                          </div>
                          <div>
                            <p className="font-bold text-gray-900">{order.customer_name}</p>
                            <p className="text-sm text-gray-500 flex items-center gap-1">
                              <Phone size={12} /> {order.customer_phone}
                            </p>
                          </div>
                        </div>
                        <div className="flex items-start gap-3">
                          <div className="w-10 h-10 rounded-full bg-blue-50 flex items-center justify-center text-blue-600">
                            <MapPin size={20} />
                          </div>
                          <div>
                            <p className="text-sm font-medium text-gray-900 line-clamp-1">{order.delivery_address}</p>
                            <p className="text-xs text-gray-500">عنوان التوصيل</p>
                          </div>
                        </div>
                      </div>
                    </div>

                    <div className="flex flex-col justify-between items-end border-t lg:border-t-0 lg:border-r border-gray-50 pt-6 lg:pt-0 lg:pr-6 min-w-[200px]">
                      <div className="text-right mb-4 lg:mb-0">
                        <p className="text-xs text-gray-400">إجمالي المبلغ</p>
                        <p className="text-2xl font-black text-emerald-600">
                          {(order.total_price || 0).toLocaleString('ar-IQ')} <span className="text-sm font-normal">د.ع</span>
                        </p>
                      </div>

                      <div className="flex items-center gap-2 w-full lg:w-auto">
                        <select
                          value={order.status}
                          onChange={event => updateOrderStatus(order.id, event.target.value)}
                          className="flex-1 lg:w-32 bg-gray-50 border-none rounded-xl text-sm font-medium p-2 cursor-pointer focus:ring-2 focus:ring-emerald-500 outline-none"
                        >
                          {STATUSES.filter(status => status !== STATUS_ALL).map(status => (
                            <option key={status} value={status}>
                              {status}
                            </option>
                          ))}
                        </select>
                        <button
                          className="p-2.5 rounded-xl bg-gray-50 text-gray-400 hover:bg-emerald-50 hover:text-emerald-600 transition-colors"
                          onClick={() => printOrder(order)}
                        >
                          <Printer size={20} />
                        </button>
                        <button className="p-2.5 rounded-xl bg-gray-50 text-gray-400 hover:bg-emerald-50 hover:text-emerald-600 transition-colors">
                          <MoreVertical size={20} />
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      )}
    </div>
  );
}
