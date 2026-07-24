interface LowStockAlert {
  branch: string
  productId: string
  stock: number
}

interface LowStockAlertsProps {
  alerts: LowStockAlert[]
}

export default function LowStockAlerts({ alerts }: LowStockAlertsProps) {
  return (
    <div className="card">
      <div className="card-header"><h3 className="card-title">تنبيهات المنظومة</h3></div>
      <div className="card-body" style={{ padding: 0 }}>
        {alerts.length > 0 ? (
          alerts.map((alert, idx) => (
            <div key={idx} style={{ padding: '16px 20px', borderBottom: '1px solid var(--gray100)', display: 'flex', gap: 12 }}>
              <div className="live-dot red" style={{ marginTop: 6 }} />
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, fontWeight: 600 }}>مخزون منخفض في {alert.branch} للمنتج ID: {alert.productId.substring(0, 8)}</div>
                <div style={{ fontSize: 11, color: 'var(--gray400)', marginTop: 2 }}>الكمية الحالية: {alert.stock}</div>
              </div>
            </div>
          ))
        ) : (
          <div style={{ padding: 30, textAlign: 'center', color: 'var(--gray400)', fontSize: 13 }}>لا توجد تنبيهات مخزون منخفض حالياً</div>
        )}
      </div>
    </div>
  )
}
