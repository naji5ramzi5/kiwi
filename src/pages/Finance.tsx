import { useState, useEffect } from 'react'
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts'
import { TrendingUp, DollarSign, Settings, ShieldCheck, HeartPulse, Store } from 'lucide-react'
import { supabase } from '../lib/supabase'
import toast from 'react-hot-toast'

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
    toast.success('تم تحديث نسب الشراكة بنجاح ✅');
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
    <div className="animate-in p-6">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">التقارير المالية والشركاء</h1>
          <p className="text-gray-500">توزيع أرباح النظام (المطور، الصيانة، الفروع)</p>
        </div>
        <button className="btn btn-outline" onClick={() => setShowSettings(true)} style={{ gap: 8 }}>
          <Settings size={18} /> إعدادات النسب
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <StatCard icon={<TrendingUp />} label="إجمالي المبيعات" value={stats.revenue} color="emerald" />
        <StatCard icon={<ShieldCheck />} label="حصة المبرمج الشريك" value={stats.dev} color="blue" sub={`${(ratios.dev * 100).toFixed(0)}%`} />
        <StatCard icon={<HeartPulse />} label="صندوق الصيانة" value={stats.maintenance} color="purple" sub={`${(ratios.maintenance * 100).toFixed(0)}%`} />
        <StatCard icon={<Store />} label="صافي أرباح الفروع" value={stats.branch} color="orange" />
      </div>

      <div className="card" style={{ padding: 0 }}>
        <div style={{ padding: '20px 24px', borderBottom: '1px solid var(--gray100)' }}>
          <h3 className="font-bold">سجل التسويات التفصيلية</h3>
        </div>
        <table className="w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-right text-xs font-bold text-gray-500">التاريخ</th>
              <th className="px-6 py-3 text-right text-xs font-bold text-gray-500">الفرع</th>
              <th className="px-6 py-3 text-right text-xs font-bold text-gray-500">المبلغ</th>
              <th className="px-6 py-3 text-right text-xs font-bold text-gray-500">المبرمج</th>
              <th className="px-6 py-3 text-right text-xs font-bold text-gray-500">الصيانة</th>
              <th className="px-6 py-3 text-right text-xs font-bold text-gray-500">الفرع</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {settlements.map((s) => (
              <tr key={s.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 text-sm">{new Date(s.created_at).toLocaleDateString('ar-IQ')}</td>
                <td className="px-6 py-4 text-sm font-bold">{s.branches?.name}</td>
                <td className="px-6 py-4 text-sm">{fmt(s.total_revenue)}</td>
                <td className="px-6 py-4 text-sm font-bold text-blue-600">{fmt(s.dev_profit)}</td>
                <td className="px-6 py-4 text-sm font-bold text-purple-600">{fmt(s.maintenance_fund)}</td>
                <td className="px-6 py-4 text-sm font-bold text-emerald-600">{fmt(s.branch_profit)}</td>
              </tr>
            ))}
          </tbody>
        </table>
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
            <p className="text-xs text-gray-400 mt-4">المتبقي سيتم احتسابه تلقائياً كصافي ربح لصاحب الفرع.</p>
            <div className="flex gap-4 mt-6">
              <button className="btn btn-primary flex-1" onClick={updateRatios}>حفظ النسب الجديدة</button>
              <button className="btn btn-ghost" onClick={() => setShowSettings(false)}>إلغاء</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function StatCard({ icon, label, value, color, sub }: any) {
  const colors: any = {
    emerald: 'bg-emerald-50 text-emerald-600',
    blue: 'bg-blue-50 text-blue-600',
    purple: 'bg-purple-50 text-purple-600',
    orange: 'bg-orange-50 text-orange-600',
  }
  return (
    <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
      <div className="flex items-center gap-4 mb-2">
        <div className={`p-3 rounded-xl ${colors[color]}`}>{icon}</div>
        <div>
          <p className="text-xs text-gray-500">{label} {sub && <span className="font-bold">({sub})</span>}</p>
          <h3 className="text-xl font-bold">{fmt(value)} <span className="text-xs font-normal">د.ع</span></h3>
        </div>
      </div>
    </div>
  )
}
