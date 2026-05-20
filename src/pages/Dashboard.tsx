import { useState, useEffect } from 'react'
import { TrendingUp, ShoppingBag, Users, MapPin, AlertCircle, ArrowUpRight, ArrowDownRight, Package, Bell } from 'lucide-react'
import { supabase } from '../lib/supabase'
import LiveMap from '../components/LiveMap'

export default function Dashboard() {
  const [branches, setBranches] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchGlobalStats()
  }, [])

  async function fetchGlobalStats() {
    // In a real app, we would use complex joins or a database view
    const { data } = await supabase.from('branches').select('*, orders(total_amount), inventory(stock_quantity)')
    setBranches(data || [])
    setLoading(false)
  }

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
          <div className="stat-value">12.8M</div>
          <div className="stat-sub stat-up"><ArrowUpRight size={14} /> +8% عن الشهر الماضي</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon-wrap" style={{ background: '#3b82f615' }}><ShoppingBag color="#3b82f6" /></div>
          <div className="stat-label">إجمالي الطلبات</div>
          <div className="stat-value">3,450</div>
          <div className="stat-sub stat-up"><ArrowUpRight size={14} /> +12% نشاط متزايد</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon-wrap" style={{ background: '#f59e0b15' }}><Package color="#f59e0b" /></div>
          <div className="stat-label">منتجات منخفضة المخزون</div>
          <div className="stat-value">14</div>
          <div className="stat-sub stat-down"><AlertCircle size={14} /> تتطلب توريد فوراً</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon-wrap" style={{ background: '#8b5cf615' }}><Users color="#8b5cf6" /></div>
          <div className="stat-label">نشاط المناديب</div>
          <div className="stat-value">42</div>
          <div className="stat-sub">مندوب نشط الآن</div>
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
            <button className="btn btn-ghost btn-sm">تقرير مفصل</button>
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
                {[
                  { name: 'فرع الكرادة', status: 'نشط', sales: '4.2M', buy: '2.8M', stock: '85%', drivers: 12, time: 'منذ 2 دقيقة' },
                  { name: 'فرع المنصور', status: 'نشط', sales: '3.8M', buy: '2.5M', stock: '92%', drivers: 8, time: 'منذ 5 دقيقة' },
                  { name: 'فرع الزيتون', status: 'موقوف', sales: '0', buy: '0', stock: '10%', drivers: 0, time: 'منذ يومين' },
                  { name: 'فرع الكاظمية', status: 'نشط', sales: '2.1M', buy: '1.4M', stock: '76%', drivers: 6, time: 'الآن' },
                ].map((b, i) => (
                  <tr key={i}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                        <div className="avatar avatar-sm">{b.name[5]}</div>
                        <span style={{ fontWeight: 700 }}>{b.name}</span>
                      </div>
                    </td>
                    <td><span className={`badge ${b.status === 'نشط' ? 'badge-green' : 'badge-red'}`}>{b.status}</span></td>
                    <td style={{ fontWeight: 800 }}>{b.sales}</td>
                    <td style={{ color: 'var(--gray400)' }}>{b.buy}</td>
                    <td>
                      <div style={{ width: 100 }}>
                        <div className="progress-bar"><div className="progress-fill" style={{ width: b.stock }} /></div>
                      </div>
                    </td>
                    <td>{b.drivers}</td>
                    <td style={{ fontSize: 11, color: 'var(--gray400)' }}>{b.time}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Recent Alerts */}
        <div className="card">
          <div className="card-header"><h3 className="card-title">تنبيهات المنظومة</h3></div>
          <div className="card-body" style={{ padding: 0 }}>
            {[
              { type: 'danger', msg: 'مخزون (طماطم) في فرع الكرادة أقل من الحد المسموح', time: '10:45 AM' },
              { type: 'warning', msg: 'إغلاق صندوق فرع المنصور تم بتفاوت 5,000 د.ع', time: '09:20 AM' },
              { type: 'success', msg: 'تم إنشاء فرع الكاظمية بنجاح وتفعيل الحساب', time: 'أمس' },
            ].map((a, i) => (
              <div key={i} style={{ padding: '16px 20px', borderBottom: '1px solid var(--gray100)', display: 'flex', gap: 12 }}>
                <div className={`live-dot ${a.type === 'danger' ? 'red' : (a.type === 'warning' ? 'yellow' : '')}`} style={{ marginTop: 6 }} />
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 600 }}>{a.msg}</div>
                  <div style={{ fontSize: 11, color: 'var(--gray400)', marginTop: 2 }}>{a.time}</div>
                </div>
              </div>
            ))}
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
