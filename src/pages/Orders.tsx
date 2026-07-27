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
  total_amount: number;
  delivery_address: string;
  customer_id: string;
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
          profiles:customer_id (full_name, phone),
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
      toast.error('فشل في تحديث حالة الطلب');
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
        if (order?.customer_id) {
          await sendFcmNotification(
            order.customer_id,
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
        // TODO: In a full implementation, notify available drivers
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
            الإجمالي: ${(order.total_amount || 0).toLocaleString('ar-IQ')} د.ع
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
      String(o.total_amount || 0),
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
    <div className="animate-in">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24, flexWrap: 'wrap', gap: 12 }}>
        <div>
          <h1 className="brand-name" style={{ fontSize: 24 }}>إدارة الطلبات</h1>
          <p className="brand-sub">متابعة وتحديث حالات الطلبات لجميع الفروع</p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
          <div style={{ position: 'relative' }}>
            <Search size={16} style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--gray400)' }} />
            <input
              type="text"
              placeholder="بحث بالاسم أو الهاتف..."
              className="form-input"
              style={{ paddingRight: 36, width: 240 }}
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
          </div>
          <button className="btn btn-outline" onClick={exportToCSV} title="تصدير CSV">
            <Download size={16} /> تصدير
          </button>
          <div style={{ display: 'flex', gap: 4, background: 'var(--white)', padding: 4, borderRadius: 12, border: '1px solid var(--gray100)' }}>
          {STATUSES.map(status => (
            <button
              key={status}
              onClick={() => setFilter(status)}
              className={filter === status ? 'btn btn-primary btn-sm' : 'btn btn-ghost btn-sm'}
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
        <div className="empty-state" style={{ minHeight: 300 }}><div className="loader"></div></div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          {filteredOrders.length === 0 ? (
            <div className="empty-state">
              <Package size={48} style={{ color: 'var(--gray300)' }} />
              <p style={{ color: 'var(--gray500)', fontWeight: 600 }}>لا توجد طلبات في هذا القسم حاليًا</p>
            </div>
          ) : (
            pagedOrders.map(order => (
              <div
                key={order.id}
                className="card"
              >
                <div style={{ padding: 20 }}>
                  <div style={{ display: 'flex', flexDirection: 'row', justifyContent: 'space-between', gap: 24, flexWrap: 'wrap' }}>
                    <div style={{ flex: 1, minWidth: 300 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16, flexWrap: 'wrap' }}>
                        <span style={{ fontSize: 12, fontFamily: 'monospace', color: 'var(--gray400)', background: 'var(--gray50)', padding: '2px 8px', borderRadius: 6 }}>
                          #{order.id.substring(0, 8)}
                        </span>
                        <div className={`badge ${getStatusColor(order.status)}`} style={{ gap: 4 }}>
                          {getStatusIcon(order.status)}
                          {getStatusLabel(order.status)}
                        </div>
                        <span style={{ fontSize: 11, color: 'var(--gray400)' }}>
                          {new Date(order.created_at).toLocaleTimeString('ar-IQ', { hour: '2-digit', minute: '2-digit' })}
                        </span>
                      </div>

                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 16 }}>
                        <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
                          <div style={{ width: 40, height: 40, borderRadius: '50%', background: 'var(--g50)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--g600)', flexShrink: 0 }}>
                            <User size={20} />
                          </div>
                          <div>
                            <p style={{ fontWeight: 700, color: 'var(--gray900)', margin: 0 }}>{order.customer_name}</p>
                            <p style={{ fontSize: 13, color: 'var(--gray500)', display: 'flex', alignItems: 'center', gap: 4, margin: 0 }}>
                              <Phone size={12} /> {order.customer_phone}
                              {order.customer_phone && order.customer_phone !== 'غير مسجل' && (
                                <a
                                  href={`https://wa.me/${order.customer_phone.replace(/[^0-9]/g, '')}`}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  style={{ color: 'var(--g500)', marginRight: 4 }}
                                >
                                  <MessageCircle size={14} />
                                </a>
                              )}
                            </p>
                          </div>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
                          <div style={{ width: 40, height: 40, borderRadius: '50%', background: '#dbeafe', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#2563eb', flexShrink: 0 }}>
                            <MapPin size={20} />
                          </div>
                          <div>
                            <p style={{ fontSize: 13, fontWeight: 500, color: 'var(--gray900)', margin: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 200 }}>{order.delivery_address}</p>
                            <p style={{ fontSize: 11, color: 'var(--gray500)', margin: 0 }}>عنوان التوصيل</p>
                          </div>
                        </div>
                      </div>
                    </div>

                    <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', alignItems: 'flex-end', borderRight: '1px solid var(--gray100)', paddingRight: 20, minWidth: 180 }}>
                      <div style={{ textAlign: 'right', marginBottom: 16 }}>
                        <p style={{ fontSize: 11, color: 'var(--gray400)', margin: 0 }}>إجمالي المبلغ</p>
                        <p style={{ fontSize: 24, fontWeight: 900, color: 'var(--g600)', margin: 0 }}>
                          {(order.total_amount || 0).toLocaleString('ar-IQ')} <span style={{ fontSize: 12, fontWeight: 500 }}>د.ع</span>
                        </p>
                      </div>

                      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                        <select
                          value={order.status}
                          onChange={event => updateOrderStatus(order.id, event.target.value)}
                          className="form-select"
                          style={{ width: 130, padding: '6px 10px', fontSize: 12 }}
                        >
                          {STATUSES.filter(status => status !== STATUS_ALL).map(status => (
                            <option key={status} value={status}>
                              {getStatusLabel(status)}
                            </option>
                          ))}
                        </select>
                        <button className="btn btn-icon btn-ghost btn-sm" onClick={() => printOrder(order)}>
                          <Printer size={18} />
                        </button>
                        {order.customer_phone && order.customer_phone !== 'غير مسجل' && (
                          <button
                            className="btn btn-icon btn-ghost btn-sm"
                            onClick={() => {
                              const phone = order.customer_phone!.replace(/[^0-9]/g, '');
                              const msg = encodeURIComponent(`مرحباً! طلبك رقم #${order.id.substring(0, 8)} قيد التجهيز من Kiwi Fresh`);
                              window.open(`https://wa.me/${phone}?text=${msg}`, '_blank');
                            }}
                          >
                            <MessageCircle size={18} />
                          </button>
                        )}
                        <button className="btn btn-icon btn-ghost btn-sm">
                          <MoreVertical size={18} />
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
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12, marginTop: 24 }}>
          <button
            onClick={() => setPage(p => Math.max(0, p - 1))}
            disabled={safePage === 0}
            className="btn btn-ghost btn-sm"
          >
            <ChevronRight size={16} /> السابق
          </button>
          <span style={{ fontSize: 13, color: 'var(--gray500)', fontWeight: 600 }}>
            صفحة {safePage + 1} من {totalPages}
            <span style={{ color: 'var(--gray400)', marginRight: 8 }}>({filteredOrders.length} طلب)</span>
          </span>
          <button
            onClick={() => setPage(p => Math.min(totalPages - 1, p + 1))}
            disabled={safePage >= totalPages - 1}
            className="btn btn-ghost btn-sm"
          >
            التالي <ChevronLeft size={16} />
          </button>
        </div>
      )}
    </div>
  );
}
