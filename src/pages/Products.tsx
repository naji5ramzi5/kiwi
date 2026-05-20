import { useState, useEffect } from 'react'
import { Plus, Search, Edit2, Trash2, Package, Image as ImageIcon, MapPin, X } from 'lucide-react'
import { supabase } from '../lib/supabase'
import type { Category, Branch } from '../lib/types'

const UNITS = ['كيلو', 'حبة', 'كرتونة', 'ربطة', 'كيس', 'غرام']

export default function Products() {
  const [products, setProducts] = useState<any[]>([])
  const [categories, setCategories] = useState<Category[]>([])
  const [branches, setBranches] = useState<Branch[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [catFilter, setCatFilter] = useState('الكل')
  const [modal, setModal] = useState<any | null | 'new'>(null)

  useEffect(() => {
    fetchData()
  }, [])

  async function fetchData() {
    setLoading(true)
    try {
      console.log('Fetching products data...')
      const [pRes, cRes, bRes] = await Promise.all([
        supabase.from('products').select('*, branch_inventory(branch_id, actual_stock)').order('created_at', { ascending: false }),
        supabase.from('categories').select('*').order('name'),
        supabase.from('branches').select('*').order('name')
      ])

      if (pRes.error) { console.error('Products Error:', pRes.error); throw pRes.error; }
      if (cRes.error) { console.error('Categories Error:', cRes.error); throw cRes.error; }
      if (bRes.error) { console.error('Branches Error:', bRes.error); throw bRes.error; }

      console.log('Data loaded:', { products: pRes.data?.length, categories: cRes.data?.length, branches: bRes.data?.length })
      setProducts(pRes.data || [])
      setCategories(cRes.data || [])
      setBranches(bRes.data || [])
    } catch (err) {
      console.error('Final Fetch Error:', err)
    } finally {
      setLoading(false)
    }
  }

  async function removeProduct(id: string) {
    if (!confirm('هل أنت متأكد من حذف هذا المنتج من الكتالوج المركزي؟')) return
    const { error } = await supabase.from('products').delete().eq('id', id)
    if (error) alert('فشل الحذف: ' + error.message)
    else fetchData()
  }

  const filtered = (products || []).filter(p => {
    if (!p) return false;
    const nameStr = (p.name || '').toLowerCase()
    const searchStr = (search || '').toLowerCase()
    const matchSearch = nameStr.includes(searchStr)
    const matchCat = catFilter === 'الكل' || p.category === catFilter
    return matchSearch && matchCat
  })

  return (
    <div className="animate-in">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h1 className="brand-name" style={{ fontSize: 24 }}>الكتالوج المركزي</h1>
          <p className="brand-sub">إدارة بطاقات المنتجات وتحديد الفروع المتاحة</p>
        </div>
        <button className="btn btn-primary" onClick={() => setModal('new')}>
          <Plus size={18} /> إضافة منتج جديد
        </button>
      </div>

      {/* Filters */}
      <div style={{ display: 'flex', gap: 12, marginBottom: 24, flexWrap: 'wrap' }}>
        <div className="icon-btn" style={{ flex: 1, maxWidth: 300, gap: 8, padding: '0 16px' }}>
          <Search size={16} />
          <input 
            placeholder="بحث في الكتالوج..." 
            style={{ border: 'none', outline: 'none', background: 'transparent', flex: 1, fontSize: 13 }}
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
        <div style={{ display: 'flex', gap: 6, overflowX: 'auto', paddingBottom: 4 }}>
          {['الكل', ...categories.map(c => c.name)].map(c => (
            <button 
              key={c} 
              onClick={() => setCatFilter(c)}
              className={catFilter === c ? 'btn btn-primary btn-sm' : 'btn btn-ghost btn-sm'}
            >
              {c}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <div className="empty-state"><div className="loader"></div></div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: 20 }}>
          {filtered && filtered.map(product => {
            if (!product) return null;
            // حساب المخزون بأمان
            const inv = product.branch_inventory || [];
            const totalStock = inv.reduce((acc: number, item: any) => acc + (parseFloat(item.actual_stock) || 0), 0);
            
            return (
              <div key={product.id} className="card hover-scale" style={{ padding: 0 }}>
                <div style={{ height: 150, background: 'var(--gray100)', position: 'relative' }}>
                  {product.image_url ? (
                    <img src={product.image_url} alt={product.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                  ) : (
                    <div style={{ height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--gray400)' }}>
                      <ImageIcon size={40} />
                    </div>
                  )}
                  <div style={{ position: 'absolute', top: 12, right: 12, background: 'white', padding: '4px 10px', borderRadius: 8, fontSize: 11, fontWeight: 800, boxShadow: 'var(--shadow-sm)' }}>
                     {product.unit}
                  </div>
                  {product.is_offer && (
                    <div style={{ position: 'absolute', top: 12, left: 12, background: '#ef4444', color: 'white', padding: '4px 10px', borderRadius: 8, fontSize: 11, fontWeight: 800 }}>
                      عرض 🔥
                    </div>
                  )}
                </div>

                <div style={{ padding: 20 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <h3 style={{ fontWeight: 800, fontSize: 16, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{product.name}</h3>
                      <span style={{ fontSize: 11, color: 'var(--g600)', background: 'var(--g50)', padding: '2px 8px', borderRadius: 6, fontWeight: 700 }}>{product.category}</span>
                    </div>
                    <div style={{ textAlign: 'left', flexShrink: 0 }}>
                      <div style={{ fontSize: 18, fontWeight: 900 }}>{(product.default_price || 0).toLocaleString('ar-IQ')}</div>
                      <div style={{ fontSize: 10, color: 'var(--gray400)' }}>د.ع</div>
                    </div>
                  </div>

                  <div style={{ marginBottom: 16, padding: '8px 12px', background: 'var(--gray50)', borderRadius: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div style={{ fontSize: 11, color: 'var(--gray500)' }}>إجمالي المخزون:</div>
                    <div style={{ fontWeight: 800, color: totalStock <= 0 ? '#ef4444' : 'var(--g700)' }}>{totalStock} {product.unit}</div>
                  </div>

                  <div style={{ display: 'flex', gap: 8 }}>
                    <button className="btn btn-outline btn-sm" style={{ flex: 1 }} onClick={() => setModal(product)}>
                      <Edit2 size={14} /> تعديل
                    </button>
                    <button className="btn btn-icon btn-ghost btn-sm" onClick={() => removeProduct(product.id)}>
                      <Trash2 size={14} color="#ef4444" />
                    </button>
                  </div>
                </div>
              </div>
            )
          })}
          {filtered.length === 0 && !loading && (
            <div style={{ gridColumn: '1 / -1', textAlign: 'center', padding: 60, color: 'var(--gray400)' }}>
              <Package size={48} style={{ marginBottom: 16, opacity: 0.2 }} />
              <p>لا توجد منتجات مطابقة للبحث</p>
            </div>
          )}
        </div>
      )}

      {modal && (
        <ProductCatalogModal 
          product={modal === 'new' ? null : modal} 
          categories={categories}
          branches={branches}
          onClose={() => setModal(null)}
          onSave={() => { setModal(null); fetchData(); }}
        />
      )}
    </div>
  )
}

function ProductCatalogModal({ product, categories, branches, onClose, onSave }: any) {
  const [loading, setLoading] = useState(false)
  const [form, setForm] = useState({
    name: product?.name || '',
    category: product?.category || (categories[0]?.name || ''),
    unit: product?.unit || 'كيلو',
    default_price: product?.default_price || 0,
    image_url: product?.image_url || '',
    allowed_branches: product?.allowed_branches || [],
    is_active: product?.is_active ?? true,
    is_offer: product?.is_offer || false
  })

  const toggleBranch = (bid: string) => {
    const current = form.allowed_branches || []
    const next = current.includes(bid) ? current.filter((id: string) => id !== bid) : [...current, bid]
    setForm({...form, allowed_branches: next})
  }

  async function handleSubmit() {
    if (!form.name || form.default_price <= 0) return alert('يرجى إكمال البيانات')
    setLoading(true)
    try {
      if (product?.id) {
        await supabase.from('products').update(form).eq('id', product.id)
      } else {
        await supabase.from('products').insert([form])
      }
      onSave()
    } catch (err: any) {
      alert('خطأ: ' + err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal animate-in" onClick={e => e.stopPropagation()} style={{ maxWidth: 550 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
          <h2 className="modal-title" style={{ margin: 0 }}>بطاقة منتج (كتالوج)</h2>
          <button className="btn btn-icon btn-ghost" onClick={onClose}><X size={20} /></button>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          <div className="form-group">
            <label className="form-label">اسم المنتج *</label>
            <input className="form-input" value={form.name} onChange={e => setForm({...form, name: e.target.value})} />
          </div>
          <div className="form-group">
            <label className="form-label">التصنيف</label>
            <select className="form-select" value={form.category} onChange={e => setForm({...form, category: e.target.value})}>
              {categories.map((c: any) => <option key={c.id} value={c.name}>{c.name}</option>)}
            </select>
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          <div className="form-group">
            <label className="form-label">السعر الافتراضي (د.ع)</label>
            <input className="form-input" type="number" value={form.default_price} onChange={e => setForm({...form, default_price: +e.target.value})} />
          </div>
          <div className="form-group">
            <label className="form-label">وحدة القياس</label>
            <select className="form-select" value={form.unit} onChange={e => setForm({...form, unit: e.target.value})}>
              {UNITS.map(u => <option key={u} value={u}>{u}</option>)}
            </select>
          </div>
        </div>

        <div className="form-group">
          <label className="form-label">رابط الصورة</label>
          <input className="form-input" value={form.image_url} onChange={e => setForm({...form, image_url: e.target.value})} placeholder="https://..." />
        </div>

        <div className="form-group" style={{ marginBottom: 24 }}>
          <label className="form-label" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <span><Package size={16} /> الفروع المسموح لها</span>
            <div style={{ display: 'flex', gap: 6 }}>
              <button type="button" className="btn btn-ghost btn-sm" style={{ fontSize: 10 }} onClick={() => setForm({...form, allowed_branches: branches.map(b => b.id)})}>تحديد الكل</button>
              <button type="button" className="btn btn-ghost btn-sm" style={{ fontSize: 10 }} onClick={() => setForm({...form, allowed_branches: []})}>مسح</button>
            </div>
          </label>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginTop: 8 }}>
            {branches.map((b: any) => (
              <button 
                key={b.id}
                onClick={() => toggleBranch(b.id)}
                className={(form.allowed_branches || []).includes(b.id) ? 'btn btn-primary btn-sm' : 'btn btn-outline btn-sm'}
              >
                {b.name}
              </button>
            ))}
          </div>
        </div>

        <div style={{ display: 'flex', gap: 12 }}>
          <button className="btn btn-primary" style={{ flex: 1 }} onClick={handleSubmit} disabled={loading}>
            {loading ? 'جاري الحفظ...' : 'حفظ بطاقة المنتج'}
          </button>
          <button className="btn btn-ghost" onClick={onClose}>إلغاء</button>
        </div>
      </div>
    </div>
  )
}
