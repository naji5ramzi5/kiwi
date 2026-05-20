import { useState, useEffect } from 'react'
import { Plus, Tag, Edit2, Trash2, Image as ImageIcon, LayoutGrid, X } from 'lucide-react'
import { supabase } from '../lib/supabase'
import type { Category } from '../lib/types'

export default function Categories() {
  const [categories, setCategories] = useState<Category[]>([])
  const [loading, setLoading] = useState(true)
  const [modal, setModal] = useState<Partial<Category> | null | 'new'>(null)

  useEffect(() => {
    fetchCategories()
  }, [])

  async function fetchCategories() {
    setLoading(true)
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .order('name')
    
    if (error) console.error(error)
    else setCategories(data || [])
    setLoading(false)
  }

  async function saveCategory(form: Partial<Category>) {
    if (!form.name) return alert('يرجى إدخال اسم التصنيف')
    
    const payload = {
      name: form.name,
      image_url: form.image_url,
      icon: form.icon || 'tag'
    }

    let error
    if (form.id) {
      const { error: err } = await supabase.from('categories').update(payload).eq('id', form.id)
      error = err
    } else {
      const { error: err } = await supabase.from('categories').insert([payload])
      error = err
    }

    if (error) {
      alert('خطأ أثناء الحفظ: ' + error.message)
    } else {
      fetchCategories()
      setModal(null)
    }
  }

  async function deleteCategory(id: string) {
    if (!confirm('هل أنت متأكد؟ سيؤدي هذا لإزالة التصنيف من جميع المنتجات المرتبطة به.')) return
    const { error } = await supabase.from('categories').delete().eq('id', id)
    if (error) alert('خطأ في الحذف: ' + error.message)
    else fetchCategories()
  }

  return (
    <div className="animate-in">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h1 className="brand-name" style={{ fontSize: 24 }}>إدارة التصنيفات</h1>
          <p className="brand-sub">تحكم في فئات المنتجات التي تظهر في الواجهة الرئيسية للتطبيق</p>
        </div>
        <button className="btn btn-primary" onClick={() => setModal('new')}>
          <Plus size={18} /> إضافة تصنيف جديد
        </button>
      </div>

      {loading ? (
        <div className="empty-state"><div className="loader"></div></div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: 20 }}>
          {categories.map(cat => (
            <div key={cat.id} className="card hover-scale" style={{ padding: 0, overflow: 'hidden' }}>
              <div style={{ height: 120, background: 'var(--gray100)', position: 'relative' }}>
                {cat.image_url ? (
                  <img src={cat.image_url} alt={cat.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                ) : (
                  <div style={{ height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--gray300)' }}>
                    <ImageIcon size={32} />
                  </div>
                )}
                <div style={{ position: 'absolute', top: 12, right: 12, background: 'white', padding: 8, borderRadius: 10, boxShadow: 'var(--shadow-sm)', color: 'var(--g600)' }}>
                  <Tag size={18} />
                </div>
              </div>
              <div style={{ padding: '16px 20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ fontWeight: 800, fontSize: 16 }}>{cat.name}</div>
                <div style={{ display: 'flex', gap: 6 }}>
                  <button className="btn btn-icon btn-ghost btn-sm" onClick={() => setModal(cat)}>
                    <Edit2 size={14} />
                  </button>
                  <button className="btn btn-icon btn-ghost btn-sm" onClick={() => deleteCategory(cat.id)}>
                    <Trash2 size={14} color="#ef4444" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {modal && (
        <CategoryModal 
          category={modal === 'new' ? null : modal} 
          onClose={() => setModal(null)} 
          onSave={saveCategory} 
        />
      )}
    </div>
  )
}

function CategoryModal({ category, onClose, onSave }: any) {
  const [form, setForm] = useState({
    name: category?.name || '',
    image_url: category?.image_url || '',
    icon: category?.icon || 'tag'
  })

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal animate-in" onClick={e => e.stopPropagation()} style={{ maxWidth: 450 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
          <h2 className="modal-title" style={{ margin: 0 }}>{category ? 'تعديل التصنيف' : 'إضافة تصنيف جديد'}</h2>
          <button className="btn btn-icon btn-ghost" onClick={onClose}><X size={20} /></button>
        </div>

        <div className="form-group">
          <label className="form-label">اسم التصنيف *</label>
          <input 
            className="form-input" 
            value={form.name} 
            onChange={e => setForm({...form, name: e.target.value})} 
            placeholder="مثلاً: خضروات طازجة"
          />
        </div>

        <div className="form-group">
          <label className="form-label">رابط صورة التصنيف (URL)</label>
          <div style={{ display: 'flex', gap: 10 }}>
            <input 
              className="form-input" 
              style={{ flex: 1 }}
              value={form.image_url} 
              onChange={e => setForm({...form, image_url: e.target.value})} 
              placeholder="https://..."
            />
            {form.image_url && (
              <img src={form.image_url} style={{ width: 44, height: 44, borderRadius: 10, objectFit: 'cover' }} />
            )}
          </div>
          <p style={{ fontSize: 11, color: 'var(--gray400)', marginTop: 6 }}>يفضل استخدام صورة ذات خلفية شفافة أو نظيفة</p>
        </div>

        <div style={{ display: 'flex', gap: 12, marginTop: 24 }}>
          <button 
            className="btn btn-primary" 
            style={{ flex: 1 }} 
            onClick={() => onSave({ ...category, ...form })}
          >
            حفظ البيانات
          </button>
          <button className="btn btn-ghost" onClick={onClose}>إلغاء</button>
        </div>
      </div>
    </div>
  )
}
