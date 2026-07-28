import { useState, useEffect, useCallback } from 'react'
import { supabase } from '../lib/supabase'
import {
  TrendingUp, DollarSign, Store, ShieldCheck, HeartPulse,
  Users, Truck, Wallet, Calendar, Download, Loader,
  ChevronDown, ChevronUp, CreditCard
} from 'lucide-react'
import toast from 'react-hot-toast'
import DateRangePicker from '../components/DateRangePicker'

const fmt = (v: number) => (v || 0).toLocaleString('ar-IQ')

const PERIOD_TABS = [
  { key: 'daily', label: 'يومي' },
  { key: 'weekly', label: 'أسبوعي' },
  { key: 'monthly', label: 'شهري' },
]

interface PartnerRatio {
  key: string; value_decimal: number; label: string; color: string;
}
interface PeriodSales {
  period: string; orders: number; revenue: number; delivery_fees: number; avg_order: number;
}
interface BranchMetric {
  branch_id: string; branch_name: string; orders: number; revenue: number;
}
interface DriverWallet {
  driver_id: string; full_name: string; balance: number; vehicle_type: string;
  last_payout_date: string | null; phone: string;
}

export default function FinancialDashboard() {
  const [periodTab, setPeriodTab] = useState('daily')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [loading, setLoading] = useState(true)
  const [salesData, setSalesData] = useState<PeriodSales[]>([])
  const [branchData, setBranchData] = useState<BranchMetric[]>([])
  const [totals, setTotals] = useState({ total_revenue: 0, total_orders: 0 })
  const [partners, setPartners] = useState<PartnerRatio[]>([
    { key: 'dev_partner_ratio', value_decimal: 0.35, label: 'حصة المبرمج', color: '#2563eb' },
    { key: 'owner_partner_ratio', value_decimal: 0.55, label: 'حصة صاحب المشروع', color: '#d97706' },
    { key: 'system_maintenance_ratio', value_decimal: 0.10, label: 'صندوق الصيانة', color: '#7c3aed' },
  ])
  const [drivers, setDrivers] = useState<DriverWallet[]>([])
  const [loadingDrivers, setLoadingDrivers] = useState(false)
  const [savingSalary, setSavingSalary] = useState<string | null>(null)
  const [showDriverFinance, setShowDriverFinance] = useState(false)

  const fetchFinancials = useCallback(async () => {
    setLoading(true)
    try {
      let query = supabase
        .from('orders')
        .select('id, total_amount, delivery_fee, branch_id, created_at, branches!inner(name)')
        .in('status', ['delivered', 'completed'])

      if (startDate) query = query.gte('created_at', startDate)
      if (endDate) query = query.lte('created_at', endDate + 'T23:59:59')

      const { data: orders, error } = await query.order('created_at', { ascending: false })
      if (error) throw error

      const now = new Date()
      const grouped: Record<string, PeriodSales> = {}
      const branchTotals: Record<string, BranchMetric> = {}

      const getPeriodKey = (dateStr: string) => {
        const d = new Date(dateStr)
        if (periodTab === 'daily') return d.toISOString().slice(0, 10)
        if (periodTab === 'weekly') {
          const start = new Date(d); start.setDate(d.getDate() - d.getDay())
          return start.toISOString().slice(0, 10)
        }
        return d.toISOString().slice(0, 7)
      }

      for (const o of (orders || [])) {
        const pk = getPeriodKey(o.created_at)
        if (!grouped[pk]) grouped[pk] = { period: pk, orders: 0, revenue: 0, delivery_fees: 0, avg_order: 0 }
        grouped[pk].orders++
        grouped[pk].revenue += (o.total_amount || 0)
        grouped[pk].delivery_fees += (o.delivery_fee || 0)

        const bName = (o.branches as unknown as { name: string })?.name || 'غير معروف'
        if (!branchTotals[bName]) branchTotals[bName] = { branch_id: o.branch_id || '', branch_name: bName, orders: 0, revenue: 0 }
        branchTotals[bName].orders++
        branchTotals[bName].revenue += (o.total_amount || 0)
      }

      for (const k of Object.keys(grouped)) {
        grouped[k].avg_order = grouped[k].orders > 0 ? Math.round(grouped[k].revenue / grouped[k].orders * 100) / 100 : 0
      }

      const salesArr = Object.values(grouped).sort((a, b) => b.period.localeCompare(a.period))
      const branchArr = Object.values(branchTotals).sort((a, b) => b.revenue - a.revenue)
      const totalRev = salesArr.reduce((s, i) => s + i.revenue, 0)
      const totalOrd = salesArr.reduce((s, i) => s + i.orders, 0)

      setSalesData(salesArr)
      setBranchData(branchArr)
      setTotals({ total_revenue: totalRev, total_orders: totalOrd })
    } catch (err) {
      console.error('Error fetching financials:', err)
      toast.error('خطأ في جلب البيانات المالية')
    } finally {
      setLoading(false)
    }
  }, [periodTab, startDate, endDate])

  const fetchPartnerRatios = useCallback(async () => {
    try {
      const { data } = await supabase.from('system_settings').select('*')
      if (data) {
        setPartners(prev => prev.map(p => {
          const found = data.find((s: { key: string; value_decimal: number }) => s.key === p.key)
          return found ? { ...p, value_decimal: found.value_decimal } : p
        }))
      }
    } catch (err) { console.error(err) }
  }, [])

  const fetchDriverWallets = useCallback(async () => {
    setLoadingDrivers(true)
    try {
      const { data: wallets, error } = await supabase
        .from('driver_wallets')
        .select('driver_id, balance, last_payout_date')
      if (error) throw error

      const driverIds = (wallets || []).map(w => w.driver_id)
      const { data: profiles } = await supabase
        .from('profiles')
        .select('id, full_name, phone, vehicle_type')
        .in('id', driverIds)

      const profileMap: Record<string, any> = {}
      for (const p of (profiles || [])) profileMap[p.id] = p

      const merged: DriverWallet[] = (wallets || []).map(w => ({
        driver_id: w.driver_id,
        balance: w.balance || 0,
        last_payout_date: w.last_payout_date,
        full_name: profileMap[w.driver_id]?.full_name || 'مندوب',
        vehicle_type: profileMap[w.driver_id]?.vehicle_type || '',
        phone: profileMap[w.driver_id]?.phone || '',
      })).sort((a, b) => b.balance - a.balance)

      setDrivers(merged)
    } catch (err) {
      console.error('Error fetching driver wallets:', err)
    } finally {
      setLoadingDrivers(false)
    }
  }, [])

  useEffect(() => { fetchFinancials(); fetchPartnerRatios() }, [fetchFinancials, fetchPartnerRatios])
  useEffect(() => { if (showDriverFinance) fetchDriverWallets() }, [showDriverFinance, fetchDriverWallets])

  async function handleSalaryPayout(driverId: string, balance: number) {
    setSavingSalary(driverId)
    try {
      const { error: walletError } = await supabase
        .from('driver_wallets')
        .update({ balance: 0, last_payout_date: new Date().toISOString(), updated_at: new Date().toISOString() })
        .eq('driver_id', driverId)

      if (walletError) throw walletError

      const { error: expenseError } = await supabase
        .from('system_expenses')
        .insert({ description: 'راتب شهري للمندوب', amount: balance, category: 'driver_salary', driver_id: driverId })

      if (expenseError) throw expenseError

      toast.success('تم تسديد الراتب بنجاح')
      fetchDriverWallets()
    } catch (err: unknown) {
      toast.error('خطأ في تسديد الراتب: ' + ((err as Error).message))
    } finally {
      setSavingSalary(null)
    }
  }

  const totalBalance = drivers.reduce((s, d) => s + d.balance, 0)
  const devShare = totals.total_revenue * partners[0].value_decimal
  const ownerShare = totals.total_revenue * partners[1].value_decimal
  const maintShare = totals.total_revenue * partners[2].value_decimal

  return (
    <div className="animate-in">
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h1 className="brand-name" style={{ fontSize: 24 }}>لوحة الإحصائيات المالية</h1>
          <p className="brand-sub">إجمالي المبيعات، توزيع الأرباح، والرواتب</p>
        </div>
        <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
          <DateRangePicker startDate={startDate} endDate={endDate} onStartDateChange={setStartDate} onEndDateChange={setEndDate} label="نطاق التاريخ" />
          {(startDate || endDate) && (
            <button className="btn btn-ghost btn-sm" onClick={() => { setStartDate(''); setEndDate('') }}>مسح</button>
          )}
        </div>
      </div>

      {/* Period Tabs */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 24 }}>
        {PERIOD_TABS.map(tab => (
          <button key={tab.key}
            onClick={() => setPeriodTab(tab.key)}
            className={periodTab === tab.key ? 'btn btn-primary btn-sm' : 'btn btn-outline btn-sm'}
            style={{ flex: 1, fontWeight: 700 }}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {loading ? (
        <div style={{ display: 'flex', justifyContent: 'center', padding: 80 }}><div className="loader" /></div>
      ) : (
        <>
          {/* Revenue Stats Cards */}
          <div className="stats-grid" style={{ marginBottom: 24 }}>
            <div className="stat-card stat-green">
              <div className="stat-icon-wrap" style={{ background: 'var(--g50)' }}><TrendingUp color="var(--g600)" /></div>
              <div className="stat-label">إجمالي المبيعات</div>
              <div className="stat-value">{fmt(totals.total_revenue)} <span style={{ fontSize: 12, fontWeight: 500 }}>د.ع</span></div>
            </div>
            <div className="stat-card" style={{ borderTop: '3px solid #2563eb' }}>
              <div className="stat-icon-wrap" style={{ background: '#dbeafe' }}><ShieldCheck color="#2563eb" /></div>
              <div className="stat-label">المبرمج ({Math.round(partners[0].value_decimal * 100)}%)</div>
              <div className="stat-value" style={{ color: '#2563eb' }}>{fmt(devShare)} <span style={{ fontSize: 12, fontWeight: 500 }}>د.ع</span></div>
            </div>
            <div className="stat-card" style={{ borderTop: '3px solid #d97706' }}>
              <div className="stat-icon-wrap" style={{ background: '#fef3c7' }}><Store color="#d97706" /></div>
              <div className="stat-label">صاحب المشروع ({Math.round(partners[1].value_decimal * 100)}%)</div>
              <div className="stat-value" style={{ color: '#d97706' }}>{fmt(ownerShare)} <span style={{ fontSize: 12, fontWeight: 500 }}>د.ع</span></div>
            </div>
            <div className="stat-card" style={{ borderTop: '3px solid #7c3aed' }}>
              <div className="stat-icon-wrap" style={{ background: '#ede9fe' }}><HeartPulse color="#7c3aed" /></div>
              <div className="stat-label">صندوق الصيانة ({Math.round(partners[2].value_decimal * 100)}%)</div>
              <div className="stat-value" style={{ color: '#7c3aed' }}>{fmt(maintShare)} <span style={{ fontSize: 12, fontWeight: 500 }}>د.ع</span></div>
            </div>
          </div>

          {/* Profit Distribution Bar */}
          <div className="card" style={{ marginBottom: 24 }}>
            <div className="card-header">
              <span className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <DollarSign size={18} /> توزيع الأرباح — نسب الشراكة الحالية
              </span>
            </div>
            <div style={{ padding: 20 }}>
              <div style={{ display: 'flex', borderRadius: 12, overflow: 'hidden', height: 36, marginBottom: 16 }}>
                <div style={{ flex: partners[0].value_decimal, background: '#2563eb', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: 800, fontSize: 13 }}>
                  المبرمج {Math.round(partners[0].value_decimal * 100)}%
                </div>
                <div style={{ flex: partners[1].value_decimal, background: '#d97706', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: 800, fontSize: 13 }}>
                  الشريك {Math.round(partners[1].value_decimal * 100)}%
                </div>
                <div style={{ flex: partners[2].value_decimal, background: '#7c3aed', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: 800, fontSize: 13 }}>
                  صيانة {Math.round(partners[2].value_decimal * 100)}%
                </div>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12 }}>
                {[
                  { label: 'المبرمج', value: devShare, color: '#2563eb', pct: partners[0].value_decimal },
                  { label: 'صاحب المشروع', value: ownerShare, color: '#d97706', pct: partners[1].value_decimal },
                  { label: 'صندوق الصيانة', value: maintShare, color: '#7c3aed', pct: partners[2].value_decimal },
                ].map(item => (
                  <div key={item.label} style={{ padding: '12px 16px', background: item.color + '08', borderRadius: 12, border: `1px solid ${item.color}20` }}>
                    <div style={{ fontSize: 12, color: 'var(--gray500)', fontWeight: 600, marginBottom: 4 }}>{item.label}</div>
                    <div style={{ fontSize: 18, fontWeight: 900, color: item.color }}>{fmt(item.value)} <span style={{ fontSize: 11 }}>د.ع</span></div>
                    <div style={{ fontSize: 11, color: 'var(--gray400)', marginTop: 2 }}>{(item.pct * 100).toFixed(0)}% من الإجمالي</div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Sales Table + Branch Metrics */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginBottom: 24 }}>
            <div className="card">
              <div className="card-header"><span className="card-title">المبيعات حسب الفترة</span></div>
              <div className="table-wrap" style={{ maxHeight: 320, overflowY: 'auto' }}>
                <table>
                  <thead>
                    <tr>
                      <th>الفترة</th>
                      <th>الطلبات</th>
                      <th>الإيرادات</th>
                      <th>متوسط الطلب</th>
                    </tr>
                  </thead>
                  <tbody>
                    {salesData.slice(0, 30).map(s => (
                      <tr key={s.period}>
                        <td style={{ fontSize: 12, fontWeight: 600 }}>
                          {periodTab === 'daily'
                            ? new Date(s.period).toLocaleDateString('ar-IQ')
                            : periodTab === 'weekly'
                              ? 'أسبوع ' + s.period
                              : s.period}
                        </td>
                        <td>{s.orders}</td>
                        <td style={{ fontWeight: 700, color: 'var(--green600)' }}>{fmt(s.revenue)}</td>
                        <td>{fmt(s.avg_order)}</td>
                      </tr>
                    ))}
                    {salesData.length === 0 && (
                      <tr><td colSpan={4} style={{ textAlign: 'center', color: 'var(--gray400)', padding: 40 }}>لا توجد بيانات</td></tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="card">
              <div className="card-header"><span className="card-title">أداء الفروع</span></div>
              <div className="table-wrap" style={{ maxHeight: 320, overflowY: 'auto' }}>
                <table>
                  <thead>
                    <tr>
                      <th>الفرع</th>
                      <th>الطلبات</th>
                      <th>الإيرادات</th>
                    </tr>
                  </thead>
                  <tbody>
                    {branchData.map(b => (
                      <tr key={b.branch_id}>
                        <td style={{ fontWeight: 700 }}>{b.branch_name}</td>
                        <td>{b.orders}</td>
                        <td style={{ fontWeight: 700, color: 'var(--green600)' }}>{fmt(b.revenue)}</td>
                      </tr>
                    ))}
                    {branchData.length === 0 && (
                      <tr><td colSpan={3} style={{ textAlign: 'center', color: 'var(--gray400)', padding: 40 }}>لا توجد بيانات</td></tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          {/* Driver Financials Section */}
          <div className="card" style={{ marginBottom: 24 }}>
            <div className="card-header" style={{ cursor: 'pointer' }} onClick={() => setShowDriverFinance(v => !v)}>
              <span className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <Truck size={18} /> الرواتب والمحافظ — المندوبين
              </span>
              {showDriverFinance ? <ChevronUp size={18} /> : <ChevronDown size={18} />}
            </div>
            {showDriverFinance && (
              <div style={{ padding: 20 }}>
                {loadingDrivers ? (
                  <div style={{ display: 'flex', justifyContent: 'center', padding: 40 }}><div className="loader" /></div>
                ) : (
                  <>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 20, padding: '14px 20px', background: 'var(--g50)', borderRadius: 14 }}>
                      <Wallet size={20} color="var(--g600)" />
                      <div>
                        <div style={{ fontSize: 12, color: 'var(--gray500)', fontWeight: 600 }}>إجمالي أرصدة المندوبين</div>
                        <div style={{ fontSize: 22, fontWeight: 900, color: 'var(--g600)' }}>{fmt(totalBalance)} <span style={{ fontSize: 13, fontWeight: 500 }}>د.ع</span></div>
                      </div>
                    </div>
                    <div className="table-wrap">
                      <table>
                        <thead>
                          <tr>
                            <th>المندوب</th>
                            <th>رقم الجوال</th>
                            <th>المركبة</th>
                            <th>الرصيد الحالي</th>
                            <th>آخر صرف</th>
                            <th></th>
                          </tr>
                        </thead>
                        <tbody>
                          {drivers.map(d => (
                            <tr key={d.driver_id}>
                              <td style={{ fontWeight: 700 }}>{d.full_name}</td>
                              <td style={{ fontSize: 13, color: 'var(--gray500)' }}>{d.phone}</td>
                              <td>
                                <span className="badge badge-green">{d.vehicle_type === 'truck' ? 'شاحنة' : 'دراجة'}</span>
                              </td>
                              <td style={{ fontWeight: 800, color: d.balance > 0 ? '#059669' : 'var(--gray400)', fontSize: 15 }}>
                                {fmt(d.balance)} د.ع
                              </td>
                              <td style={{ fontSize: 12, color: 'var(--gray400)' }}>
                                {d.last_payout_date ? new Date(d.last_payout_date).toLocaleDateString('ar-IQ') : '—'}
                              </td>
                              <td>
                                <button
                                  className="btn btn-primary btn-sm"
                                  disabled={d.balance <= 0 || savingSalary === d.driver_id}
                                  onClick={() => handleSalaryPayout(d.driver_id, d.balance)}
                                  style={{ whiteSpace: 'nowrap', fontSize: 11 }}
                                >
                                  {savingSalary === d.driver_id ? <Loader size={14} className="spin" /> : <CreditCard size={14} />}
                                  {savingSalary === d.driver_id ? '...' : 'تسديد'}
                                </button>
                              </td>
                            </tr>
                          ))}
                          {drivers.length === 0 && (
                            <tr><td colSpan={6} style={{ textAlign: 'center', padding: 40, color: 'var(--gray400)' }}>لا يوجد مناديب بعد</td></tr>
                          )}
                        </tbody>
                      </table>
                    </div>
                  </>
                )}
              </div>
            )}
          </div>
        </>
      )}

      <style>{`.spin { animation: spin 1s linear infinite; } @keyframes spin { from{transform:rotate(0)} to{transform:rotate(360deg)} }`}</style>
    </div>
  )
}
