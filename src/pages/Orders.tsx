import { useEffect, useState } from 'react';
import {
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  Clock,
  Download,
  MapPin,
  MessageCircle,
  MoreVertical,
  Package,
  Phone,
  Printer,
  Search,
  Truck,
  User,
  X,
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { sendFcmNotification } from '../lib/fcm';
import toast from 'react-hot-toast';
import DateRangePicker from '../components/DateRangePicker';
import {
  ORDER_STATUS,
  ORDER_STATUS_LABELS,
  ORDER_STATUS_COLORS,
  ORDER_STATUS_FILTERS,
  getStatusLabel,
  getStatusColor,
} from '../lib/orderStatus';

const PAGE_SIZE = 15;

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

const STATUS_ALL = ORDER_STATUS_FILTERS[0];
const STATUSES = ORDER_STATUS_FILTERS;

export default function Orders() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState(STATUS_ALL);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(0);
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

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

      const formattedOrders = (data || []).map((order: Record<string, unknown> & { profiles?: Record<string, unknown>; branches?: Record<string, unknown> }) => ({
        ...order,
        customer_name: (order.profiles?.full_name as string) || 'زبون مجهول',
        customer_phone: (order.profiles?.phone as string) || 'غير مسجل',
        branch_name: (order.branches?.name as string) || 'فرع غير معروف',
      }));

      setOrders(formattedOrders);
    } catch (err) {
      console.error('Error fetching orders:', err);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void (async () => {
      await fetchOrders();
    })();

    const channel = supabase
      .channel('orders-channel')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'orders' }, () => {
        toast.success('🛒 طلب جديد وصل!', { duration: 4000, icon: '🔔' });
        void (async () => { await fetchOrders(); })();
      })
      .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'orders' }, () => {
        void (async () => { await fetchOrders(); })();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  async function updateOrderStatus(orderId: string, newStatus: string) {
    const previousOrders = orders;
    const oldStatus = orders.find(o => o.id === orderId)?.status ?? null;
    setOrders(current =>
      current.map(order => (order.id === orderId ? { ...order, status: newStatus } : order)),
    );

    const { error } = await supabase.from('orders').update({ status: newStatus }).eq('id', orderId);

    if (error) {
      setOrders(previousOrders);
      alert('فشل في تحديث حالة الطلب');
    } else {
      // Log the status change to the audit trail
      try {
        const { data: { user } } = await supabase.auth.getUser();
        const { error: historyErr } = await supabase
          .from('order_status_history')
          .insert({
            order_id: orderId,
            old_status: oldStatus,
            new_status: newStatus,
            changed_by: user?.id ?? null,
            changed_at: new Date().toISOString(),
          });
        if (historyErr) console.warn('Failed to log status history:', historyErr);
      } catch (histErr) {
        console.warn('Failed to log status history:', histErr);
      }

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
      if (newStatus === ORDER_STATUS.DELIVERING) {
        // In a full implementation, notify available drivers
        console.log('Order ready for delivery, would notify drivers');
      }
    }
  }

  function getStatusIcon(status: string) {
    switch (status) {
      case ORDER_STATUS.PENDING:
        return <Package size={16} />;
      case ORDER_STATUS.PREPARING:
        return <Clock size={16} />;
      case ORDER_STATUS.PICKED_UP:
        return <Truck size={16} />;
      case ORDER_STATUS.DELIVERING:
        return <Truck size={16} />;
      case ORDER_STATUS.DELIVERED:
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

  const filteredOrders = orders.filter(order => {
    if (filter !== STATUS_ALL && order.status !== filter) return false;
    if (search && !order.customer_name?.includes(search) && !order.customer_phone?.includes(search) && !order.delivery_address?.includes(search)) return false;
    if (startDate) {
      const orderDate = new Date(order.created_at).toISOString().slice(0, 10);
      if (orderDate < startDate) return false;
    }
    if (endDate) {
      const orderDate = new Date(order.created_at).toISOString().slice(0, 10);
      if (orderDate > endDate) return false;
    }
    return true;
  });

  const totalPages = Math.max(1, Math.ceil(filteredOrders.length / PAGE_SIZE));
  const safePage = Math.min(page, totalPages - 1);
  const pagedOrders = filteredOrders.slice(safePage * PAGE_SIZE, (safePage + 1) * PAGE_SIZE);

  // Reset to page 0 when filter/search changes
  useEffect(() => { void (async () => { setPage(0); })(); }, [filter, search, startDate, endDate]);

  function exportToCSV() {
    const headers = ['Order ID', 'Customer', 'Phone', 'Status', 'Total', 'Address', 'Date'];
    const rows = filteredOrders.map(o => [
      o.id.substring(0, 8),
      o.customer_name || '',
      o.customer_phone || '',
      o.status || '',
      String(o.total_price || 0),
      o.delivery_address || '',
      new Date(o.created_at).toLocaleDateString('ar-IQ'),
    ]);
    const csv = [headers, ...rows].map(r => r.map(c => `"${c}"`).join(',')).join('\n');
    const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `orders_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  return (
    <div className="p-6 max-w-7xl mx-auto animate-in fade-in duration-500">
      <div className="flex flex-col md:flex-row md:items-center justify-between mb-8 gap-4">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 mb-1">إدارة الطلبات</h1>
          <p className="text-gray-500">متابعة وتحديث حالات الطلبات لجميع الفروع</p>
        </div>

        <div className="flex items-center gap-3">
          <div className="relative">
            <Search size={16} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              placeholder="بحث بالاسم أو الهاتف..."
              className="pr-10 pl-4 py-2 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-emerald-500 focus:border-transparent outline-none transition-all w-56"
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
          </div>
          <button
            onClick={exportToCSV}
            className="flex items-center gap-2 px-4 py-2 bg-white border border-gray-200 rounded-xl text-sm font-medium text-gray-600 hover:bg-emerald-50 hover:border-emerald-300 hover:text-emerald-600 transition-all"
            title="تصدير CSV"
          >
            <Download size={16} />
            تصدير
          </button>
          <div className="flex items-center gap-1 bg-white p-1 rounded-xl border border-gray-100 shadow-sm">
          {STATUSES.map(status => (
            <button
              key={status}
              onClick={() => setFilter(status)}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${
                filter === status ? 'bg-emerald-500 text-white shadow-md' : 'text-gray-500 hover:bg-gray-50'
              }`}
            >
              {status === STATUS_ALL ? STATUS_ALL : getStatusLabel(status)}
            </button>
          ))}
          </div>
        </div>
      </div>

      {/* Date Range Filter */}
      <div style={{ marginBottom: 20, display: 'flex', gap: 12 }}>
        <DateRangePicker
          startDate={startDate}
          endDate={endDate}
          onStartDateChange={setStartDate}
          onEndDateChange={setEndDate}
          label="تصفية حسب التاريخ"
        />
        {(startDate || endDate) && (
          <button className="btn btn-ghost btn-sm" onClick={() => { setStartDate(''); setEndDate('') }}>
            <X size={14} /> مسح الفلتر
          </button>
        )}
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
            pagedOrders.map(order => (
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
                          {getStatusLabel(order.status)}
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
                              {order.customer_phone && order.customer_phone !== 'غير مسجل' && (
                                <a
                                  href={`https://wa.me/${order.customer_phone.replace(/[^0-9]/g, '')}`}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className="text-green-500 hover:text-green-600 mr-1"
                                >
                                  <MessageCircle size={14} />
                                </a>
                              )}
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
                              {getStatusLabel(status)}
                            </option>
                          ))}
                        </select>
                        <button
                          className="p-2.5 rounded-xl bg-gray-50 text-gray-400 hover:bg-emerald-50 hover:text-emerald-600 transition-colors"
                          onClick={() => printOrder(order)}
                        >
                          <Printer size={20} />
                        </button>
                        {order.customer_phone && order.customer_phone !== 'غير مسجل' && (
                          <button
                            className="p-2.5 rounded-xl bg-gray-50 text-gray-400 hover:bg-green-50 hover:text-green-600 transition-colors"
                            onClick={() => {
                              const phone = order.customer_phone!.replace(/[^0-9]/g, '');
                              const msg = encodeURIComponent(`مرحباً! طلبك رقم #${order.id.substring(0, 8)} قيد التجهيز من Kiwi Fresh`);
                              window.open(`https://wa.me/${phone}?text=${msg}`, '_blank');
                            }}
                          >
                            <MessageCircle size={20} />
                          </button>
                        )}
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

      {/* Pagination */}
      {!loading && filteredOrders.length > PAGE_SIZE && (
        <div className="flex items-center justify-center gap-4 mt-8">
          <button
            onClick={() => setPage(p => Math.max(0, p - 1))}
            disabled={safePage === 0}
            className="flex items-center gap-1 px-4 py-2 rounded-xl text-sm font-medium bg-white border border-gray-200 text-gray-600 hover:bg-emerald-50 hover:border-emerald-300 disabled:opacity-40 disabled:cursor-not-allowed transition-all"
          >
            <ChevronRight size={16} />
            السابق
          </button>
          <span className="text-sm text-gray-500 font-medium">
            صفحة {safePage + 1} من {totalPages}
            <span className="text-gray-400 mr-2">({filteredOrders.length} طلب)</span>
          </span>
          <button
            onClick={() => setPage(p => Math.min(totalPages - 1, p + 1))}
            disabled={safePage >= totalPages - 1}
            className="flex items-center gap-1 px-4 py-2 rounded-xl text-sm font-medium bg-white border border-gray-200 text-gray-600 hover:bg-emerald-50 hover:border-emerald-300 disabled:opacity-40 disabled:cursor-not-allowed transition-all"
          >
            التالي
            <ChevronLeft size={16} />
          </button>
        </div>
      )}
    </div>
  );
}
