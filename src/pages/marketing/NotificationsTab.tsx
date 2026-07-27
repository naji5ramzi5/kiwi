import { useState, useRef } from 'react'
import { Send, Image as ImageIcon, CheckCircle, Loader, Upload, X } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { FCM_FUNCTION_URL, SUPABASE_ANON_KEY } from '../../config'
import toast from 'react-hot-toast'

async function invokeEdgeFunction(body: Record<string, unknown>) {
  const res = await fetch(FCM_FUNCTION_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
    },
    body: JSON.stringify(body),
  })
  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: res.statusText }))
    throw new Error(err.error || 'Failed to send')
  }
  return res.json()
}

export default function NotificationsTab() {
  const [notifTitle, setNotifTitle] = useState('')
  const [notifBody, setNotifBody] = useState('')
  const [notifImage, setNotifImage] = useState('')
  const [notifTarget, setNotifTarget] = useState<'all' | 'driver' | 'single'>('all')
  const [notifPhone, setNotifPhone] = useState('')
  const [sending, setSending] = useState(false)
  const [sent, setSent] = useState(false)
  const [uploading, setUploading] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  async function handleImageUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    if (file.size > 5 * 1024 * 1024) {
      toast.error('حجم الصورة يجب أن يكون أقل من 5 ميجابايت')
      return
    }
    setUploading(true)
    try {
      const ext = file.name.split('.').pop() || 'png'
      const path = `notifications/${Date.now()}.${ext}`
      const { error: uploadError } = await supabase.storage
        .from('kiwi_images')
        .upload(path, file, { contentType: file.type, upsert: true })
      if (uploadError) throw uploadError
      const { data: urlData } = supabase.storage.from('kiwi_images').getPublicUrl(path)
      setNotifImage(urlData.publicUrl)
      toast.success('تم رفع الصورة بنجاح')
    } catch (err: unknown) {
      toast.error('خطأ في رفع الصورة: ' + ((err as Error).message || String(err)))
    } finally {
      setUploading(false)
      if (fileInputRef.current) fileInputRef.current.value = ''
    }
  }

  async function sendNotif() {
    if (!notifTitle || !notifBody) { toast.error('يرجى ملء عنوان ونص الإشعار'); return }
    setSending(true)
    try {
      const payload: Record<string, unknown> = { title: notifTitle, body: notifBody, data: notifImage ? { image: notifImage } : {} }
      if (notifTarget === 'all') {
        await invokeEdgeFunction({ ...payload, broadcast: true })
        toast.success('تم إرسال الإشعار بنجاح لجميع الأجهزة!')
      } else if (notifTarget === 'driver') {
        const { data: drivers, error: dErr } = await supabase.from('profiles').select('id').eq('role', 'driver')
        if (dErr) throw dErr
        if (!drivers || drivers.length === 0) { toast.error('لا يوجد مناديب مسجلين'); setSending(false); return }
        const results = await Promise.all(drivers.map(d => invokeEdgeFunction({ ...payload, userId: d.id }).then(() => true).catch(() => false)))
        const successCount = results.filter(Boolean).length
        if (successCount > 0) {
          toast.success(`تم إرسال الإشعار بنجاح لـ ${successCount} مندوب!`)
        } else {
          throw new Error('فشلت جميع محاولات إرسال الإشعارات')
        }
      } else {
        const { data: user, error: uErr } = await supabase.from('profiles').select('id').eq('phone', notifPhone).single()
        if (uErr || !user) { toast.error('لم يتم العثور على مستخدم بهذا الرقم'); setSending(false); return }
        await invokeEdgeFunction({ ...payload, userId: user.id })
        toast.success('تم إرسال الإشعار بنجاح!')
      }
      setSent(true)
      setNotifTitle(''); setNotifBody(''); setNotifImage(''); setNotifPhone('')
      setTimeout(() => setSent(false), 4000)
    } catch (err: unknown) {
      toast.error('خطأ في إرسال الإشعار: ' + ((err as Error).message || String(err)))
    } finally {
      setSending(false)
    }
  }

  return (
    <div className="grid-2">
      <div className="card">
        <div className="card-header"><span className="card-title">📤 إرسال إشعار متقدم (Push)</span></div>
        <div className="card-body">
          {sent && (
            <div style={{ background: '#ecfdf5', border: '1px solid #a7f3d0', borderRadius: 10, padding: '12px 16px', marginBottom: 18, color: '#047857', fontWeight: 700, fontSize: 13, display: 'flex', alignItems: 'center', gap: 8 }}>
              <CheckCircle size={18} /> تم إرسال الإشعار بنجاح لجميع الأجهزة!
            </div>
          )}
          <div className="form-group">
            <label className="form-label">الجمهور المستهدف</label>
            <div style={{ display: 'flex', gap: 8 }}>
              {[{ v: 'all', l: '👥 الجميع' }, { v: 'driver', l: '🚗 المناديب فقط' }, { v: 'single', l: '👤 مستخدم محدد' }].map(o => (
                <button key={o.v} onClick={() => setNotifTarget(o.v as typeof notifTarget)}
                  className={notifTarget === o.v ? 'btn btn-primary btn-sm' : 'btn btn-outline btn-sm'}
                  style={{ flex: 1, fontSize: 12, fontWeight: 600 }}>{o.l}</button>
              ))}
            </div>
          </div>
          {notifTarget === 'single' && (
            <div className="form-group">
              <label className="form-label">رقم الهاتف (لإشعار شخصي)</label>
              <input className="form-input" value={notifPhone} onChange={e => setNotifPhone(e.target.value)} placeholder="07xxxxxxxxx" />
            </div>
          )}
          <div className="form-group">
            <label className="form-label">عنوان الإشعار *</label>
            <input className="form-input" value={notifTitle} onChange={e => setNotifTitle(e.target.value)} placeholder="مثال: 🍅 خضروات طازجة وصلت للتو!" />
          </div>
          <div className="form-group">
            <label className="form-label">نص الإشعار *</label>
            <textarea className="form-textarea" rows={3} value={notifBody} onChange={e => setNotifBody(e.target.value)} placeholder="اكتب تفاصيل الإشعار هنا..." />
          </div>
          <div className="form-group">
            <label className="form-label">صورة مرفقة (اختياري)</label>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              <div style={{ position: 'relative', flex: 1 }}>
                <ImageIcon size={16} style={{ position: 'absolute', right: 12, top: 12, color: 'var(--gray400)' }} />
                <input className="form-input" style={{ paddingRight: 36 }} value={notifImage} onChange={e => setNotifImage(e.target.value)} placeholder="رابط الصورة (URL) أو ارفع صورة" />
              </div>
              <input ref={fileInputRef} type="file" accept="image/*" onChange={handleImageUpload} style={{ display: 'none' }} />
              <button
                className="btn btn-outline btn-sm"
                onClick={() => fileInputRef.current?.click()}
                disabled={uploading}
                style={{ height: 40, minWidth: 40, padding: '0 12px', display: 'flex', alignItems: 'center', gap: 6 }}
              >
                {uploading ? <Loader size={16} className="spin" /> : <Upload size={16} />}
                {uploading ? 'جاري الرفع...' : 'رفع صورة'}
              </button>
            </div>
            {notifImage && (
              <div style={{ marginTop: 10, borderRadius: 8, overflow: 'hidden', border: '1px solid var(--gray200)', height: 120, background: 'var(--gray50)', position: 'relative' }}>
                <img src={notifImage} alt="preview" style={{ width: '100%', height: '100%', objectFit: 'cover' }} onError={(e) => (e.currentTarget.style.display = 'none')} />
                <button
                  onClick={() => setNotifImage('')}
                  style={{ position: 'absolute', top: 6, left: 6, background: 'rgba(0,0,0,0.6)', border: 'none', borderRadius: '50%', width: 24, height: 24, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', color: 'white' }}
                >
                  <X size={14} />
                </button>
              </div>
            )}
          </div>
          <button className="btn btn-primary" style={{ width: '100%', height: 44, fontSize: 14 }} onClick={sendNotif} disabled={sending}>
            {sending ? <><Loader size={18} className="spin" /> جاري الإرسال...</> : <><Send size={18} /> إرسال الإشعار الآن</>}
          </button>
        </div>
      </div>

      <div className="card">
        <div className="card-header"><span className="card-title">📱 معاينة الإشعار</span></div>
        <div className="card-body" style={{ background: 'linear-gradient(135deg, #f0fdf4, #ecfdf5)', display: 'flex', justifyContent: 'center', alignItems: 'center', padding: 40, borderRadius: '0 0 16px 16px' }}>
          <div style={{ background: 'white', width: 320, borderRadius: 16, boxShadow: '0 10px 25px rgba(0,0,0,.12)', overflow: 'hidden' }}>
            <div style={{ padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 8, borderBottom: '1px solid var(--gray50)', background: '#f8fafc' }}>
              <img src="/kiwi-logo.jpg" alt="Kiwi" style={{ width: 24, height: 24, borderRadius: 6, objectFit: 'cover' }} />
              <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--g700)' }}>Kiwi App</span>
              <span style={{ fontSize: 10, color: 'var(--gray400)', marginRight: 'auto' }}>الآن</span>
            </div>
            {notifImage && <img src={notifImage} style={{ width: '100%', height: 140, objectFit: 'cover' }} alt="notif" />}
            <div style={{ padding: '14px 16px' }}>
              <div style={{ fontWeight: 800, fontSize: 14, color: '#111', marginBottom: 4 }}>{notifTitle || 'عنوان الإشعار يظهر هنا'}</div>
              <div style={{ fontSize: 12, color: 'var(--gray600)', lineHeight: 1.6 }}>{notifBody || 'محتوى الإشعار وتفاصيل العرض تظهر في هذا الجزء بشكل واضح للمستخدم.'}</div>
            </div>
          </div>
        </div>
        <div style={{ padding: '0 24px 24px' }}>
          <div style={{ fontSize: 13, fontWeight: 700, marginBottom: 12, color: 'var(--gray700)' }}>🚀 قوالب سريعة</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {[
              { title: '🍅 خضروات طازجة وصلت!', body: 'وصلنا اليوم بأحدث وأطيب خضروات موسم الصيف. اطلب الآن وستصلك خلال 45 دقيقة 🌿' },
              { title: '⚡ عرض اليوم فقط 30%', body: 'خصم استثنائي على جميع الفواكه اليوم فقط! لا تفوت الفرصة واطلب الآن 🎉' },
              { title: '🚚 توصيل مجاني اليوم', body: 'استمتع بتوصيل مجاني لجميع الطلبات فوق 10,000 دينار اليوم فقط!' },
            ].map((tmpl, i) => (
              <button key={i} onClick={() => { setNotifTitle(tmpl.title); setNotifBody(tmpl.body) }}
                style={{ textAlign: 'right', padding: '10px 14px', background: 'var(--gray50)', border: '1px solid var(--gray100)', borderRadius: 10, cursor: 'pointer', fontSize: 12, fontWeight: 600, color: 'var(--gray700)', transition: 'all .2s' }}
                onMouseEnter={e => e.currentTarget.style.background = 'var(--g50)'}
                onMouseLeave={e => e.currentTarget.style.background = 'var(--gray50)'}>
                {tmpl.title}
              </button>
            ))}
          </div>
        </div>
      </div>
      <style>{`.spin { animation: spin 1s linear infinite; } @keyframes spin { from{transform:rotate(0)} to{transform:rotate(360deg)} }`}</style>
    </div>
  )
}
