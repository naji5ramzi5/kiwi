import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { PackageCheck, Calendar, Phone, Search, User, Truck, Bike, Eye, Wallet, MapPin, Pencil } from 'lucide-react'
import toast from 'react-hot-toast'

interface DeliveredOrder {
  id: string
  order_number: string
  customer_name_manual?: string
  customer_phone?: string
  delivery_address?: string
  total_amount?: number
  delivery_fee?: number
  delivered_at?: string
  proof_image?: string
  branch_name?: string
  employee_name?: string
  employee_phone?: string
  vehicle_type?: string
  employee_joined_at?: string
  delivery_earnings?: number
  area?: string
  street?: string
  building?: string
}

export default function DeliveredOrders() {
  const [orders, setOrders] = useState<DeliveredOrder[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [dates, setDates] = useState({ from: '', to: '' })
  const [branchFilter, setBranchFilter] = useState('')
  const [employeeFilter, setEmployeeFilter] = useState('')
  const [selected, setSelected] = useState<DeliveredOrder | null>(null)
  const [stats, setStats] = useState({ count: 0, earnings: 0 })
  const [editing, setEditing] = useState<DeliveredOrder | null>(null)
  const [editAmount, setEditAmount] = useState('')
  const [savingEdit, setSavingEdit] = useState(false)

  useEffect(() => { fetchOrders() }, [])

  async function saveEarnings() {
    if (!editing) return
    const amount = Number(editAmount)
    if (isNaN(amount) || amount < 0) { toast.error('أدخل مبلغاً صحيحاً'); return }
    setSavingEdit(true)
    const { error } = await supabase
      .from('delivery_earnings')
      .update({ amount })
      .eq('order_id', editing.id)
    setSavingEdit(false)
    if (error) { toast.error('فشل حفظ الربح: ' + error.message); return }
    toast.success('تم تحديث أرباح التوصيل')
    setEditing(null)
    applyFilters()
  }

  async function fetchOrders(extraFilters?: { from?: string; to?: string; branch?: string; employee?: string }) {
    setLoading(true)
    let query = supabase
      .from('delivered_orders_report')
      .select('*')
      .order('delivered_at', { ascending: false })
      .limit(500)

    if (extraFilters?.from) query = query.gte('delivered_at', new Date(extraFilters.from).toISOString())
    if (extraFilters?.to) query = query.lte('delivered_at', new Date(new Date(extraFilters.to).getTime() + 86400000).toISOString())
    if (extraFilters?.branch && extraFilters.branch !== '') query = query.eq('branch_name', extraFilters.branch)
    if (extraFilters?.employee && extraFilters.employee !== '') query = query.eq('employee_name', extraFilters.employee)

    const { data, error } = await query
    if (error) { toast.error('خطأ في جلب البيانات: ' + error.message); setLoading(false); return }
    const list = (data || []) as DeliveredOrder[]
    setOrders(list)
    setStats({
      count: list.length,
      earnings: list.reduce((s, o) => s + (Number(o.delivery_earnings) || 0), 0),
    })
    setLoading(false)
  }

  function applyFilters() {
    fetchOrders({ from: dates.from, to: dates.to, branch: branchFilter, employee: employeeFilter })
  }

  function clearFilters() {
    setDates({ from: '', to: '' })
    setSearch('')
    setBranchFilter('')
    setEmployeeFilter('')
    fetchOrders()
  }

  const branches = Array.from(new Set(orders.map(o => o.branch_name).filter(Boolean))).sort() as string[]
  const employees = Array.from(new Set(orders.map(o => o.employee_name).filter(Boolean))).sort() as string[]

  const filtered = orders.filter(o => {
    if (search) {
      const q = search.toLowerCase()
      const match =
        (o.order_number || '').toLowerCase().includes(q) ||
        (o.customer_name_manual || '').toLowerCase().includes(q) ||
        (o.employee_name || '').toLowerCase().includes(q) ||
        (o.customer_phone || '').includes(search)
      if (!match) return false
    }
    if (branchFilter && o.branch_name !== branchFilter) return false
    if (employeeFilter && o.employee_name !== employeeFilter) return false
    return true
  })

  return (
    <div className="animate-in">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24, flexWrap: 'wrap', gap: 12 }}>
        <div>
          <h1 className="brand-name" style={{ fontSize: 24 }}>الطلبات المُسلَّمة</h1>
          <p className="brand-sub">سجل الطلبات المكتملة مع صورة الإثبات وأرباح التوصيل</p>
        </div>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
          <div style={{ position: 'relative' }}>
            <Search size={16} style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--gray400)' }} />
            <input
              type="text"
              placeholder="بحث برقم الطلب أو الاسم..."
              className="form-input"
              style={{ paddingRight: 36, width: 220 }}
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
          </div>
          <input type="date" className="form-input" style={{ width: 150 }} value={dates.from} onChange={e => setDates(p => ({ ...p, from: e.target.value }))} />
          <input type="date" className="form-input" style={{ width: 150 }} value={dates.to} onChange={e => setDates(p => ({ ...p, to: e.target.value }))} />
          <select className="form-input" style={{ width: 160 }} value={branchFilter} onChange={e => setBranchFilter(e.target.value)}>
            <option value="">كل الفروع</option>
            {branches.map(b => <option key={b} value={b}>{b}</option>)}
          </select>
          <select className="form-input" style={{ width: 160 }} value={employeeFilter} onChange={e => setEmployeeFilter(e.target.value)}>
            <option value="">كل الموظفين</option>
            {employees.map(n => <option key={n} value={n}>{n}</option>)}
          </select>
          <button className="btn btn-primary" onClick={applyFilters} style={{ height: 40 }}>تصفية</button>
          <button className="btn btn-ghost" onClick={clearFilters} style={{ height: 40 }}>مسح</button>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 16, marginBottom: 24 }}>
        <div className="card" style={{ padding: 20 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 44, height: 44, borderRadius: 12, background: 'rgba(16,185,129,.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <PackageCheck size={22} color="#10b981" />
            </div>
            <div>
              <div style={{ fontSize: 13, color: 'var(--gray400)' }}>إجمالي الطلبات</div>
              <div style={{ fontSize: 22, fontWeight: 800, color: 'var(--gray900)' }}>{stats.count}</div>
            </div>
          </div>
        </div>
        <div className="card" style={{ padding: 20 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 44, height: 44, borderRadius: 12, background: 'rgba(245,158,11,.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Wallet size={22} color="#f59e0b" />
            </div>
            <div>
              <div style={{ fontSize: 13, color: 'var(--gray400)' }}>أرباح التوصيل</div>
              <div style={{ fontSize: 22, fontWeight: 800, color: 'var(--gray900)' }}>{stats.earnings.toLocaleString()} د.ع</div>
            </div>
          </div>
        </div>
      </div>

      {loading ? (
        <div className="card" style={{ padding: 40, display: 'flex', justifyContent: 'center' }}><div className="loader"></div></div>
      ) : filtered.length === 0 ? (
        <div className="card" style={{ padding: 50, textAlign: 'center', color: 'var(--gray400)' }}>
          <PackageCheck size={48} style={{ margin: '0 auto 12px', display: 'block', opacity: .4 }} />
          <div style={{ fontSize: 15, fontWeight: 700 }}>لا توجد طلبات مُسلَّمة بهذه المعايير</div>
        </div>
      ) : (
        <div style={{ overflowX: 'auto' }}>
          <table className="table">
            <thead>
              <tr>
                <th>رقم الطلب</th>
                <th>العميل</th>
                <th>الموظف</th>
                <th>الفرع</th>
                <th>تاريخ التسليم</th>
                <th>الأرباح</th>
                <th>تعديل</th>
                <th>الإثبات</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {filtered.map(o => (
                <tr key={o.id}>
                  <td><span className="badge badge-blue" style={{ fontVariantNumeric: 'tabular-nums' }}>{o.order_number}</span></td>
                  <td>
                    <div style={{ fontWeight: 700 }}>{o.customer_name_manual || '-'}</div>
                    {o.customer_phone && <div style={{ fontSize: 12, color: 'var(--gray400)' }} dir="ltr">{o.customer_phone}</div>}
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      {o.vehicle_type === 'truck' ? <Truck size={14} color="var(--gray400)" /> : <Bike size={14} color="var(--gray400)" />}
                      <span>{o.employee_name || '-'}</span>
                    </div>
                  </td>
                  <td>{o.branch_name || '-'}</td>
                  <td style={{ fontSize: 12 }}>{o.delivered_at ? new Date(o.delivered_at).toLocaleString('ar-IQ') : '-'}</td>
                  <td>
                    <span style={{ fontWeight: 800, color: '#059669' }}>{Number(o.delivery_earnings || 0).toLocaleString()}</span>
                  </td>
                  <td>
                    <button
                      className="btn btn-ghost btn-sm"
                      style={{ color: '#2563eb' }}
                      title="تعديل الربح"
                      onClick={() => { setEditing(o); setEditAmount(String(Number(o.delivery_earnings || 0))) }}
                    >
                      <Pencil size={15} />
                    </button>
                  </td>
                  <td>
                    {o.proof_image ? (
                      <button className="btn btn-ghost btn-sm" onClick={() => setSelected(o)} title="عرض صورة الإثبات">
                        <Eye size={16} />
                      </button>
                    ) : <span style={{ color: 'var(--gray300)', fontSize: 12 }}>بدون</span>}
                  </td>
                  <td>
                    <button className="btn btn-ghost btn-sm" onClick={() => setSelected(o)}>
                      <Eye size={16} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {selected && (
        <div className="modal-overlay" onClick={() => setSelected(null)}>
          <div className="modal" style={{ maxWidth: 560 }} onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
              <h3 style={{ fontSize: 18, fontWeight: 800, color: 'var(--gray900)' }}>
                تفاصيل الطلب <span className="badge badge-blue" style={{ fontVariantNumeric: 'tabular-nums' }}>{selected.order_number}</span>
              </h3>
              <button className="btn btn-ghost btn-sm" onClick={() => setSelected(null)}>×</button>
            </div>

            {selected.proof_image && (
              <div style={{ marginBottom: 16 }}>
                <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--gray600)', marginBottom: 8 }}>صورة إثبات التوصيل</div>
                <img
                  src={selected.proof_image}
                  alt="إثبات التسليم"
                  style={{ width: '100%', height: 280, objectFit: 'cover', borderRadius: 16, border: '1px solid var(--gray100)' }}
                />
              </div>
            )}

            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                <span style={{ color: 'var(--gray400)', fontSize: 13 }}>اسم العميل</span>
                <span style={{ fontWeight: 700 }}>{selected.customer_name_manual || '-'}</span>
              </div>
              {selected.customer_phone && (
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                  <span style={{ color: 'var(--gray400)', fontSize: 13 }}>هاتف العميل</span>
                  <a href={`tel:${selected.customer_phone}`} style={{ fontWeight: 700, color: '#10b981', direction: 'ltr' }}>{selected.customer_phone}</a>
                </div>
              )}
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                <span style={{ color: 'var(--gray400)', fontSize: 13 }}>العنوان</span>
                <span style={{ fontWeight: 700, textAlign: 'left', flex: 1 }}>{selected.delivery_address || '-'}</span>
              </div>
              {(selected.area || selected.street || selected.building) && (
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                  <span style={{ color: 'var(--gray400)', fontSize: 13 }}>المنطقة / الشارع / البناء</span>
                  <span style={{ fontWeight: 700, textAlign: 'left', flex: 1 }}>
                    {[selected.area, selected.street, selected.building].filter(Boolean).join(' — ')}
                  </span>
                </div>
              )}
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                <span style={{ color: 'var(--gray400)', fontSize: 13 }}>الموظف المسؤول</span>
                <span style={{ fontWeight: 700 }}>{selected.employee_name || '-'}</span>
              </div>
              {selected.employee_phone && (
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                  <span style={{ color: 'var(--gray400)', fontSize: 13 }}>هاتف الموظف</span>
                  <a href={`tel:${selected.employee_phone}`} style={{ fontWeight: 700, color: '#10b981', direction: 'ltr' }}>{selected.employee_phone}</a>
                </div>
              )}
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                <span style={{ color: 'var(--gray400)', fontSize: 13 }}>الفرع</span>
                <span style={{ fontWeight: 700 }}>{selected.branch_name || '-'}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                <span style={{ color: 'var(--gray400)', fontSize: 13 }}>تاريخ التسليم</span>
                <span style={{ fontWeight: 700 }}>{selected.delivered_at ? new Date(selected.delivered_at).toLocaleString('ar-IQ') : '-'}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                <span style={{ color: 'var(--gray400)', fontSize: 13 }}>إجمالي الطلب</span>
                <span style={{ fontWeight: 800 }}>{Number(selected.total_amount || 0).toLocaleString()} د.ع</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                <span style={{ color: 'var(--gray400)', fontSize: 13 }}>أرباح التوصيل</span>
                <span style={{ fontWeight: 800, color: '#059669' }}>{Number(selected.delivery_earnings || 0).toLocaleString()} د.ع</span>
              </div>
            </div>

            <button
              className="btn btn-primary"
              style={{ width: '100%', marginTop: 16 }}
              onClick={() => { setEditing(selected); setEditAmount(String(Number(selected.delivery_earnings || 0))) }}
            >
              <Pencil size={16} /> تعديل أرباح التوصيل
            </button>
          </div>
        </div>
      )}

      {editing && (
        <div className="modal-overlay" onClick={() => setEditing(null)}>
          <div className="modal" style={{ maxWidth: 420 }} onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
              <h3 style={{ fontSize: 18, fontWeight: 800, color: 'var(--gray900)' }}>
                تعديل الربح — <span className="badge badge-blue" style={{ fontVariantNumeric: 'tabular-nums' }}>{editing.order_number}</span>
              </h3>
              <button className="btn btn-ghost btn-sm" onClick={() => setEditing(null)}>×</button>
            </div>

            <div style={{ fontSize: 13, color: 'var(--gray400)', marginBottom: 10 }}>
              المندوب: <b>{editing.employee_name || '-'}</b> — الفرع: <b>{editing.branch_name || '-'}</b>
            </div>

            <input
              type="number" min="0" step="250"
              autoFocus
              className="form-input"
              style={{ width: '100%', fontWeight: 800, fontSize: 20, textAlign: 'center', padding: 12 }}
              value={editAmount}
              onChange={e => setEditAmount(e.target.value)}
              onKeyDown={e => { if (e.key === 'Enter') saveEarnings() }}
              placeholder="0"
            />
            <div style={{ fontSize: 12, color: 'var(--gray400)', textAlign: 'center', marginTop: 6 }}>مبلغ ربح التوصيل لهذا الطلب (د.ع)</div>

            <div style={{ display: 'flex', gap: 10, marginTop: 16 }}>
              <button className="btn btn-ghost" style={{ flex: 1 }} onClick={() => setEditing(null)}>إلغاء</button>
              <button className="btn btn-primary" style={{ flex: 1 }} disabled={savingEdit} onClick={saveEdit}>
                {savingEdit ? 'جاري الحفظ...' : 'حفظ'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}