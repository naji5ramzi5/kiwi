import { TrendingUp, ShoppingBag, Users, AlertCircle, ArrowUpRight, Package } from 'lucide-react'

interface StatCardsProps {
  totalSales: number
  deliveredOrders: number
  lowStockCount: number
  activeDriversCount: number
  totalDrivers: number
}

export default function StatCards({ totalSales, deliveredOrders, lowStockCount, activeDriversCount, totalDrivers }: StatCardsProps) {
  return (
    <div className="stats-grid">
      <div className="stat-card stat-green">
        <div className="stat-icon-wrap" style={{ background: 'var(--g50)' }}><TrendingUp color="var(--g600)" size={24} /></div>
        <div className="stat-label">إجمالي مبيعات الفروع</div>
        <div className="stat-value">{(totalSales || 0).toLocaleString('ar-IQ')} <span className="text-xs" style={{ fontSize: 13, fontWeight: 500 }}>د.ع</span></div>
        <div className="stat-sub stat-up"><ArrowUpRight size={14} /> مبيعات حية محدثة</div>
      </div>
      <div className="stat-card stat-blue">
        <div className="stat-icon-wrap" style={{ background: '#3b82f615' }}><ShoppingBag color="#3b82f6" size={24} /></div>
        <div className="stat-label">إجمالي المبيعات المسلّمة</div>
        <div className="stat-value">{(deliveredOrders || 0).toLocaleString('ar-IQ')} <span className="text-xs" style={{ fontSize: 13, fontWeight: 500 }}>د.ع</span></div>
        <div className="stat-sub stat-up"><ArrowUpRight size={14} /> من الطلبات المكتملة</div>
      </div>
      <div className="stat-card stat-amber">
        <div className="stat-icon-wrap" style={{ background: '#f59e0b15' }}><Package color="#f59e0b" size={24} /></div>
        <div className="stat-label">منتجات منخفضة المخزون</div>
        <div className="stat-value">{(lowStockCount || 0).toLocaleString('ar-IQ')} <span className="text-xs" style={{ fontSize: 13, fontWeight: 500 }}>صنف</span></div>
        <div className="stat-sub stat-down"><AlertCircle size={14} /> تتطلب توريداً فورياً</div>
      </div>
      <div className="stat-card stat-purple">
        <div className="stat-icon-wrap" style={{ background: '#8b5cf615' }}><Users color="#8b5cf6" size={24} /></div>
        <div className="stat-label">نشاط المناديب</div>
        <div className="stat-value">{(activeDriversCount || 0).toLocaleString('ar-IQ')} <span className="text-xs" style={{ fontSize: 13, fontWeight: 500 }}>مندوب متاح</span></div>
        <div className="stat-sub">من أصل {totalDrivers} مندوب مسجل</div>
      </div>
    </div>
  )
}
