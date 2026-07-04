import { useState, useEffect } from 'react'
import { TrendingUp, ShoppingBag, Users, MapPin, AlertCircle, ArrowUpRight, ArrowDownRight, Package, Bell } from 'lucide-react'
import { supabase } from '../lib/supabase'
import LiveMap from '../components/LiveMap'

export default function Dashboard() {
  const [branches, setBranches] = useState<any[]>([])
  const [drivers, setDrivers] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchGlobalStats()
  }, [])

  async function fetchGlobalStats() {
    setLoading(true)
    try {
      const { data: branchesData, error: bErr } = await supabase
        .from('branches')
        .select('*, orders(*), branch_inventory(*), purchases(*)')
      if (bErr) throw bErr

      const { data: driversData } = await supabase.from('drivers').select('*')

      setBranches(branchesData || [])
      setDrivers(driversData || [])
    } catch (err) {
      console.error('Error fetching global stats:', err)
    } finally {
      setLoading(false)
    }
  }

  // Calculate aggregates
  const totalSales = branches.reduce((sum, b) => {
    const branchSales = (b.orders || [])
      .filter((o: any) => o.status === 'تم التوصيل' || o.status === 'مكتمل' || o.status === 'delivered')
      .reduce((s: number, o: any) => s + Number(o.total_amount || o.total_price || 0), 0)
    return sum + branchSales
  }, 0)

  const totalOrdersCount = branches.reduce((sum, b) => sum + (b.orders?.length || 0), 0)

  const lowStockCount = branches.reduce((sum, b) => {
    const branchInv = b.branch_inventory || []
    const lowItems = branchInv.filter((i: any) => i.actual_stock <= (i.buffer_limit || 2)).length
    return sum + lowItems
  }, 0)

  const activeDriversCount = drivers.filter((d: any) => d.is_active && d.current_status === 'متاح').length

  return (
    <div className="animate-in">
      <div style={{ marginBottom: 24 }}>
        <h1 className="brand-name" style={{ fontSize: 24 }}>المراقبة المركزية</h1>
        <p className="brand-sub">متابعة أداء الفروع والمبيعات والمخزون في الوقت الحقيقي</p>
      </div>

      {/* Top Stats Row */}
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon-wrap" style={{ background: 'var(--g50)' }}><TrendingUp color="var(--g600)" /></div>
          <div className="stat-label">إجمالي مبيعات الفروع</div>
          <div className="stat-value">{(totalSales || 0).toLocaleString('ar-IQ')} <span className="text-xs">د.ع</span></div>
          <div className="stat-sub stat-up"><ArrowUpRight size={14} /> مبيعات حية محدثة</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon-wrap" style={{ background: '#3b82f615' }}><ShoppingBag color="#3b82f6" /></div>
          <div className="stat-label">إجمالي الطلبات</div>
          <div className="stat-value">{(totalOrdersCount || 0).toLocaleString('ar-IQ')} <span className="text-xs">طلب</span></div>
          <div className="stat-sub stat-up"><ArrowUpRight size={14} /> نشاط الفروع والتطبيق</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon-wrap" style={{ background: '#f59e0b15' }}><Package color="#f59e0b" /></div>
          <div className="stat-label">منتجات منخفضة المخزون</div>
          <div className="stat-value">{(lowStockCount || 0).toLocaleString('ar-IQ')} <span className="text-xs">صنف</span></div>
          <div className="stat-sub stat-down"><AlertCircle size={14} /> تتطلب توريداً فورياً</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon-wrap" style={{ background: '#8b5cf615' }}><Users color="#8b5cf6" /></div>
          <div className="stat-label">نشاط المناديب</div>
          <div className="stat-value">{(activeDriversCount || 0).toLocaleString('ar-IQ')} <span className="text-xs">مندوب متاح</span></div>
          <div className="stat-sub">من أصل {drivers.length} مندوب مسجل</div>
        </div>
      </div>

      {/* Live Operations Map */}
      <div className="card" style={{ marginBottom: 24, padding: 0, overflow: 'hidden' }}>
        <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--gray100)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h3 className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <MapPin size={20} color="var(--g600)" /> خريطة العمليات الحية (فروع ومناديب)
          </h3>
          <div style={{ display: 'flex', gap: 12 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12 }}>
              <div style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--g500)' }} /> فرع نشط
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12 }}>
              <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#3b82f6' }} /> مندوب في مهمة
            </div>
          </div>
        </div>
        <LiveMap branches={branches} />
      </div>

      <div className="grid-2">
        {/* Branch Performance Table */}
        <div className="card col-span-2">
          <div className="card-header">
            <h3 className="card-title">أداء الفروع (مبيعات ومخزون)</h3>
            <button className="btn btn-ghost btn-sm" onClick={fetchGlobalStats}>تحديث البيانات</button>
          </div>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>الفرع</th>
                  <th>الحالة</th>
                  <th>المبيعات (د.ع)</th>
                  <th>المشتريات (د.ع)</th>
                  <th>المخزون المتوفر</th>
                  <th>المناديب</th>
                  <th>آخر حركة</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr>
                    <td colSpan={7} style={{ textAlign: 'center', padding: 20 }}>جاري تحميل البيانات...</td>
                  </tr>
                ) : branches.length === 0 ? (
                  <tr>
                    <td colSpan={7} style={{ textAlign: 'center', padding: 20 }}>لا توجد فروع مسجلة</td>
                  </tr>
                ) : (
                  branches.map((b, i) => {
                    const branchSales = (b.orders || [])
                      .filter((o: any) => o.status === 'تم التوصيل' || o.status === 'مكتمل' || o.status === 'delivered')
                      .reduce((s: number, o: any) => s + Number(o.total_amount || o.total_price || 0), 0)

                    const branchPurchases = (b.purchases || [])
                      .reduce((s: number, p: any) => s + Number(p.total_value || 0), 0)

                    const branchInv = b.branch_inventory || []
                    const inStockCount = branchInv.filter((item: any) => item.actual_stock > (item.buffer_limit || 2)).length
                    const stockPercent = branchInv.length > 0 ? Math.round((inStockCount / branchInv.length) * 100) : 100

                    const branchDriversCount = drivers.filter((d: any) => d.branch_id === b.id).length

                    return (
                      <tr key={b.id}>
                        <td>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                            <div className="avatar avatar-sm">{b.name[0]}</div>
                            <span style={{ fontWeight: 700 }}>{b.name}</span>
                          </div>
                        </td>
                        <td><span className={`badge ${b.status === 'نشط' ? 'badge-green' : 'badge-red'}`}>{b.status}</span></td>
                        <td style={{ fontWeight: 800 }}>{branchSales.toLocaleString('ar-IQ')}</td>
                        <td style={{ color: 'var(--gray600)', fontWeight: 700 }}>{branchPurchases.toLocaleString('ar-IQ')}</td>
                        <td>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                            <div style={{ width: 60 }}>
                              <div className="progress-bar"><div className="progress-fill" style={{ width: `${stockPercent}%` }} /></div>
                            </div>
                            <span style={{ fontSize: 11, fontWeight: 700 }}>{stockPercent}%</span>
                          </div>
                        </td>
                        <td>{branchDriversCount}</td>
                        <td style={{ fontSize: 11, color: 'var(--gray400)' }}>
                          {b.orders && b.orders.length > 0 
                            ? new Date(b.orders[0].created_at).toLocaleTimeString('ar-IQ', { hour: '2-digit', minute: '2-digit' })
                            : 'لا يوجد حركة'}
                        </td>
                      </tr>
                    )
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Recent Alerts */}
        <div className="card">
          <div className="card-header"><h3 className="card-title">تنبيهات المنظومة</h3></div>
          <div className="card-body" style={{ padding: 0 }}>
            {branches.some(b => (b.branch_inventory || []).some((i: any) => i.actual_stock <= (i.buffer_limit || 2))) ? (
              branches.flatMap(b => {
                const lowItems = (b.branch_inventory || []).filter((i: any) => i.actual_stock <= (i.buffer_limit || 2))
                return lowItems.slice(0, 3).map((item: any, idx: number) => (
                  <div key={idx} style={{ padding: '16px 20px', borderBottom: '1px solid var(--gray100)', display: 'flex', gap: 12 }}>
                    <div className="live-dot red" style={{ marginTop: 6 }} />
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 13, fontWeight: 600 }}>مخزون منخفض في {b.name} للمنتج ID: {item.product_id.substring(0, 8)}</div>
                      <div style={{ fontSize: 11, color: 'var(--gray400)', marginTop: 2 }}>الكمية الحالية: {item.actual_stock}</div>
                    </div>
                  </div>
                ))
              })
            ) : (
              <div style={{ padding: 30, textAlign: 'center', color: 'var(--gray400)', fontSize: 13 }}>لا توجد تنبيهات مخزون منخفض حالياً</div>
            )}
          </div>
        </div>

        {/* Global Sales Chart Mock */}
        <div className="card">
          <div className="card-header"><h3 className="card-title">توزيع المبيعات حسب التصنيف</h3></div>
          <div className="card-body">
            <div style={{ height: 200, display: 'flex', alignItems: 'flex-end', gap: 20, padding: '0 20px' }}>
              {[
                { h: '80%', l: 'خضروات', c: 'var(--g500)' },
                { h: '60%', l: 'فواكه', c: 'var(--g300)' },
                { h: '30%', l: 'لحوم', c: '#ef4444' },
                { h: '45%', l: 'ألبان', c: '#3b82f6' },
              ].map((b, i) => (
                <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                  <div style={{ width: '100%', height: b.h, background: b.c, borderRadius: '8px 8px 0 0' }} />
                  <div style={{ fontSize: 10, marginTop: 8, fontWeight: 700 }}>{b.l}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

