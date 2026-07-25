import { useState, useEffect } from 'react'
import { TrendingUp, DollarSign, Settings, ShieldCheck, HeartPulse, Store, Search, Users, Loader } from 'lucide-react'
import { supabase } from '../lib/supabase'
import toast from 'react-hot-toast'
import DateRangePicker from '../components/DateRangePicker'

interface Settlement {
  id: string;
  total_revenue: number;
  dev_profit: number;
  maintenance_fund: number;
  branch_profit: number;
  created_at: string;
  branches: { name: string };
}

interface PartnerRatio {
  key: string;
  value_decimal: number;
  label: string;
  color: string;
  icon: typeof ShieldCheck;
}

const fmt = (v: number) => v.toLocaleString('ar-IQ');

export default function Finance() {
  const [settlements, setSettlements] = useState<Settlement[]>([]);
  const [loading, setLoading] = useState(true);
  const [showSettings, setShowSettings] = useState(false);
  const [search, setSearch] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [savingPartners, setSavingPartners] = useState(false);
  
  const [partners, setPartners] = useState<PartnerRatio[]>([
    { key: 'dev_partner_ratio', value_decimal: 0.35, label: 'حصة المبرمج الشريك', color: '#2563eb', icon: ShieldCheck },
    { key: 'owner_partner_ratio', value_decimal: 0.55, label: 'حصة صاحب المشروع', color: '#d97706', icon: Store },
    { key: 'system_maintenance_ratio', value_decimal: 0.10, label: 'صندوق الصيانة والسيرفر', color: '#7c3aed', icon: HeartPulse },
  ]);

  const totalPercent = partners.reduce((sum, p) => sum + (p.value_decimal * 100), 0);

  const filteredSettlements = settlements.filter(s => {
    if (search && !s.branches?.name?.includes(search)) return false;
    if (startDate) { const d = new Date(s.created_at).toISOString().slice(0, 10); if (d < startDate) return false; }
    if (endDate) { const d = new Date(s.created_at).toISOString().slice(0, 10); if (d > endDate) return false; }
    return true;
  });

  const stats = filteredSettlements.reduce((acc, curr) => ({
    revenue: acc.revenue + curr.total_revenue,
    dev: acc.dev + curr.dev_profit,
    maintenance: acc.maintenance + curr.maintenance_fund,
    branch: acc.branch + curr.branch_profit
  }), { revenue: 0, dev: 0, maintenance: 0, branch: 0 });

  // Calculate owner profit from live percentages
  const ownerProfit = stats.revenue * (partners[1]?.value_decimal || 0.55);

  useEffect(() => {
    fetchSettlements();
    fetchPartnerSettings();
  }, []);

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
      setShowSettings(false)
    } catch (err: unknown) {
      toast.error('خطأ في الحفظ: ' + ((err as Error).message))
    } finally {
      setSavingPartners(false)
    }
  }

  async function fetchSettlements() {
    try {
      const { data, error } = await supabase
        .from('partner_settlements')
        .select('*, branches(name)')
        .order('created_at', { ascending: false });
      if (error) throw error;
      setSettlements(data || []);
    } catch (err) {
      toast.error('خطأ في جلب البيانات المالية');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="animate-in">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h1 className="brand-name" style={{ fontSize: 24 }}>التقارير المالية والشركاء</h1>
          <p className="brand-sub">توزيع أرباح النظام (المطور، الصيانة، صاحب المشروع، الفروع)</p>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{ position: 'relative' }}>
            <Search size={16} style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--gray400)' }} />
            <input
              type="text"
              placeholder="بحث بالفرع..."
              className="form-input"
              style={{ paddingRight: 36, width: 200 }}
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
          </div>
          <button className="btn btn-outline" onClick={() => setShowSettings(true)}>
            <Settings size={18} /> إعدادات النسب
          </button>
        </div>
      </div>

      {/* Date Range Filter */}
      <div style={{ marginBottom: 20, display: 'flex', gap: 12 }}>
        <DateRangePicker
          startDate={startDate}
          endDate={endDate}
          onStartDateChange={setStartDate}
          onEndDateChange={setEndDate}
          label="تصفية حسب التاريخ"
        />
        {(startDate || endDate) && (
          <button className="btn btn-ghost btn-sm" onClick={() => { setStartDate(''); setEndDate('') }}>
            مسح الفلتر
          </button>
        )}
      </div>

      {/* Stats Cards — Dynamic from DB percentages */}
      <div className="stats-grid">
        <div className="stat-card stat-green">
          <div className="stat-icon-wrap" style={{ background: 'var(--g50)' }}><TrendingUp color="var(--g600)" /></div>
          <div className="stat-label">إجمالي المبيعات</div>
          <div className="stat-value">{fmt(stats.revenue)} <span style={{ fontSize: 12, fontWeight: 500 }}>د.ع</span></div>
        </div>
        <div className="stat-card stat-blue">
          <div className="stat-icon-wrap" style={{ background: '#dbeafe' }}><ShieldCheck color="#2563eb" /></div>
          <div className="stat-label">حصة المبرمج ({(partners[0].value_decimal * 100).toFixed(0)}%)</div>
          <div className="stat-value">{fmt(stats.revenue * partners[0].value_decimal)} <span style={{ fontSize: 12, fontWeight: 500 }}>د.ع</span></div>
        </div>
        <div className="stat-card stat-amber">
          <div className="stat-icon-wrap" style={{ background: '#fef3c7' }}><Store color="#d97706" /></div>
          <div className="stat-label">حصة صاحب المشروع ({(partners[1].value_decimal * 100).toFixed(0)}%)</div>
          <div className="stat-value">{fmt(ownerProfit)} <span style={{ fontSize: 12, fontWeight: 500 }}>د.ع</span></div>
        </div>
        <div className="stat-card stat-purple">
          <div className="stat-icon-wrap" style={{ background: '#ede9fe' }}><HeartPulse color="#7c3aed" /></div>
          <div className="stat-label">صندوق الصيانة ({(partners[2].value_decimal * 100).toFixed(0)}%)</div>
          <div className="stat-value">{fmt(stats.revenue * partners[2].value_decimal)} <span style={{ fontSize: 12, fontWeight: 500 }}>د.ع</span></div>
        </div>
      </div>

      {/* Partnership Summary Bar */}
      <div className="card" style={{ marginBottom: 20 }}>
        <div style={{ padding: 16, display: 'flex', alignItems: 'center', gap: 16, flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, fontWeight: 700, color: 'var(--gray700)' }}>
            <Users size={16} /> نسب الشراكة الحالية:
          </div>
          {partners.map(p => (
            <div key={p.key} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '4px 12px', borderRadius: 8, background: p.color + '15', color: p.color, fontSize: 12, fontWeight: 700 }}>
              <div style={{ width: 8, height: 8, borderRadius: '50%', background: p.color }}></div>
              {p.label}: {(p.value_decimal * 100).toFixed(0)}%
            </div>
          ))}
          <div style={{ fontSize: 12, color: totalPercent === 100 ? 'var(--g600)' : '#ef4444', fontWeight: 700 }}>
            المجموع: {totalPercent.toFixed(0)}%
          </div>
        </div>
      </div>

      <div className="card">
        <div className="card-header">
          <span className="card-title">سجل التسويات التفصيلية</span>
        </div>
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>التاريخ</th>
                <th>الفرع</th>
                <th>المبلغ</th>
                <th>المبرمج</th>
                <th>صاحب المشروع</th>
                <th>الصيانة</th>
                <th>الفرع</th>
              </tr>
            </thead>
            <tbody>
              {filteredSettlements.map((s) => (
                <tr key={s.id}>
                  <td style={{ fontSize: 13 }}>{new Date(s.created_at).toLocaleDateString('ar-IQ')}</td>
                  <td style={{ fontWeight: 700 }}>{s.branches?.name}</td>
                  <td>{fmt(s.total_revenue)}</td>
                  <td style={{ fontWeight: 700, color: '#2563eb' }}>{fmt(s.total_revenue * partners[0].value_decimal)}</td>
                  <td style={{ fontWeight: 700, color: '#d97706' }}>{fmt(s.total_revenue * partners[1].value_decimal)}</td>
                  <td style={{ fontWeight: 700, color: '#7c3aed' }}>{fmt(s.total_revenue * partners[2].value_decimal)}</td>
                  <td style={{ fontWeight: 700, color: 'var(--g600)' }}>{fmt(s.branch_profit)}</td>
                </tr>
              ))}
              {filteredSettlements.length === 0 && (
                <tr><td colSpan={7} style={{ textAlign: 'center', color: 'var(--gray400)', padding: '40px 0' }}>لا توجد تسويات مالية بعد</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Partnership Settings Modal */}
      {showSettings && (
        <div className="modal-overlay" onClick={() => setShowSettings(false)}>
          <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 450 }}>
            <h2 className="modal-title" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Users size={20} /> تعديل نسب الشراكة
            </h2>
            
            {partners.map((partner, idx) => {
              const Icon = partner.icon
              return (
                <div key={partner.key} style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16, padding: '12px 16px', background: 'var(--gray50)', borderRadius: 12 }}>
                  <div style={{ width: 36, height: 36, borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', background: partner.color + '20', color: partner.color, flexShrink: 0 }}>
                    <Icon size={18} />
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontWeight: 700, fontSize: 13 }}>{partner.label}</div>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                    <input 
                      type="number" step="1" min="0" max="100"
                      className="form-input" 
                      style={{ width: 70, textAlign: 'center', fontWeight: 700 }}
                      value={Math.round(partner.value_decimal * 100)}
                      onChange={e => {
                        const val = Math.min(100, Math.max(0, parseInt(e.target.value) || 0))
                        setPartners(prev => prev.map((p, i) => i === idx ? { ...p, value_decimal: val / 100 } : p))
                      }}
                    />
                    <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--gray500)' }}>%</span>
                  </div>
                </div>
              )
            })}

            <div style={{ padding: '10px 14px', borderRadius: 10, marginBottom: 16, fontSize: 12, fontWeight: 700,
              background: totalPercent === 100 ? '#ecfdf5' : totalPercent > 100 ? '#fef2f2' : '#fffbeb',
              color: totalPercent === 100 ? '#065f46' : totalPercent > 100 ? '#991b1b' : '#92400e'
            }}>
              المجموع: {totalPercent.toFixed(0)}%
              {totalPercent < 100 && ` — المتبقي ${(100 - totalPercent).toFixed(0)}% لصاحب الفرع`}
              {totalPercent > 100 && ' — النسب تجاوزت 100%!'}
            </div>

            <div style={{ display: 'flex', gap: 12 }}>
              <button className="btn btn-primary" style={{ flex: 1 }} onClick={savePartnerSettings} disabled={savingPartners || totalPercent > 100}>
                {savingPartners ? <><Loader size={16} className="spin" /> جاري الحفظ...</> : 'حفظ النسب'}
              </button>
              <button className="btn btn-ghost" onClick={() => setShowSettings(false)}>إلغاء</button>
            </div>
          </div>
        </div>
      )}

      <style>{`.spin { animation: spin 1s linear infinite; } @keyframes spin { from{transform:rotate(0)} to{transform:rotate(360deg)} }`}</style>
    </div>
  )
}
