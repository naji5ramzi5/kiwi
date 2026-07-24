import { useState, useEffect } from 'react'
import { Search, Phone, MapPin, ShoppingCart, Star, Users, Loader2 } from 'lucide-react'
import { supabase } from '../lib/supabase'

interface Customer {
  id: string
  full_name: string
  phone: string
  email: string
  created_at: string
}

export default function Customers() {
  const [customers, setCustomers] = useState<Customer[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [totalCount, setTotalCount] = useState(0)

  useEffect(() => {
    fetchCustomers()
  }, [])

  async function fetchCustomers() {
    try {
      setLoading(true)

      const { data, error, count } = await supabase
        .from('profiles')
        .select('id, full_name, phone, email, created_at', { count: 'exact' })
        .eq('role', 'customer')
        .order('created_at', { ascending: false })

      if (error) throw error
      setCustomers((data || []) as Customer[])
      setTotalCount(count || 0)
    } catch (err) {
      console.error('Error fetching customers:', err)
    } finally {
      setLoading(false)
    }
  }

  const filtered = customers.filter(c => {
    const name = (c.full_name || '').toLowerCase()
    const phone = (c.phone || '').toLowerCase()
    const searchStr = (search || '').toLowerCase()
    return name.includes(searchStr) || phone.includes(searchStr)
  })

  const PAGE_SIZE = 20
  const [page, setPage] = useState(0)
  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE))
  const safePage = Math.min(page, totalPages - 1)
  const paged = filtered.slice(safePage * PAGE_SIZE, (safePage + 1) * PAGE_SIZE)

  useEffect(() => { setPage(0) }, [search])

  return (
    <div>
      {/* Stats */}
      <div className="stats-grid" style={{ marginBottom: 22 }}>
        <div className="stat-card">
          <div className="stat-icon-wrap" style={{ background: '#8b5cf618' }}><Users size={22} style={{ color: '#8b5cf6' }} /></div>
          <div className="stat-label">إجمالي العملاء</div>
          <div className="stat-value">{totalCount.toLocaleString('ar-IQ')}</div>
          <div className="stat-sub">عميل مسجل</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon-wrap" style={{ background: '#22c55e18' }}><Star size={22} style={{ color: '#22c55e' }} /></div>
          <div className="stat-label">عملاء هذا الشهر</div>
          <div className="stat-value">
            {customers.filter(c => {
              const d = new Date(c.created_at)
              const now = new Date()
              return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear()
            }).length}
          </div>
          <div className="stat-sub">عميل جديد</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon-wrap" style={{ background: '#3b82f618' }}><Phone size={22} style={{ color: '#3b82f6' }} /></div>
          <div className="stat-label">عملاء لديهم هاتف</div>
          <div className="stat-value">
            {customers.filter(c => c.phone && c.phone.trim().length > 0).length}
          </div>
          <div className="stat-sub">مسجل رقم</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon-wrap" style={{ background: '#f59e0b18' }}><MapPin size={22} style={{ color: '#f59e0b' }} /></div>
          <div className="stat-label">آخر تسجيل</div>
          <div className="stat-value" style={{ fontSize: 18 }}>
            {customers.length > 0 ? new Date(customers[0].created_at).toLocaleDateString('ar-IQ') : '-'}
          </div>
          <div className="stat-sub">آخر عميل</div>
        </div>
      </div>

      {/* Search */}
      <div style={{ position: 'relative', maxWidth: 360, marginBottom: 18 }}>
        <Search size={15} style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--gray400)' }} />
        <input className="form-input" style={{ paddingRight: 36 }} placeholder="ابحث بالاسم أو الهاتف..." value={search} onChange={e => setSearch(e.target.value)} />
      </div>

      {/* Table */}
      {loading ? (
        <div className="card"><div className="empty-state"><div className="loader"></div></div></div>
      ) : (
        <div className="card">
          <div className="table-wrap">
            <table>
              <thead>
                <tr><th>#</th><th>العميل</th><th>الهاتف</th><th>البريد</th><th>انضم في</th></tr>
              </thead>
              <tbody>
                {paged.map((c, i) => (
                  <tr key={c.id}>
                    <td style={{ fontSize: 12, color: 'var(--gray400)' }}>{safePage * PAGE_SIZE + i + 1}</td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                        <div className="avatar avatar-sm">{(c.full_name || '?')[0]}</div>
                        <span style={{ fontWeight: 600, fontSize: 13 }}>{c.full_name || 'بدون اسم'}</span>
                      </div>
                    </td>
                    <td style={{ fontSize: 12, color: 'var(--gray500)', direction: 'ltr', textAlign: 'right' }}>{c.phone || '-'}</td>
                    <td style={{ fontSize: 12, color: 'var(--gray500)' }}>{c.email || '-'}</td>
                    <td style={{ fontSize: 11, color: 'var(--gray400)' }}>{new Date(c.created_at).toLocaleDateString('ar-IQ')}</td>
                  </tr>
                ))}
                {paged.length === 0 && (
                  <tr>
                    <td colSpan={5} style={{ textAlign: 'center', padding: 40, color: 'var(--gray400)' }}>
                      <Users size={36} style={{ marginBottom: 12, opacity: 0.3 }} />
                      <p>لا يوجد عملاء</p>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {filtered.length > PAGE_SIZE && (
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 16, padding: '16px 0' }}>
              <button className="btn btn-ghost btn-sm" onClick={() => setPage(p => Math.max(0, p - 1))} disabled={safePage === 0}>السابق</button>
              <span style={{ fontSize: 13, color: 'var(--gray500)' }}>صفحة {safePage + 1} من {totalPages}</span>
              <button className="btn btn-ghost btn-sm" onClick={() => setPage(p => Math.min(totalPages - 1, p + 1))} disabled={safePage >= totalPages - 1}>التالي</button>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
