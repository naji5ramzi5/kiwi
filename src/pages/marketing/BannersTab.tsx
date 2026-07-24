import { useState, useEffect } from 'react'
import { Plus, Trash2, Edit2, Link } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import toast from 'react-hot-toast'
import type { Banner } from './types'

export default function BannersTab() {
  const [banners, setBanners] = useState<Banner[]>([])
  const [showBannerModal, setShowBannerModal] = useState(false)
  const [currentBanner, setCurrentBanner] = useState<Partial<Banner>>({})

  useEffect(() => { fetchBanners() }, [])

  async function fetchBanners() {
    try {
      const { data, error } = await supabase
        .from('banners').select('*').order('created_at', { ascending: false })
      if (error) throw error
      setBanners((data || []).map(d => {
        let title = 'بنر إعلاني'; let parsedValue = d.link_value;
        try {
          if (d.link_value?.startsWith('{')) {
            const parsed = JSON.parse(d.link_value);
            title = parsed.title || title; parsedValue = parsed.value || '';
          }
        } catch {
          // ignore parse errors
        }
        return { id: d.id, title, imageUrl: d.image_url, linkType: d.link_type, linkValue: parsedValue || '', active: d.is_active };
      }))
    } catch { toast.error('فشل جلب البنرات') }
  }

  async function handleSaveBanner() {
    if (!currentBanner.title || !currentBanner.imageUrl) return
    try {
      const encodedLinkValue = JSON.stringify({ title: currentBanner.title, value: currentBanner.linkValue || '' })
      const payload = { image_url: currentBanner.imageUrl, link_type: currentBanner.linkType || 'none', link_value: encodedLinkValue, is_active: currentBanner.active ?? true }
      if (currentBanner.id) {
        const { error } = await supabase.from('banners').update(payload).eq('id', currentBanner.id)
        if (error) throw error
      } else {
        const { error } = await supabase.from('banners').insert(payload)
        if (error) throw error
      }
      toast.success('تم حفظ البنر بنجاح'); setShowBannerModal(false); fetchBanners()
    } catch (err: unknown) { toast.error('خطأ: ' + ((err as Error).message)) }
  }

  async function handleDeleteBanner(id: string) {
    if (!confirm('تأكيد الحذف؟')) return
    try { const { error } = await supabase.from('banners').delete().eq('id', id); if (error) throw error; toast.success('تم حذف البنر'); fetchBanners() }
    catch (err: unknown) { toast.error('خطأ: ' + ((err as Error).message)) }
  }

  async function toggleBannerActive(id: string, current: boolean) {
    try { const { error } = await supabase.from('banners').update({ is_active: !current }).eq('id', id); if (error) throw error; fetchBanners() }
    catch (err: unknown) { toast.error('خطأ: ' + ((err as Error).message)) }
  }

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ fontSize: 18, fontWeight: 800, color: 'var(--gray900)', margin: 0 }}>البنرات الإعلانية</h2>
          <p style={{ fontSize: 12, color: 'var(--gray500)', margin: '4px 0 0 0' }}>صور متحركة أعلى الشاشة الرئيسية للتطبيق</p>
        </div>
        <button className="btn btn-primary" onClick={() => { setCurrentBanner({ linkType: 'none', active: true }); setShowBannerModal(true); }}>
          <Plus size={16} /> إضافة بنر
        </button>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: 16 }}>
        {banners.map(b => (
          <div key={b.id} className="card hover-scale" style={{ padding: 0, overflow: 'hidden', opacity: b.active ? 1 : 0.55 }}>
            <div style={{ height: 160, background: 'var(--gray100)', position: 'relative' }}>
              <img src={b.imageUrl} alt={b.title} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
              <div style={{ position: 'absolute', top: 10, right: 10 }}>
                <label className="toggle"><input type="checkbox" checked={b.active} onChange={() => toggleBannerActive(b.id, b.active)} /><span className="toggle-slider" /></label>
              </div>
              {b.active && <div style={{ position: 'absolute', bottom: 8, left: 8, background: '#10b981', color: 'white', fontSize: 10, fontWeight: 700, padding: '2px 8px', borderRadius: 20 }}>نشط</div>}
            </div>
            <div style={{ padding: '16px' }}>
              <div style={{ fontWeight: 800, fontSize: 15, marginBottom: 4, color: 'var(--gray900)' }}>{b.title}</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: 'var(--gray500)', marginBottom: 12 }}>
                <Link size={12} />{b.linkType === 'none' ? 'بدون رابط' : b.linkType === 'external' ? 'رابط خارجي' : 'منتج داخل التطبيق'}
              </div>
              <div style={{ display: 'flex', gap: 8 }}>
                <button className="btn btn-outline btn-sm" style={{ flex: 1 }} onClick={() => { setCurrentBanner(b); setShowBannerModal(true); }}><Edit2 size={14} /> تعديل</button>
                <button className="btn btn-icon btn-ghost btn-sm" onClick={() => handleDeleteBanner(b.id)}><Trash2 size={16} style={{ color: '#ef4444' }} /></button>
              </div>
            </div>
          </div>
        ))}
      </div>
      {showBannerModal && (
        <div className="modal-overlay" onClick={() => setShowBannerModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 500 }}>
            <div className="modal-title">{currentBanner.id ? 'تعديل البنر' : 'إضافة بنر جديد'}</div>
            <div className="form-group"><label className="form-label">عنوان البنر</label><input className="form-input" value={currentBanner.title || ''} onChange={e => setCurrentBanner(p => ({ ...p, title: e.target.value }))} placeholder="مثال: خصم الفواكه" /></div>
            <div className="form-group"><label className="form-label">صورة البنر (الرابط)</label><input className="form-input" value={currentBanner.imageUrl || ''} onChange={e => setCurrentBanner(p => ({ ...p, imageUrl: e.target.value }))} placeholder="https://..." />{currentBanner.imageUrl && <img src={currentBanner.imageUrl} alt="" style={{ width: '100%', height: 100, objectFit: 'cover', borderRadius: 8, marginTop: 8 }} />}</div>
            <div className="form-group"><label className="form-label">نوع الرابط عند الضغط</label><select className="form-select" value={currentBanner.linkType || 'none'} onChange={e => setCurrentBanner(p => ({ ...p, linkType: e.target.value as Banner['linkType'], linkValue: '' }))}><option value="none">صورة فقط</option><option value="external">رابط خارجي</option><option value="product">منتج داخل التطبيق</option></select></div>
            {currentBanner.linkType !== 'none' && (<div className="form-group"><label className="form-label">{currentBanner.linkType === 'external' ? 'الرابط الخارجي' : 'معرف المنتج (Product ID)'}</label><input className="form-input" value={currentBanner.linkValue || ''} onChange={e => setCurrentBanner(p => ({ ...p, linkValue: e.target.value }))} /></div>)}
            <div style={{ display: 'flex', gap: 10, marginTop: 24 }}><button className="btn btn-primary" style={{ flex: 1 }} onClick={handleSaveBanner}>حفظ البنر</button><button className="btn btn-ghost" onClick={() => setShowBannerModal(false)}>إلغاء</button></div>
          </div>
        </div>
      )}
    </div>
  )
}
