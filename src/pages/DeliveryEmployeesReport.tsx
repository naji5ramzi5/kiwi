import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { Truck, Bike, Search, Wallet, PackageCheck, User, Calendar, Database, CircleDot, Timer, ArrowUpDown, Phone, Mail, Eye } from 'lucide-react'
import toast from 'react-hot-toast'

interface EmployeeReport {
  id: string
  user_id: string
  full_name: string
  phone?: string
  email?: string
  vehicle_type?: string
  account_status?: boolean
  branch_name?: string
  online_status?: string
  is_active?: boolean
  joined_at?: string
  total_deliveries?: number
  wallet_balance?: number
  today_deliveries?: number
  month_deliveries?: number
  today_earnings?: number
  month_earnings?: number
  total_earnings?: number
  last_active_at?: string
}

type SortKey = 'joined_at' | 'total_deliveries' | 'today_earnings' | 'month_earnings' | 'total_earnings' | 'last_active_at'

const VEHICLE_LABELS: Record<string, string> = { truck: 'شاحنة', car: 'سيارة', van: 'فان', bike: 'دراجة نارية' }

export default function DeliveryEmployeesReport() {
  const [employees, setEmployees] = useState<EmployeeReport[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [branchFilter, setBranchFilter] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [vehicleFilter, setVehicleFilter] = useState('')
  const [sortKey, setSortKey] = useState<SortKey>('total_earnings')
  const [sortAsc, setSortAsc] = useState(false)
  const [selected, setSelected] = useState<EmployeeReport | null>(null)
  const [stats, setStats] = useState({ drivers: 0, active: 0, online: 0, total: 0 })

  useEffect(() => { fetchEmployees() }, [])

  async function fetchEmployees() {
    const { data, error } = await supabase.from('delivery_employees_report').select('*').order('joined_at', { ascending: false })
    if (error) { toast.error('خطأ في جلب التقرير: ' + error.message); setLoading(false); return }
    const list = (data || []) as EmployeeReport[]
    setEmployees(list)
    setStats({
      drivers: list.length,
      active: list.filter(e => e.is_active).length,
      online: list.filter(e => e.online_status === 'online').length,
      total: list.reduce((s, e) => s + (Number(e.total_deliveries) || 0), 0),
    })
    setLoading(false)
  }

  function toggleSort(key: SortKey) {
    if (sortKey === key) { setSortAsc(a => !a) } else { setSortKey(key); setSortAsc(false) }
  }

  const branches = Array.from(new Set(employees.map(e => e.branch_name).filter(Boolean))).sort() as string[]

  const filtered = employees
    .filter(e => {
      if (search) {
        const q = search.toLowerCase()
        const match =
          (e.full_name || '').toLowerCase().includes(q) ||
          (e.phone || '').includes(search) ||
          (e.branch_name || '').toLowerCase().includes(q)
        if (!match) return false
      }
      if (branchFilter && e.branch_name !== branchFilter) return false
      if (vehicleFilter && e.vehicle_type !== vehicleFilter) return false
      if (statusFilter === 'active' && !e.is_active) return false
      if (statusFilter === 'inactive' && e.is_active) return false
      if (statusFilter === 'approved' && !e.account_status) return false
      if (statusFilter === 'pending' && e.account_status) return false
      return true
    })
    .sort((a, b) => {
      const av = Number(a[sortKey] ?? 0)
      const bv = Number(b[sortKey] ?? 0)
      if (!Number.isFinite(av) || !Number.isFinite(bv)) return 0
      return sortAsc ? av - bv : bv - av
    })

  return (
    <div className="animate-in">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24, flexWrap: 'wrap', gap: 12 }}>
        <div>
          <h1 className="brand-name" style={{ fontSize: 24 }}>تقرير موظفي التوصيل</h1>
          <p className="brand-sub">ملخص حسابات موظفي التوصيل: الحالة، الفرع، الاشتراك، الأرباح</p>
        </div>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
          <div style={{ position: 'relative' }}>
            <Search size={16} style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--gray400)' }} />
            <input
              type="text"
              placeholder="بحث باسم الموظف أو الفرع..."
              className="form-input"
              style={{ paddingRight: 36, width: 200 }}
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
          </div>
          <select className="form-input" style={{ width: 160 }} value={branchFilter} onChange={e => setBranchFilter(e.target.value)}>
            <option value="">كل الفروع</option>
            {branches.map(b => <option key={b} value={b}>{b}</option>)}
          </select>
          <select className="form-input" style={{ width: 150 }} value={vehicleFilter} onChange={e => setVehicleFilter(e.target.value)}>
            <option value="">كل المركبات</option>
            <option value="truck">شاحنة</option>
            <option value="car">سيارة</option>
            <option value="van">فان</option>
            <option value="bike">دراجة نارية</option>
          </select>
          <select className="form-input" style={{ width: 150 }} value={statusFilter} onChange={e => setStatusFilter(e.target.value)}>
            <option value="">كل الحالات</option>
            <option value="active">مفعّل</option>
            <option value="inactive">موقوف</option>
            <option value="approved">مقبول</option>
            <option value="pending">بانتظار الموافقة</option>
          </select>
          <select className="form-input" style={{ width: 160 }} value={sortKey} onChange={e => toggleSort(e.target.value as SortKey)}>
            <option value="total_earnings">ترتيب: الأرباح الإجمالية</option>
            <option value="today_earnings">ترتيب: أرباح اليوم</option>
            <option value="month_earnings">ترتيب: أرباح الشهر</option>
            <option value="total_deliveries">ترتيب: التوصيلات</option>
            <option value="joined_at">ترتيب: تاريخ الانضمام</option>
            <option value="last_active_at">ترتيب: آخر نشاط</option>
          </select>
          <button className="btn btn-ghost" onClick={() => toggleSort(sortKey)} title="عكس اتجاه الترتيب" style={{ height: 40 }}>
            <ArrowUpDown size={16} /> {sortAsc ? 'تصاعدي' : 'تنازلي'}
          </button>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 16, marginBottom: 24 }}>
        <div className="card" style={{ padding: 20 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 44, height: 44, borderRadius: 12, background: 'rgba(16,185,129,.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><User size={22} color="#10b981" /></div>
            <div>
              <div style={{ fontSize: 13, color: 'var(--gray400)' }}>إجمالي الموظفين</div>
              <div style={{ fontSize: 22, fontWeight: 800, color: 'var(--gray900)' }}>{stats.drivers}</div>
            </div>
          </div>
        </div>
        <div className="card" style={{ padding: 20 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 44, height: 44, borderRadius: 12, background: 'rgba(59,130,246,.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><CircleDot size={22} color="#3b82f6" /></div>
            <div>
              <div style={{ fontSize: 13, color: 'var(--gray400)' }}>متصلون الآن</div>
              <div style={{ fontSize: 22, fontWeight: 800, color: 'var(--gray900)' }}>{stats.online}</div>
            </div>
          </div>
        </div>
        <div className="card" style={{ padding: 20 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 44, height: 44, borderRadius: 12, background: 'rgba(139,92,246,.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><PackageCheck size={22} color="#8b5cf6" /></div>
            <div>
              <div style={{ fontSize: 13, color: 'var(--gray400)' }}>إجمالي التوصيلات</div>
              <div style={{ fontSize: 22, fontWeight: 800, color: 'var(--gray900)' }}>{stats.total}</div>
            </div>
          </div>
        </div>
        <div className="card" style={{ padding: 20 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 44, height: 44, borderRadius: 12, background: 'rgba(245,158,11,.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Wallet size={22} color="#f59e0b" /></div>
            <div>
              <div style={{ fontSize: 13, color: 'var(--gray400)' }}>موظفون مفعّلون</div>
              <div style={{ fontSize: 22, fontWeight: 800, color: 'var(--gray900)' }}>{stats.active}</div>
            </div>
          </div>
        </div>
      </div>

      {loading ? (
        <div className="card" style={{ padding: 40, display: 'flex', justifyContent: 'center' }}><div className="loader"></div></div>
      ) : filtered.length === 0 ? (
        <div className="card" style={{ padding: 50, textAlign: 'center', color: 'var(--gray400)' }}>
          <User size={48} style={{ margin: '0 auto 12px', display: 'block', opacity: .4 }} />
          <div style={{ fontSize: 15, fontWeight: 700 }}>لا يوجد موظفو توصيل مسجلون بعد</div>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: 20 }}>
          {filtered.map(e => (
            <div key={e.id} className="card" style={{ padding: 0, overflow: 'hidden', cursor: 'pointer' }} onClick={() => setSelected(e)}>
              <div style={{ padding: 20, borderBottom: '1px solid var(--gray100)', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                  <div style={{ width: 52, height: 52, borderRadius: 14, background: 'var(--g50)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--g600)', border: '2px solid var(--g100)' }}>
                    {e.vehicle_type === 'truck' ? <Truck size={24} /> : <Bike size={24} />}
                  </div>
                  <div>
                    <h3 style={{ fontWeight: 800, fontSize: 16, color: 'var(--gray900)' }}>{e.full_name || 'بدون اسم'}</h3>
                    <div style={{ fontSize: 12, color: 'var(--gray400)', marginTop: 2 }}>{e.phone || e.email || 'لا يوجد هاتف'}</div>
                  </div>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6, alignItems: 'flex-end' }}>
                  <span className={`badge ${e.online_status === 'online' ? 'badge-green' : 'badge-gray'}`}>
                    {e.online_status === 'online' ? 'متصل' : 'غير متصل'}
                  </span>
                  <span style={{ color: 'var(--gray400)', fontSize: 11 }}>اضغط للتفاصيل <Eye size={11} style={{ verticalAlign: 'middle' }} /></span>
                </div>
              </div>

              <div style={{ padding: 16, display: 'flex', flexDirection: 'column', gap: 10 }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', background: 'var(--gray50)', borderRadius: 12, border: '1px solid var(--gray100)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: 'var(--gray600)' }}>
                    <Database size={16} color="var(--g600)" />
                    <span style={{ fontWeight: 700 }}>الفرع:</span>
                  </div>
                  <span style={{ fontSize: 13, fontWeight: 800, color: 'var(--gray900)' }}>{e.branch_name || 'غير محدد'}</span>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', background: 'var(--gray50)', borderRadius: 12, border: '1px solid var(--gray100)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: 'var(--gray600)' }}>
                    <Calendar size={16} color="var(--g600)" />
                    <span style={{ fontWeight: 700 }}>الانضمام:</span>
                  </div>
                  <span style={{ fontSize: 13, fontWeight: 800, color: 'var(--gray900)' }}>
                    {e.joined_at ? new Date(e.joined_at).toLocaleDateString('ar-IQ') : '-'}
                  </span>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', background: 'var(--gray50)', borderRadius: 12, border: '1px solid var(--gray100)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: 'var(--gray600)' }}>
                    <PackageCheck size={16} color="#8b5cf6" />
                    <span style={{ fontWeight: 700 }}>توصيلات اليوم / الشهر:</span>
                  </div>
                  <span style={{ fontSize: 13, fontWeight: 800, color: 'var(--gray900)' }}>
                    {e.today_deliveries ?? 0} / {e.month_deliveries ?? 0}
                  </span>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', background: 'var(--gray50)', borderRadius: 12, border: '1px solid var(--gray100)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: 'var(--gray600)' }}>
                    <Wallet size={16} color="#10b981" />
                    <span style={{ fontWeight: 700 }}>أرباح اليوم / الشهر:</span>
                  </div>
                  <span style={{ fontSize: 13, fontWeight: 800, color: '#059669' }}>
                    {(Number(e.today_earnings || 0)).toLocaleString()} / {(Number(e.month_earnings || 0)).toLocaleString()} د.ع
                  </span>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', background: 'var(--gray50)', borderRadius: 12, border: '1px solid var(--gray100)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: 'var(--gray600)' }}>
                    <Wallet size={16} color="#059669" />
                    <span style={{ fontWeight: 700 }}>إجمالي الأرباح:</span>
                  </div>
                  <span style={{ fontSize: 13, fontWeight: 800, color: '#059669' }}>{Number(e.total_earnings || 0).toLocaleString()} د.ع</span>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', background: 'var(--gray50)', borderRadius: 12, border: '1px solid var(--gray100)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: 'var(--gray600)' }}>
                    <Timer size={16} color="#3b82f6" />
                    <span style={{ fontWeight: 700 }}>آخر نشاط:</span>
                  </div>
                  <span style={{ fontSize: 13, fontWeight: 800, color: 'var(--gray900)' }}>
                    {e.last_active_at ? new Date(e.last_active_at).toLocaleString('ar-IQ') : '-'}
                  </span>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', background: 'var(--gray50)', borderRadius: 12, border: '1px solid var(--gray100)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: 'var(--gray600)' }}>
                    <Wallet size={16} color="#10b981" />
                    <span style={{ fontWeight: 700 }}>رصيد المحفظة:</span>
                  </div>
                  <span style={{ fontSize: 13, fontWeight: 800, color: '#059669' }}>{Number(e.wallet_balance || 0).toLocaleString()} د.ع</span>
                </div>

                <div style={{ display: 'flex', gap: 8 }}>
                  <span className={`badge ${e.is_active ? 'badge-green' : 'badge-gray'}`}>{e.is_active ? 'مفعّل' : 'موقوف'}</span>
                  <span className={`badge ${e.account_status ? 'badge-green' : 'badge-yellow'}`}>{e.account_status ? 'حساب مقبول' : 'بانتظار الموافقة'}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {selected && (
        <div className="modal-overlay" onClick={() => setSelected(null)}>
          <div className="modal" style={{ maxWidth: 520 }} onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
              <h3 style={{ fontSize: 18, fontWeight: 800, color: 'var(--gray900)' }}>
                ملف {selected.full_name || 'الموظف'}
              </h3>
              <button className="btn btn-ghost btn-sm" onClick={() => setSelected(null)}>×</button>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 16 }}>
              <div style={{ width: 56, height: 56, borderRadius: 16, background: 'var(--g50)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--g600)', border: '2px solid var(--g100)' }}>
                {selected.vehicle_type === 'truck' ? <Truck size={26} /> : <Bike size={26} />}
              </div>
              <div>
                <div style={{ fontWeight: 800, fontSize: 17, color: 'var(--gray900)' }}>{selected.full_name || 'بدون اسم'}</div>
                <div style={{ fontSize: 12, color: 'var(--gray400)' }}>
                  {VEHICLE_LABELS[selected.vehicle_type || ''] || 'دراجة نارية'} — {selected.branch_name || 'غير محدد'}
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                <span style={{ color: 'var(--gray400)', fontSize: 13 }}>الحالة</span>
                <span style={{ display: 'flex', gap: 6 }}>
                  <span className={`badge ${selected.online_status === 'online' ? 'badge-green' : 'badge-gray'}`}>{selected.online_status === 'online' ? 'متصل' : 'غير متصل'}</span>
                  <span className={`badge ${selected.is_active ? 'badge-green' : 'badge-gray'}`}>{selected.is_active ? 'مفعّل' : 'موقوف'}</span>
                  <span className={`badge ${selected.account_status ? 'badge-green' : 'badge-yellow'}`}>{selected.account_status ? 'مقبول' : 'بانتظار الموافقة'}</span>
                </span>
              </div>
              {selected.phone && (
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                  <span style={{ color: 'var(--gray400)', fontSize: 13 }}><Phone size={13} style={{ verticalAlign: 'middle', marginLeft: 4 }} />الهاتف</span>
                  <a href={`tel:${selected.phone}`} style={{ fontWeight: 700, color: '#10b981', direction: 'ltr' }}>{selected.phone}</a>
                </div>
              )}
              {selected.email && (
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                  <span style={{ color: 'var(--gray400)', fontSize: 13 }}><Mail size={13} style={{ verticalAlign: 'middle', marginLeft: 4 }} />البريد</span>
                  <span style={{ fontWeight: 700, direction: 'ltr' }}>{selected.email}</span>
                </div>
              )}
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                <span style={{ color: 'var(--gray400)', fontSize: 13 }}>الانضمام</span>
                <span style={{ fontWeight: 700 }}>{selected.joined_at ? new Date(selected.joined_at).toLocaleDateString('ar-IQ') : '-'}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                <span style={{ color: 'var(--gray400)', fontSize: 13 }}>آخر نشاط</span>
                <span style={{ fontWeight: 700 }}>{selected.last_active_at ? new Date(selected.last_active_at).toLocaleString('ar-IQ') : '-'}</span>
              </div>
              <div style={{ borderTop: '1px solid var(--gray100)', margin: '4px 0', paddingTop: 10 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                  <span style={{ color: 'var(--gray400)', fontSize: 13 }}>توصيلات اليوم / الشهر</span>
                  <span style={{ fontWeight: 800 }}>{selected.today_deliveries ?? 0} / {selected.month_deliveries ?? 0}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                  <span style={{ color: 'var(--gray400)', fontSize: 13 }}>أرباح اليوم / الشهر</span>
                  <span style={{ fontWeight: 800, color: '#059669' }}>{(Number(selected.today_earnings || 0)).toLocaleString()} / {(Number(selected.month_earnings || 0)).toLocaleString()} د.ع</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                  <span style={{ color: 'var(--gray400)', fontSize: 13 }}>إجمالي الأرباح</span>
                  <span style={{ fontWeight: 800, color: '#059669' }}>{Number(selected.total_earnings || 0).toLocaleString()} د.ع</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                  <span style={{ color: 'var(--gray400)', fontSize: 13 }}>رصيد المحفظة</span>
                  <span style={{ fontWeight: 800, color: '#059669' }}>{Number(selected.wallet_balance || 0).toLocaleString()} د.ع</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}