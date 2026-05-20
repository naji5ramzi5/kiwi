import { useState } from 'react'
import { Send, Bell, Image as ImageIcon, Tag, Megaphone, Plus, Trash2, Edit2, Link, AlignLeft, Video, Type } from 'lucide-react'

// --- Types ---
interface Banner { 
  id: string; 
  title: string; 
  imageUrl: string; 
  linkType: 'none' | 'external' | 'product'; 
  linkValue: string; 
  active: boolean 
}

interface StoryItem {
  id: string;
  type: 'image' | 'video' | 'text';
  url?: string;
  textContent?: string;
  bgColor?: string;
  duration: number; // in seconds
}

interface StoryGroup { 
  id: string; 
  title: string; 
  thumbnailUrl: string; 
  items: StoryItem[]; 
  active: boolean 
}

interface Discount { 
  id: string; 
  code: string; 
  discount: number; 
  type: '%' | 'مبلغ'; 
  uses: number; 
  limit: number; 
  active: boolean 
}

// --- Initial Mock Data ---
const BANNERS_INIT: Banner[] = [
  { id: '1', title: 'عرض الخضروات الطازجة', imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80', linkType: 'product', linkValue: 'prod_123', active: true },
  { id: '2', title: 'خصم 20% لفترة محدودة', imageUrl: 'https://images.unsplash.com/photo-1573246123716-6b1782bfc499?auto=format&fit=crop&w=400&q=80', linkType: 'external', linkValue: 'https://example.com/promo', active: true },
  { id: '3', title: 'توصيل مجاني اليوم', imageUrl: 'https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?auto=format&fit=crop&w=400&q=80', linkType: 'none', linkValue: '', active: false },
]

const STORIES_INIT: StoryGroup[] = [
  { 
    id: '1', title: 'عروض اليوم', thumbnailUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=200&q=80', active: true,
    items: [
      { id: 's1', type: 'image', url: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=400&q=80', duration: 5 },
      { id: 's2', type: 'text', textContent: 'خصم 15% على كل السلطات!', bgColor: '#22c55e', duration: 5 }
    ]
  },
  { 
    id: '2', title: 'فواكه الصيف', thumbnailUrl: 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=200&q=80', active: true,
    items: [
      { id: 's3', type: 'video', url: 'https://example.com/video.mp4', duration: 30 }
    ]
  },
]

type Tab = 'notifications' | 'banners' | 'stories' | 'discounts'

export default function Marketing() {
  const [tab, setTab] = useState<Tab>('notifications')

  // Data state
  const [banners, setBanners] = useState<Banner[]>(BANNERS_INIT)
  const [stories, setStories] = useState<StoryGroup[]>(STORIES_INIT)
  
  // Notification form
  const [notifTitle, setNotifTitle] = useState('')
  const [notifBody, setNotifBody] = useState('')
  const [notifImage, setNotifImage] = useState('')
  const [notifTarget, setNotifTarget] = useState<'all' | 'driver' | 'single'>('all')
  const [notifPhone, setNotifPhone] = useState('')
  const [sent, setSent] = useState(false)

  // Banner form
  const [showBannerModal, setShowBannerModal] = useState(false)
  const [currentBanner, setCurrentBanner] = useState<Partial<Banner>>({})

  // Story Form
  const [showStoryModal, setShowStoryModal] = useState(false)
  const [currentStory, setCurrentStory] = useState<Partial<StoryGroup>>({})

  function sendNotif() {
    if (!notifTitle || !notifBody) return
    setSent(true)
    setNotifTitle(''); setNotifBody(''); setNotifImage('')
    setTimeout(() => setSent(false), 3000)
  }

  function handleSaveBanner() {
    if (!currentBanner.title || !currentBanner.imageUrl) return
    const newBanner = { ...currentBanner, id: currentBanner.id || Date.now().toString(), active: currentBanner.active ?? true } as Banner
    setBanners(prev => currentBanner.id ? prev.map(b => b.id === currentBanner.id ? newBanner : b) : [...prev, newBanner])
    setShowBannerModal(false)
  }

  const TABS: { id: Tab; label: string; icon: React.ReactNode }[] = [
    { id: 'notifications', label: 'الإشعارات الذكية', icon: <Bell size={16} /> },
    { id: 'banners', label: 'إدارة البنرات', icon: <ImageIcon size={16} /> },
    { id: 'stories', label: 'قصص التطبيق (Stories)', icon: <Megaphone size={16} /> },
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
                  ✅ تم إرسال الإشعار بنجاح لجميع الأجهزة!
                </div>
              )}
              
              <div className="form-group">
                <label className="form-label">الجمهور المستهدف</label>
                <div style={{ display: 'flex', gap: 8 }}>
                  {[{ v: 'all', l: 'الجميع' }, { v: 'driver', l: 'المناديب فقط' }, { v: 'single', l: 'مستخدم محدد' }].map(o => (
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
                <label className="form-label">صورة مرفقة (اختياري) - تظهر في الإشعار</label>
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

              <button className="btn btn-primary" style={{ width: '100%', height: 44, fontSize: 14 }} onClick={sendNotif}>
                <Send size={18} /> إرسال الإشعار الآن
              </button>
            </div>
          </div>

          <div className="card">
            <div className="card-header"><span className="card-title">📱 معاينة الإشعار</span></div>
            <div className="card-body" style={{ background: 'var(--gray50)', display: 'flex', justifyContent: 'center', alignItems: 'center', padding: 40, borderRadius: '0 0 16px 16px' }}>
              <div style={{ background: 'white', width: 320, borderRadius: 16, boxShadow: '0 10px 25px rgba(0,0,0,.1)', overflow: 'hidden' }}>
                <div style={{ padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 8, borderBottom: '1px solid var(--gray50)' }}>
                  <div style={{ width: 20, height: 20, background: 'var(--g500)', borderRadius: 4, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Leaf size={12} color="white" />
                  </div>
                  <span style={{ fontSize: 11, fontWeight: 600, color: 'var(--gray500)' }}>Fresh App • الآن</span>
                </div>
                {notifImage && <img src={notifImage} style={{ width: '100%', height: 140, objectFit: 'cover' }} alt="notif" />}
                <div style={{ padding: '14px 16px' }}>
                  <div style={{ fontWeight: 800, fontSize: 14, color: '#111', marginBottom: 4 }}>{notifTitle || 'عنوان الإشعار يظهر هنا'}</div>
                  <div style={{ fontSize: 12, color: 'var(--gray600)', lineHeight: 1.5 }}>{notifBody || 'محتوى الإشعار وتفاصيل العرض تظهر في هذا الجزء بشكل واضح للمستخدم.'}</div>
                </div>
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
              <div key={b.id} className="card" style={{ padding: 0, overflow: 'hidden', opacity: b.active ? 1 : 0.6 }}>
                <div style={{ height: 140, background: 'var(--gray100)', position: 'relative' }}>
                  <img src={b.imageUrl} alt={b.title} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                  <div style={{ position: 'absolute', top: 10, right: 10 }}>
                    <label className="toggle">
                      <input type="checkbox" checked={b.active} onChange={() => setBanners(p => p.map(x => x.id === b.id ? { ...x, active: !x.active } : x))} />
                      <span className="toggle-slider" />
                    </label>
                  </div>
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
                    <button className="btn btn-icon btn-ghost btn-sm" onClick={() => setBanners(p => p.filter(x => x.id !== b.id))}>
                      <Trash2 size={16} style={{ color: '#ef4444' }} />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Banner Modal */}
          {showBannerModal && (
            <div className="modal-overlay" onClick={() => setShowBannerModal(false)}>
              <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 500 }}>
                <div className="modal-title">{currentBanner.id ? 'تعديل البنر' : 'إضافة بنر جديد'}</div>
                
                <div className="form-group">
                  <label className="form-label">عنوان البنر (للتوضيح الداخلي)</label>
                  <input className="form-input" value={currentBanner.title || ''} onChange={e => setCurrentBanner(p => ({ ...p, title: e.target.value }))} placeholder="مثال: خصم الفواكه" />
                </div>

                <div className="form-group">
                  <label className="form-label">صورة البنر (الرابط)</label>
                  <input className="form-input" value={currentBanner.imageUrl || ''} onChange={e => setCurrentBanner(p => ({ ...p, imageUrl: e.target.value }))} placeholder="https://..." />
                </div>

                <div className="form-group">
                  <label className="form-label">نوع الرابط عند الضغط على البنر</label>
                  <select className="form-select" value={currentBanner.linkType || 'none'} onChange={e => setCurrentBanner(p => ({ ...p, linkType: e.target.value as any, linkValue: '' }))}>
                    <option value="none">صورة فقط (لا يحدث شيء)</option>
                    <option value="external">رابط موقع خارجي</option>
                    <option value="product">التوجيه لمنتج داخل التطبيق</option>
                  </select>
                </div>

                {currentBanner.linkType === 'external' && (
                  <div className="form-group">
                    <label className="form-label">الرابط الخارجي</label>
                    <input className="form-input" value={currentBanner.linkValue || ''} onChange={e => setCurrentBanner(p => ({ ...p, linkValue: e.target.value }))} placeholder="https://..." />
                  </div>
                )}

                {currentBanner.linkType === 'product' && (
                  <div className="form-group">
                    <label className="form-label">رقم/معرف المنتج (Product ID)</label>
                    <input className="form-input" value={currentBanner.linkValue || ''} onChange={e => setCurrentBanner(p => ({ ...p, linkValue: e.target.value }))} placeholder="مثال: uuid-of-product" />
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
          <div style={{ background: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: 12, padding: '16px 20px', marginBottom: 24, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div>
              <h2 style={{ fontSize: 16, fontWeight: 800, color: '#0f172a', margin: 0 }}>قصص التطبيق (Stories)</h2>
              <p style={{ fontSize: 12, color: '#64748b', margin: '4px 0 0 0' }}>نظام قصص مثل انستغرام - يمكنك إضافة حتى 7 مجموعات</p>
            </div>
            <button 
              className="btn btn-primary" 
              disabled={stories.length >= 7}
              onClick={() => { setCurrentStory({ active: true, items: [] }); setShowStoryModal(true); }}>
              <Plus size={16} /> مجموعة جديدة {stories.length}/7
            </button>
          </div>

          <div style={{ display: 'flex', gap: 16, overflowX: 'auto', paddingBottom: 16 }}>
            {stories.map((story) => (
              <div key={story.id} style={{ width: 120, flexShrink: 0, opacity: story.active ? 1 : 0.5, cursor: 'pointer', textAlign: 'center' }} onClick={() => { setCurrentStory(story); setShowStoryModal(true); }}>
                <div style={{ width: 80, height: 80, borderRadius: '50%', margin: '0 auto 8px', padding: 3, background: story.active ? 'linear-gradient(45deg, #f59e0b, #ec4899)' : 'var(--gray300)' }}>
                  <div style={{ width: '100%', height: '100%', borderRadius: '50%', border: '2px solid white', overflow: 'hidden', background: 'white' }}>
                    <img src={story.thumbnailUrl || 'https://via.placeholder.com/80'} style={{ width: '100%', height: '100%', objectFit: 'cover' }} alt="story" />
                  </div>
                </div>
                <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--gray900)' }}>{story.title}</div>
                <div style={{ fontSize: 10, color: 'var(--gray500)' }}>{story.items.length} عناصر</div>
              </div>
            ))}
          </div>

          {/* Story Edit Modal */}
          {showStoryModal && (
            <div className="modal-overlay" onClick={() => setShowStoryModal(false)}>
              <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 600, width: '90%' }}>
                <div className="modal-title" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span>{currentStory.id ? 'تعديل مجموعة القصص' : 'مجموعة قصص جديدة'}</span>
                  {currentStory.id && (
                    <button className="btn btn-icon btn-ghost btn-sm" onClick={() => {
                       setStories(p => p.filter(s => s.id !== currentStory.id));
                       setShowStoryModal(false);
                    }}>
                      <Trash2 size={16} color="#ef4444" />
                    </button>
                  )}
                </div>

                <div className="grid-2" style={{ gap: 16 }}>
                  <div className="form-group">
                    <label className="form-label">اسم المجموعة (يظهر تحت الدائرة)</label>
                    <input className="form-input" value={currentStory.title || ''} onChange={e => setCurrentStory(p => ({ ...p, title: e.target.value }))} placeholder="مثال: عروض الصيف" />
                  </div>
                  <div className="form-group">
                    <label className="form-label">رابط صورة الغلاف (الدائرة المصغرة)</label>
                    <input className="form-input" value={currentStory.thumbnailUrl || ''} onChange={e => setCurrentStory(p => ({ ...p, thumbnailUrl: e.target.value }))} />
                  </div>
                </div>

                <div style={{ marginTop: 24, marginBottom: 12, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <h3 style={{ fontSize: 14, fontWeight: 800, margin: 0 }}>محتويات القصة</h3>
                  <div style={{ display: 'flex', gap: 6 }}>
                    <button className="btn btn-outline btn-sm" onClick={() => setCurrentStory(p => ({ ...p, items: [...(p.items||[]), { id: Date.now().toString(), type: 'image', duration: 5 }] }))}>
                      <ImageIcon size={14}/> صورة
                    </button>
                    <button className="btn btn-outline btn-sm" onClick={() => setCurrentStory(p => ({ ...p, items: [...(p.items||[]), { id: Date.now().toString(), type: 'video', duration: 30 }] }))}>
                      <Video size={14}/> فيديو
                    </button>
                    <button className="btn btn-outline btn-sm" onClick={() => setCurrentStory(p => ({ ...p, items: [...(p.items||[]), { id: Date.now().toString(), type: 'text', duration: 5, bgColor: '#3b82f6', textContent: 'نص القصة' }] }))}>
                      <Type size={14}/> نص
                    </button>
                  </div>
                </div>

                <div style={{ background: 'var(--gray50)', padding: 12, borderRadius: 12, maxHeight: 300, overflowY: 'auto' }}>
                  {(!currentStory.items || currentStory.items.length === 0) ? (
                    <div style={{ textAlign: 'center', padding: 20, color: 'var(--gray500)', fontSize: 13 }}>لا توجد عناصر في هذه القصة، أضف صورة أو فيديو أو نص.</div>
                  ) : (
                    currentStory.items.map((item, idx) => (
                      <div key={item.id} style={{ background: 'white', border: '1px solid var(--gray200)', padding: 12, borderRadius: 8, marginBottom: 10, display: 'flex', gap: 12, alignItems: 'flex-start' }}>
                        <div style={{ width: 32, height: 32, background: 'var(--g100)', color: 'var(--g600)', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          {item.type === 'image' ? <ImageIcon size={16}/> : item.type === 'video' ? <Video size={16}/> : <Type size={16}/>}
                        </div>
                        <div style={{ flex: 1 }}>
                          {item.type === 'text' ? (
                            <div className="grid-2" style={{ gap: 8 }}>
                              <input className="form-input form-input-sm" value={item.textContent || ''} onChange={e => {
                                const newItems = [...(currentStory.items || [])]; newItems[idx].textContent = e.target.value; setCurrentStory({ ...currentStory, items: newItems });
                              }} placeholder="اكتب النص..." />
                              <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                                <input type="color" value={item.bgColor || '#3b82f6'} onChange={e => {
                                  const newItems = [...(currentStory.items || [])]; newItems[idx].bgColor = e.target.value; setCurrentStory({ ...currentStory, items: newItems });
                                }} style={{ width: 34, height: 34, padding: 0, border: 'none', borderRadius: 4, cursor: 'pointer' }} />
                                <span style={{ fontSize: 11, color: 'var(--gray500)' }}>خلفية</span>
                              </div>
                            </div>
                          ) : (
                            <input className="form-input form-input-sm" value={item.url || ''} onChange={e => {
                              const newItems = [...(currentStory.items || [])]; newItems[idx].url = e.target.value; setCurrentStory({ ...currentStory, items: newItems });
                            }} placeholder={`رابط الـ ${item.type === 'video' ? 'فيديو (Max 60s)' : 'صورة'}...`} />
                          )}
                          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 8 }}>
                            <span style={{ fontSize: 11, color: 'var(--gray500)' }}>مدة العرض (ثواني):</span>
                            <input className="form-input form-input-sm" type="number" style={{ width: 70 }} value={item.duration} onChange={e => {
                              const newItems = [...(currentStory.items || [])]; newItems[idx].duration = Number(e.target.value); setCurrentStory({ ...currentStory, items: newItems });
                            }} />
                          </div>
                        </div>
                        <button className="btn btn-icon btn-ghost btn-sm" onClick={() => {
                          const newItems = [...(currentStory.items || [])]; newItems.splice(idx, 1); setCurrentStory({ ...currentStory, items: newItems });
                        }}><Trash2 size={16} color="#ef4444" /></button>
                      </div>
                    ))
                  )}
                </div>

                <div style={{ display: 'flex', gap: 10, marginTop: 24 }}>
                  <button className="btn btn-primary" style={{ flex: 1 }} onClick={() => {
                    const newStory = { ...currentStory, id: currentStory.id || Date.now().toString() } as StoryGroup;
                    setStories(prev => currentStory.id ? prev.map(s => s.id === currentStory.id ? newStory : s) : [...prev, newStory]);
                    setShowStoryModal(false);
                  }}>حفظ القصة</button>
                  <button className="btn btn-ghost" onClick={() => setShowStoryModal(false)}>إلغاء</button>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* ─── DISCOUNTS TAB ─── (Keep Simple) */}
      {tab === 'discounts' && (
        <div className="empty-state">
           <div className="empty-icon">🏷️</div>
           <div className="empty-text">سيتم تحديث نظام أكواد الخصم لاحقاً</div>
        </div>
      )}
    </div>
  )
}

function Leaf(props: any) {
  return <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}><path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"/><path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12"/></svg>
}
