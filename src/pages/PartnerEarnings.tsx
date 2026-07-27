import { useState, useEffect } from 'react'
import { TrendingUp, ShieldCheck, Store, HeartPulse, Calendar, ChevronDown } from 'lucide-react'
import { supabase } from '../lib/supabase'
import toast from 'react-hot-toast'

const fmt = (v: number) => v.toLocaleString('ar-IQ')

interface PeriodData { label: string; revenue: number; dev: number; owner: number; maintenance: number; branch: number; orders: number }

export default function PartnerEarnings() {
  const [loading, setLoading] = useState(true)
  const [period, setPeriod] = useState<'daily' | 'weekly' | 'monthly'>('daily')
  const [data, setData] = useState<PeriodData[]>([])
  const [devRatio, setDevRatio] = useState(0.35)
  const [ownerRatio, setOwnerRatio] = useState(0.55)
  const [maintenanceRatio, setMaintenanceRatio] = useState(0.10)

  useEffect(() => { fetchData() }, [period])

  async function fetchData() {
    setLoading(true)
    try {
      // Fetch partner ratios
      const { data: settings } = await supabase.from('system_settings').select('key, value_decimal')
      if (settings) {
        const dev = settings.find((s: { key: string }) => s.key === 'dev_partner_ratio')
        const owner = settings.find((s: { key: string }) => s.key === 'owner_partner_ratio')
        const maint = settings.find((s: { key: string }) => s.key === 'system_maintenance_ratio')
        if (dev) setDevRatio(dev.value_decimal)
        if (owner) setOwnerRatio(owner.value_decimal)
        if (maint) setMaintenanceRatio(maint.value_decimal)
      }

      // Fetch delivered orders
      const { data: orders } = await supabase.from('orders')
        .select('total_amount, delivery_fee, created_at, branch_id, branches(name)')
        .eq('status', 'delivered')
        .order('created_at', { ascending: false })

      if (!orders) { setLoading(false); return }

      // Group by period
      const grouped: Record<string, { revenue: number; orders: number }> = {}
      orders.forEach(o => {
        const d = new Date(o.created_at)
        let key: string
        if (period === 'daily') key = d.toLocaleDateString('ar-IQ')
        else if (period === 'weekly') {
          const weekStart = new Date(d); weekStart.setDate(d.getDate() - d.getDay())
          key = 'أسبوع ' + weekStart.toLocaleDateString('ar-IQ')
        } else {
          key = `${d.getFullYear()}/${String(d.getMonth() + 1).padStart(2, '0')}`
        }
        if (!grouped[key]) grouped[key] = { revenue: 0, orders: 0 }
        grouped[key].revenue += o.total_amount || 0
        grouped[key].orders++
      })

      const result: PeriodData[] = Object.entries(grouped).map(([label, g]) => ({
        label,
        revenue: g.revenue,
        dev: g.revenue * devRatio,
        owner: g.revenue * ownerRatio,
        maintenance: g.revenue * maintenanceRatio,
        branch: g.revenue * (1 - devRatio - ownerRatio - maintenanceRatio),
        orders: g.orders,
      }))

      setData(result)
    } catch (err) {
      toast.error('خطأ في جلب البيانات')
    } finally {
      setLoading(false)
    }
  }

  const totals = data.reduce((acc, d) => ({
    revenue: acc.revenue + d.revenue, dev: acc.dev + d.dev, owner: acc.owner + d.owner,
    maintenance: acc.maintenance + d.maintenance, branch: acc.branch + d.branch, orders: acc.orders + d.orders,
  }), { revenue: 0, dev: 0, owner: 0, maintenance: 0, branch: 0, orders: 0 })

  return (
    <div className="animate-in">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h1 className="brand-name" style={{ fontSize: 24 }}>أرباح الشركاء</h1>
          <p className="brand-sub">توزيع الأرباح بشكل لحظي — يومي / أسبوعي / شهري</p>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          {(['daily', 'weekly', 'monthly'] as const).map(p => (
            <button key={p} className={`btn ${period === p ? 'btn-primary' : 'btn-outline'} btn-sm`}
              onClick={() => setPeriod(p)}>
              <Calendar size={14} /> {p === 'daily' ? 'يومي' : p === 'weekly' ? 'أسبوعي' : 'شهري'}
            </button>
          ))}
        </div>
      </div>

      {/* Partner Ratios Display */}
      <div className="card" style={{ marginBottom: 20 }}>
        <div style={{ padding: 16, display: 'flex', alignItems: 'center', gap: 16, flexWrap: 'wrap' }}>
          <span style={{ fontWeight: 700, fontSize: 13, color: 'var(--gray700)' }}>📊 نسب الشراكة:</span>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '4px 12px', borderRadius: 8, background: '#2563eb15', color: '#2563eb', fontSize: 12, fontWeight: 700 }}>
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#2563eb' }}></div>
            المبرمج: {(devRatio * 100).toFixed(0)}%
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '4px 12px', borderRadius: 8, background: '#d9770615', color: '#d97706', fontSize: 12, fontWeight: 700 }}>
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#d97706' }}></div>
            صاحب المشروع: {(ownerRatio * 100).toFixed(0)}%
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '4px 12px', borderRadius: 8, background: '#7c3aed15', color: '#7c3aed', fontSize: 12, fontWeight: 700 }}>
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#7c3aed' }}></div>
            الصيانة: {(maintenanceRatio * 100).toFixed(0)}%
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '4px 12px', borderRadius: 8, background: '#10b98115', color: '#10b981', fontSize: 12, fontWeight: 700 }}>
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#10b981' }}></div>
            صاحب الفرع: {((1 - devRatio - ownerRatio - maintenanceRatio) * 100).toFixed(0)}%
          </div>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="stats-grid">
        <div className="stat-card stat-green">
          <div className="stat-icon-wrap" style={{ background: 'var(--g50)' }}><TrendingUp color="var(--g600)" /></div>
          <div className="stat-label">إجمالي الإيرادات</div>
          <div className="stat-value">{fmt(totals.revenue)} <span style={{ fontSize: 11 }}>د.ع</span></div>
          <div style={{ fontSize: 11, color: 'var(--gray400)', marginTop: 4 }}>{totals.orders} طلب</div>
        </div>
        <div className="stat-card stat-blue">
          <div className="stat-icon-wrap" style={{ background: '#dbeafe' }}><ShieldCheck color="#2563eb" /></div>
          <div className="stat-label">حصة المبرمج ({(devRatio * 100).toFixed(0)}%)</div>
          <div className="stat-value">{fmt(totals.dev)} <span style={{ fontSize: 11 }}>د.ع</span></div>
        </div>
        <div className="stat-card stat-amber">
          <div className="stat-icon-wrap" style={{ background: '#fef3c7' }}><Store color="#d97706" /></div>
          <div className="stat-label">حصة صاحب المشروع ({(ownerRatio * 100).toFixed(0)}%)</div>
          <div className="stat-value">{fmt(totals.owner)} <span style={{ fontSize: 11 }}>د.ع</span></div>
        </div>
        <div className="stat-card stat-purple">
          <div className="stat-icon-wrap" style={{ background: '#ede9fe' }}><HeartPulse color="#7c3aed" /></div>
          <div className="stat-label">صندوق الصيانة ({(maintenanceRatio * 100).toFixed(0)}%)</div>
          <div className="stat-value">{fmt(totals.maintenance)} <span style={{ fontSize: 11 }}>د.ع</span></div>
        </div>
      </div>

      {/* Period Table */}
      <div className="card">
        <div className="card-header">
          <span className="card-title">تفاصيل الأرباح — {period === 'daily' ? 'يومي' : period === 'weekly' ? 'أسبوعي' : 'شهري'}</span>
        </div>
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>الفترة</th>
                <th>الطلبات</th>
                <th>الإيراد</th>
                <th style={{ color: '#2563eb' }}>المبرمج</th>
                <th style={{ color: '#d97706' }}>صاحب المشروع</th>
                <th style={{ color: '#7c3aed' }}>الصيانة</th>
                <th style={{ color: '#10b981' }}>صاحب الفرع</th>
              </tr>
            </thead>
            <tbody>
              {data.map((d, i) => (
                <tr key={i}>
                  <td style={{ fontWeight: 700 }}>{d.label}</td>
                  <td>{d.orders}</td>
                  <td style={{ fontWeight: 700 }}>{fmt(d.revenue)}</td>
                  <td style={{ fontWeight: 700, color: '#2563eb' }}>{fmt(d.dev)}</td>
                  <td style={{ fontWeight: 700, color: '#d97706' }}>{fmt(d.owner)}</td>
                  <td style={{ fontWeight: 700, color: '#7c3aed' }}>{fmt(d.maintenance)}</td>
                  <td style={{ fontWeight: 700, color: '#10b981' }}>{fmt(d.branch)}</td>
                </tr>
              ))}
              {/* Totals Row */}
              <tr style={{ background: 'var(--gray50)', fontWeight: 800 }}>
                <td>الإجمالي</td>
                <td>{totals.orders}</td>
                <td>{fmt(totals.revenue)}</td>
                <td style={{ color: '#2563eb' }}>{fmt(totals.dev)}</td>
                <td style={{ color: '#d97706' }}>{fmt(totals.owner)}</td>
                <td style={{ color: '#7c3aed' }}>{fmt(totals.maintenance)}</td>
                <td style={{ color: '#10b981' }}>{fmt(totals.branch)}</td>
              </tr>
              {data.length === 0 && (
                <tr><td colSpan={7} style={{ textAlign: 'center', color: 'var(--gray400)', padding: 40 }}>لا توجد بيانات بعد</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
