import { useState, useEffect } from 'react'
import { Shield, User, HeartPulse, Save, Loader, Lock, Unlock, Store, Bike, Car, Truck, Bus } from 'lucide-react'
import { supabase } from '../lib/supabase'
import toast from 'react-hot-toast'

const CORRECT_PIN = '6868142'

interface PartnerSetting {
  key: string; value_decimal: number; label: string; color: string;
}

export default function Settings() {
  const [unlocked, setUnlocked] = useState(false)
  const [pinInput, setPinInput] = useState('')
  const [pinError, setPinError] = useState(false)
  const [showPinModal, setShowPinModal] = useState(false)
  const [saving, setSaving] = useState(false)
  const [partners, setPartners] = useState<PartnerSetting[]>([
    { key: 'dev_partner_ratio', value_decimal: 0.35, label: 'حصة المبرمج الشريك', color: '#2563eb' },
    { key: 'owner_partner_ratio', value_decimal: 0.55, label: 'حصة صاحب المشروع', color: '#d97706' },
    { key: 'system_maintenance_ratio', value_decimal: 0.10, label: 'صندوق الصيانة والسيرفر', color: '#7c3aed' },
  ])
  const [deliveryEarning, setDeliveryEarning] = useState(0)
  const [vehicleEarnings, setVehicleEarnings] = useState<Record<string, number>>({
    delivery_earnings_motorcycle: 0,
    delivery_earnings_car: 0,
    delivery_earnings_van: 0,
    delivery_earnings_truck: 0,
  })
  const [savingEarning, setSavingEarning] = useState(false)

  useEffect(() => { fetchSettings() }, [])

  async function fetchSettings() {
    try {
      const { data } = await supabase.from('system_settings').select('*')
      if (data) {
        setPartners(prev => prev.map(p => {
          const found = data.find((s: { key: string; value_decimal: number }) => s.key === p.key)
          return found ? { ...p, value_decimal: found.value_decimal } : p
        }))
        const earning = data.find((s: { key: string; value_decimal: number }) => s.key === 'delivery_earnings_per_order')
        if (earning) setDeliveryEarning(Number(earning.value_decimal) || 0)
        setVehicleEarnings(prev => {
          const next = { ...prev }
          for (const key of Object.keys(next)) {
            const found = data.find((s: { key: string; value_decimal: number }) => s.key === key)
            if (found) next[key] = Number(found.value_decimal) || 0
          }
          return next
        })
      }
    } catch (err) { console.error(err) }
  }

  function handleUnlock() {
    if (pinInput === CORRECT_PIN) {
      setUnlocked(true)
      setShowPinModal(false)
      setPinInput('')
      setPinError(false)
    } else {
      setPinError(true)
    }
  }

  async function saveSettings() {
    setSaving(true)
    try {
      for (const p of partners) {
        await supabase.from('system_settings').upsert(
          { key: p.key, value_decimal: p.value_decimal },
          { onConflict: 'key' }
        )
      }
      toast.success('تم تحديث نسب الشراكة بنجاح')
    } catch (err: unknown) {
      toast.error('خطأ في الحفظ: ' + ((err as Error).message))
    } finally {
      setSaving(false)
    }
  }

  async function saveDeliveryEarning() {
    setSavingEarning(true)
    try {
      await supabase.from('system_settings').upsert(
        { key: 'delivery_earnings_per_order', value_decimal: deliveryEarning },
        { onConflict: 'key' }
      )
      for (const [key, val] of Object.entries(vehicleEarnings)) {
        await supabase.from('system_settings').upsert(
          { key, value_decimal: val },
          { onConflict: 'key' }
        )
      }
      toast.success('تم حفظ أرباح التوصيل (حسب نوع المركبة) بنجاح')
    } catch (err: unknown) {
      toast.error('خطأ في الحفظ: ' + ((err as Error).message))
    } finally {
      setSavingEarning(false)
    }
  }

  const totalPercent = partners.reduce((s, p) => s + p.value_decimal * 100, 0)

  return (
    <div className="animate-in" style={{ maxWidth: 680, margin: '0 auto', padding: '24px 0' }}>
      {/* PIN Modal */}
      {showPinModal && (
        <div className="modal-overlay" onClick={() => { setShowPinModal(false); setPinError(false); setPinInput('') }}>
          <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 380 }}>
            <div style={{ textAlign: 'center', marginBottom: 24 }}>
              <div style={{ width: 56, height: 56, borderRadius: '50%', background: '#fef3c7', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 12px' }}>
                <Lock size={24} color="#d97706" />
              </div>
              <h2 className="modal-title">إدخال رمز الحماية</h2>
              <p style={{ fontSize: 13, color: 'var(--gray500)', marginTop: 4 }}>يجب إدخال الرقم السري لتعديل نسب الشراكة</p>
            </div>
            <input
              type="password"
              inputMode="numeric"
              autoFocus
              maxLength={10}
              className="form-input"
              value={pinInput}
              onChange={e => { setPinInput(e.target.value); setPinError(false) }}
              onKeyDown={e => { if (e.key === 'Enter') handleUnlock() }}
              placeholder="أدخل الرقم السري"
              style={{ textAlign: 'center', fontSize: 20, letterSpacing: 8, padding: '14px 16px', direction: 'ltr' }}
            />
            {pinError && (
              <div style={{ color: '#ef4444', fontSize: 13, fontWeight: 700, textAlign: 'center', marginTop: 10 }}>
                رمز خاطئ! أعد المحاولة
              </div>
            )}
            <div style={{ display: 'flex', gap: 12, marginTop: 20 }}>
              <button className="btn btn-primary" style={{ flex: 1, height: 44 }} onClick={handleUnlock}>
                <Unlock size={16} /> فتح التعديل
              </button>
              <button className="btn btn-ghost" onClick={() => { setShowPinModal(false); setPinError(false); setPinInput('') }}>
                إلغاء
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Page Header */}
      <div style={{ marginBottom: 32 }}>
        <h1 className="brand-name" style={{ fontSize: 24, marginBottom: 8 }}>الإعدادات</h1>
        <p className="brand-sub">إدارة نسب الشراكة المالية</p>
      </div>

      {/* Partnership Section Header */}
      <div className="card">
        <div className="card-header">
          <span className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <Store size={18} /> نسب الشراكة — توزيع الأرباح
          </span>
        </div>
        <div className="card-body">
          <p style={{ fontSize: 13, color: 'var(--gray500)', marginBottom: 20 }}>
            حدد النسب المئوية لتوزيع الأرباح على الشركاء. النسبة المتبقية تحتسب تلقائياً لصاحب الفرع.
            التعديل محمي برقم سري.
          </p>

          {/* Current ratios display */}
          <div style={{ display: 'flex', gap: 12, marginBottom: 20, flexWrap: 'wrap' }}>
            {partners.map(p => (
              <div key={p.key} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '6px 14px', borderRadius: 8, background: p.color + '12', color: p.color, fontSize: 13, fontWeight: 700 }}>
                <div style={{ width: 8, height: 8, borderRadius: '50%', background: p.color }} />
                {p.label}: {(p.value_decimal * 100).toFixed(0)}%
              </div>
            ))}
          </div>

          {/* Edit Button or Unlocked Edit Fields */}
          {!unlocked ? (
            <button className="btn btn-outline" style={{ width: '100%', height: 44 }} onClick={() => setShowPinModal(true)}>
              <Lock size={16} /> تعديل نسب الشراكة (محمي برقم سري)
            </button>
          ) : (
            <>
              <div style={{ padding: 16, background: '#fef3c7', borderRadius: 12, marginBottom: 20, display: 'flex', alignItems: 'center', gap: 10 }}>
                <Unlock size={16} color="#d97706" />
                <span style={{ fontSize: 13, fontWeight: 700, color: '#92400e' }}>وضع التعديل مفتوح — يمكنك تغيير النسب</span>
              </div>

              {partners.map((partner, idx) => (
                <div key={partner.key} style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 16, padding: '12px 16px', background: 'var(--gray50)', borderRadius: 12 }}>
                  <div style={{
                    width: 40, height: 40, borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                    background: idx === 0 ? '#dbeafe' : idx === 1 ? '#fef3c7' : '#ede9fe',
                    color: idx === 0 ? '#2563eb' : idx === 1 ? '#d97706' : '#7c3aed'
                  }}>
                    {idx === 0 ? <Shield size={20} /> : idx === 1 ? <User size={20} /> : <HeartPulse size={20} />}
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontWeight: 700, fontSize: 14, marginBottom: 2 }}>{partner.label}</div>
                    <div style={{ fontSize: 11, color: 'var(--gray400)' }}>{(partner.value_decimal * 100).toFixed(0)}% من الأرباح</div>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <input
                      type="number" step="1" min="0" max="100"
                      className="form-input"
                      style={{ width: 80, textAlign: 'center', fontWeight: 700 }}
                      value={Math.round(partner.value_decimal * 100)}
                      onChange={e => {
                        const val = Math.min(100, Math.max(0, parseInt(e.target.value) || 0))
                        setPartners(prev => prev.map((p, i) => i === idx ? { ...p, value_decimal: val / 100 } : p))
                      }}
                    />
                    <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--gray500)' }}>%</span>
                  </div>
                </div>
              ))}

              <div style={{
                padding: '12px 16px', borderRadius: 12, marginTop: 16,
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

              <div style={{ display: 'flex', gap: 12, marginTop: 20 }}>
                <button className="btn btn-primary" style={{ flex: 1, height: 44 }} onClick={saveSettings} disabled={saving || totalPercent > 100}>
                  {saving ? <><Loader size={16} className="spin" /> جاري الحفظ...</> : <><Save size={16} /> حفظ نسب الشراكة</>}
                </button>
                <button className="btn btn-ghost" onClick={() => setUnlocked(false)}>
                  إغلاق
                </button>
              </div>
            </>
          )}
        </div>
      </div>

      {/* Delivery Earnings Section */}
      <div className="card" style={{ marginTop: 24 }}>
        <div className="card-header">
          <span className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <Bike size={18} /> أرباح التوصيل — للمناديب
          </span>
        </div>
        <div className="card-body">
          <p style={{ fontSize: 13, color: 'var(--gray500)', marginBottom: 20 }}>
            حدد أجر المندوب عن كل طلب تم توصيله حسب نوع مركبته. عند ترك القيمة صفراً، يُحتسب أجر المندوب
            من التسعيرة العامة أدناه، وإن كانت صفراً فمن رسوم التوصيل (delivery_fee) الخاصة بالطلب.
          </p>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 12, marginBottom: 20 }}>
            {[
              { key: 'delivery_earnings_motorcycle', label: 'الدراجة النارية', icon: <Bike size={18} />, color: '#10b981' },
              { key: 'delivery_earnings_car', label: 'السيارة', icon: <Car size={18} />, color: '#2563eb' },
              { key: 'delivery_earnings_van', label: 'الفان', icon: <Bus size={18} />, color: '#8b5cf6' },
              { key: 'delivery_earnings_truck', label: 'الشاحنة', icon: <Truck size={18} />, color: '#f59e0b' },
            ].map(v => (
              <div key={v.key} style={{ padding: 14, background: 'var(--gray50)', borderRadius: 14, border: '1px solid var(--gray100)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
                  <div style={{ width: 34, height: 34, borderRadius: 10, background: v.color + '15', display: 'flex', alignItems: 'center', justifyContent: 'center', color: v.color }}>
                    {v.icon}
                  </div>
                  <div style={{ fontWeight: 700, fontSize: 14 }}>{v.label}</div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <input
                    type="number" min="0" step="250"
                    className="form-input"
                    style={{ flex: 1, fontWeight: 700, fontSize: 15, textAlign: 'center' }}
                    value={vehicleEarnings[v.key]}
                    onChange={e => setVehicleEarnings(prev => ({ ...prev, [v.key]: Math.max(0, Number(e.target.value) || 0) }))}
                  />
                  <span style={{ fontSize: 12, color: 'var(--gray400)', fontWeight: 700 }}>د.ع/طلب</span>
                </div>
              </div>
            ))}
          </div>

          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 16, flexWrap: 'wrap' }}>
            <div style={{ flex: 1, minWidth: 240 }}>
              <label style={{ display: 'block', fontSize: 12, fontWeight: 700, color: 'var(--gray600)', marginBottom: 6 }}>
                التسعير العام لكل طلب (د.ع) — يُستخدم عند غياب تسعيرة المركبة
              </label>
              <input
                type="number" min="0" step="500"
                className="form-input"
                style={{ width: '100%', fontWeight: 700, fontSize: 16, textAlign: 'center' }}
                value={deliveryEarning}
                onChange={e => setDeliveryEarning(Math.max(0, Number(e.target.value) || 0))}
              />
            </div>
            <button
              className="btn btn-primary"
              style={{ height: 44, minWidth: 160, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}
              onClick={saveDeliveryEarning}
              disabled={savingEarning}
            >
              {savingEarning ? <><Loader size={16} className="spin" /> جاري الحفظ...</> : <><Save size={16} /> حفظ الأرباح</>}
            </button>
          </div>
          <div style={{ marginTop: 12, fontSize: 12, color: 'var(--gray400)' }}>
            {deliveryEarning > 0
              ? `سيُضاف ${deliveryEarning.toLocaleString()} د.ع إلى رصيد المندوب عند كل تسليم كإعداد عام.`
              : 'سيُستخدم مبلغ delivery_fee الخاص بكل طلب كأجر للمندوب (عند غياب التسعيرات أعلاه).'}
          </div>
        </div>
      </div>

      <style>{`.spin { animation: spin 1s linear infinite; } @keyframes spin { from{transform:rotate(0)} to{transform:rotate(360deg)} }`}</style>
    </div>
  )
}
