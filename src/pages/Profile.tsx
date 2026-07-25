import { useState, useEffect } from 'react'
import { User, Shield, Save, Loader, Users } from 'lucide-react'
import { supabase } from '../lib/supabase'
import toast from 'react-hot-toast'

interface ProfileData {
  id: string;
  full_name: string;
  phone: string;
  role: string;
}

interface PartnerSetting {
  key: string;
  value_decimal: number;
  label: string;
}

export default function Profile() {
  const [profile, setProfile] = useState<ProfileData | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [fullName, setFullName] = useState('')
  const [phone, setPhone] = useState('')
  const [partners, setPartners] = useState<PartnerSetting[]>([
    { key: 'dev_partner_ratio', value_decimal: 0.35, label: 'حصة المبرمج الشريك' },
    { key: 'owner_partner_ratio', value_decimal: 0.55, label: 'حصة صاحب المشروع' },
    { key: 'system_maintenance_ratio', value_decimal: 0.10, label: 'صندوق الصيانة والسيرفر' },
  ])
  const [savingPartners, setSavingPartners] = useState(false)

  useEffect(() => {
    fetchProfile()
    fetchPartnerSettings()
  }, [])

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

  async function fetchPartnerSettings() {
    try {
      const { data } = await supabase.from('system_settings').select('*')
      if (data) {
        setPartners(prev => prev.map(p => {
          const found = data.find((s: { key: string; value_decimal: number }) => s.key === p.key)
          return found ? { ...p, value_decimal: found.value_decimal } : p
        }))
      }
    } catch (err) {
      console.error('Error fetching partner settings:', err)
    }
  }

  async function saveProfile() {
    if (!profile) return
    setSaving(true)
    try {
      const { error } = await supabase.from('profiles').update({
        full_name: fullName,
        phone: phone
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

  async function savePartnerSettings() {
    setSavingPartners(true)
    try {
      for (const partner of partners) {
        await supabase.from('system_settings').upsert({
          key: partner.key,
          value_decimal: partner.value_decimal
        }, { onConflict: 'key' })
      }
      toast.success('تم تحديث نسب الشراكة بنجاح')
    } catch (err: unknown) {
      toast.error('خطأ في حفظ النسب: ' + ((err as Error).message))
    } finally {
      setSavingPartners(false)
    }
  }

  const totalPercent = partners.reduce((sum, p) => sum + (p.value_decimal * 100), 0)

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
      <p className="brand-sub" style={{ marginBottom: 32 }}>إدارة البيانات الشخصية ونسب الشراكة</p>

      {/* Profile Card */}
      <div className="card" style={{ marginBottom: 24 }}>
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

      {/* Partnership Division Card */}
      <div className="card">
        <div className="card-header">
          <span className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <Users size={18} /> تقسيم الشراكة — نسب الأرباح
          </span>
        </div>
        <div className="card-body">
          <p style={{ fontSize: 13, color: 'var(--gray500)', marginBottom: 20 }}>
            حدد النسب المئوية لتوزيع الأرباح الشهرية على كل شريك. المتبقي يُحسب تلقائياً كصافي ربح لصاحب الفرع.
          </p>

          {partners.map((partner, idx) => (
            <div key={partner.key} style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 16, padding: '12px 16px', background: 'var(--gray50)', borderRadius: 12 }}>
              <div style={{ width: 40, height: 40, borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                background: idx === 0 ? '#dbeafe' : idx === 1 ? '#fef3c7' : '#ede9fe',
                color: idx === 0 ? '#2563eb' : idx === 1 ? '#d97706' : '#7c3aed'
              }}>
                {idx === 0 ? <Shield size={20} /> : idx === 1 ? <User size={20} /> : <Shield size={20} />}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 700, fontSize: 14, marginBottom: 4 }}>{partner.label}</div>
                <div style={{ fontSize: 11, color: 'var(--gray400)' }}>{(partner.value_decimal * 100).toFixed(0)}% من إجمالي الأرباح</div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <input 
                  type="number" 
                  step="1" 
                  min="0" 
                  max="100"
                  className="form-input" 
                  style={{ width: 80, textAlign: 'center', fontWeight: 700 }}
                  value={Math.round(partner.value_decimal * 100)}
                  onChange={e => {
                    const val = Math.min(100, Math.max(0, parseInt(e.target.value) || 0))
                    const newPartners = [...partners]
                    newPartners[idx] = { ...partner, value_decimal: val / 100 }
                    setPartners(newPartners)
                  }}
                />
                <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--gray500)' }}>%</span>
              </div>
            </div>
          ))}

          <div style={{ padding: '12px 16px', borderRadius: 12, marginTop: 16, 
            background: totalPercent === 100 ? '#ecfdf5' : totalPercent > 100 ? '#fef2f2' : '#fffbeb',
            border: `1px solid ${totalPercent === 100 ? '#a7f3d0' : totalPercent > 100 ? '#fecaca' : '#fde68a'}`,
            color: totalPercent === 100 ? '#065f46' : totalPercent > 100 ? '#991b1b' : '#92400e'
          }}>
            <div style={{ fontWeight: 700, fontSize: 13 }}>
              المجموع: {totalPercent.toFixed(0)}%
              {totalPercent === 100 && ' — النسب مكتملة ✓'}
              {totalPercent > 100 && ' — النسب تجاوزت 100%!'}
              {totalPercent < 100 && ` — المتبقي ${(100 - totalPercent).toFixed(0)}% لصاحب الفرع`}
            </div>
          </div>

          <button className="btn btn-primary" style={{ width: '100%', marginTop: 16, height: 44 }} onClick={savePartnerSettings} disabled={savingPartners || totalPercent > 100}>
            {savingPartners ? <><Loader size={16} className="spin" /> جاري الحفظ...</> : <><Save size={16} /> حفظ نسب الشراكة</>}
          </button>
        </div>
      </div>

      <style>{`.spin { animation: spin 1s linear infinite; } @keyframes spin { from{transform:rotate(0)} to{transform:rotate(360deg)} }`}</style>
    </div>
  )
}
