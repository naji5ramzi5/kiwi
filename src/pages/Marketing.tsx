import { useState, useEffect } from 'react'
import { Send, Bell, Image as ImageIcon, Tag, Megaphone, Plus, Trash2, Edit2, Link, Video, Type, CheckCircle, Loader, ToggleLeft, ToggleRight, Copy, RefreshCw } from 'lucide-react'
import { supabase } from '../lib/supabase'
import toast from 'react-hot-toast'

// --- Types ---
interface Banner { 
  id: string; title: string; imageUrl: string; 
  linkType: 'none' | 'external' | 'product'; linkValue: string; active: boolean 
}
interface StoryItem {
  id: string; type: 'image' | 'video' | 'text'; url?: string;
  textContent?: string; bgColor?: string; duration: number;
}
interface StoryGroup { 
  id: string; title: string; thumbnailUrl: string; items: StoryItem[]; active: boolean 
}
interface Discount { 
  id: string; code: string; discount_amount: number; type: 'percent' | 'fixed';
  max_uses: number; used_count: number; is_active: boolean; expires_at?: string;
  min_order_amount?: number; created_at: string;
}

type Tab = 'notifications' | 'banners' | 'stories' | 'discounts'

// Initialize Empty instead of mock
const BANNERS_INIT: Banner[] = []
const STORIES_INIT: StoryGroup[] = []

// Generate random discount code
function generateCode(prefix = 'FRESH') {
  return `${prefix}${Math.random().toString(36).substring(2, 7).toUpperCase()}`
}

export default function Marketing() {
  const [tab, setTab] = useState<Tab>('notifications')

  // Banners & Stories (State)
  const [banners, setBanners] = useState<Banner[]>(BANNERS_INIT)
  const [stories, setStories] = useState<StoryGroup[]>(STORIES_INIT)
  const [loadingMedia, setLoadingMedia] = useState(false)

  // Notification form
  const [notifTitle, setNotifTitle] = useState('')
  const [notifBody, setNotifBody] = useState('')
  const [notifImage, setNotifImage] = useState('')
  const [notifTarget, setNotifTarget] = useState<'all' | 'driver' | 'single'>('all')
  const [notifPhone, setNotifPhone] = useState('')
  const [sending, setSending] = useState(false)
  const [sent, setSent] = useState(false)

  // Banner form
  const [showBannerModal, setShowBannerModal] = useState(false)
  const [currentBanner, setCurrentBanner] = useState<Partial<Banner>>({})

  // Story Form
  const [showStoryModal, setShowStoryModal] = useState(false)
  const [currentStory, setCurrentStory] = useState<Partial<StoryGroup>>({})

  // Discounts
  const [discounts, setDiscounts] = useState<Discount[]>([])
  const [discLoading, setDiscLoading] = useState(false)
  const [showDiscModal, setShowDiscModal] = useState(false)
  const [discForm, setDiscForm] = useState<Partial<Discount>>({
    type: 'percent', discount_amount: 10, max_uses: 100, is_active: true
  })

  useEffect(() => {
    if (tab === 'discounts') fetchDiscounts()
    if (tab === 'banners') fetchBanners()
    if (tab === 'stories') fetchStories()
  }, [tab])

  // ─── Fetch Banners from Supabase ───
  async function fetchBanners() {
    setLoadingMedia(true)
    try {
      const { data, error } = await supabase
        .from('banners')
        .select('*')
        .order('created_at', { ascending: false })
      if (error) throw error
      
      setBanners((data || []).map(d => {
        let title = 'بنر إعلاني';
        let parsedValue = d.link_value;
        try {
          if (d.link_value?.startsWith('{')) {
             const parsed = JSON.parse(d.link_value);
             title = parsed.title || title;
             parsedValue = parsed.value || '';
          }
        } catch(e) {}
        return {
          id: d.id,
          title: title,
          imageUrl: d.image_url,
          linkType: d.link_type,
          linkValue: parsedValue || '',
          active: d.is_active
        };
      }))
    } catch (err: any) {
      toast.error('فشل جلب البنرات')
    } finally {
      setLoadingMedia(false)
    }
  }

  // ─── Fetch Stories from Supabase ───
  async function fetchStories() {
    setLoadingMedia(true)
    try {
      const { data: groupsData, error: groupsErr } = await supabase
        .from('story_groups')
        .select('*')
        .order('created_at', { ascending: false })
      if (groupsErr) throw groupsErr
      
      if (!groupsData || groupsData.length === 0) {
        setStories([]);
        return;
      }
      
      const { data: itemsData, error: itemsErr } = await supabase
        .from('story_items')
        .select('*')
        .in('group_id', groupsData.map(g => g.id))
      if (itemsErr) throw itemsErr
      
      const parsedStories: StoryGroup[] = groupsData.map(g => {
        const gItems = (itemsData || []).filter(i => i.group_id === g.id).map(i => ({
          id: i.id,
          type: i.media_type,
          url: i.media_url,
          textContent: i.text_content,
          bgColor: i.bg_color,
          duration: i.duration
        } as StoryItem));
        
        return {
          id: g.id,
          title: g.title,
          thumbnailUrl: g.thumbnail_url,
          active: g.is_active,
          items: gItems
        };
      })
      setStories(parsedStories)
    } catch (err: any) {
      toast.error('فشل جلب القصص')
    } finally {
      setLoadingMedia(false)
    }
  }

  // ─── Fetch Discounts from Supabase ───
  async function fetchDiscounts() {
    setDiscLoading(true)
    try {
      const { data, error } = await supabase
        .from('discount_codes')
        .select('*')
        .order('created_at', { ascending: false })
      if (error) throw error
      setDiscounts(data || [])
    } catch (err: any) {
      // Table might not exist yet
      setDiscounts([])
    } finally {
      setDiscLoading(false)
    }
  }

  async function saveDiscount() {
    if (!discForm.code) { toast.error('يرجى إدخال الكود أو توليده'); return }
    try {
      const payload = {
        code: discForm.code!.toUpperCase(),
        discount_amount: discForm.discount_amount || 10,
        type: discForm.type || 'percent',
        max_uses: discForm.max_uses || 100,
        used_count: 0,
        is_active: discForm.is_active ?? true,
        min_order_amount: discForm.min_order_amount || null,
        expires_at: discForm.expires_at || null,
      }
      if (discForm.id) {
        const { error } = await supabase.from('discount_codes').update(payload).eq('id', discForm.id)
        if (error) throw error
        toast.success('تم تحديث كود الخصم ✅')
      } else {
        const { error } = await supabase.from('discount_codes').insert(payload)
        if (error) throw error
        toast.success('تم إضافة كود الخصم بنجاح 🎉')
      }
      setShowDiscModal(false)
      setDiscForm({ type: 'percent', discount_amount: 10, max_uses: 100, is_active: true })
      fetchDiscounts()
    } catch (err: any) {
      toast.error('خطأ: ' + (err.message || 'فشل الحفظ'))
    }
  }

  async function toggleDiscount(id: string, current: boolean) {
    await supabase.from('discount_codes').update({ is_active: !current }).eq('id', id)
    setDiscounts(prev => prev.map(d => d.id === id ? { ...d, is_active: !current } : d))
  }

  async function deleteDiscount(id: string) {
    if (!confirm('هل أنت متأكد من حذف هذا الكود؟')) return
    await supabase.from('discount_codes').delete().eq('id', id)
    setDiscounts(prev => prev.filter(d => d.id !== id))
    toast.success('تم حذف كود الخصم')
  }

  // ─── Send Push Notification via Supabase Edge Function ───
  async function sendNotif() {
    if (!notifTitle || !notifBody) { toast.error('يرجى ملء عنوان ونص الإشعار'); return }
    setSending(true)
    try {
      // 1. Query users with active tokens on client-side
      let profilesQuery = supabase.from('profiles').select('id, role, phone').not('fcm_token', 'is', null)
      if (notifTarget === 'driver') {
        profilesQuery = profilesQuery.eq('role', 'driver')
      } else if (notifTarget === 'single') {
        profilesQuery = profilesQuery.eq('phone', notifPhone)
      }
      const { data: pData, error: pError } = await profilesQuery
      if (pError) throw pError

      const { data: tData, error: tError } = await supabase.from('user_fcm_tokens').select('user_id, device_type')
      if (tError) throw tError

      // Get target user IDs based on device type or roles
      let tUserIds: string[] = []
      if (tData && tData.length > 0) {
        // We need roles/phone for matching target filters on user_fcm_tokens
        const userIdsInFcmTokens = tData.map(t => t.user_id)
        const { data: matchedProfiles, error: mpError } = await supabase
          .from('profiles')
          .select('id, role, phone')
          .in('id', userIdsInFcmTokens)
        if (mpError) throw mpError

        if (matchedProfiles) {
          tUserIds = matchedProfiles.filter(p => {
            if (notifTarget === 'driver') return p.role === 'driver'
            if (notifTarget === 'single') return p.phone === notifPhone
            return true
          }).map(p => p.id)
        }
      }

      const pUserIds = (pData || []).map(p => p.id)
      const userIds = Array.from(new Set([...pUserIds, ...tUserIds]))

      if (userIds.length === 0) {
        toast.error('لم يتم العثور على أجهزة مسجلة للمستهدفين في قاعدة البيانات')
        setSending(false)
        return
      }

      // 2. Call Supabase Edge Function 'send-fcm-notification' concurrently for each target user
      const promises = userIds.map(userId =>
        supabase.functions.invoke('send-fcm-notification', {
          body: {
            userId,
            title: notifTitle,
            body: notifBody,
            data: notifImage ? { image: notifImage } : {}
          }
        })
      )
      
      const results = await Promise.all(promises)
      const successCount = results.filter(r => !r.error).length

      if (successCount > 0) {
        setSent(true)
        toast.success(`✅ تم إرسال الإشعار بنجاح لـ ${successCount} مستخدم!`)
        setNotifTitle(''); setNotifBody(''); setNotifImage(''); setNotifPhone('')
        setTimeout(() => setSent(false), 4000)
      } else {
        throw new Error('فشلت جميع محاولات إرسال الإشعارات عبر الـ Edge Function')
      }
    } catch (err: any) {
      toast.error('خطأ في إرسال الإشعار: ' + (err.message || String(err)))
    } finally {
      setSending(false)
    }
  }

  async function handleSaveBanner() {
    if (!currentBanner.title || !currentBanner.imageUrl) return
    setLoadingMedia(true)
    try {
      const encodedLinkValue = JSON.stringify({ title: currentBanner.title, value: currentBanner.linkValue || '' })
      const payload = {
        image_url: currentBanner.imageUrl,
        link_type: currentBanner.linkType || 'none',
        link_value: encodedLinkValue,
        is_active: currentBanner.active ?? true
      }
      if (currentBanner.id) {
        const { error } = await supabase.from('banners').update(payload).eq('id', currentBanner.id)
        if (error) throw error
      } else {
        const { error } = await supabase.from('banners').insert(payload)
        if (error) throw error
      }
      toast.success('تم حفظ البنر بنجاح')
      setShowBannerModal(false)
      fetchBanners()
    } catch (err: any) {
      toast.error('خطأ: ' + err.message)
    } finally {
      setLoadingMedia(false)
    }
  }

  async function handleDeleteBanner(id: string) {
    if (!confirm('تأكيد الحذف؟')) return
    try {
      const { error } = await supabase.from('banners').delete().eq('id', id)
      if (error) throw error
      toast.success('تم حذف البنر')
      fetchBanners()
    } catch (err: any) {
      toast.error('خطأ: ' + err.message)
    }
  }

  async function toggleBannerActive(id: string, current: boolean) {
    try {
      const { error } = await supabase.from('banners').update({ is_active: !current }).eq('id', id)
      if (error) throw error
      fetchBanners()
    } catch (err: any) {
      toast.error('خطأ: ' + err.message)
    }
  }

  async function handleSaveStory() {
    if (!currentStory.title) return
    setLoadingMedia(true)
    try {
      let groupId = currentStory.id
      const groupPayload = {
        title: currentStory.title,
        thumbnail_url: currentStory.thumbnailUrl || '',
        is_active: currentStory.active ?? true
      }
      
      if (groupId) {
        const { error } = await supabase.from('story_groups').update(groupPayload).eq('id', groupId)
        if (error) throw error
        // Delete old items
        const { error: delError } = await supabase.from('story_items').delete().eq('group_id', groupId)
        if (delError) throw delError
      } else {
        const { data, error } = await supabase.from('story_groups').insert(groupPayload).select('id').single()
        if (error) throw error
        groupId = data.id
      }
      
      if (currentStory.items && currentStory.items.length > 0) {
        const itemsPayload = currentStory.items.map(item => ({
          group_id: groupId,
          media_type: item.type,
          media_url: item.url || '',
          text_content: item.textContent || '',
          bg_color: item.bgColor || '',
          duration: item.duration || 5
        }))
        const { error: itemsError } = await supabase.from('story_items').insert(itemsPayload)
        if (itemsError) throw itemsError
      }
      
      toast.success('تم حفظ القصة بنجاح')
      setShowStoryModal(false)
      fetchStories()
    } catch (err: any) {
      toast.error('خطأ: ' + err.message)
    } finally {
      setLoadingMedia(false)
    }
  }

  async function handleDeleteStory(id: string) {
    if (!confirm('تأكيد الحذف؟')) return
    try {
      const { error } = await supabase.from('story_groups').delete().eq('id', id)
      if (error) throw error
      toast.success('تم حذف القصة')
      fetchStories()
    } catch (err: any) {
      toast.error('خطأ: ' + err.message)
    }
  }

  const TABS: { id: Tab; label: string; icon: React.ReactNode }[] = [
    { id: 'notifications', label: 'الإشعارات الذكية', icon: <Bell size={16} /> },
    { id: 'banners', label: 'إدارة البنرات', icon: <ImageIcon size={16} /> },
    { id: 'stories', label: 'قصص التطبيق', icon: <Megaphone size={16} /> },
    { id: 'discounts', label: 'أكواد الخصم', icon: <Tag size={16} /> },
  ]

  return (
    <div style={{ paddingBottom: 40 }}>
      {/* Tabs */}
      <div style={{ display: 'flex', gap: 6, marginBottom: 24, background: 'var(--white)', borderRadius: 12, padding: 6, border: '1px solid var(--gray100)', width: 'fit-content', boxShadow: 'var(--shadow-sm)' }}>
        {TABS.map(t => (
          <button key={t.id} onClick={() => setTab(t.id)}
            className={tab === t.id ? 'btn btn-primary btn-sm' : 'btn btn-ghost btn-sm'}
            style={{ gap: 8, padding: '8px 16px', fontSize: 13, fontWeight: 700 }}>
            {t.icon} {t.label}
          </button>
        ))}
      </div>

      {/* ─── NOTIFICATIONS TAB ─── */}
      {tab === 'notifications' && (
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
                <div style={{ position: 'relative' }}>
                  <ImageIcon size={16} style={{ position: 'absolute', right: 12, top: 12, color: 'var(--gray400)' }} />
                  <input className="form-input" style={{ paddingRight: 36 }} value={notifImage} onChange={e => setNotifImage(e.target.value)} placeholder="رابط الصورة (URL)" />
                </div>
                {notifImage && (
                  <div style={{ marginTop: 10, borderRadius: 8, overflow: 'hidden', border: '1px solid var(--gray200)', height: 120, background: 'var(--gray50)' }}>
                    <img src={notifImage} alt="preview" style={{ width: '100%', height: '100%', objectFit: 'cover' }} onError={(e) => (e.currentTarget.style.display = 'none')} />
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
                  <div style={{ width: 24, height: 24, background: 'var(--g500)', borderRadius: 6, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Leaf size={14} color="white" />
                  </div>
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

            {/* Quick Templates */}
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
        </div>
      )}

      {/* ─── BANNERS TAB ─── */}
      {tab === 'banners' && (
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
                    <label className="toggle">
                      <input type="checkbox" checked={b.active} onChange={() => toggleBannerActive(b.id, b.active)} />
                      <span className="toggle-slider" />
                    </label>
                  </div>
                  {b.active && <div style={{ position: 'absolute', bottom: 8, left: 8, background: '#10b981', color: 'white', fontSize: 10, fontWeight: 700, padding: '2px 8px', borderRadius: 20 }}>نشط</div>}
                </div>
                <div style={{ padding: '16px' }}>
                  <div style={{ fontWeight: 800, fontSize: 15, marginBottom: 4, color: 'var(--gray900)' }}>{b.title}</div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: 'var(--gray500)', marginBottom: 12 }}>
                    <Link size={12} />
                    {b.linkType === 'none' ? 'بدون رابط' : b.linkType === 'external' ? 'رابط خارجي' : 'منتج داخل التطبيق'}
                  </div>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <button className="btn btn-outline btn-sm" style={{ flex: 1 }} onClick={() => { setCurrentBanner(b); setShowBannerModal(true); }}>
                      <Edit2 size={14} /> تعديل
                    </button>
                    <button className="btn btn-icon btn-ghost btn-sm" onClick={() => handleDeleteBanner(b.id)}>
                      <Trash2 size={16} style={{ color: '#ef4444' }} />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {showBannerModal && (
            <div className="modal-overlay" onClick={() => setShowBannerModal(false)}>
              <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 500 }}>
                <div className="modal-title">{currentBanner.id ? 'تعديل البنر' : 'إضافة بنر جديد'}</div>
                <div className="form-group">
                  <label className="form-label">عنوان البنر</label>
                  <input className="form-input" value={currentBanner.title || ''} onChange={e => setCurrentBanner(p => ({ ...p, title: e.target.value }))} placeholder="مثال: خصم الفواكه" />
                </div>
                <div className="form-group">
                  <label className="form-label">صورة البنر (الرابط)</label>
                  <input className="form-input" value={currentBanner.imageUrl || ''} onChange={e => setCurrentBanner(p => ({ ...p, imageUrl: e.target.value }))} placeholder="https://..." />
                  {currentBanner.imageUrl && <img src={currentBanner.imageUrl} alt="" style={{ width: '100%', height: 100, objectFit: 'cover', borderRadius: 8, marginTop: 8 }} />}
                </div>
                <div className="form-group">
                  <label className="form-label">نوع الرابط عند الضغط</label>
                  <select className="form-select" value={currentBanner.linkType || 'none'} onChange={e => setCurrentBanner(p => ({ ...p, linkType: e.target.value as any, linkValue: '' }))}>
                    <option value="none">صورة فقط</option>
                    <option value="external">رابط خارجي</option>
                    <option value="product">منتج داخل التطبيق</option>
                  </select>
                </div>
                {currentBanner.linkType !== 'none' && (
                  <div className="form-group">
                    <label className="form-label">{currentBanner.linkType === 'external' ? 'الرابط الخارجي' : 'معرف المنتج (Product ID)'}</label>
                    <input className="form-input" value={currentBanner.linkValue || ''} onChange={e => setCurrentBanner(p => ({ ...p, linkValue: e.target.value }))} />
                  </div>
                )}
                <div style={{ display: 'flex', gap: 10, marginTop: 24 }}>
                  <button className="btn btn-primary" style={{ flex: 1 }} onClick={handleSaveBanner}>حفظ البنر</button>
                  <button className="btn btn-ghost" onClick={() => setShowBannerModal(false)}>إلغاء</button>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* ─── STORIES TAB ─── */}
      {tab === 'stories' && (
        <div>
          <div style={{ background: 'linear-gradient(135deg, #f0fdf4, #ecfdf5)', border: '1px solid #a7f3d0', borderRadius: 12, padding: '16px 20px', marginBottom: 24, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div>
              <h2 style={{ fontSize: 16, fontWeight: 800, color: '#065f46', margin: 0 }}>قصص التطبيق (Stories)</h2>
              <p style={{ fontSize: 12, color: '#047857', margin: '4px 0 0 0' }}>نظام قصص مثل انستغرام — يمكنك إضافة حتى 7 مجموعات</p>
            </div>
            <button className="btn btn-primary" disabled={stories.length >= 7} onClick={() => { setCurrentStory({ active: true, items: [] }); setShowStoryModal(true); }}>
              <Plus size={16} /> مجموعة جديدة {stories.length}/7
            </button>
          </div>

          <div style={{ display: 'flex', gap: 20, overflowX: 'auto', paddingBottom: 20, paddingTop: 8 }}>
            {stories.map((story) => (
              <div key={story.id} style={{ width: 130, flexShrink: 0, opacity: story.active ? 1 : 0.5, cursor: 'pointer', textAlign: 'center' }} onClick={() => { setCurrentStory(story); setShowStoryModal(true); }}>
                <div style={{ width: 90, height: 90, borderRadius: '50%', margin: '0 auto 10px', padding: 3, background: story.active ? 'linear-gradient(45deg, #10b981, #059669)' : 'var(--gray300)' }}>
                  <div style={{ width: '100%', height: '100%', borderRadius: '50%', border: '3px solid white', overflow: 'hidden', background: 'white' }}>
                    <img src={story.thumbnailUrl || 'https://via.placeholder.com/90'} style={{ width: '100%', height: '100%', objectFit: 'cover' }} alt="story" />
                  </div>
                </div>
                <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--gray900)' }}>{story.title}</div>
                <div style={{ fontSize: 11, color: 'var(--gray500)' }}>{story.items.length} عناصر</div>
              </div>
            ))}
          </div>

          {showStoryModal && (
            <div className="modal-overlay" onClick={() => setShowStoryModal(false)}>
              <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 600, width: '90%' }}>
                <div className="modal-title" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span>{currentStory.id ? 'تعديل مجموعة القصص' : 'مجموعة قصص جديدة'}</span>
                  {currentStory.id && (
                    <button className="btn btn-icon btn-ghost btn-sm" onClick={() => { handleDeleteStory(currentStory.id!); setShowStoryModal(false); }}>
                      <Trash2 size={16} color="#ef4444" />
                    </button>
                  )}
                </div>
                <div className="grid-2" style={{ gap: 16 }}>
                  <div className="form-group">
                    <label className="form-label">اسم المجموعة</label>
                    <input className="form-input" value={currentStory.title || ''} onChange={e => setCurrentStory(p => ({ ...p, title: e.target.value }))} placeholder="مثال: عروض الصيف" />
                  </div>
                  <div className="form-group">
                    <label className="form-label">رابط صورة الغلاف</label>
                    <input className="form-input" value={currentStory.thumbnailUrl || ''} onChange={e => setCurrentStory(p => ({ ...p, thumbnailUrl: e.target.value }))} />
                  </div>
                </div>
                <div style={{ marginTop: 20, marginBottom: 12, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <h3 style={{ fontSize: 14, fontWeight: 800, margin: 0 }}>محتويات القصة</h3>
                  <div style={{ display: 'flex', gap: 6 }}>
                    <button className="btn btn-outline btn-sm" onClick={() => setCurrentStory(p => ({ ...p, items: [...(p.items||[]), { id: Date.now().toString(), type: 'image', duration: 5 }] }))}><ImageIcon size={14}/> صورة</button>
                    <button className="btn btn-outline btn-sm" onClick={() => setCurrentStory(p => ({ ...p, items: [...(p.items||[]), { id: Date.now().toString(), type: 'video', duration: 30 }] }))}><Video size={14}/> فيديو</button>
                    <button className="btn btn-outline btn-sm" onClick={() => setCurrentStory(p => ({ ...p, items: [...(p.items||[]), { id: Date.now().toString(), type: 'text', duration: 5, bgColor: '#10b981', textContent: 'نص القصة' }] }))}><Type size={14}/> نص</button>
                  </div>
                </div>
                <div style={{ background: 'var(--gray50)', padding: 12, borderRadius: 12, maxHeight: 280, overflowY: 'auto' }}>
                  {(!currentStory.items || currentStory.items.length === 0) ? (
                    <div style={{ textAlign: 'center', padding: 20, color: 'var(--gray500)', fontSize: 13 }}>لا توجد عناصر، أضف صورة أو فيديو أو نص.</div>
                  ) : (
                    currentStory.items.map((item, idx) => (
                      <div key={item.id} style={{ background: 'white', border: '1px solid var(--gray200)', padding: 12, borderRadius: 8, marginBottom: 10, display: 'flex', gap: 12, alignItems: 'flex-start' }}>
                        <div style={{ width: 32, height: 32, background: 'var(--g100)', color: 'var(--g600)', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                          {item.type === 'image' ? <ImageIcon size={16}/> : item.type === 'video' ? <Video size={16}/> : <Type size={16}/>}
                        </div>
                        <div style={{ flex: 1 }}>
                          {item.type === 'text' ? (
                            <div className="grid-2" style={{ gap: 8 }}>
                              <input className="form-input form-input-sm" value={item.textContent || ''} onChange={e => { const ni = [...(currentStory.items||[])]; ni[idx].textContent = e.target.value; setCurrentStory({...currentStory, items: ni}); }} placeholder="اكتب النص..." />
                              <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                                <input type="color" value={item.bgColor || '#10b981'} onChange={e => { const ni = [...(currentStory.items||[])]; ni[idx].bgColor = e.target.value; setCurrentStory({...currentStory, items: ni}); }} style={{ width: 34, height: 34, padding: 0, border: 'none', borderRadius: 4, cursor: 'pointer' }} />
                                <span style={{ fontSize: 11, color: 'var(--gray500)' }}>خلفية</span>
                              </div>
                            </div>
                          ) : (
                            <input className="form-input form-input-sm" value={item.url || ''} onChange={e => { const ni = [...(currentStory.items||[])]; ni[idx].url = e.target.value; setCurrentStory({...currentStory, items: ni}); }} placeholder={`رابط الـ ${item.type === 'video' ? 'فيديو' : 'صورة'}...`} />
                          )}
                          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 8 }}>
                            <span style={{ fontSize: 11, color: 'var(--gray500)' }}>مدة العرض (ثواني):</span>
                            <input className="form-input form-input-sm" type="number" style={{ width: 70 }} value={item.duration} onChange={e => { const ni = [...(currentStory.items||[])]; ni[idx].duration = Number(e.target.value); setCurrentStory({...currentStory, items: ni}); }} />
                          </div>
                        </div>
                        <button className="btn btn-icon btn-ghost btn-sm" onClick={() => { const ni = [...(currentStory.items||[])]; ni.splice(idx, 1); setCurrentStory({...currentStory, items: ni}); }}><Trash2 size={16} color="#ef4444" /></button>
                      </div>
                    ))
                  )}
                </div>
                <div style={{ display: 'flex', gap: 10, marginTop: 20 }}>
                  <button className="btn btn-primary" style={{ flex: 1 }} disabled={loadingMedia} onClick={handleSaveStory}>
                    {loadingMedia ? 'جاري الحفظ...' : 'حفظ القصة'}
                  </button>
                  <button className="btn btn-ghost" onClick={() => setShowStoryModal(false)}>إلغاء</button>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* ─── DISCOUNTS TAB ─── */}
      {tab === 'discounts' && (
        <div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
            <div>
              <h2 style={{ fontSize: 18, fontWeight: 800, color: 'var(--gray900)', margin: 0 }}>🏷️ أكواد الخصم</h2>
              <p style={{ fontSize: 12, color: 'var(--gray500)', margin: '4px 0 0 0' }}>إنشاء وإدارة أكواد الخصم للزبائن</p>
            </div>
            <div style={{ display: 'flex', gap: 10 }}>
              <button className="btn btn-ghost btn-sm" onClick={fetchDiscounts}><RefreshCw size={14} /> تحديث</button>
              <button className="btn btn-primary" onClick={() => { setDiscForm({ type: 'percent', discount_amount: 10, max_uses: 100, is_active: true }); setShowDiscModal(true); }}>
                <Plus size={16} /> كود خصم جديد
              </button>
            </div>
          </div>

          {/* Summary Stats */}
          <div className="stats-grid" style={{ marginBottom: 24 }}>
            <div className="stat-card">
              <div className="stat-label">إجمالي الأكواد</div>
              <div className="stat-value">{discounts.length}</div>
            </div>
            <div className="stat-card">
              <div className="stat-label">الأكواد النشطة</div>
              <div className="stat-value" style={{ color: 'var(--g600)' }}>{discounts.filter(d => d.is_active).length}</div>
            </div>
            <div className="stat-card">
              <div className="stat-label">إجمالي الاستخدام</div>
              <div className="stat-value">{discounts.reduce((sum, d) => sum + (d.used_count || 0), 0)}</div>
            </div>
          </div>

          {discLoading ? (
            <div className="empty-state"><div className="loader"></div></div>
          ) : discounts.length === 0 ? (
            <div className="card">
              <div className="empty-state">
                <div className="empty-icon">🏷️</div>
                <div className="empty-text">لا توجد أكواد خصم بعد</div>
                <button className="btn btn-primary" style={{ marginTop: 16 }} onClick={() => { setDiscForm({ type: 'percent', discount_amount: 10, max_uses: 100, is_active: true }); setShowDiscModal(true); }}>
                  <Plus size={16} /> إنشاء أول كود خصم
                </button>
              </div>
            </div>
          ) : (
            <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ background: 'var(--gray50)', borderBottom: '1px solid var(--gray100)' }}>
                    {['الكود', 'الخصم', 'النوع', 'الاستخدام', 'الحد الأدنى', 'الانتهاء', 'الحالة', 'إجراءات'].map(h => (
                      <th key={h} style={{ padding: '14px 16px', textAlign: 'right', fontSize: 12, fontWeight: 700, color: 'var(--gray600)' }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {discounts.map(d => (
                    <tr key={d.id} style={{ borderBottom: '1px solid var(--gray50)', transition: 'background .15s' }}
                      onMouseEnter={e => e.currentTarget.style.background = 'var(--gray50)'}
                      onMouseLeave={e => e.currentTarget.style.background = ''}>
                      <td style={{ padding: '14px 16px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                          <code style={{ background: 'var(--g50)', color: 'var(--g700)', padding: '4px 10px', borderRadius: 8, fontSize: 13, fontWeight: 800, letterSpacing: 1 }}>{d.code}</code>
                          <button className="btn btn-icon btn-ghost btn-sm" style={{ width: 28, height: 28 }} onClick={() => { navigator.clipboard.writeText(d.code); toast.success('تم نسخ الكود!') }}><Copy size={12} /></button>
                        </div>
                      </td>
                      <td style={{ padding: '14px 16px', fontWeight: 800, fontSize: 16, color: 'var(--g600)' }}>
                        {d.type === 'percent' ? `${d.discount_amount}%` : `${d.discount_amount?.toLocaleString('ar-IQ')} د.ع`}
                      </td>
                      <td style={{ padding: '14px 16px' }}>
                        <span className={`badge ${d.type === 'percent' ? 'badge-green' : 'badge-blue'}`}>{d.type === 'percent' ? 'نسبة %' : 'مبلغ ثابت'}</span>
                      </td>
                      <td style={{ padding: '14px 16px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <div style={{ flex: 1, background: 'var(--gray100)', borderRadius: 4, height: 6, overflow: 'hidden', minWidth: 60 }}>
                            <div style={{ height: '100%', background: 'var(--g500)', width: `${Math.min(100, ((d.used_count || 0) / (d.max_uses || 1)) * 100)}%`, borderRadius: 4 }} />
                          </div>
                          <span style={{ fontSize: 12, fontWeight: 700 }}>{d.used_count || 0}/{d.max_uses}</span>
                        </div>
                      </td>
                      <td style={{ padding: '14px 16px', fontSize: 12, color: 'var(--gray500)' }}>
                        {d.min_order_amount ? `${d.min_order_amount?.toLocaleString('ar-IQ')} د.ع` : '—'}
                      </td>
                      <td style={{ padding: '14px 16px', fontSize: 12, color: d.expires_at && new Date(d.expires_at) < new Date() ? '#ef4444' : 'var(--gray500)' }}>
                        {d.expires_at ? new Date(d.expires_at).toLocaleDateString('ar-IQ') : '∞ دائم'}
                      </td>
                      <td style={{ padding: '14px 16px' }}>
                        <button onClick={() => toggleDiscount(d.id, d.is_active)} style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 4 }}>
                          {d.is_active ? <ToggleRight size={24} color="#10b981" /> : <ToggleLeft size={24} color="#9ca3af" />}
                          <span style={{ fontSize: 11, color: d.is_active ? '#10b981' : '#9ca3af', fontWeight: 700 }}>{d.is_active ? 'نشط' : 'موقوف'}</span>
                        </button>
                      </td>
                      <td style={{ padding: '14px 16px' }}>
                        <div style={{ display: 'flex', gap: 6 }}>
                          <button className="btn btn-icon btn-ghost btn-sm" onClick={() => { setDiscForm(d); setShowDiscModal(true); }}><Edit2 size={14} /></button>
                          <button className="btn btn-icon btn-ghost btn-sm" onClick={() => deleteDiscount(d.id)}><Trash2 size={14} color="#ef4444" /></button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* Discount Modal */}
          {showDiscModal && (
            <div className="modal-overlay" onClick={() => setShowDiscModal(false)}>
              <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 480 }}>
                <div className="modal-title">{discForm.id ? 'تعديل كود الخصم' : 'إنشاء كود خصم جديد'}</div>
                
                <div className="form-group">
                  <label className="form-label">كود الخصم *</label>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <input className="form-input" style={{ flex: 1, fontFamily: 'monospace', fontWeight: 800, letterSpacing: 2, textTransform: 'uppercase' }}
                      value={discForm.code || ''} onChange={e => setDiscForm(p => ({ ...p, code: e.target.value.toUpperCase() }))} placeholder="FRESH2025" />
                    <button className="btn btn-outline" onClick={() => setDiscForm(p => ({ ...p, code: generateCode() }))} title="توليد كود عشوائي">
                      <RefreshCw size={16} />
                    </button>
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">نوع الخصم</label>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <button className={`btn btn-sm ${discForm.type === 'percent' ? 'btn-primary' : 'btn-outline'}`} style={{ flex: 1 }} onClick={() => setDiscForm(p => ({ ...p, type: 'percent' }))}>نسبة مئوية %</button>
                    <button className={`btn btn-sm ${discForm.type === 'fixed' ? 'btn-primary' : 'btn-outline'}`} style={{ flex: 1 }} onClick={() => setDiscForm(p => ({ ...p, type: 'fixed' }))}>مبلغ ثابت (د.ع)</button>
                  </div>
                </div>

                <div className="grid-2" style={{ gap: 12 }}>
                  <div className="form-group">
                    <label className="form-label">{discForm.type === 'percent' ? 'نسبة الخصم (%)' : 'مبلغ الخصم (د.ع)'}</label>
                    <input className="form-input" type="number" value={discForm.discount_amount || ''} onChange={e => setDiscForm(p => ({ ...p, discount_amount: Number(e.target.value) }))} placeholder={discForm.type === 'percent' ? '10' : '5000'} />
                  </div>
                  <div className="form-group">
                    <label className="form-label">الحد الأقصى للاستخدام</label>
                    <input className="form-input" type="number" value={discForm.max_uses || ''} onChange={e => setDiscForm(p => ({ ...p, max_uses: Number(e.target.value) }))} placeholder="100" />
                  </div>
                </div>

                <div className="grid-2" style={{ gap: 12 }}>
                  <div className="form-group">
                    <label className="form-label">الحد الأدنى للطلب (د.ع)</label>
                    <input className="form-input" type="number" value={discForm.min_order_amount || ''} onChange={e => setDiscForm(p => ({ ...p, min_order_amount: Number(e.target.value) || undefined }))} placeholder="10000 (اختياري)" />
                  </div>
                  <div className="form-group">
                    <label className="form-label">تاريخ الانتهاء (اختياري)</label>
                    <input className="form-input" type="date" value={discForm.expires_at ? discForm.expires_at.split('T')[0] : ''} onChange={e => setDiscForm(p => ({ ...p, expires_at: e.target.value ? e.target.value + 'T23:59:59Z' : undefined }))} />
                  </div>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 0', borderTop: '1px solid var(--gray100)', marginTop: 4 }}>
                  <span style={{ fontWeight: 700, fontSize: 14 }}>حالة الكود</span>
                  <button onClick={() => setDiscForm(p => ({ ...p, is_active: !p.is_active }))} style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6 }}>
                    {discForm.is_active ? <ToggleRight size={28} color="#10b981" /> : <ToggleLeft size={28} color="#9ca3af" />}
                    <span style={{ fontWeight: 700, color: discForm.is_active ? '#10b981' : '#9ca3af' }}>{discForm.is_active ? 'نشط' : 'موقوف'}</span>
                  </button>
                </div>

                <div style={{ display: 'flex', gap: 10, marginTop: 16 }}>
                  <button className="btn btn-primary" style={{ flex: 1 }} onClick={saveDiscount}>
                    {discForm.id ? 'حفظ التعديلات' : 'إنشاء الكود'}
                  </button>
                  <button className="btn btn-ghost" onClick={() => setShowDiscModal(false)}>إلغاء</button>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      <style>{`.spin { animation: spin 1s linear infinite; } @keyframes spin { from{transform:rotate(0)} to{transform:rotate(360deg)} }`}</style>
    </div>
  )
}

function Leaf(props: any) {
  return <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}><path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"/><path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12"/></svg>
}
