import { useState, useEffect } from 'react'
import { Search, Save, Package, AlertTriangle, CheckCircle2, History, ArrowUpRight, ArrowDownRight, RefreshCw, Printer } from 'lucide-react'
import { supabase } from '../lib/supabase'
import type { InventoryWithProduct, Branch } from '../lib/types'

export default function Inventory() {
  const [inventory, setInventory] = useState<any[]>([])
  const [branches, setBranches] = useState<Branch[]>([])
  const [selectedBranch, setSelectedBranch] = useState<string>('')
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [saving, setSaving] = useState<string | null>(null)

  useEffect(() => {
    fetchBranches()
  }, [])

  useEffect(() => {
    if (selectedBranch) {
      fetchInventory()
    }
  }, [selectedBranch])

  async function fetchBranches() {
    const { data } = await supabase.from('branches').select('*').order('name')
    if (data && data.length > 0) {
      setBranches(data)
      setSelectedBranch(data[0].id)
    }
  }

  async function fetchInventory() {
    setLoading(true)
    const { data, error } = await supabase
      .from('branch_inventory')
      .select(`
        *,
        products (
          name,
          unit,
          category,
          image_url
        )
      `)
      .eq('branch_id', selectedBranch)
      .order('updated_at', { ascending: false })
    
    if (error) console.error(error)
    else setInventory(data || [])
    setLoading(false)
  }

  async function updateStock(id: string, actual_stock: number, buffer_limit: number) {
    setSaving(id)
    const { error } = await supabase
      .from('branch_inventory')
      .update({ 
        actual_stock, 
        buffer_limit,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
    
    if (error) {
      alert('خطأ في التحديث: ' + error.message)
    } else {
      // تحديث الحالة محلياً لسرعة الاستجابة
      setInventory(prev => prev.map(item => item.id === id ? { ...item, actual_stock, buffer_limit } : item))
    }
    setSaving(null)
  }

  async function reportWaste(productId: string, quantity: number, reason: string) {
    if (quantity <= 0) return;
    
    // Find product to get price for loss calculation
    const item = inventory.find(i => i.product_id === productId);
    const lossValue = (item?.products?.price || 0) * quantity;

    const { error } = await supabase.from('waste_records').insert([{
      branch_id: selectedBranch,
      product_id: productId,
      quantity,
      reason,
      loss_value: lossValue
    }]);

    if (error) {
      alert('فشل تسجيل التالف: ' + error.message);
    } else {
      alert('تم تسجيل التالف وتحديث المخزون بنجاح ✅');
      fetchInventory();
    }
  }

  const [wasteModal, setWasteModal] = useState<any | null>(null);

  const filtered = inventory.filter(item => 
    item.products?.name.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="animate-in">
      {/* Header & Branch Selector */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: 30, gap: 20 }}>
        <div style={{ flex: 1 }}>
          <h1 className="brand-name" style={{ fontSize: 24 }}>إدارة مخزون الفرع والتوالف</h1>
          <p className="brand-sub">تحديث الكميات الفعلية وتسجيل سجلات التوالف لتقليل الهدر</p>
          
          <div style={{ marginTop: 20, display: 'flex', gap: 12 }}>
            <div className="form-group" style={{ margin: 0, width: 250 }}>
              <label className="form-label">اختر الفرع للمراقبة</label>
              <select 
                className="form-select" 
                value={selectedBranch} 
                onChange={e => setSelectedBranch(e.target.value)}
                style={{ background: 'var(--white)', fontWeight: 700 }}
              >
                {branches.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
              </select>
            </div>
            <div className="icon-btn" style={{ flex: 1, maxWidth: 300, gap: 8, padding: '0 16px', height: 42, alignSelf: 'flex-end' }}>
              <Search size={16} />
              <input 
                placeholder="بحث عن منتج في المخزون..." 
                style={{ border: 'none', outline: 'none', background: 'transparent', flex: 1, fontSize: 13 }}
                value={search}
                onChange={e => setSearch(e.target.value)}
              />
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', gap: 12 }}>
          <button className="btn btn-outline" onClick={() => window.print()} style={{ gap: 8 }}>
            <Printer size={16} /> طباعة جرد
          </button>
          <button className="btn btn-ghost" onClick={fetchInventory} style={{ gap: 8 }}>
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} /> تحديث البيانات
          </button>
        </div>
      </div>

      {loading ? (
        <div className="empty-state"><div className="loader"></div></div>
      ) : (
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          <div className="table-wrap">
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ background: 'var(--gray50)', borderBottom: '1px solid var(--gray100)' }}>
                  <th style={{ padding: '16px 20px', textAlign: 'right', fontSize: 12, color: 'var(--gray500)' }}>المنتج</th>
                  <th style={{ padding: '16px 20px', textAlign: 'right', fontSize: 12, color: 'var(--gray500)' }}>التصنيف</th>
                  <th style={{ padding: '16px 20px', textAlign: 'center', fontSize: 12, color: 'var(--gray500)' }}>الحالة</th>
                  <th style={{ padding: '16px 20px', textAlign: 'center', fontSize: 12, background: 'var(--g50)', color: 'var(--g700)' }}>المخزون الفعلي</th>
                  <th style={{ padding: '16px 20px', textAlign: 'center', fontSize: 12, color: 'var(--gray500)' }}>حد الأمان (Buffer)</th>
                  <th style={{ padding: '16px 20px', textAlign: 'left', fontSize: 12, color: 'var(--gray500)' }}>إجراءات</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((item) => {
                  return (
                    <InventoryRow 
                      key={item.id} 
                      item={item} 
                      onSave={updateStock}
                      onReportWaste={(qty: number) => setWasteModal({ ...item, qty })}
                      isSaving={saving === item.id}
                    />
                  )
                })}
              </tbody>
            </table>
          </div>
          {filtered.length === 0 && (
            <div style={{ padding: 60, textAlign: 'center', color: 'var(--gray400)' }}>
              <Package size={48} style={{ marginBottom: 16, opacity: 0.2 }} />
              <p>لا توجد منتجات مخصصة لهذا الفرع في الكتالوج حالياً</p>
            </div>
          )}
        </div>
      )}

      {wasteModal && (
        <div className="modal-overlay" onClick={() => setWasteModal(null)}>
          <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 400 }}>
            <h3 className="modal-title">تسجيل تالف: {wasteModal.products.name}</h3>
            <p style={{ fontSize: 13, color: 'var(--gray500)', marginBottom: 20 }}>سيتم خصم الكمية من المخزون الحالي وتسجيلها في تقرير الخسائر.</p>
            
            <div className="form-group">
              <label className="form-label">الكمية التالفة ({wasteModal.products.unit})</label>
              <input 
                type="number" 
                className="form-input" 
                defaultValue={wasteModal.qty || 1} 
                id="waste_qty"
              />
            </div>

            <div className="form-group">
              <label className="form-label">سبب التلف</label>
              <select className="form-select" id="waste_reason">
                <option value="عفن / فساد">عفن / فساد</option>
                <option value="تلف نقل">تلف نقل</option>
                <option value="انتهاء صلاحية">انتهاء صلاحية</option>
                <option value="أخرى">أخرى</option>
              </select>
            </div>

            <div style={{ display: 'flex', gap: 12, marginTop: 24 }}>
              <button className="btn btn-danger" style={{ flex: 1 }} onClick={() => {
                const qty = parseFloat((document.getElementById('waste_qty') as HTMLInputElement).value);
                const reason = (document.getElementById('waste_reason') as HTMLSelectElement).value;
                reportWaste(wasteModal.product_id, qty, reason);
                setWasteModal(null);
              }}>تأكيد الخصم</button>
              <button className="btn btn-ghost" onClick={() => setWasteModal(null)}>إلغاء</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function InventoryRow({ item, onSave, onReportWaste, isSaving }: any) {
  const [stock, setStock] = useState(item.actual_stock)
  const [buffer, setBuffer] = useState(item.buffer_limit)
  const isChanged = stock !== item.actual_stock || buffer !== item.buffer_limit

  const isLow = stock <= buffer;
  const isOutOfStock = stock <= 0;

  return (
    <tr style={{ borderBottom: '1px solid var(--gray50)', transition: 'background .2s' }} className="hover-bg">
      <td style={{ padding: '12px 20px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          {item.products?.image_url ? (
            <img src={item.products.image_url} style={{ width: 36, height: 36, borderRadius: 8, objectFit: 'cover' }} />
          ) : (
            <div style={{ width: 36, height: 36, borderRadius: 8, background: 'var(--gray100)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Package size={18} color="var(--gray400)" />
            </div>
          )}
          <div style={{ fontWeight: 700, fontSize: 14 }}>{item.products?.name}</div>
        </div>
      </td>
      <td style={{ padding: '12px 20px' }}>
        <span style={{ fontSize: 11, color: 'var(--gray500)' }}>{item.products?.category}</span>
      </td>
      <td style={{ padding: '12px 20px', textAlign: 'center' }}>
        {isOutOfStock ? (
          <span className="badge badge-red" style={{ fontSize: 10 }}>مقطوع ❌</span>
        ) : isLow ? (
          <span className="badge badge-yellow" style={{ fontSize: 10 }}>منخفض ⚠️</span>
        ) : (
          <span className="badge badge-green" style={{ fontSize: 10 }}>متوفر ✅</span>
        )}
      </td>
      <td style={{ padding: '12px 20px', textAlign: 'center', background: 'rgba(16, 185, 129, 0.03)' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10 }}>
          <button className="btn btn-icon btn-ghost btn-sm" onClick={() => setStock(Math.max(0, stock - 1))}>
            <ArrowDownRight size={14} color="#ef4444" />
          </button>
          <input 
            type="number" 
            className="form-input" 
            style={{ width: 80, textAlign: 'center', fontWeight: 800, fontSize: 16, color: 'var(--g700)' }}
            value={stock}
            onChange={e => setStock(parseFloat(e.target.value) || 0)}
          />
          <button className="btn btn-icon btn-ghost btn-sm" onClick={() => setStock(stock + 1)}>
            <ArrowUpRight size={14} color="#22c55e" />
          </button>
          <span style={{ fontSize: 10, color: 'var(--gray400)', width: 30 }}>{item.products?.unit}</span>
        </div>
      </td>
      <td style={{ padding: '12px 20px', textAlign: 'center' }}>
        <input 
          type="number" 
          className="form-input" 
          style={{ width: 60, textAlign: 'center', fontSize: 13 }}
          value={buffer}
          onChange={e => setBuffer(parseFloat(e.target.value) || 0)}
        />
      </td>
      <td style={{ padding: '12px 20px', textAlign: 'left' }}>
        <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
          {isChanged ? (
            <button 
              className="btn btn-primary btn-sm" 
              style={{ padding: '6px 12px', gap: 6 }}
              onClick={() => onSave(item.id, stock, buffer)}
              disabled={isSaving}
            >
              {isSaving ? '...' : <Save size={14} />}
            </button>
          ) : (
            <CheckCircle2 size={18} color="var(--g400)" style={{ margin: '0 8px' }} />
          )}
          
          <button 
            className="btn btn-icon btn-ghost btn-sm" 
            title="تسجيل تالف"
            style={{ color: '#ef4444' }}
            onClick={() => onReportWaste(0)}
          >
            <AlertTriangle size={16} />
          </button>
        </div>
      </td>
    </tr>
  )
}
