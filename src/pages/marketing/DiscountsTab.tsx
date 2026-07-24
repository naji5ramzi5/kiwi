import { useState, useEffect } from 'react'
import { Plus, Trash2, Edit2, Copy, RefreshCw, ToggleLeft, ToggleRight } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import toast from 'react-hot-toast'
import type { Discount } from './types'
import { generateCode } from './types'

export default function DiscountsTab() {
  const [discounts, setDiscounts] = useState<Discount[]>([])
  const [discLoading, setDiscLoading] = useState(false)
  const [showDiscModal, setShowDiscModal] = useState(false)
  const [discForm, setDiscForm] = useState<Partial<Discount>>({ type: 'percent', discount_amount: 10, max_uses: 100, is_active: true })

  useEffect(() => { fetchDiscounts() }, [])

  async function fetchDiscounts() {
    setDiscLoading(true)
    try {
      const { data, error } = await supabase.from('discount_codes').select('*').order('created_at', { ascending: false })
      if (error) throw error
      setDiscounts(data || [])
    } catch { setDiscounts([]) } finally { setDiscLoading(false) }
  }

  async function saveDiscount() {
    if (!discForm.code) { toast.error('يرجى إدخال الكود أو توليده'); return }
    try {
      const payload = { code: discForm.code!.toUpperCase(), discount_amount: discForm.discount_amount || 10, type: discForm.type || 'percent', max_uses: discForm.max_uses || 100, used_count: 0, is_active: discForm.is_active ?? true, min_order_amount: discForm.min_order_amount || null, expires_at: discForm.expires_at || null }
      if (discForm.id) { const { error } = await supabase.from('discount_codes').update(payload).eq('id', discForm.id); if (error) throw error; toast.success('تم تحديث كود الخصم') }
      else { const { error } = await supabase.from('discount_codes').insert(payload); if (error) throw error; toast.success('تم إضافة كود الخصم بنجاح') }
      setShowDiscModal(false); setDiscForm({ type: 'percent', discount_amount: 10, max_uses: 100, is_active: true }); fetchDiscounts()
    } catch (err: unknown) { toast.error('خطأ: ' + ((err as Error).message || 'فشل الحفظ')) }
  }

  async function toggleDiscount(id: string, current: boolean) {
    await supabase.from('discount_codes').update({ is_active: !current }).eq('id', id)
    setDiscounts(prev => prev.map(d => d.id === id ? { ...d, is_active: !current } : d))
  }

  async function deleteDiscount(id: string) {
    if (!confirm('هل أنت متأكد من حذف هذا الكود؟')) return
    await supabase.from('discount_codes').delete().eq('id', id)
    setDiscounts(prev => prev.filter(d => d.id !== id)); toast.success('تم حذف كود الخصم')
  }

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div><h2 style={{ fontSize: 18, fontWeight: 800, color: 'var(--gray900)', margin: 0 }}>🏷️ أكواد الخصم</h2><p style={{ fontSize: 12, color: 'var(--gray500)', margin: '4px 0 0 0' }}>إنشاء وإدارة أكواد الخصم للزبائن</p></div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button className="btn btn-ghost btn-sm" onClick={fetchDiscounts}><RefreshCw size={14} /> تحديث</button>
          <button className="btn btn-primary" onClick={() => { setDiscForm({ type: 'percent', discount_amount: 10, max_uses: 100, is_active: true }); setShowDiscModal(true); }}><Plus size={16} /> كود خصم جديد</button>
        </div>
      </div>
      <div className="stats-grid" style={{ marginBottom: 24 }}>
        <div className="stat-card"><div className="stat-label">إجمالي الأكواد</div><div className="stat-value">{discounts.length}</div></div>
        <div className="stat-card"><div className="stat-label">الأكواد النشطة</div><div className="stat-value" style={{ color: 'var(--g600)' }}>{discounts.filter(d => d.is_active).length}</div></div>
        <div className="stat-card"><div className="stat-label">إجمالي الاستخدام</div><div className="stat-value">{discounts.reduce((sum, d) => sum + (d.used_count || 0), 0)}</div></div>
      </div>
      {discLoading ? (<div className="empty-state"><div className="loader"></div></div>) : discounts.length === 0 ? (
        <div className="card"><div className="empty-state"><div className="empty-icon">🏷️</div><div className="empty-text">لا توجد أكواد خصم بعد</div><button className="btn btn-primary" style={{ marginTop: 16 }} onClick={() => { setDiscForm({ type: 'percent', discount_amount: 10, max_uses: 100, is_active: true }); setShowDiscModal(true); }}><Plus size={16} /> إنشاء أول كود خصم</button></div></div>
      ) : (
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead><tr style={{ background: 'var(--gray50)', borderBottom: '1px solid var(--gray100)' }}>{['الكود', 'الخصم', 'النوع', 'الاستخدام', 'الحد الأدنى', 'الانتهاء', 'الحالة', 'إجراءات'].map(h => (<th key={h} style={{ padding: '14px 16px', textAlign: 'right', fontSize: 12, fontWeight: 700, color: 'var(--gray600)' }}>{h}</th>))}</tr></thead>
            <tbody>{discounts.map(d => (
              <tr key={d.id} style={{ borderBottom: '1px solid var(--gray50)', transition: 'background .15s' }} onMouseEnter={e => e.currentTarget.style.background = 'var(--gray50)'} onMouseLeave={e => e.currentTarget.style.background = ''}>
                <td style={{ padding: '14px 16px' }}><div style={{ display: 'flex', alignItems: 'center', gap: 8 }}><code style={{ background: 'var(--g50)', color: 'var(--g700)', padding: '4px 10px', borderRadius: 8, fontSize: 13, fontWeight: 800, letterSpacing: 1 }}>{d.code}</code><button className="btn btn-icon btn-ghost btn-sm" style={{ width: 28, height: 28 }} onClick={() => { navigator.clipboard.writeText(d.code); toast.success('تم نسخ الكود!') }}><Copy size={12} /></button></div></td>
                <td style={{ padding: '14px 16px', fontWeight: 800, fontSize: 16, color: 'var(--g600)' }}>{d.type === 'percent' ? `${d.discount_amount}%` : `${d.discount_amount?.toLocaleString('ar-IQ')} د.ع`}</td>
                <td style={{ padding: '14px 16px' }}><span className={`badge ${d.type === 'percent' ? 'badge-green' : 'badge-blue'}`}>{d.type === 'percent' ? 'نسبة %' : 'مبلغ ثابت'}</span></td>
                <td style={{ padding: '14px 16px' }}><div style={{ display: 'flex', alignItems: 'center', gap: 6 }}><div style={{ flex: 1, background: 'var(--gray100)', borderRadius: 4, height: 6, overflow: 'hidden', minWidth: 60 }}><div style={{ height: '100%', background: 'var(--g500)', width: `${Math.min(100, ((d.used_count || 0) / (d.max_uses || 1)) * 100)}%`, borderRadius: 4 }} /></div><span style={{ fontSize: 12, fontWeight: 700 }}>{d.used_count || 0}/{d.max_uses}</span></div></td>
                <td style={{ padding: '14px 16px', fontSize: 12, color: 'var(--gray500)' }}>{d.min_order_amount ? `${d.min_order_amount?.toLocaleString('ar-IQ')} د.ع` : '—'}</td>
                <td style={{ padding: '14px 16px', fontSize: 12, color: d.expires_at && new Date(d.expires_at) < new Date() ? '#ef4444' : 'var(--gray500)' }}>{d.expires_at ? new Date(d.expires_at).toLocaleDateString('ar-IQ') : '∞ دائم'}</td>
                <td style={{ padding: '14px 16px' }}><button onClick={() => toggleDiscount(d.id, d.is_active)} style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 4 }}>{d.is_active ? <ToggleRight size={24} color="#10b981" /> : <ToggleLeft size={24} color="#9ca3af" />}<span style={{ fontSize: 11, color: d.is_active ? '#10b981' : '#9ca3af', fontWeight: 700 }}>{d.is_active ? 'نشط' : 'موقوف'}</span></button></td>
                <td style={{ padding: '14px 16px' }}><div style={{ display: 'flex', gap: 6 }}><button className="btn btn-icon btn-ghost btn-sm" onClick={() => { setDiscForm(d); setShowDiscModal(true); }}><Edit2 size={14} /></button><button className="btn btn-icon btn-ghost btn-sm" onClick={() => deleteDiscount(d.id)}><Trash2 size={14} color="#ef4444" /></button></div></td>
              </tr>
            ))}</tbody>
          </table>
        </div>
      )}
      {showDiscModal && (
        <div className="modal-overlay" onClick={() => setShowDiscModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 480 }}>
            <div className="modal-title">{discForm.id ? 'تعديل كود الخصم' : 'إنشاء كود خصم جديد'}</div>
            <div className="form-group"><label className="form-label">كود الخصم *</label><div style={{ display: 'flex', gap: 8 }}><input className="form-input" style={{ flex: 1, fontFamily: 'monospace', fontWeight: 800, letterSpacing: 2, textTransform: 'uppercase' }} value={discForm.code || ''} onChange={e => setDiscForm(p => ({ ...p, code: e.target.value.toUpperCase() }))} placeholder="KIWI2025" /><button className="btn btn-outline" onClick={() => setDiscForm(p => ({ ...p, code: generateCode() }))} title="توليد كود عشوائي"><RefreshCw size={16} /></button></div></div>
            <div className="form-group"><label className="form-label">نوع الخصم</label><div style={{ display: 'flex', gap: 8 }}><button className={`btn btn-sm ${discForm.type === 'percent' ? 'btn-primary' : 'btn-outline'}`} style={{ flex: 1 }} onClick={() => setDiscForm(p => ({ ...p, type: 'percent' }))}>نسبة مئوية %</button><button className={`btn btn-sm ${discForm.type === 'fixed' ? 'btn-primary' : 'btn-outline'}`} style={{ flex: 1 }} onClick={() => setDiscForm(p => ({ ...p, type: 'fixed' }))}>مبلغ ثابت (د.ع)</button></div></div>
            <div className="grid-2" style={{ gap: 12 }}><div className="form-group"><label className="form-label">{discForm.type === 'percent' ? 'نسبة الخصم (%)' : 'مبلغ الخصم (د.ع)'}</label><input className="form-input" type="number" value={discForm.discount_amount || ''} onChange={e => setDiscForm(p => ({ ...p, discount_amount: Number(e.target.value) }))} placeholder={discForm.type === 'percent' ? '10' : '5000'} /></div><div className="form-group"><label className="form-label">الحد الأقصى للاستخدام</label><input className="form-input" type="number" value={discForm.max_uses || ''} onChange={e => setDiscForm(p => ({ ...p, max_uses: Number(e.target.value) }))} placeholder="100" /></div></div>
            <div className="grid-2" style={{ gap: 12 }}><div className="form-group"><label className="form-label">الحد الأدنى للطلب (د.ع)</label><input className="form-input" type="number" value={discForm.min_order_amount || ''} onChange={e => setDiscForm(p => ({ ...p, min_order_amount: Number(e.target.value) || undefined }))} placeholder="10000 (اختياري)" /></div><div className="form-group"><label className="form-label">تاريخ الانتهاء (اختياري)</label><input className="form-input" type="date" value={discForm.expires_at ? discForm.expires_at.split('T')[0] : ''} onChange={e => setDiscForm(p => ({ ...p, expires_at: e.target.value ? e.target.value + 'T23:59:59Z' : undefined }))} /></div></div>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 0', borderTop: '1px solid var(--gray100)', marginTop: 4 }}><span style={{ fontWeight: 700, fontSize: 14 }}>حالة الكود</span><button onClick={() => setDiscForm(p => ({ ...p, is_active: !p.is_active }))} style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6 }}>{discForm.is_active ? <ToggleRight size={28} color="#10b981" /> : <ToggleLeft size={28} color="#9ca3af" />}<span style={{ fontWeight: 700, color: discForm.is_active ? '#10b981' : '#9ca3af' }}>{discForm.is_active ? 'نشط' : 'موقوف'}</span></button></div>
            <div style={{ display: 'flex', gap: 10, marginTop: 16 }}><button className="btn btn-primary" style={{ flex: 1 }} onClick={saveDiscount}>{discForm.id ? 'حفظ التعديلات' : 'إنشاء الكود'}</button><button className="btn btn-ghost" onClick={() => setShowDiscModal(false)}>إلغاء</button></div>
          </div>
        </div>
      )}
    </div>
  )
}
