import { useState, useEffect } from 'react'
import { User, Save, Loader } from 'lucide-react'
import { supabase } from '../lib/supabase'
import toast from 'react-hot-toast'

interface ProfileData {
  id: string;
  full_name: string;
  phone: string;
  role: string;
}

export default function Profile() {
  const [profile, setProfile] = useState<ProfileData | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [fullName, setFullName] = useState('')
  const [phone, setPhone] = useState('')

  useEffect(() => { fetchProfile() }, [])

  async function fetchProfile() {
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) return
      const { data, error } = await supabase.from('profiles').select('*').eq('id', user.id).single()
      if (error) throw error
      setProfile(data)
      setFullName(data?.full_name || '')
      setPhone(data?.phone || '')
    } catch (err) {
      console.error('Error fetching profile:', err)
    } finally {
      setLoading(false)
    }
  }

  async function saveProfile() {
    if (!profile) return
    setSaving(true)
    try {
      const { error } = await supabase.from('profiles').update({
        full_name: fullName, phone: phone
      }).eq('id', profile.id)
      if (error) throw error
      toast.success('تم تحديث الملف الشخصي بنجاح')
      setProfile({ ...profile, full_name: fullName, phone })
    } catch (err: unknown) {
      toast.error('خطأ في الحفظ: ' + ((err as Error).message))
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '60vh' }}>
        <div className="loader"></div>
      </div>
    )
  }

  return (
    <div style={{ maxWidth: 700, margin: '0 auto', padding: '32px 0' }}>
      <h1 className="brand-name" style={{ fontSize: 24, marginBottom: 8 }}>الإدارة العليا — الملف الشخصي</h1>
      <p className="brand-sub" style={{ marginBottom: 32 }}>إدارة البيانات الشخصية</p>

      <div className="card">
        <div className="card-header">
          <span className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <User size={18} /> البيانات الشخصية
          </span>
        </div>
        <div className="card-body">
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 16 }}>
            <div className="form-group">
              <label className="form-label">الاسم الكامل</label>
              <input className="form-input" value={fullName} onChange={e => setFullName(e.target.value)} />
            </div>
            <div className="form-group">
              <label className="form-label">رقم الهاتف</label>
              <input className="form-input" value={phone} onChange={e => setPhone(e.target.value)} />
            </div>
          </div>
          <div className="form-group">
            <label className="form-label">الدور</label>
            <input className="form-input" value={profile?.role || ''} disabled style={{ opacity: 0.6 }} />
          </div>
          <div style={{ display: 'flex', gap: 12, marginTop: 16 }}>
            <button className="btn btn-primary" style={{ flex: 1 }} onClick={saveProfile} disabled={saving}>
              {saving ? <><Loader size={16} className="spin" /> جاري الحفظ...</> : <><Save size={16} /> حفظ البيانات</>}
            </button>
          </div>
        </div>
      </div>

      <style>{`.spin { animation: spin 1s linear infinite; } @keyframes spin { from{transform:rotate(0)} to{transform:rotate(360deg)} }`}</style>
    </div>
  )
}
