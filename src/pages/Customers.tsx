import { useState } from 'react'
import { Search, Eye, Phone, MapPin, ShoppingCart, Star } from 'lucide-react'

interface Customer {
  id: number; name: string; phone: string; address: string;
  orders: number; totalSpent: number; joined: string; lastOrder: string;
}

const CUSTOMERS: Customer[] = [
  { id: 1, name: 'أحمد محمد الكعبي', phone: '07801234567', address: 'الكرادة، ش 14 رمضان', orders: 23, totalSpent: 425000, joined: '2024-01-15', lastOrder: 'اليوم' },
  { id: 2, name: 'سارة عبدالله الحسيني', phone: '07709876543', address: 'الزيتون، حي النهضة', orders: 17, totalSpent: 312000, joined: '2024-02-20', lastOrder: 'أمس' },
  { id: 3, name: 'محمد علي العبيدي', phone: '07811234567', address: 'الرشيد، مقابل الجسر', orders: 8, totalSpent: 145000, joined: '2024-03-10', lastOrder: '3 أيام' },
  { id: 4, name: 'فاطمة كاظم الموسوي', phone: '07712345678', address: 'الكرادة، حي العمال', orders: 31, totalSpent: 587000, joined: '2023-12-01', lastOrder: 'اليوم' },
  { id: 5, name: 'يوسف إبراهيم الجبوري', phone: '07801111222', address: 'المنصور، خلف البنك', orders: 12, totalSpent: 218000, joined: '2024-01-30', lastOrder: '5 أيام' },
  { id: 6, name: 'رنا أحمد الراوي', phone: '07709999888', address: 'الكرادة، ش الفلسطين', orders: 5, totalSpent: 89000, joined: '2024-04-05', lastOrder: 'أسبوع' },
  { id: 7, name: 'عمر حسين الشمري', phone: '07811111333', address: 'الزيتون، قرب السوق', orders: 19, totalSpent: 356000, joined: '2024-02-14', lastOrder: 'أمس' },
]

export default function Customers() {
  const [search, setSearch] = useState('')
  const filtered = CUSTOMERS.filter(c => c.name.includes(search) || c.phone.includes(search))
  const totalSpent = CUSTOMERS.reduce((a, c) => a + c.totalSpent, 0)
  const avgOrders = Math.round(CUSTOMERS.reduce((a, c) => a + c.orders, 0) / CUSTOMERS.length)

  return (
    <div>
      {/* Stats */}
      <div className="stats-grid" style={{ marginBottom: 22 }}>
        <div className="stat-card">
          <div className="stat-icon-wrap" style={{ background: '#8b5cf618' }}><Star size={22} style={{ color: '#8b5cf6' }} /></div>
          <div className="stat-label">إجمالي العملاء</div>
          <div className="stat-value">1,427</div>
          <div className="stat-sub stat-up">+37 هذا الأسبوع</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon-wrap" style={{ background: '#22c55e18' }}><ShoppingCart size={22} style={{ color: '#22c55e' }} /></div>
          <div className="stat-label">متوسط الطلبات / عميل</div>
          <div className="stat-value">{avgOrders}</div>
          <div className="stat-sub">طلب</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon-wrap" style={{ background: '#3b82f618' }}><Phone size={22} style={{ color: '#3b82f6' }} /></div>
          <div className="stat-label">عملاء نشطون هذا الأسبوع</div>
          <div className="stat-value">284</div>
          <div className="stat-sub stat-up">+12%</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon-wrap" style={{ background: '#f59e0b18' }}><MapPin size={22} style={{ color: '#f59e0b' }} /></div>
          <div className="stat-label">متوسط الإنفاق / عميل</div>
          <div className="stat-value">{Math.round(totalSpent / CUSTOMERS.length / 1000)}k</div>
          <div className="stat-sub">د.ع</div>
        </div>
      </div>

      {/* Search */}
      <div style={{ position: 'relative', maxWidth: 360, marginBottom: 18 }}>
        <Search size={15} style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--gray400)' }} />
        <input className="form-input" style={{ paddingRight: 36 }} placeholder="ابحث بالاسم أو الهاتف..." value={search} onChange={e => setSearch(e.target.value)} />
      </div>

      {/* Table */}
      <div className="card">
        <div className="table-wrap">
          <table>
            <thead>
              <tr><th>#</th><th>العميل</th><th>الهاتف</th><th>العنوان</th><th>الطلبات</th><th>إجمالي الإنفاق</th><th>آخر طلب</th><th>انضم في</th></tr>
            </thead>
            <tbody>
              {filtered.map((c, i) => (
                <tr key={c.id}>
                  <td style={{ fontSize: 12, color: 'var(--gray400)' }}>{i + 1}</td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <div className="avatar avatar-sm">{c.name[0]}</div>
                      <span style={{ fontWeight: 600, fontSize: 13 }}>{c.name}</span>
                    </div>
                  </td>
                  <td style={{ fontSize: 12, color: 'var(--gray500)', direction: 'ltr', textAlign: 'right' }}>{c.phone}</td>
                  <td style={{ fontSize: 12 }}><MapPin size={11} style={{ display: 'inline', marginLeft: 3, color: 'var(--gray400)' }} />{c.address}</td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <ShoppingCart size={12} style={{ color: 'var(--g500)' }} />
                      <span style={{ fontWeight: 700, color: 'var(--gray900)' }}>{c.orders}</span>
                    </div>
                  </td>
                  <td style={{ fontWeight: 700, color: 'var(--g700)' }}>{c.totalSpent.toLocaleString('ar-IQ')} <span style={{ fontSize: 10, fontWeight: 400 }}>د.ع</span></td>
                  <td>
                    <span className={`badge ${c.lastOrder === 'اليوم' ? 'badge-green' : c.lastOrder === 'أمس' ? 'badge-blue' : 'badge-gray'}`} style={{ fontSize: 10 }}>
                      {c.lastOrder}
                    </span>
                  </td>
                  <td style={{ fontSize: 11, color: 'var(--gray400)' }}>{c.joined}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
