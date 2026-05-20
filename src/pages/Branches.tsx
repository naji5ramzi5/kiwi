import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus, MapPin, Users, ShoppingCart, TrendingUp, Edit2, Key, Shield, ShieldOff, Search, Printer, Leaf } from 'lucide-react'
import { supabase } from '../lib/supabase'
import ZoneMap from '../components/ZoneMap'

interface Branch {
  id: string;
  name: string;
  address: string;
  city: string;
  phone: string;
  status: 'نشط' | 'موقوف' | 'مؤقت';
  location_url?: string;
  latitude?: number;
  longitude?: number;
  created_at: string;
  access_code?: string;
  orders_count?: number;
  sales_sum?: number;
  drivers_count?: number;
}

const STATUS_CLASS: Record<string, string> = { 'نشط': 'badge-green', 'موقوف': 'badge-red', 'مؤقت': 'badge-yellow' }

export default function Branches() {
  const navigate = useNavigate()
  const [branches, setBranches] = useState<Branch[]>([])
  const [loading, setLoading] = useState(true)
  const [modal, setModal] = useState<Partial<Branch> | null | 'new'>(null)
  const [search, setSearch] = useState('')
  const [showCert, setShowCert] = useState<Branch | null>(null)

  useEffect(() => {
    fetchBranches()
  }, [])

  async function fetchBranches() {
    setLoading(true)
    const { data, error } = await supabase
      .from('branches')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (error) console.error('Error:', error)
    else setBranches(data || [])
    setLoading(false)
  }

  async function saveBranch(form: Partial<Branch>) {
    setLoading(true)
    try {
      if (form.id) {
        const { error } = await supabase.from('branches').update(form).eq('id', form.id)
        if (error) throw error
      } else {
        const code = form.access_code || ('FR-' + Math.random().toString(36).substring(2, 7).toUpperCase())
        const { error } = await supabase.from('branches').insert([{ ...form, access_code: code }])
        if (error) throw error
      }
      fetchBranches()
      setModal(null)
      alert('تم حفظ الفرع وتوليد رمز التفعيل بنجاح! 🎉')
    } catch (err: any) {
      console.error('Error saving branch:', err)
      alert('فشل في حفظ الفرع: ' + (err.message || 'خطأ غير معروف'))
    } finally {
      setLoading(false)
    }
  }

  async function toggleStatus(id: string, current: string) {
    const next = current === 'نشط' ? 'موقوف' : 'نشط'
    setBranches(prev => prev.map(b => b.id === id ? { ...b, status: next as any } : b))
    const { error } = await supabase.from('branches').update({ status: next }).eq('id', id)
    if (error) fetchBranches()
  }

  const filtered = branches.filter(b => b.name.includes(search))

  return (
    <div className="animate-in">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h1 className="brand-name" style={{ fontSize: 24 }}>إدارة الفروع</h1>
          <p className="brand-sub">تحكم في فروع "فرش" وحسابات المديرين من هنا</p>
        </div>
        <div style={{ display: 'flex', gap: 12 }}>
          <div className="icon-btn" style={{ width: 'auto', padding: '0 16px', gap: 8 }}>
            <Search size={16} />
            <input 
              placeholder="بحث عن فرع..." 
              style={{ border: 'none', outline: 'none', background: 'transparent', fontSize: 13, width: 150 }}
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
          </div>
          <button className="btn btn-primary" onClick={() => setModal('new')}>
            <Plus size={18} /> إضافة فرع جديد
          </button>
        </div>
      </div>

      {/* Stats Summary */}
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon-wrap" style={{ background: 'var(--g50)' }}><MapPin className="text-emerald-500" /></div>
          <div className="stat-label">الفروع النشطة</div>
          <div className="stat-value">{branches.filter(b => b.status === 'نشط').length}</div>
          <div className="stat-sub">من أصل {branches.length} فروع</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon-wrap" style={{ background: '#3b82f615' }}><ShoppingCart className="text-blue-500" /></div>
          <div className="stat-label">إجمالي الطلبات اليوم</div>
          <div className="stat-value">0</div>
          <div className="stat-sub stat-up"><TrendingUp size={12} /> +0% عن أمس</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon-wrap" style={{ background: '#8b5cf615' }}><TrendingUp className="text-purple-500" /></div>
          <div className="stat-label">مبيعات الفروع</div>
          <div className="stat-value">0</div>
          <div className="stat-sub">د.ع</div>
        </div>
      </div>

      {/* Branches List */}
      {loading ? (
        <div className="empty-state"><div className="loader"></div></div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))', gap: 20 }}>
          {filtered.map(branch => (
            <div key={branch.id} className="card hover-scale" style={{ padding: 0 }}>
              <div style={{ padding: 20, borderBottom: '1px solid var(--gray100)', display: 'flex', gap: 16 }}>
                <div className="brand-icon" style={{ width: 48, height: 48, flexShrink: 0 }}>
                  <MapPin size={24} color="white" />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
                    <h3 style={{ fontWeight: 800, fontSize: 16 }}>{branch.name}</h3>
                    <span className={`badge ${STATUS_CLASS[branch.status]}`}>{branch.status}</span>
                  </div>
                  <div style={{ fontSize: 12, color: 'var(--gray500)', display: 'flex', alignItems: 'center', gap: 4, marginBottom: 4 }}>
                    <MapPin size={12} /> {branch.address}
                  </div>
                  <div style={{ fontSize: 11, color: 'var(--g700)', fontWeight: 700, background: 'var(--g50)', padding: '2px 8px', borderRadius: 6, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                    <Key size={10} /> رمز التفعيل: {branch.access_code || '---'}
                  </div>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  <button className="btn btn-icon btn-ghost btn-sm" onClick={() => setModal(branch)}>
                    <Edit2 size={14} />
                  </button>
                  <button 
                    className={`btn btn-icon btn-sm ${branch.status === 'نشط' ? 'btn-danger' : 'btn-outline'}`}
                    onClick={() => toggleStatus(branch.id, branch.status)}
                  >
                    {branch.status === 'نشط' ? <ShieldOff size={14} /> : <Shield size={14} />}
                  </button>
                </div>
              </div>

              {/* Stats - ZERO FOR NEW BRANCHES */}
              <div style={{ padding: '16px 20px', display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12, background: 'var(--gray50)' }}>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: 18, fontWeight: 800 }}>{branch.orders_count || 0}</div>
                  <div style={{ fontSize: 10, color: 'var(--gray400)' }}>طلب</div>
                </div>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: 18, fontWeight: 800 }}>{branch.drivers_count || 0}</div>
                  <div style={{ fontSize: 10, color: 'var(--gray400)' }}>مندوب</div>
                </div>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: 18, fontWeight: 800 }}>{(branch.sales_sum || 0).toLocaleString('ar-IQ')}</div>
                  <div style={{ fontSize: 10, color: 'var(--gray400)' }}>مبيعات</div>
                </div>
              </div>

              <div style={{ padding: '16px 20px', borderTop: '1px solid var(--gray100)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <div className="avatar avatar-sm">M</div>
                  <div style={{ fontSize: 12 }}>
                    <div style={{ fontWeight: 700 }}>مدير الفرع</div>
                    <div style={{ color: 'var(--gray400)' }}>{branch.phone}</div>
                  </div>
                </div>
                <div style={{ display: 'flex', gap: 6 }}>
                  <button className="btn btn-ghost btn-sm" style={{ padding: '4px 10px' }} onClick={() => setShowCert(branch)}>
                    <Key size={12} /> وثيقة التفعيل
                  </button>
                  <button className="btn btn-outline btn-sm" style={{ padding: '4px 10px' }} onClick={() => navigate(`/branches/${branch.id}`)}>
                    <TrendingUp size={12} /> الإحصائيات
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Save/Edit Modal */}
      {modal && (
        <div className="modal-overlay" onClick={() => setModal(null)}>
          <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 480 }}>
            <h2 className="modal-title">{modal === 'new' ? 'إضافة فرع جديد' : 'تعديل بيانات الفرع'}</h2>
            <div className="form-group">
              <label className="form-label">اسم الفرع *</label>
              <input className="form-input" id="b_name" defaultValue={modal === 'new' ? '' : (modal as Branch).name} />
            </div>
            <div className="form-group">
              <label className="form-label">رقم الهاتف</label>
              <input className="form-input" id="b_phone" defaultValue={modal === 'new' ? '' : (modal as Branch).phone} />
            </div>
            <div className="form-group">
              <label className="form-label">عنوان الفرع بالتفصيل</label>
              <textarea className="form-textarea" id="b_address" defaultValue={modal === 'new' ? '' : (modal as Branch).address} />
            </div>

            <div className="form-group">
              <label className="form-label">رمز تفعيل الفرع (اتركه فارغاً للتوليد التلقائي)</label>
              <input className="form-input" id="b_access_code" placeholder="مثلاً: 1234" defaultValue={modal === 'new' ? '' : (modal as Branch).access_code} />
            </div>

            <div className="form-group">
              <label className="form-label">رابط موقع الفرع (Google Maps)</label>
              <input className="form-input" id="b_location_url" placeholder="https://maps.google.com/..." defaultValue={modal === 'new' ? '' : (modal as Branch).location_url} />
              <p style={{ fontSize: 10, color: 'var(--gray400)', marginTop: 4 }}>الصق الرابط هنا وسيتم تحديد الموقع تلقائياً على الخريطة ✨</p>
            </div>

            <div className="form-group">
              <label className="form-label">مناطق التوصيل (رسم الزونات)</label>
              <ZoneMap 
                center={[(modal as Branch).latitude || 33.3152, (modal as Branch).longitude || 44.3661]} 
                zones={(modal as any).delivery_zones || []}
                onZonesChange={(newZones) => setModal(modal === 'new' ? { delivery_zones: newZones } as any : { ...modal, delivery_zones: newZones } as any)}
              />
              <p style={{ fontSize: 10, color: 'var(--gray400)', marginTop: 4 }}>استخدم الأدوات في أعلى يمين الخريطة لرسم مناطق التوصيل المسموحة لهذا الفرع.</p>
            </div>

            <div style={{ display: 'flex', gap: 12, marginTop: 20 }}>
              <button className="btn btn-primary" style={{ flex: 1 }} onClick={() => {
                const name = (document.getElementById('b_name') as HTMLInputElement).value;
                const phone = (document.getElementById('b_phone') as HTMLInputElement).value;
                const address = (document.getElementById('b_address') as HTMLTextAreaElement).value;
                const location_url = (document.getElementById('b_location_url') as HTMLInputElement).value;
                const access_code = (document.getElementById('b_access_code') as HTMLInputElement).value;
                const delivery_zones = (modal as any).delivery_zones || [];
                
                let latitude = (modal as Branch).latitude || 33.3152;
                let longitude = (modal as Branch).longitude || 44.3661;
                
                const regex = /@(-?\d+\.\d+),(-?\d+\.\d+)/;
                const match = location_url.match(regex);
                if (match) {
                  latitude = parseFloat(match[1]);
                  longitude = parseFloat(match[2]);
                }

                const isNew = modal === 'new' || !(modal as any).id;
                saveBranch({ 
                  ...(isNew ? {} : modal as Branch), 
                  name, phone, address, location_url, access_code, 
                  latitude, longitude, status: 'نشط', city: 'بغداد',
                  delivery_zones 
                });
              }}>حفظ بيانات الفرع</button>
              <button className="btn btn-ghost" onClick={() => setModal(null)}>إلغاء</button>
            </div>
          </div>
        </div>
      )}

      {/* Activation Document Modal */}
      {showCert && (
        <div className="modal-overlay no-print" style={{ background: 'rgba(0,0,0,0.85)', zIndex: 2000 }} onClick={() => setShowCert(null)}>
          <div className="modal animate-in" onClick={e => e.stopPropagation()} style={{ maxWidth: 700, padding: 0, background: 'white', borderRadius: 16, overflow: 'hidden' }}>
            <div className="printable-cert" style={{ padding: '40px', direction: 'rtl' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '3px solid #10b981', paddingBottom: 20, marginBottom: 30 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <Leaf size={32} color="#10b981" />
                  <h1 style={{ fontSize: 22, fontWeight: 900, margin: 0 }}>FRESH ENTERPRISE</h1>
                </div>
                <div style={{ textAlign: 'left' }}>
                  <div style={{ fontSize: 12, color: '#999' }}>{new Date().toLocaleDateString('ar-IQ')}</div>
                </div>
              </div>
              <div style={{ textAlign: 'center', marginBottom: 30 }}>
                <h2 style={{ fontSize: 28, fontWeight: 900 }}>وثيقة تفعيل الفرع</h2>
              </div>
              <div style={{ background: '#f9fafb', padding: 25, borderRadius: 15, marginBottom: 30 }}>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
                  <div><label style={{ fontSize: 12, color: '#999' }}>الفرع:</label><div style={{ fontSize: 18, fontWeight: 700 }}>{showCert.name}</div></div>
                  <div><label style={{ fontSize: 12, color: '#999' }}>الموقع:</label><div style={{ fontSize: 16, fontWeight: 700 }}>{showCert.address}</div></div>
                  <div style={{ gridColumn: 'span 2', textAlign: 'center', borderTop: '1px dashed #ccc', paddingTop: 20 }}>
                    <label style={{ fontSize: 14, fontWeight: 700 }}>رمز التفعيل ( Activation Key )</label>
                    <div style={{ fontSize: 48, fontWeight: 900, color: '#059669', letterSpacing: 5, padding: 15, background: 'white', borderRadius: 10, border: '2px solid #10b981', marginTop: 10 }}>
                      {showCert.access_code}
                    </div>
                  </div>
                </div>
              </div>
              <div style={{ fontSize: 13, color: '#666', lineHeight: 1.8 }}>
                <b>تعليمات:</b> أدخل هذا الرمز في تطبيق الكاشير لمرة واحدة فقط لربط الجهاز بالفرع.
              </div>
            </div>
            <div className="no-print" style={{ padding: 15, background: '#f1f5f9', display: 'flex', gap: 10 }}>
              <button className="btn btn-primary" style={{ flex: 1 }} onClick={() => window.print()}><Printer size={16}/> طباعة</button>
              <button className="btn btn-ghost" onClick={() => setShowCert(null)}>إغلاق</button>
            </div>
          </div>
          <style>{`@media print {.no-print {display:none;} body {padding:0; margin:0;} .modal {max-width:none; width:100%; border:none;}}`}</style>
        </div>
      )}
    </div>
  )
}
