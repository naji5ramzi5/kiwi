import { useState, useEffect } from 'react'
import { Plus, Trash2, Image as ImageIcon, Video, Type } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import toast from 'react-hot-toast'
import type { StoryGroup, StoryItem } from './types'

export default function StoriesTab() {
  const [stories, setStories] = useState<StoryGroup[]>([])
  const [loadingMedia, setLoadingMedia] = useState(false)
  const [showStoryModal, setShowStoryModal] = useState(false)
  const [currentStory, setCurrentStory] = useState<Partial<StoryGroup>>({})

  useEffect(() => { fetchStories() }, [])

  async function fetchStories() {
    setLoadingMedia(true)
    try {
      const { data: groupsData, error: groupsErr } = await supabase.from('story_groups').select('*').order('created_at', { ascending: false })
      if (groupsErr) throw groupsErr
      if (!groupsData || groupsData.length === 0) { setStories([]); return }
      const { data: itemsData, error: itemsErr } = await supabase.from('story_items').select('*').in('group_id', groupsData.map(g => g.id))
      if (itemsErr) throw itemsErr
      const parsedStories: StoryGroup[] = groupsData.map(g => {
        const gItems = (itemsData || []).filter(i => i.group_id === g.id).map(i => ({ id: i.id, type: i.media_type, url: i.media_url, textContent: i.text_content, bgColor: i.bg_color, duration: i.duration } as StoryItem))
        return { id: g.id, title: g.title, thumbnailUrl: g.thumbnail_url, active: g.is_active, items: gItems }
      })
      setStories(parsedStories)
    } catch { toast.error('فشل جلب القصص') } finally { setLoadingMedia(false) }
  }

  async function handleSaveStory() {
    if (!currentStory.title) return
    setLoadingMedia(true)
    try {
      let groupId = currentStory.id
      const groupPayload = { title: currentStory.title, thumbnail_url: currentStory.thumbnailUrl || '', is_active: currentStory.active ?? true }
      if (groupId) {
        const { error } = await supabase.from('story_groups').update(groupPayload).eq('id', groupId); if (error) throw error
        const { error: delError } = await supabase.from('story_items').delete().eq('group_id', groupId); if (delError) throw delError
      } else {
        const { data, error } = await supabase.from('story_groups').insert(groupPayload).select('id').single(); if (error) throw error; groupId = data.id
      }
      if (currentStory.items && currentStory.items.length > 0) {
        const itemsPayload = currentStory.items.map(item => ({ group_id: groupId, media_type: item.type, media_url: item.url || '', text_content: item.textContent || '', bg_color: item.bgColor || '', duration: item.duration || 5 }))
        const { error: itemsError } = await supabase.from('story_items').insert(itemsPayload); if (itemsError) throw itemsError
      }
      toast.success('تم حفظ القصة بنجاح'); setShowStoryModal(false); fetchStories()
    } catch (err: unknown) { toast.error('خطأ: ' + ((err as Error).message)) } finally { setLoadingMedia(false) }
  }

  async function handleDeleteStory(id: string) {
    if (!confirm('تأكيد الحذف؟')) return
    try { const { error } = await supabase.from('story_groups').delete().eq('id', id); if (error) throw error; toast.success('تم حذف القصة'); fetchStories() }
    catch (err: unknown) { toast.error('خطأ: ' + ((err as Error).message)) }
  }

  return (
    <div>
      <div style={{ background: 'linear-gradient(135deg, #f0fdf4, #ecfdf5)', border: '1px solid #a7f3d0', borderRadius: 12, padding: '16px 20px', marginBottom: 24, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div><h2 style={{ fontSize: 16, fontWeight: 800, color: '#065f46', margin: 0 }}>قصص التطبيق (Stories)</h2><p style={{ fontSize: 12, color: '#047857', margin: '4px 0 0 0' }}>نظام قصص مثل انستغرام — يمكنك إضافة حتى 7 مجموعات</p></div>
        <button className="btn btn-primary" disabled={stories.length >= 7} onClick={() => { setCurrentStory({ active: true, items: [] }); setShowStoryModal(true); }}><Plus size={16} /> مجموعة جديدة {stories.length}/7</button>
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
              {currentStory.id && (<button className="btn btn-icon btn-ghost btn-sm" onClick={() => { handleDeleteStory(currentStory.id!); setShowStoryModal(false); }}><Trash2 size={16} color="#ef4444" /></button>)}
            </div>
            <div className="grid-2" style={{ gap: 16 }}>
              <div className="form-group"><label className="form-label">اسم المجموعة</label><input className="form-input" value={currentStory.title || ''} onChange={e => setCurrentStory(p => ({ ...p, title: e.target.value }))} placeholder="مثال: عروض الصيف" /></div>
              <div className="form-group"><label className="form-label">رابط صورة الغلاف</label><input className="form-input" value={currentStory.thumbnailUrl || ''} onChange={e => setCurrentStory(p => ({ ...p, thumbnailUrl: e.target.value }))} /></div>
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
              ) : currentStory.items.map((item, idx) => (
                <div key={item.id} style={{ background: 'white', border: '1px solid var(--gray200)', padding: 12, borderRadius: 8, marginBottom: 10, display: 'flex', gap: 12, alignItems: 'flex-start' }}>
                  <div style={{ width: 32, height: 32, background: 'var(--g100)', color: 'var(--g600)', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    {item.type === 'image' ? <ImageIcon size={16}/> : item.type === 'video' ? <Video size={16}/> : <Type size={16}/>}
                  </div>
                  <div style={{ flex: 1 }}>
                    {item.type === 'text' ? (
                      <div className="grid-2" style={{ gap: 8 }}>
                        <input className="form-input form-input-sm" value={item.textContent || ''} onChange={e => { const ni = [...(currentStory.items||[])]; ni[idx].textContent = e.target.value; setCurrentStory({...currentStory, items: ni}); }} placeholder="اكتب النص..." />
                        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}><input type="color" value={item.bgColor || '#10b981'} onChange={e => { const ni = [...(currentStory.items||[])]; ni[idx].bgColor = e.target.value; setCurrentStory({...currentStory, items: ni}); }} style={{ width: 34, height: 34, padding: 0, border: 'none', borderRadius: 4, cursor: 'pointer' }} /><span style={{ fontSize: 11, color: 'var(--gray500)' }}>خلفية</span></div>
                      </div>
                    ) : (
                      <input className="form-input form-input-sm" value={item.url || ''} onChange={e => { const ni = [...(currentStory.items||[])]; ni[idx].url = e.target.value; setCurrentStory({...currentStory, items: ni}); }} placeholder={`رابط الـ ${item.type === 'video' ? 'فيديو' : 'صورة'}...`} />
                    )}
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 8 }}><span style={{ fontSize: 11, color: 'var(--gray500)' }}>مدة العرض (ثواني):</span><input className="form-input form-input-sm" type="number" style={{ width: 70 }} value={item.duration} onChange={e => { const ni = [...(currentStory.items||[])]; ni[idx].duration = Number(e.target.value); setCurrentStory({...currentStory, items: ni}); }} /></div>
                  </div>
                  <button className="btn btn-icon btn-ghost btn-sm" onClick={() => { const ni = [...(currentStory.items||[])]; ni.splice(idx, 1); setCurrentStory({...currentStory, items: ni}); }}><Trash2 size={16} color="#ef4444" /></button>
                </div>
              ))}
            </div>
            <div style={{ display: 'flex', gap: 10, marginTop: 20 }}>
              <button className="btn btn-primary" style={{ flex: 1 }} disabled={loadingMedia} onClick={handleSaveStory}>{loadingMedia ? 'جاري الحفظ...' : 'حفظ القصة'}</button>
              <button className="btn btn-ghost" onClick={() => setShowStoryModal(false)}>إلغاء</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
