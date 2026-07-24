import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from 'recharts'

interface CategoryDatum {
  name: string
  value: number
}

interface SalesChartProps {
  data: CategoryDatum[]
}

const COLORS = ['#10b981', '#3b82f6', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899']

export default function SalesChart({ data }: SalesChartProps) {
  return (
    <div className="card">
      <div className="card-header"><h3 className="card-title">توزيع المبيعات حسب التصنيف</h3></div>
      <div className="card-body">
        {data.length > 0 ? (
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={data} layout="vertical" margin={{ top: 5, right: 20, left: 10, bottom: 5 }}>
              <XAxis type="number" tick={{ fontSize: 11 }} />
              <YAxis type="category" dataKey="name" tick={{ fontSize: 12 }} width={70} />
              <Tooltip
                formatter={(value: number) => [`${value.toLocaleString('ar-IQ')} د.ع`, 'المبيعات']}
                contentStyle={{ borderRadius: 8, fontSize: 12 }}
              />
              <Bar dataKey="value" radius={[0, 6, 6, 0]}>
                {data.map((_, i) => (
                  <Cell key={i} fill={COLORS[i % COLORS.length]} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        ) : (
          <div style={{ height: 200, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--gray400)', fontSize: 13 }}>
            لا توجد بيانات مبيعات بعد
          </div>
        )}
      </div>
    </div>
  )
}
