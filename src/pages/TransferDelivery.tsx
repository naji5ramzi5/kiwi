import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { Search, GitBranch, ArrowLeftRight, Clock, User, Phone, BadgeCheck, X, Loader2 } from 'lucide-react'
import toast from 'react-hot-toast'

interface DeliveryEmployee {
  id: string; user_id: string; branch_id: string | null; phone: string | null;
  status: string; is_active: boolean; total_deliveries: number; joined_at: string;
  transferred_at: string | null;
  full_name?: string; avatar_url?: string; is_online?: boolean;
  branch_name?: string;
}

interface Branch { id: string; name: string; }

interface TransferRecord {
  id: string; delivery_employee_id: string; old_branch_id: string;
  new_branch_id: string; transferred_by: string; reason: string; transferred_at: string;
  old_branch?: { name: string }; new_branch?: { name: string };
}

export default function TransferDelivery() {
  const [employees, setEmployees] = useState<DeliveryEmployee[]>([])
  const [branches, setBranches] = useState<Branch[]>([])
  const [transfers, setTransfers] = useState<TransferRecord[]>([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [selectedEmployee, setSelectedEmployee] = useState<DeliveryEmployee | null>(null)
  const [selectedNewBranch, setSelectedNewBranch] = useState('')
  const [transferReason, setTransferReason] = useState('')
  const [transferring, setTransferring] = useState(false)
  const [showHistory, setShowHistory] = useState(false)

  useEffect(() => { loadData() }, [])

  async function loadData() {
    setLoading(true)
    await Promise.all([fetchEmployees(), fetchBranches(), fetchTransfers()])
    setLoading(false)
  }

  async function fetchEmployees() {
    const { data, error } = await supabase
      .from('delivery_employees_with_profiles')
      .select('*')
      .eq('is_active', true)
      .order('created_at', { ascending: false })
    if (error) { toast.error('خطأ في جلب المناديب'); return }
    const branchIds = [...new Set((data || []).map(d => d.branch_id).filter(Boolean))]
    const { data: branchData } = await supabase.from('branches').select('id, name').in('id', branchIds)
    const branchMap = Object.fromEntries((branchData || []).map((b: Branch) => [b.id, b.name]))
    setEmployees((data || []).map(d => ({ ...d, branch_name: branchMap[d.branch_id] || 'غير معين' })))
  }

  async function fetchBranches() {
    const { data } = await supabase.from('branches').select('id, name').eq('status', 'نشط').order('name')
    setBranches(data || [])
  }

  async function fetchTransfers() {
    const { data } = await supabase
      .from('delivery_transfer_history')
      .select('*, old_branch:old_branch_id(name), new_branch:new_branch_id(name)')
      .order('transferred_at', { ascending: false })
      .limit(50)
    setTransfers(data || [])
  }

  function getEmployeeName(e: DeliveryEmployee) {
    return e.full_name || 'مندوب'
  }

  function getOnlineStatus(e: DeliveryEmployee) {
    return e.is_online ?? false
  }

  async function handleTransfer() {
    if (!selectedEmployee || !selectedNewBranch) {
      toast.error('يرجى اختيار مندوب وفرع جديد')
      return
    }
    if (selectedEmployee.branch_id === selectedNewBranch) {
      toast.error('المندوب موجود بالفعل في هذا الفرع')
      return
    }
    setTransferring(true)
    try {
      const { error } = await supabase.rpc('transfer_delivery_employee', {
        p_employee_id: selectedEmployee.id,
        p_new_branch_id: selectedNewBranch,
        p_reason: transferReason
      })
      if (error) { toast.error('فشل النقل: ' + error.message); return }
      toast.success(`تم نقل ${getEmployeeName(selectedEmployee)} بنجاح`)
      setSelectedEmployee(null)
      setSelectedNewBranch('')
      setTransferReason('')
      loadData()
    } catch (e: any) {
      toast.error('فشل النقل: ' + e.message)
    } finally {
      setTransferring(false)
    }
  }

  const filtered = employees.filter(e =>
    !search || getEmployeeName(e).includes(search) || e.phone?.includes(search)
  )

  return (
    <div className="animate-in">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h1 className="brand-name" style={{ fontSize: 24 }}>نقل المناديب</h1>
          <p className="brand-sub">نقل مندوب من فرع إلى آخر مع الحفاظ على جميع البيانات</p>
        </div>
        <div style={{ display: 'flex', gap: 12 }}>
          <button className="btn btn-outline" onClick={() => setShowHistory(v => !v)} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <Clock size={16} /> {showHistory ? 'إخفاء السجل' : 'سجل النقل'}
          </button>
          <div style={{ position: 'relative' }}>
            <Search size={16} style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--gray400)' }} />
            <input type="text" placeholder="بحث بالاسم أو الهاتف..." className="form-input"
              style={{ paddingRight: 36, width: 220 }} value={search} onChange={e => setSearch(e.target.value)} />
          </div>
        </div>
      </div>

      {/* Transfer History Panel */}
      {showHistory && (
        <div className="card" style={{ marginBottom: 24, padding: 20, maxHeight: 300, overflowY: 'auto' }}>
          <h3 style={{ fontWeight: 700, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
            <Clock size={18} /> سجل النقل
          </h3>
          {transfers.length === 0 ? (
            <p style={{ color: 'var(--gray400)', fontSize: 14 }}>لا يوجد سجل نقل بعد</p>
          ) : (
            <div style={{ display: 'grid', gap: 12 }}>
              {transfers.map(t => (
                <div key={t.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: 12, background: 'var(--gray50)', borderRadius: 12, fontSize: 13 }}>
                  <ArrowLeftRight size={16} style={{ color: 'var(--g500)', flexShrink: 0 }} />
                  <span style={{ fontWeight: 600 }}>{t.old_branch?.name || 'غير معروف'}</span>
                  <ArrowLeftRight size={14} style={{ color: 'var(--gray400)' }} />
                  <span style={{ fontWeight: 600, color: 'var(--g700)' }}>{t.new_branch?.name || 'غير معروف'}</span>
                  <span style={{ color: 'var(--gray400)', marginRight: 'auto' }}>{t.reason}</span>
                  <span style={{ color: 'var(--gray400)', fontSize: 11 }}>{new Date(t.transferred_at).toLocaleDateString('ar-IQ')}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {loading ? (
        <div style={{ display: 'flex', justifyContent: 'center', padding: 80 }}>
          <Loader2 size={32} className="spin" style={{ color: 'var(--g500)' }} />
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))', gap: 20 }}>
          {filtered.map(emp => (
            <div key={emp.id} className="card" style={{ padding: 0, overflow: 'hidden', border: selectedEmployee?.id === emp.id ? '2px solid var(--g500)' : '1px solid var(--gray100)' }}>
              <div style={{ padding: 20, borderBottom: '1px solid var(--gray100)', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                  <div style={{ position: 'relative' }}>
                    <div style={{ width: 52, height: 52, borderRadius: 14, background: 'var(--g50)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--g600)', border: '2px solid var(--g100)' }}>
                      <User size={24} />
                    </div>
                    <div style={{ position: 'absolute', bottom: -2, right: -2, width: 14, height: 14, borderRadius: '50%', border: '3px solid white', background: getOnlineStatus(emp) ? '#10b981' : '#9ca3af' }} />
                  </div>
                  <div>
                    <h3 style={{ fontWeight: 800, fontSize: 15, color: 'var(--gray900)' }}>{getEmployeeName(emp)}</h3>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'var(--gray400)', marginTop: 4 }}>
                      <BadgeCheck size={14} style={{ color: '#10b981' }} />
                      <span style={{ fontSize: 12 }}>{emp.total_deliveries} توصيلة</span>
                    </div>
                  </div>
                </div>
                <span className={`badge ${emp.status === 'online' ? 'badge-green' : 'badge-gray'}`}>
                  {emp.status === 'online' ? 'متصل' : 'غير متصل'}
                </span>
              </div>

              <div style={{ padding: 16 }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', background: 'var(--gray50)', borderRadius: 12, border: '1px solid var(--gray100)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: 'var(--gray600)' }}>
                    <GitBranch size={16} style={{ color: 'var(--g600)' }} />
                    <span style={{ fontWeight: 700 }}>الفرع الحالي:</span>
                  </div>
                  <span style={{ fontSize: 13, fontWeight: 800, color: 'var(--gray900)' }}>{emp.branch_name}</span>
                </div>

                {emp.phone && (
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', background: 'var(--gray50)', borderRadius: 12, border: '1px solid var(--gray100)', marginTop: 8 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: 'var(--gray600)' }}>
                      <Phone size={16} style={{ color: 'var(--g600)' }} />
                      <span style={{ fontWeight: 700 }}>الهاتف:</span>
                    </div>
                    <span style={{ fontSize: 13, fontWeight: 800, color: 'var(--gray900)' }}>{emp.phone}</span>
                  </div>
                )}
              </div>

              <div style={{ padding: '0 20px 20px' }}>
                <button className="btn btn-primary" style={{ width: '100%', height: 44, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}
                  onClick={() => { setSelectedEmployee(emp); setSelectedNewBranch(''); setTransferReason('') }}>
                  <ArrowLeftRight size={18} /> نقل المندوب
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {filtered.length === 0 && !loading && (
        <div className="empty-state" style={{ padding: '80px 20px', textAlign: 'center' }}>
          <div style={{ width: 80, height: 80, borderRadius: '50%', background: 'var(--gray100)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 16px' }}>
            <User size={36} style={{ color: 'var(--gray300)' }} />
          </div>
          <p style={{ color: 'var(--gray400)', fontWeight: 700 }}>لا يوجد مناديب مسجلين</p>
        </div>
      )}

      {/* Transfer Modal */}
      {selectedEmployee && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}
          onClick={() => !transferring && setSelectedEmployee(null)}>
          <div className="card" style={{ width: 480, maxWidth: '90vw', padding: 32 }} onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
              <h3 style={{ fontWeight: 800, fontSize: 18 }}>نقل {getEmployeeName(selectedEmployee)}</h3>
              <button className="btn btn-ghost" onClick={() => setSelectedEmployee(null)} disabled={transferring}>
                <X size={20} />
              </button>
            </div>

            <div style={{ marginBottom: 20, padding: 16, background: 'var(--gray50)', borderRadius: 12, border: '1px solid var(--gray100)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
                <span style={{ fontSize: 13, color: 'var(--gray500)' }}>الفرع الحالي</span>
                <span style={{ fontWeight: 700, fontSize: 15 }}>{selectedEmployee.branch_name}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontSize: 13, color: 'var(--gray500)' }}>إجمالي التوصيلات</span>
                <span style={{ fontWeight: 700 }}>{selectedEmployee.total_deliveries}</span>
              </div>
            </div>

            <div style={{ marginBottom: 20 }}>
              <label style={{ display: 'block', marginBottom: 8, fontWeight: 700, fontSize: 14, color: 'var(--gray700)' }}>
                الفرع الجديد
              </label>
              <select className="form-input" value={selectedNewBranch} onChange={e => setSelectedNewBranch(e.target.value)}
                style={{ width: '100%', padding: '12px 16px' }}>
                <option value="">-- اختر الفرع --</option>
                {branches.filter(b => b.id !== selectedEmployee.branch_id).map(b => (
                  <option key={b.id} value={b.id}>{b.name}</option>
                ))}
              </select>
            </div>

            <div style={{ marginBottom: 24 }}>
              <label style={{ display: 'block', marginBottom: 8, fontWeight: 700, fontSize: 14, color: 'var(--gray700)' }}>
                سبب النقل (اختياري)
              </label>
              <input type="text" className="form-input" placeholder="مثال: إعادة توزيع المناديب" style={{ width: '100%' }}
                value={transferReason} onChange={e => setTransferReason(e.target.value)} />
            </div>

            <div style={{ display: 'flex', gap: 12 }}>
              <button className="btn btn-outline" style={{ flex: 1, height: 44 }} onClick={() => setSelectedEmployee(null)} disabled={transferring}>
                إلغاء
              </button>
              <button className="btn btn-primary" style={{ flex: 1, height: 44, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}
                onClick={handleTransfer} disabled={!selectedNewBranch || transferring}>
                {transferring ? <Loader2 size={18} className="spin" /> : <ArrowLeftRight size={18} />}
                {transferring ? 'جاري النقل...' : 'تأكيد النقل'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
