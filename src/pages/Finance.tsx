import { useState, useEffect } from 'react'
import { TrendingUp, DollarSign, Settings, ShieldCheck, HeartPulse, Store, Search } from 'lucide-react'
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

const fmt = (v: number) => v.toLocaleString('ar-IQ');

export default function Finance() {
  const [settlements, setSettlements] = useState<Settlement[]>([]);
  const [loading, setLoading] = useState(true);
  const [ratios, setRatios] = useState({ dev: 0.35, maintenance: 0.10 });
  const [showSettings, setShowSettings] = useState(false);
  const [search, setSearch] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  const stats = settlements.reduce((acc, curr) => ({
    revenue: acc.revenue + curr.total_revenue,
    dev: acc.dev + curr.dev_profit,
    maintenance: acc.maintenance + curr.maintenance_fund,
    branch: acc.branch + curr.branch_profit
  }), { revenue: 0, dev: 0, maintenance: 0, branch: 0 });

  useEffect(() => {
    fetchSettlements();
    fetchSettings();
  }, []);

  async function fetchSettings() {
    const { data } = await supabase.from('system_settings').select('*');
    if (data) {
      const dev = data.find(s => s.key === 'dev_partner_ratio')?.value_decimal || 0.35;
      const maintenance = data.find(s => s.key === 'system_maintenance_ratio')?.value_decimal || 0.10;
      setRatios({ dev, maintenance });
    }
  }

  async function updateRatios() {
    await supabase.from('system_settings').update({ value_decimal: ratios.dev }).eq('key', 'dev_partner_ratio');
    await supabase.from('system_settings').update({ value_decimal: ratios.maintenance }).eq('key', 'system_maintenance_ratio');
    toast.success('تم تحديث نسب الشراكة بنجاح');
    setShowSettings(false);
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
          <p className="brand-sub">توزيع أرباح النظام (المطور، الصيانة، الفروع)</p>
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

      <div className="stats-grid">
        <div className="stat-card stat-green">
          <div className="stat-icon-wrap" style={{ background: 'var(--g50)' }}><TrendingUp color="var(--g600)" /></div>
          <div className="stat-label">إجمالي المبيعات</div>
          <div className="stat-value">{fmt(stats.revenue)} <span style={{ fontSize: 12, fontWeight: 500 }}>د.ع</span></div>
        </div>
        <div className="stat-card stat-blue">
          <div className="stat-icon-wrap" style={{ background: '#dbeafe' }}><ShieldCheck color="#2563eb" /></div>
          <div className="stat-label">حصة المبرمج الشريك ({(ratios.dev * 100).toFixed(0)}%)</div>
          <div className="stat-value">{fmt(stats.dev)} <span style={{ fontSize: 12, fontWeight: 500 }}>د.ع</span></div>
        </div>
        <div className="stat-card stat-purple">
          <div className="stat-icon-wrap" style={{ background: '#ede9fe' }}><HeartPulse color="#7c3aed" /></div>
          <div className="stat-label">صندوق الصيانة ({(ratios.maintenance * 100).toFixed(0)}%)</div>
          <div className="stat-value">{fmt(stats.maintenance)} <span style={{ fontSize: 12, fontWeight: 500 }}>د.ع</span></div>
        </div>
        <div className="stat-card stat-amber">
          <div className="stat-icon-wrap" style={{ background: '#fff7ed' }}><Store color="#ea580c" /></div>
          <div className="stat-label">صافي أرباح الفروع</div>
          <div className="stat-value">{fmt(stats.branch)} <span style={{ fontSize: 12, fontWeight: 500 }}>د.ع</span></div>
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
                <th>الصيانة</th>
                <th>الفرع</th>
              </tr>
            </thead>
            <tbody>
              {settlements.filter(s => {
                if (search && !s.branches?.name?.includes(search)) return false;
                if (startDate) { const d = new Date(s.created_at).toISOString().slice(0, 10); if (d < startDate) return false; }
                if (endDate) { const d = new Date(s.created_at).toISOString().slice(0, 10); if (d > endDate) return false; }
                return true;
              }).map((s) => (
                <tr key={s.id}>
                  <td style={{ fontSize: 13 }}>{new Date(s.created_at).toLocaleDateString('ar-IQ')}</td>
                  <td style={{ fontWeight: 700 }}>{s.branches?.name}</td>
                  <td>{fmt(s.total_revenue)}</td>
                  <td style={{ fontWeight: 700, color: '#2563eb' }}>{fmt(s.dev_profit)}</td>
                  <td style={{ fontWeight: 700, color: '#7c3aed' }}>{fmt(s.maintenance_fund)}</td>
                  <td style={{ fontWeight: 700, color: 'var(--g600)' }}>{fmt(s.branch_profit)}</td>
                </tr>
              ))}
              {settlements.length === 0 && (
                <tr><td colSpan={6} style={{ textAlign: 'center', color: 'var(--gray400)', padding: '40px 0' }}>لا توجد تسويات مالية بعد</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {showSettings && (
        <div className="modal-overlay" onClick={() => setShowSettings(false)}>
          <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 400 }}>
            <h2 className="modal-title">تعديل نسب الشراكة</h2>
            <div className="form-group">
              <label className="form-label">نسبة المبرمج الشريك (مثلاً 0.35)</label>
              <input 
                type="number" step="0.01" className="form-input" 
                value={ratios.dev} onChange={e => setRatios({...ratios, dev: parseFloat(e.target.value)})}
              />
            </div>
            <div className="form-group">
              <label className="form-label">نسبة الصيانة والسيرفر (مثلاً 0.10)</label>
              <input 
                type="number" step="0.01" className="form-input" 
                value={ratios.maintenance} onChange={e => setRatios({...ratios, maintenance: parseFloat(e.target.value)})}
              />
            </div>
            <p style={{ fontSize: 11, color: 'var(--gray400)', marginTop: 16 }}>المتبقي سيتم احتسابه تلقائياً كصافي ربح لصاحب الفرع.</p>
            <div style={{ display: 'flex', gap: 12, marginTop: 20 }}>
              <button className="btn btn-primary" style={{ flex: 1 }} onClick={updateRatios}>حفظ النسب الجديدة</button>
              <button className="btn btn-ghost" onClick={() => setShowSettings(false)}>إلغاء</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
