interface BranchStats {
  branchId: string; name: string; status: string;
  sales: number; purchases: number;
  stockTotal: number; stockInGood: number;
  driversCount: number; lastOrderAt: string | null;
}

interface BranchTableProps {
  branches: { id: string; name: string; status: string }[]
  branchStats: Record<string, BranchStats>
  loading: boolean
  onRefresh: () => void
}

export default function BranchTable({ branches, branchStats, loading, onRefresh }: BranchTableProps) {
  return (
    <div className="card col-span-2">
      <div className="card-header">
        <h3 className="card-title">أداء الفروع (مبيعات ومخزون)</h3>
        <button className="btn btn-ghost btn-sm" onClick={onRefresh}>تحديث البيانات</button>
      </div>
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>الفرع</th>
              <th>الحالة</th>
              <th>المبيعات (د.ع)</th>
              <th>المشتريات (د.ع)</th>
              <th>المخزون المتوفر</th>
              <th>المناديب</th>
              <th>آخر حركة</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={7} style={{ textAlign: 'center', padding: 20 }}>جاري تحميل البيانات...</td></tr>
            ) : branches.length === 0 ? (
              <tr><td colSpan={7} style={{ textAlign: 'center', padding: 20 }}>لا توجد فروع مسجلة</td></tr>
            ) : (
              branches.map(b => {
                const s = branchStats[b.id]
                if (!s) return null
                const stockPercent = s.stockTotal > 0 ? Math.round((s.stockInGood / s.stockTotal) * 100) : 100
                return (
                  <tr key={b.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                        <div className="avatar avatar-sm">{b.name[0]}</div>
                        <span style={{ fontWeight: 700 }}>{b.name}</span>
                      </div>
                    </td>
                    <td><span className={`badge ${b.status === 'نشط' ? 'badge-green' : 'badge-red'}`}>{b.status}</span></td>
                    <td style={{ fontWeight: 800 }}>{s.sales.toLocaleString('ar-IQ')}</td>
                    <td style={{ color: 'var(--gray600)', fontWeight: 700 }}>{s.purchases.toLocaleString('ar-IQ')}</td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <div style={{ width: 60 }}>
                          <div className="progress-bar"><div className="progress-fill" style={{ width: `${stockPercent}%` }} /></div>
                        </div>
                        <span style={{ fontSize: 11, fontWeight: 700 }}>{stockPercent}%</span>
                      </div>
                    </td>
                    <td>{s.driversCount}</td>
                    <td style={{ fontSize: 11, color: 'var(--gray400)' }}>
                      {s.lastOrderAt
                        ? new Date(s.lastOrderAt).toLocaleTimeString('ar-IQ', { hour: '2-digit', minute: '2-digit' })
                        : 'لا يوجد حركة'}
                    </td>
                  </tr>
                )
              })
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
