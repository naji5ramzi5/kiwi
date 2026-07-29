import { useState, useEffect } from 'react'
import { Search, Save, DollarSign, Store, X, ChevronLeft, ChevronRight } from 'lucide-react'
import { supabase } from '../lib/supabase'
import toast from 'react-hot-toast'
import type { Branch } from '../lib/types'

const PAGE_SIZE = 20

export default function BranchPrices() {
  const [branches, setBranches] = useState<Branch[]>([])
  const [selectedBranchId, setSelectedBranchId] = useState<string | null>(null)
  const [products, setProducts] = useState<Array<Record<string, unknown>>>([])
  const [prices, setPrices] = useState<Record<string, string>>({})
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(0)
  const [dirtyCount, setDirtyCount] = useState(0)

  useEffect(() => {
    supabase.from('branches').select('*').order('name').then(({ data }) => {
      if (data) setBranches(data)
    })
  }, [])

  useEffect(() => {
    if (!selectedBranchId) { setProducts([]); setPrices({}); return }
    setLoading(true)
    setPage(0)
    Promise.all([
      supabase.from('products').select('id, name, category, unit, unit_type, default_price, price, image_url, is_active').order('name'),
      supabase.from('branch_product_prices').select('product_id, price').eq('branch_id', selectedBranchId)
    ]).then(([pRes, bpRes]) => {
      if (pRes.error) { toast.error('فشل تحميل المنتجات'); return }
      setProducts(pRes.data || [])
      const overrideMap: Record<string, string> = {}
      if (bpRes.data) {
        for (const bp of bpRes.data) {
          overrideMap[bp.product_id as string] = String(bp.price)
        }
      }
      setPrices(overrideMap)
    }).finally(() => setLoading(false))
  }, [selectedBranchId])

  const filtered = products.filter(p => {
    const name = (p.name as string || '').toLowerCase()
    return name.includes(search.toLowerCase())
  })

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE))
  const safePage = Math.min(page, totalPages - 1)
  const paged = filtered.slice(safePage * PAGE_SIZE, (safePage + 1) * PAGE_SIZE)

  useEffect(() => { setPage(0) }, [search])

  async function savePrices() {
    if (dirtyCount === 0 || !selectedBranchId) return
    setSaving(true)
    try {
      const changed = Object.entries(prices).filter(([pid, val]) => {
        const product = products.find(p => p.id === pid)
        const defaultPrice = product?.default_price ?? product?.price ?? 0
        return val !== '' && +val !== +defaultPrice
      })

      for (const [productId, priceStr] of changed) {
        const price = +priceStr
        if (price <= 0) continue

        const { error } = await supabase.from('branch_product_prices').upsert({
          branch_id: selectedBranchId,
          product_id: productId,
          price: price
        }, { onConflict: 'branch_id,product_id' })

        if (error) throw error
      }

      const deleted = Object.entries(prices).filter(([, val]) => val === '').map(([pid]) => pid)
      if (deleted.length > 0) {
        const { error } = await supabase.from('branch_product_prices')
          .delete()
          .eq('branch_id', selectedBranchId)
          .in('product_id', deleted)
        if (error) throw error
      }

      toast.success('تم حفظ أسعار الفرع ✅')
      setDirtyCount(0)
    } catch (err: unknown) {
      toast.error('خطأ: ' + ((err as Error).message || 'فشل الحفظ'))
    } finally {
      setSaving(false)
    }
  }

  function setPrice(productId: string, val: string) {
    setPrices(prev => ({ ...prev, [productId]: val }))
    setDirtyCount(prev => prev + 1)
  }

  return (
    <div className="animate-in">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h1 className="brand-name" style={{ fontSize: 24 }}>أسعار الفروع</h1>
          <p className="brand-sub">تخصيص سعر لكل منتج حسب الفرع</p>
        </div>
        {dirtyCount > 0 && (
          <button className="btn btn-primary" onClick={savePrices} disabled={saving}>
            <Save size={16} /> {saving ? 'جاري الحفظ...' : `حفظ التغييرات (${dirtyCount})`}
          </button>
        )}
      </div>

      <div style={{ display: 'flex', gap: 12, marginBottom: 20, flexWrap: 'wrap' }}>
        {branches.map(b => (
          <button key={b.id} className={`btn ${selectedBranchId === b.id ? 'btn-primary' : 'btn-outline'}`}
            style={{ display: 'flex', alignItems: 'center', gap: 6 }}
            onClick={() => setSelectedBranchId(b.id)}>
            <Store size={16} /> {b.name}
          </button>
        ))}
      </div>

      {selectedBranchId && (
        <div style={{ display: 'flex', gap: 12, marginBottom: 16 }}>
          <div className="icon-btn" style={{ flex: 1, maxWidth: 300, gap: 8, padding: '0 16px' }}>
            <Search size={16} />
            <input placeholder="بحث في المنتجات..." style={{ border: 'none', outline: 'none', background: 'transparent', flex: 1, fontSize: 13 }}
              value={search} onChange={e => setSearch(e.target.value)} />
          </div>
        </div>
      )}

      {!selectedBranchId ? (
        <div style={{ textAlign: 'center', padding: 60, color: 'var(--gray400)' }}>
          <Store size={48} style={{ marginBottom: 12, opacity: 0.3 }} />
          <p>اختر فرعاً لعرض وإدارة أسعار منتجاته</p>
        </div>
      ) : loading ? (
        <div style={{ textAlign: 'center', padding: 60 }}>جاري التحميل...</div>
      ) : (
        <>
          <div style={{ overflowX: 'auto', borderRadius: 12, border: '1px solid var(--gray200)' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
              <thead>
                <tr style={{ background: 'var(--gray50)' }}>
                  <th style={{ padding: '12px 16px', textAlign: 'right', fontWeight: 700, color: 'var(--gray600)' }}>المنتج</th>
                  <th style={{ padding: '12px 16px', textAlign: 'right', fontWeight: 700, color: 'var(--gray600)' }}>التصنيف</th>
                  <th style={{ padding: '12px 16px', textAlign: 'right', fontWeight: 700, color: 'var(--gray600)' }}>الوحدة</th>
                  <th style={{ padding: '12px 16px', textAlign: 'right', fontWeight: 700, color: 'var(--gray600)' }}>السعر العام</th>
                  <th style={{ padding: '12px 16px', textAlign: 'right', fontWeight: 700, color: 'var(--gray600)' }}>سعر الفرع</th>
                </tr>
              </thead>
              <tbody>
                {paged.map(p => {
                  const pid = p.id as string
                  const defaultPrice = (p.default_price as number) ?? (p.price as number) ?? 0
                  const branchPrice = prices[pid]
                  const isOverridden = branchPrice !== undefined && branchPrice !== '' && +branchPrice !== +defaultPrice
                  return (
                    <tr key={pid} style={{ borderTop: '1px solid var(--gray100)' }}>
                      <td style={{ padding: '10px 16px', display: 'flex', alignItems: 'center', gap: 10 }}>
                        {p.image_url ? <img src={p.image_url as string} alt="" style={{ width: 32, height: 32, borderRadius: 6, objectFit: 'cover' }} /> : <div style={{ width: 32, height: 32, borderRadius: 6, background: 'var(--gray100)' }} />}
                        <span style={{ fontWeight: 600 }}>{p.name as string}</span>
                      </td>
                      <td style={{ padding: '10px 16px', color: 'var(--gray500)' }}>{p.category as string}</td>
                      <td style={{ padding: '10px 16px' }}>
                        <span style={{ background: 'var(--gray100)', padding: '2px 8px', borderRadius: 6, fontSize: 12 }}>{p.unit as string}</span>
                      </td>
                      <td style={{ padding: '10px 16px', fontWeight: 600, color: 'var(--gray500)' }}>
                        {defaultPrice.toLocaleString('ar-IQ')} د.ع
                      </td>
                      <td style={{ padding: '10px 16px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <DollarSign size={14} style={{ color: isOverridden ? 'var(--g600)' : 'var(--gray300)' }} />
                          <input type="number" className="form-input" style={{ width: 120, padding: '6px 10px', border: isOverridden ? '2px solid var(--g500)' : '1px solid var(--gray200)', fontSize: 13 }}
                            placeholder={defaultPrice.toLocaleString('ar-IQ')}
                            value={branchPrice ?? ''}
                            onChange={e => setPrice(pid, e.target.value)} />
                          {isOverridden && (
                            <button className="btn btn-icon btn-ghost btn-sm" style={{ width: 28, height: 28, color: 'var(--red500)' }}
                              onClick={() => setPrice(pid, '')}
                              title="إعادة للسعر العام">
                              <X size={14} />
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>

          {totalPages > 1 && (
            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 12, marginTop: 20 }}>
              <button className="btn btn-ghost btn-sm" disabled={safePage === 0} onClick={() => setPage(safePage - 1)}>
                <ChevronRight size={16} /> السابق
              </button>
              <span style={{ fontSize: 13, color: 'var(--gray500)' }}>{safePage + 1} / {totalPages}</span>
              <button className="btn btn-ghost btn-sm" disabled={safePage >= totalPages - 1} onClick={() => setPage(safePage + 1)}>
                التالي <ChevronLeft size={16} />
              </button>
            </div>
          )}
        </>
      )}
    </div>
  )
}
