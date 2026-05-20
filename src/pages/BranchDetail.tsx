import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { 
  ArrowRight, Printer, MapPin, Phone, Calendar, 
  TrendingUp, ShoppingCart, Send, AlertTriangle, History, Monitor
} from 'lucide-react'
import { 
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, 
  AreaChart, Area, PieChart, Pie, Cell
} from 'recharts'
import { supabase } from '../lib/supabase'

const COLORS = ['#10b981', '#3b82f6', '#f59e0b', '#ef4444', '#8b5cf6']

export default function BranchDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [branch, setBranch] = useState<any>(null)
  const [orders, setOrders] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [showNotifModal, setShowNotifModal] = useState(false)
  const [notifText, setNotifText] = useState('')

  // Mock data to prevent crash if DB is empty
  const salesData = [
    { name: 'السبت', sales: 0 }, { name: 'الأحد', sales: 0 },
    { name: 'الأثنين', sales: 0 }, { name: 'الثلاثاء', sales: 0 },
    { name: 'الأربعاء', sales: 0 }, { name: 'الخميس', sales: 0 },
    { name: 'الجمعة', sales: 0 }
  ]

  const categoryData = [
    { name: 'خضروات', value: 40 }, { name: 'فواكه', value: 30 },
    { name: 'أخرى', value: 30 }
  ]

  useEffect(() => {
    if (id) {
      fetchBranch()
      fetchRecentOrders()
    }
  }, [id])

  async function fetchBranch() {
    const { data, error } = await supabase
      .from('branches')
      .select('*')
      .eq('id', id)
      .single()
    if (data) setBranch(data)
  }

  async function fetchRecentOrders() {
    const { data, error } = await supabase
      .from('orders')
      .select('*')
      .eq('branch_id', id)
      .order('created_at', { ascending: false })
      .limit(10)
    if (data) setOrders(data)
    setLoading(false)
  }

  async function sendNotification(type: string = 'admin_note') {
    if (!notifText) return
    const { error } = await supabase.from('admin_notifications').insert([{
      target_branch_id: id,
      title: type === 'stock_alert' ? '⚠️ تنبيه مخزون' : '🔔 رسالة إدارية',
      message: notifText,
      type: type
    }])
    if (!error) {
      alert('تم إرسال الإشعار بنجاح للفرع')
      setShowNotifModal(false)
      setNotifText('')
    }
  }

  if (loading) return <div className="loader-overlay"><div className="loader"></div></div>
  if (!branch) return <div className="empty-state">الفرع غير موجود</div>

  return (
    <div className="animate-in">
      {/* Header & Actions */}
      <div className="no-print" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <button className="btn btn-ghost" onClick={() => navigate('/branches')}>
          <ArrowRight size={18} /> العودة للفروع
        </button>
        <div style={{ display: 'flex', gap: 10 }}>
          <button className="btn btn-outline" onClick={() => setShowNotifModal(true)}>
            <Send size={16} /> إرسال إشعار للفرع
          </button>
          <button className="btn btn-outline" onClick={() => window.print()}>
            <Printer size={16} /> طباعة التقرير (PDF)
          </button>
        </div>
      </div>

      {/* Info Cards */}
      <div className="grid-3" style={{ marginBottom: 24 }}>
        <div className="card" style={{ display: 'flex', gap: 16, alignItems: 'center' }}>
          <div style={{ background: 'var(--g50)', color: 'var(--g600)', padding: 12, borderRadius: 12 }}><MapPin size={24} /></div>
          <div><div style={{ fontSize: 12, color: '#999' }}>الموقع</div><div style={{ fontWeight: 800 }}>{branch.address}</div></div>
        </div>
        <div className="card" style={{ display: 'flex', gap: 16, alignItems: 'center' }}>
          <div style={{ background: '#3b82f615', color: '#3b82f6', padding: 12, borderRadius: 12 }}><Phone size={24} /></div>
          <div><div style={{ fontSize: 12, color: '#999' }}>الاتصال</div><div style={{ fontWeight: 800 }}>{branch.phone}</div></div>
        </div>
        <div className="card" style={{ display: 'flex', gap: 16, alignItems: 'center' }}>
          <div style={{ background: '#f59e0b15', color: '#f59e0b', padding: 12, borderRadius: 12 }}><Calendar size={24} /></div>
          <div><div style={{ fontSize: 12, color: '#999' }}>تاريخ البدء</div><div style={{ fontWeight: 800 }}>{new Date(branch.created_at).toLocaleDateString('ar-IQ')}</div></div>
        </div>
      </div>

      {/* Charts Section */}
      <div className="grid-2" style={{ marginBottom: 24 }}>
        <div className="card">
          <h3 className="card-title">نمو المبيعات الأسبوعي</h3>
          <div style={{ height: 300 }}>
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={salesData}>
                <defs>
                  <linearGradient id="colorSales" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.1}/><stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fontSize: 12}} />
                <YAxis axisLine={false} tickLine={false} tick={{fontSize: 12}} />
                <Tooltip />
                <Area type="monotone" dataKey="sales" stroke="#10b981" strokeWidth={3} fillOpacity={1} fill="url(#colorSales)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
        <div className="card">
          <h3 className="card-title">توزيع الفئات</h3>
          <div style={{ height: 300 }}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={categoryData} cx="50%" cy="50%" innerRadius={60} outerRadius={80} dataKey="value">
                  {categoryData.map((_, index) => <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />)}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
      
      {/* Recent Transactions Table */}
      <div className="card">
        <h3 className="card-title"><History size={20} /> سجل العمليات الأخيرة</h3>
        <div className="table-wrap">
          <table>
            <thead><tr><th>نوع العملية</th><th>العميل</th><th>الوقت</th><th>القيمة</th></tr></thead>
            <tbody>
              {!orders || orders.length === 0 ? (
                <tr><td colSpan={4} style={{ textAlign: 'center', padding: 40 }}>لا توجد عمليات</td></tr>
              ) : (
                orders.map(order => (
                  <tr key={order.id}>
                    <td>{order.order_type === 'pos' ? 'كاشير' : 'تطبيق'}</td>
                    <td>{order.customer_name_manual || 'مسجل'}</td>
                    <td>{new Date(order.created_at).toLocaleString('ar-IQ')}</td>
                    <td>{(order.total_amount || 0).toLocaleString()} د.ع</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Notification Modal */}
      {showNotifModal && (
        <div className="modal-overlay" onClick={() => setShowNotifModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h2 className="modal-title">إرسال إشعار للفرع</h2>
            <textarea className="form-textarea" placeholder="اكتب ملاحظاتك..." value={notifText} onChange={e => setNotifText(e.target.value)} />
            <div style={{ display: 'flex', gap: 10, marginTop: 10 }}>
              <button className="btn btn-primary" style={{ flex: 1 }} onClick={() => sendNotification('admin_note')}>إشعار عام</button>
              <button className="btn btn-outline" style={{ flex: 1 }} onClick={() => sendNotification('stock_alert')}>تنبيه مخزون</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
