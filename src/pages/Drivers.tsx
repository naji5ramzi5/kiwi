import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { UserCheck, UserX, Truck, Bike, ShieldCheck, ShieldAlert, CreditCard, User, Star, Search } from 'lucide-react'
import toast from 'react-hot-toast'

interface Driver {
  id: string; full_name: string; email: string; vehicle_type: string;
  is_approved: boolean; is_online: boolean; plate_number?: string;
  avatar_url?: string; avg_rating?: number; total_ratings?: number;
}

export default function Drivers() {
  const [drivers, setDrivers] = useState<Driver[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')

  useEffect(() => { fetchDrivers() }, [])

  async function fetchDrivers() {
    const { data, error } = await supabase.from('profiles').select('*').eq('role', 'driver')
    if (error) { toast.error('خطأ في جلب البيانات'); setLoading(false); return }
    const driversWithRatings = await Promise.all((data || []).map(async (d) => {
      const { data: ratingData } = await supabase.from('driver_ratings').select('rating').eq('driver_id', d.id)
      const ratings = (ratingData || []) as { rating: number }[]
      const avg = ratings.length > 0 ? ratings.reduce((s, r) => s + r.rating, 0) / ratings.length : 0
      return { ...d, avg_rating: Math.round(avg * 10) / 10, total_ratings: ratings.length }
    }))
    setDrivers(driversWithRatings)
    setLoading(false)
  }

  async function toggleApproval(id: string, currentStatus: boolean) {
    const { error } = await supabase.from('profiles').update({ is_approved: !currentStatus }).eq('id', id)
    if (error) toast.error('فشلت العملية')
    else { toast.success(currentStatus ? 'تم إلغاء التفعيل' : 'تم تفعيل حساب المندوب'); fetchDrivers() }
  }

  return (
    <div className="animate-in">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h1 className="brand-name" style={{ fontSize: 24 }}>إدارة فريق التوصيل</h1>
          <p className="brand-sub">مراجعة ملفات المناديب والموافقة على طلبات الانضمام</p>
        </div>
        <div style={{ position: 'relative' }}>
          <Search size={16} style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--gray400)' }} />
          <input
            type="text"
            placeholder="بحث بالاسم..."
            className="form-input"
            style={{ paddingRight: 36, width: 220 }}
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: 20 }}>
        {drivers.filter(d => !search || d.full_name?.includes(search) || d.email?.includes(search)).map((driver) => (
          <div key={driver.id} className="card" style={{ padding: 0, overflow: 'hidden' }}>
            <div style={{ padding: 20, borderBottom: '1px solid var(--gray100)', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                <div style={{ position: 'relative' }}>
                  {driver.avatar_url ? (
                    <img src={driver.avatar_url} style={{ width: 56, height: 56, borderRadius: 14, objectFit: 'cover', border: '2px solid var(--g100)' }} alt={driver.full_name} />
                  ) : (
                    <div style={{ width: 56, height: 56, borderRadius: 14, background: 'var(--g50)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--g600)', border: '2px solid var(--g100)' }}>
                      <User size={26} />
                    </div>
                  )}
                  <div style={{ position: 'absolute', bottom: -2, right: -2, width: 16, height: 16, borderRadius: '50%', border: '3px solid white', background: driver.is_online ? '#10b981' : '#9ca3af' }} />
                </div>
                <div>
                  <h3 style={{ fontWeight: 800, fontSize: 16, color: 'var(--gray900)' }}>{driver.full_name}</h3>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'var(--gray400)', marginTop: 4 }}>
                    {driver.vehicle_type === 'truck' ? <Truck size={14} /> : <Bike size={14} />}
                    <span style={{ fontSize: 12, fontWeight: 700 }}>{driver.vehicle_type === 'truck' ? 'شاحنة خضار' : 'دراجة نارية'}</span>
                  </div>
                </div>
              </div>
              <span className={`badge ${driver.is_online ? 'badge-green' : 'badge-gray'}`}>
                {driver.is_online ? 'متصل' : 'غير متصل'}
              </span>
            </div>

            <div style={{ padding: 16, display: 'flex', flexDirection: 'column', gap: 10 }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', background: 'var(--gray50)', borderRadius: 12, border: '1px solid var(--gray100)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: 'var(--gray600)' }}>
                  <CreditCard size={16} style={{ color: 'var(--g600)' }} />
                  <span style={{ fontWeight: 700 }}>رقم اللوحة:</span>
                </div>
                <span style={{ fontSize: 13, fontWeight: 800, color: 'var(--gray900)' }}>{driver.plate_number || 'غير مسجل'}</span>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', background: 'var(--gray50)', borderRadius: 12, border: '1px solid var(--gray100)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: 'var(--gray600)' }}>
                  {driver.is_approved ? <ShieldCheck size={16} style={{ color: '#10b981' }} /> : <ShieldAlert size={16} style={{ color: '#f59e0b' }} />}
                  <span style={{ fontWeight: 700 }}>حالة الاعتماد:</span>
                </div>
                <span style={{ fontSize: 13, fontWeight: 800, color: driver.is_approved ? '#059669' : '#d97706' }}>
                  {driver.is_approved ? 'حساب معتمد' : 'بانتظار المراجعة'}
                </span>
              </div>

              {(driver.total_ratings ?? 0) > 0 && (
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', background: 'var(--gray50)', borderRadius: 12, border: '1px solid var(--gray100)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: 'var(--gray600)' }}>
                    <Star size={16} style={{ color: '#f59e0b' }} />
                    <span style={{ fontWeight: 700 }}>التقييم:</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <div style={{ display: 'flex', gap: 2 }}>
                      {Array.from({ length: 5 }, (_, i) => (
                        <Star key={i} size={14} style={{ color: i < Math.round(driver.avg_rating ?? 0) ? '#f59e0b' : '#e5e7eb', fill: i < Math.round(driver.avg_rating ?? 0) ? '#f59e0b' : 'none' }} />
                      ))}
                    </div>
                    <span style={{ fontSize: 13, fontWeight: 800, color: 'var(--gray900)' }}>{driver.avg_rating?.toFixed(1)}</span>
                    <span style={{ fontSize: 11, color: 'var(--gray400)' }}>({driver.total_ratings})</span>
                  </div>
                </div>
              )}
            </div>

            <div style={{ padding: '0 20px 20px' }}>
              <button
                onClick={() => toggleApproval(driver.id, driver.is_approved)}
                className={driver.is_approved ? 'btn btn-danger' : 'btn btn-primary'}
                style={{ width: '100%', height: 44, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}
              >
                {driver.is_approved ? <UserX size={18} /> : <UserCheck size={18} />}
                {driver.is_approved ? 'إلغاء الاعتماد' : 'الموافقة على الانضمام'}
              </button>
            </div>
          </div>
        ))}
      </div>

      {drivers.length === 0 && !loading && (
        <div className="empty-state" style={{ padding: '80px 20px', textAlign: 'center' }}>
          <div style={{ width: 80, height: 80, borderRadius: '50%', background: 'var(--gray100)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 16px' }}>
            <User size={36} style={{ color: 'var(--gray300)' }} />
          </div>
          <p style={{ color: 'var(--gray400)', fontWeight: 700 }}>لا يوجد طلبات انضمام حالياً</p>
        </div>
      )}
    </div>
  )
}
