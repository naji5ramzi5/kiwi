import { useState, useEffect } from 'react'
import { ShoppingCart, DollarSign, Users, Truck, TrendingUp, Download, BarChart3, Package } from 'lucide-react'
import { supabase } from '../lib/supabase'
import toast from 'react-hot-toast'
import DateRangePicker from '../components/DateRangePicker'

const fmt = (v: number) => v.toLocaleString('ar-IQ')

interface OrderStats { date: string; count: number; total: number; delivered: number; cancelled: number }
interface BranchStats { name: string; orders: number; revenue: number; avg: number }
interface DriverStats { name: string; deliveries: number; earnings: number; rating: number }
interface ProductStats { name: string; quantity: number; revenue: number }

export default function Reports() {
  const [loading, setLoading] = useState(true)
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [activeTab, setActiveTab] = useState<'orders' | 'branches' | 'drivers' | 'products'>('orders')

  const [totalOrders, setTotalOrders] = useState(0)
  const [totalRevenue, setTotalRevenue] = useState(0)
  const [totalDeliveryFees, setTotalDeliveryFees] = useState(0)
  const [avgOrder, setAvgOrder] = useState(0)
  const [totalCustomers, setTotalCustomers] = useState(0)
  const [totalDrivers, setTotalDrivers] = useState(0)

  const [orderStats, setOrderStats] = useState<OrderStats[]>([])
  const [branchStats, setBranchStats] = useState<BranchStats[]>([])
  const [driverStats, setDriverStats] = useState<DriverStats[]>([])
  const [productStats, setProductStats] = useState<ProductStats[]>([])

  useEffect(() => { fetchAll() }, [startDate, endDate])

  async function fetchAll() {
    setLoading(true)
    try {
      let query = supabase.from('orders').select('*, branches:branch_id(name), drivers:driver_id(profiles:full_name), order_items(product_id, quantity, unit_price, total_price, name_snapshot)')
      if (startDate) query = query.gte('created_at', startDate + 'T00:00:00')
      if (endDate) query = query.lte('created_at', endDate + 'T23:59:59')
      const { data: orders } = await query

      const delivered = orders?.filter(o => o.status === 'delivered') || []
      const cancelled = orders?.filter(o => o.status === 'cancelled') || []
      
      setTotalOrders(orders?.length || 0)
      setTotalRevenue(delivered.reduce((s, o) => s + (o.total_amount || 0), 0))
      setTotalDeliveryFees(delivered.reduce((s, o) => s + (o.delivery_fee || 0), 0))
      setAvgOrder(delivered.length ? delivered.reduce((s, o) => s + (o.total_amount || 0), 0) / delivered.length : 0)

      // Order stats by date
      const byDate: Record<string, OrderStats> = {}
      orders?.forEach(o => {
        const d = new Date(o.created_at).toLocaleDateString('ar-IQ')
        if (!byDate[d]) byDate[d] = { date: d, count: 0, total: 0, delivered: 0, cancelled: 0 }
        byDate[d].count++
        byDate[d].total += o.total_amount || 0
        if (o.status === 'delivered') byDate[d].delivered++
        if (o.status === 'cancelled') byDate[d].cancelled++
      })
      setOrderStats(Object.values(byDate).sort((a, b) => b.date.localeCompare(a.date)))

      // Branch stats
      const byBranch: Record<string, BranchStats> = {}
      delivered.forEach(o => {
        const bn = o.branches?.name || 'غير محدد'
        if (!byBranch[bn]) byBranch[bn] = { name: bn, orders: 0, revenue: 0, avg: 0 }
        byBranch[bn].orders++
        byBranch[bn].revenue += o.total_amount || 0
      })
      Object.values(byBranch).forEach(b => b.avg = b.orders ? b.revenue / b.orders : 0)
      setBranchStats(Object.values(byBranch).sort((a, b) => b.revenue - a.revenue))

      // Driver stats
      const byDriver: Record<string, DriverStats> = {}
      delivered.forEach(o => {
        const dn = o.drivers?.profiles?.full_name || 'غير محدد'
        if (!byDriver[dn]) byDriver[dn] = { name: dn, deliveries: 0, earnings: 0, rating: 0 }
        byDriver[dn].deliveries++
        byDriver[dn].earnings += o.delivery_fee || 0
      })
      setDriverStats(Object.values(byDriver).sort((a, b) => b.deliveries - a.deliveries))

      // Product stats
      const byProduct: Record<string, ProductStats> = {}
      delivered.forEach(o => {
        o.order_items?.forEach((item: Record<string, unknown>) => {
          const pn = (item.name_snapshot as string) || 'غير محدد'
          if (!byProduct[pn]) byProduct[pn] = { name: pn, quantity: 0, revenue: 0 }
          byProduct[pn].quantity += (item.quantity as number) || 0
          byProduct[pn].revenue += (item.total_price as number) || 0
        })
      })
      setProductStats(Object.values(byProduct).sort((a, b) => b.revenue - a.revenue).slice(0, 20))

      // Customer & Driver counts
      const { count: custCount } = await supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'customer')
      const { count: drvCount } = await supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'driver')
      setTotalCustomers(custCount || 0)
      setTotalDrivers(drvCount || 0)

    } catch (err) {
      toast.error('خطأ في جلب التقارير')
    } finally {
      setLoading(false)
    }
  }

  function exportCSV(data: Record<string, unknown>[], filename: string) {
    if (!data.length) return
    const headers = Object.keys(data[0]).join(',')
    const rows = data.map(r => Object.values(r).map(v => `"${v}"`).join(',')).join('\n')
    const blob = new Blob(['\uFEFF' + headers + '\n' + rows], { type: 'text/csv;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a'); a.href = url; a.download = filename; a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="animate-in">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h1 className="brand-name" style={{ fontSize: 24 }}>التقارير التفصيلية</h1>
          <p className="brand-sub">تحليل شامل للأداء والمبيعات</p>
        </div>
        <button className="btn btn-outline" onClick={() => {
          const data = activeTab === 'orders' ? orderStats : activeTab === 'branches' ? branchStats : activeTab === 'drivers' ? driverStats : productStats
          exportCSV(data as Record<string, unknown>[], `report-${activeTab}-${new Date().toISOString().slice(0,10)}.csv`)
        }}><Download size={16} /> تصدير CSV</button>
      </div>

      <div style={{ marginBottom: 20, display: 'flex', gap: 12 }}>
        <DateRangePicker startDate={startDate} endDate={endDate} onStartDateChange={setStartDate} onEndDateChange={setEndDate} label="تصفية حسب التاريخ" />
        {(startDate || endDate) && <button className="btn btn-ghost btn-sm" onClick={() => { setStartDate(''); setEndDate('') }}>مسح الفلتر</button>}
      </div>

      <div className="stats-grid">
        <div className="stat-card stat-green"><div className="stat-icon-wrap" style={{ background: 'var(--g50)' }}><ShoppingCart color="var(--g600)" /></div><div className="stat-label">إجمالي الطلبات</div><div className="stat-value">{fmt(totalOrders)}</div></div>
        <div className="stat-card stat-blue"><div className="stat-icon-wrap" style={{ background: '#dbeafe' }}><DollarSign color="#2563eb" /></div><div className="stat-label">إجمالي المبيعات</div><div className="stat-value">{fmt(totalRevenue)} <span style={{ fontSize: 11 }}>د.ع</span></div></div>
        <div className="stat-card stat-amber"><div className="stat-icon-wrap" style={{ background: '#fef3c7' }}><TrendingUp color="#d97706" /></div><div className="stat-label">رسوم التوصيل</div><div className="stat-value">{fmt(totalDeliveryFees)} <span style={{ fontSize: 11 }}>د.ع</span></div></div>
        <div className="stat-card stat-purple"><div className="stat-icon-wrap" style={{ background: '#ede9fe' }}><BarChart3 color="#7c3aed" /></div><div className="stat-label">متوسط الطلب</div><div className="stat-value">{fmt(avgOrder)} <span style={{ fontSize: 11 }}>د.ع</span></div></div>
        <div className="stat-card stat-green"><div className="stat-icon-wrap" style={{ background: 'var(--g50)' }}><Users color="var(--g600)" /></div><div className="stat-label">العملاء</div><div className="stat-value">{fmt(totalCustomers)}</div></div>
        <div className="stat-card stat-blue"><div className="stat-icon-wrap" style={{ background: '#dbeafe' }}><Truck color="#2563eb" /></div><div className="stat-label">المناديب</div><div className="stat-value">{fmt(totalDrivers)}</div></div>
      </div>

      <div style={{ display: 'flex', gap: 8, marginBottom: 20 }}>
        {[{ k: 'orders', l: '📊 الطلبات', icon: ShoppingCart }, { k: 'branches', l: '🏪 الفروع', icon: Package }, { k: 'drivers', l: '🚗 المناديب', icon: Truck }, { k: 'products', l: '📦 المنتجات', icon: Package }].map(t => (
          <button key={t.k} className={`btn ${activeTab === t.k ? 'btn-primary' : 'btn-outline'} btn-sm`} onClick={() => setActiveTab(t.k as typeof activeTab)}>{t.l}</button>
        ))}
      </div>

      {loading ? <div style={{ textAlign: 'center', padding: 40 }}><div className="loader"></div></div> : (
        <div className="card">
          <div className="table-wrap">
            <table>
              <thead>
                {activeTab === 'orders' && <tr><th>التاريخ</th><th>عدد الطلبات</th><th>المبلغ</th><th>تم التوصيل</th><th>ملغي</th></tr>}
                {activeTab === 'branches' && <tr><th>الفرع</th><th>عدد الطلبات</th><th>الإيراد</th><th>متوسط الطلب</th></tr>}
                {activeTab === 'drivers' && <tr><th>المندوب</th><th>عدد التوصيلات</th><th>الأرباح</th></tr>}
                {activeTab === 'products' && <tr><th>المنتج</th><th>الكمية المباعة</th><th>الإيراد</th></tr>}
              </thead>
              <tbody>
                {activeTab === 'orders' && orderStats.map((s, i) => (
                  <tr key={i}><td>{s.date}</td><td style={{ fontWeight: 700 }}>{s.count}</td><td>{fmt(s.total)}</td><td style={{ color: 'var(--g600)' }}>{s.delivered}</td><td style={{ color: '#ef4444' }}>{s.cancelled}</td></tr>
                ))}
                {activeTab === 'branches' && branchStats.map((s, i) => (
                  <tr key={i}><td style={{ fontWeight: 700 }}>{s.name}</td><td>{s.orders}</td><td>{fmt(s.revenue)}</td><td>{fmt(s.avg)}</td></tr>
                ))}
                {activeTab === 'drivers' && driverStats.map((s, i) => (
                  <tr key={i}><td style={{ fontWeight: 700 }}>{s.name}</td><td>{s.deliveries}</td><td>{fmt(s.earnings)} د.ع</td></tr>
                ))}
                {activeTab === 'products' && productStats.map((s, i) => (
                  <tr key={i}><td style={{ fontWeight: 700 }}>{s.name}</td><td>{s.quantity}</td><td>{fmt(s.revenue)} د.ع</td></tr>
                ))}
                {((activeTab === 'orders' && !orderStats.length) || (activeTab === 'branches' && !branchStats.length) || (activeTab === 'drivers' && !driverStats.length) || (activeTab === 'products' && !productStats.length)) && (
                  <tr><td colSpan={5} style={{ textAlign: 'center', color: 'var(--gray400)', padding: 40 }}>لا توجد بيانات</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  )
}
