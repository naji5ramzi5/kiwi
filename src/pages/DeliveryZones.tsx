import { useState, useEffect } from 'react'
import { MapPin, Plus, Trash2, Save, RefreshCw, Eye, EyeOff, Info } from 'lucide-react'
import { supabase } from '../lib/supabase'
import ZoneMap from '../components/ZoneMap'
import toast from 'react-hot-toast'

interface Zone {
  id: string
  branch_id: string
  branch_name?: string
  name: string
  color: string
  delivery_fee: number
  min_order: number
  max_delivery_time: number
  is_active: boolean
  geojson: any
  created_at: string
}

interface Branch {
  id: string
  name: string
  latitude: number
  longitude: number
}

const ZONE_COLORS = ['#10b981', '#3b82f6', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899']

export default function DeliveryZones() {
  const [branches, setBranches] = useState<Branch[]>([])
  const [selectedBranch, setSelectedBranch] = useState<Branch | null>(null)
  const [zones, setZones] = useState<Zone[]>([])
  const [mapZones, setMapZones] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [showModal, setShowModal] = useState(false)
  const [editingZone, setEditingZone] = useState<Partial<Zone> | null>(null)

  useEffect(() => {
    fetchBranches()
  }, [])

  useEffect(() => {
    if (selectedBranch) {
      fetchZonesForBranch(selectedBranch.id)
    }
  }, [selectedBranch])

  async function fetchBranches() {
    setLoading(true)
    try {
      const { data, error } = await supabase.from('branches').select('id, name, latitude, longitude').eq('status', 'نشط')
      if (error) throw error
      setBranches(data || [])
      if (data && data.length > 0) setSelectedBranch(data[0])
    } catch (err: any) {
      toast.error('فشل تحميل الفروع')
    } finally {
      setLoading(false)
    }
  }

  async function fetchZonesForBranch(branchId: string) {
    setLoading(true)
    try {
      const { data, error } = await supabase
        .from('delivery_zones')
        .select('*')
        .eq('branch_id', branchId)
        .order('created_at', { ascending: true })
      if (error) throw error
      const zonesData = data || []
      setZones(zonesData)
      // Load GeoJSON polygons into map
      const geoJsonList = zonesData
        .filter(z => z.geojson && z.is_active)
        .map(z => z.geojson)
      setMapZones(geoJsonList)
    } catch (err: any) {
      // Table might not exist - show empty
      setZones([])
      setMapZones([])
    } finally {
      setLoading(false)
    }
  }

  async function saveZone(zoneData: Partial<Zone>, drawnGeojson?: any) {
    if (!selectedBranch) return
    setSaving(true)
    try {
      const payload = {
        branch_id: selectedBranch.id,
        name: zoneData.name || 'منطقة جديدة',
        color: zoneData.color || '#10b981',
        delivery_fee: zoneData.delivery_fee || 0,
        min_order: zoneData.min_order || 5000,
        max_delivery_time: zoneData.max_delivery_time || 45,
        is_active: zoneData.is_active ?? true,
        geojson: drawnGeojson || zoneData.geojson || null,
      }

      if (zoneData.id) {
        const { error } = await supabase.from('delivery_zones').update(payload).eq('id', zoneData.id)
        if (error) throw error
        toast.success('✅ تم تحديث منطقة التوصيل')
      } else {
        const { error } = await supabase.from('delivery_zones').insert(payload)
        if (error) throw error
        toast.success('✅ تم إضافة منطقة التوصيل')
      }

      setShowModal(false)
      setEditingZone(null)
      fetchZonesForBranch(selectedBranch.id)
    } catch (err: any) {
      toast.error('خطأ: ' + (err.message || 'فشل الحفظ'))
    } finally {
      setSaving(false)
    }
  }

  async function deleteZone(id: string) {
    if (!confirm('هل أنت متأكد من حذف منطقة التوصيل هذه؟')) return
    const { error } = await supabase.from('delivery_zones').delete().eq('id', id)
    if (!error) {
      toast.success('تم حذف المنطقة')
      if (selectedBranch) fetchZonesForBranch(selectedBranch.id)
    }
  }

  async function toggleZone(id: string, current: boolean) {
    await supabase.from('delivery_zones').update({ is_active: !current }).eq('id', id)
    setZones(prev => prev.map(z => z.id === id ? { ...z, is_active: !current } : z))
    setMapZones(prev => {
      const zone = zones.find(z => z.id === id)
      if (!zone) return prev
      if (current) {
        // was active, now inactive - remove from map
        return zones.filter(z => z.id !== id && z.is_active).map(z => z.geojson).filter(Boolean)
      } else {
        // was inactive, now active - add to map
        return [...prev, zone.geojson].filter(Boolean)
      }
    })
  }

  // When user draws new polygon on map
  function handleMapZonesChange(newMapZones: any[]) {
    // Only track the last drawn zone - open modal for details
    if (newMapZones.length > mapZones.length) {
      const lastDrawn = newMapZones[newMapZones.length - 1]
      setEditingZone({ geojson: lastDrawn, is_active: true, delivery_fee: 1000, min_order: 5000, max_delivery_time: 45, color: ZONE_COLORS[zones.length % ZONE_COLORS.length] })
      setShowModal(true)
    }
    setMapZones(newMapZones)
  }

  return (
    <div className="animate-in">
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h1 className="brand-name" style={{ fontSize: 24 }}>🗺️ مناطق التوصيل</h1>
          <p className="brand-sub">ارسم وحدد مناطق التوصيل لكل فرع بدقة احترافية</p>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button className="btn btn-ghost btn-sm" onClick={() => selectedBranch && fetchZonesForBranch(selectedBranch.id)}>
            <RefreshCw size={14} /> تحديث
          </button>
          <button className="btn btn-primary" onClick={() => { setEditingZone({ is_active: true, delivery_fee: 1000, min_order: 5000, max_delivery_time: 45, color: ZONE_COLORS[zones.length % ZONE_COLORS.length] }); setShowModal(true) }}>
            <Plus size={16} /> منطقة جديدة (بدون رسم)
          </button>
        </div>
      </div>

      {/* Info Banner */}
      <div style={{ background: 'linear-gradient(135deg, #f0fdf4, #ecfdf5)', border: '1px solid #a7f3d0', borderRadius: 12, padding: '14px 20px', marginBottom: 24, display: 'flex', alignItems: 'center', gap: 12 }}>
        <Info size={20} color="#059669" />
        <div style={{ fontSize: 13, color: '#065f46', lineHeight: 1.6 }}>
          <strong>كيفية الاستخدام:</strong> اختر الفرع، ثم استخدم أدوات الرسم في <strong>أعلى يمين الخريطة</strong> لرسم مضلع منطقة التوصيل. بعد الرسم ستظهر نافذة لإدخال تفاصيل المنطقة (اسم، رسوم التوصيل، الحد الأدنى للطلب).
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '320px 1fr', gap: 24 }}>
        {/* Left Panel - Branch Selector & Zone List */}
        <div>
          {/* Branch Selector */}
          <div className="card" style={{ marginBottom: 16 }}>
            <div className="card-header"><span className="card-title">🏪 اختر الفرع</span></div>
            <div className="card-body">
              {branches.map(branch => (
                <button
                  key={branch.id}
                  onClick={() => setSelectedBranch(branch)}
                  style={{
                    width: '100%', textAlign: 'right', padding: '10px 14px',
                    background: selectedBranch?.id === branch.id ? 'var(--g50)' : 'transparent',
                    border: selectedBranch?.id === branch.id ? '1.5px solid var(--g300)' : '1px solid var(--gray100)',
                    borderRadius: 10, cursor: 'pointer', fontSize: 14, fontWeight: selectedBranch?.id === branch.id ? 700 : 500,
                    color: selectedBranch?.id === branch.id ? 'var(--g700)' : 'var(--gray700)',
                    marginBottom: 6, display: 'flex', alignItems: 'center', gap: 8
                  }}
                >
                  <MapPin size={14} color={selectedBranch?.id === branch.id ? 'var(--g500)' : '#9ca3af'} />
                  {branch.name}
                </button>
              ))}
            </div>
          </div>

          {/* Zones List */}
          <div className="card">
            <div className="card-header">
              <span className="card-title">مناطق الفرع ({zones.length})</span>
            </div>
            <div className="card-body" style={{ padding: 0 }}>
              {loading ? (
                <div style={{ padding: 20, textAlign: 'center' }}><div className="loader" /></div>
              ) : zones.length === 0 ? (
                <div style={{ padding: 20, textAlign: 'center', color: 'var(--gray400)', fontSize: 13 }}>
                  <MapPin size={32} style={{ opacity: 0.3, marginBottom: 8 }} />
                  <div>لا توجد مناطق بعد</div>
                  <div style={{ fontSize: 11, marginTop: 4 }}>ارسم منطقة على الخريطة أو اضغط "منطقة جديدة"</div>
                </div>
              ) : (
                zones.map(zone => (
                  <div key={zone.id} style={{ padding: '12px 16px', borderBottom: '1px solid var(--gray50)', opacity: zone.is_active ? 1 : 0.5 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                      <div style={{ width: 12, height: 12, borderRadius: '50%', background: zone.color || '#10b981', flexShrink: 0 }} />
                      <span style={{ fontWeight: 700, fontSize: 14, flex: 1 }}>{zone.name}</span>
                      <button onClick={() => toggleZone(zone.id, zone.is_active)} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 2 }}>
                        {zone.is_active ? <Eye size={14} color="#10b981" /> : <EyeOff size={14} color="#9ca3af" />}
                      </button>
                      <button onClick={() => { setEditingZone(zone); setShowModal(true) }} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 2 }}>
                        ✏️
                      </button>
                      <button onClick={() => deleteZone(zone.id)} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 2 }}>
                        <Trash2 size={14} color="#ef4444" />
                      </button>
                    </div>
                    <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                      <span style={{ fontSize: 11, background: 'var(--g50)', color: 'var(--g700)', padding: '2px 8px', borderRadius: 6, fontWeight: 600 }}>
                        رسوم: {zone.delivery_fee?.toLocaleString('ar-IQ')} د.ع
                      </span>
                      <span style={{ fontSize: 11, background: '#f0f9ff', color: '#0369a1', padding: '2px 8px', borderRadius: 6, fontWeight: 600 }}>
                        ⏱ {zone.max_delivery_time} دقيقة
                      </span>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>

        {/* Right - Map */}
        <div>
          <div className="card" style={{ height: '100%', minHeight: 550 }}>
            <div className="card-header">
              <span className="card-title">🗺️ خريطة مناطق التوصيل — {selectedBranch?.name || 'اختر فرعاً'}</span>
              <span style={{ fontSize: 12, color: 'var(--gray500)' }}>ارسم المضلع لتحديد نطاق التوصيل</span>
            </div>
            <div className="card-body" style={{ padding: 0, height: 'calc(100% - 60px)' }}>
              {selectedBranch ? (
                <ZoneMap
                  center={[selectedBranch.latitude || 33.3152, selectedBranch.longitude || 44.3661]}
                  zones={mapZones}
                  onZonesChange={handleMapZonesChange}
                />
              ) : (
                <div style={{ height: 500, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--gray400)', flexDirection: 'column', gap: 12 }}>
                  <MapPin size={48} style={{ opacity: 0.2 }} />
                  <span>اختر فرعاً من القائمة لعرض الخريطة</span>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Zone Form Modal */}
      {showModal && editingZone !== null && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 480 }}>
            <div className="modal-title">
              {editingZone.id ? 'تعديل منطقة التوصيل' : '✨ منطقة توصيل جديدة'}
            </div>

            {editingZone.geojson && (
              <div style={{ background: '#f0fdf4', border: '1px solid #a7f3d0', borderRadius: 8, padding: '8px 12px', marginBottom: 16, fontSize: 12, color: '#065f46', fontWeight: 600 }}>
                ✅ تم رسم المنطقة على الخريطة بنجاح
              </div>
            )}

            <div className="form-group">
              <label className="form-label">اسم المنطقة *</label>
              <input className="form-input" value={editingZone.name || ''} onChange={e => setEditingZone(p => ({ ...p, name: e.target.value }))} placeholder="مثال: منطقة الكرادة الداخلية" />
            </div>

            <div className="form-group">
              <label className="form-label">لون المنطقة على الخريطة</label>
              <div style={{ display: 'flex', gap: 8 }}>
                {ZONE_COLORS.map(c => (
                  <div key={c} onClick={() => setEditingZone(p => ({ ...p, color: c }))} style={{ width: 32, height: 32, borderRadius: '50%', background: c, cursor: 'pointer', border: editingZone.color === c ? '3px solid #111' : '2px solid transparent', transition: 'all .2s' }} />
                ))}
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <div className="form-group">
                <label className="form-label">رسوم التوصيل (د.ع)</label>
                <input className="form-input" type="number" value={editingZone.delivery_fee || ''} onChange={e => setEditingZone(p => ({ ...p, delivery_fee: Number(e.target.value) }))} placeholder="1000" />
              </div>
              <div className="form-group">
                <label className="form-label">الحد الأدنى للطلب (د.ع)</label>
                <input className="form-input" type="number" value={editingZone.min_order || ''} onChange={e => setEditingZone(p => ({ ...p, min_order: Number(e.target.value) }))} placeholder="5000" />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">الحد الأقصى لوقت التوصيل (دقيقة)</label>
              <input className="form-input" type="number" value={editingZone.max_delivery_time || ''} onChange={e => setEditingZone(p => ({ ...p, max_delivery_time: Number(e.target.value) }))} placeholder="45" />
            </div>

            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 0', borderTop: '1px solid var(--gray100)', marginTop: 4 }}>
              <span style={{ fontWeight: 700 }}>حالة المنطقة</span>
              <button onClick={() => setEditingZone(p => ({ ...p, is_active: !p?.is_active }))} style={{ background: 'none', border: 'none', cursor: 'pointer', fontWeight: 700, color: editingZone.is_active ? '#10b981' : '#9ca3af', fontSize: 14 }}>
                {editingZone.is_active ? '✅ نشطة' : '⏸️ موقوفة'}
              </button>
            </div>

            <div style={{ display: 'flex', gap: 10, marginTop: 16 }}>
              <button className="btn btn-primary" style={{ flex: 1 }} onClick={() => saveZone(editingZone, editingZone.geojson)} disabled={saving}>
                <Save size={16} /> {saving ? 'جاري الحفظ...' : (editingZone.id ? 'حفظ التعديلات' : 'إضافة المنطقة')}
              </button>
              <button className="btn btn-ghost" onClick={() => { setShowModal(false); setEditingZone(null) }}>إلغاء</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
