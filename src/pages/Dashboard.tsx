import { useState, useEffect } from 'react'
import { MapPin } from 'lucide-react'
import { supabase } from '../lib/supabase'
import { ORDER_STATUS } from '../lib/orderStatus'
import LiveMap from '../components/LiveMap'
import StatCards from '../components/dashboard/StatCards'
import BranchTable from '../components/dashboard/BranchTable'
import LowStockAlerts from '../components/dashboard/LowStockAlerts'
import SalesChart from '../components/dashboard/SalesChart'

interface BranchRow {
  id: string; name: string; status: string;
  latitude: number; longitude: number;
}
interface BranchStats {
  branchId: string; name: string; status: string;
  sales: number; purchases: number;
  stockTotal: number; stockInGood: number;
  driversCount: number; lastOrderAt: string | null;
}

export default function Dashboard() {
  const [branches, setBranches] = useState<BranchRow[]>([])
  const [drivers, setDrivers] = useState<any[]>([])
  const [branchStats, setBranchStats] = useState<Record<string, BranchStats>>({})
  const [lowStockAlerts, setLowStockAlerts] = useState<{ branch: string; productId: string; stock: number }[]>([])
  const [categoryData, setCategoryData] = useState<{ name: string; value: number }[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => { fetchDashboardData() }, [])

  async function fetchDashboardData() {
    setLoading(true)
    try {
      const [branchesRes, driversRes, ordersRes, inventoryRes, purchasesRes, categoryRes] = await Promise.all([
        supabase.from('branches').select('id, name, status, latitude, longitude'),
        supabase.from('drivers').select('id, branch_id, is_active, current_status'),
        supabase.from('orders').select('id, branch_id, status, total_amount, total_price, created_at'),
        supabase.from('branch_inventory').select('id, branch_id, product_id, actual_stock, buffer_limit, branches!inner(name)'),
        supabase.from('purchases').select('id, branch_id, total_value'),
        supabase.from('order_items').select('quantity, unit_price, total_price, products!inner(category)'),
      ])

      const branchesData = (branchesRes.data || []) as BranchRow[]
      const driversData = driversRes.data || []
      const ordersData = ordersRes.data || []
      const inventoryData = inventoryRes.data || []
      const purchasesData = purchasesRes.data || []
      const categoryItems = categoryRes.data || []

      setBranches(branchesData)
      setDrivers(driversData)

      // Build per-branch stats
      const stats: Record<string, BranchStats> = {}
      for (const b of branchesData) {
        stats[b.id] = {
          branchId: b.id, name: b.name, status: b.status,
          sales: 0, purchases: 0, stockTotal: 0, stockInGood: 0, driversCount: 0, lastOrderAt: null,
        }
      }

      // Orders aggregation
      for (const o of ordersData as any[]) {
        const s = stats[o.branch_id]
        if (!s) continue
        const delivered = o.status === ORDER_STATUS.DELIVERED || o.status === 'مكتمل'
        if (delivered) s.sales += Number(o.total_amount || o.total_price || 0)
        if (!s.lastOrderAt || (o.created_at && o.created_at > s.lastOrderAt)) s.lastOrderAt = o.created_at
      }

      // Purchases aggregation
      for (const p of purchasesData as any[]) {
        const s = stats[p.branch_id]
        if (s) s.purchases += Number(p.total_value || 0)
      }

      // Inventory aggregation
      const alerts: typeof lowStockAlerts = []
      for (const inv of inventoryData as any[]) {
        const s = stats[inv.branch_id]
        if (!s) continue
        s.stockTotal++
        const buffer = inv.buffer_limit || 2
        if (inv.actual_stock > buffer) s.stockInGood++
        else alerts.push({ branch: inv.branches?.name || '', productId: inv.product_id, stock: inv.actual_stock })
      }

      // Drivers aggregation
      for (const d of driversData as any[]) {
        const s = stats[d.branch_id]
        if (s) s.driversCount++
      }

      setBranchStats(stats)
      setLowStockAlerts(alerts.slice(0, 6))

      // Category sales aggregation
      const catMap: Record<string, number> = {}
      for (const item of categoryItems as any[]) {
        const cat = item.products?.category || 'أخرى'
        catMap[cat] = (catMap[cat] || 0) + Number(item.total_price || (item.quantity * (item.unit_price || 0)))
      }
      setCategoryData(
        Object.entries(catMap)
          .map(([name, value]) => ({ name, value: Math.round(value) }))
          .sort((a, b) => b.value - a.value)
          .slice(0, 6)
      )
    } catch (err) {
      console.error('Dashboard fetch error:', err)
    } finally {
      setLoading(false)
    }
  }

  // Computed aggregates
  const statsArr = Object.values(branchStats)
  const totalSales = statsArr.reduce((s, b) => s + b.sales, 0)
  const lowStockCount = lowStockAlerts.length
  const activeDriversCount = drivers.filter((d: any) => d.is_active && d.current_status === 'متاح').length
  const deliveredOrders = statsArr.reduce((s, b) => s + b.sales, 0)

  return (
    <div className="animate-in">
      <div style={{ marginBottom: 24 }}>
        <h1 className="brand-name" style={{ fontSize: 24 }}>المراقبة المركزية</h1>
        <p className="brand-sub">متابعة أداء الفروع والمبيعات والمخزون في الوقت الحقيقي</p>
      </div>

      <StatCards
        totalSales={totalSales}
        deliveredOrders={deliveredOrders}
        lowStockCount={lowStockCount}
        activeDriversCount={activeDriversCount}
        totalDrivers={drivers.length}
      />

      {/* Live Operations Map */}
      <div className="card" style={{ marginBottom: 24, padding: 0, overflow: 'hidden' }}>
        <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--gray100)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h3 className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <MapPin size={20} color="var(--g600)" /> خريطة العمليات الحية (فروع ومناديب)
          </h3>
          <div style={{ display: 'flex', gap: 12 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12 }}>
              <div style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--g500)' }} /> فرع نشط
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12 }}>
              <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#3b82f6' }} /> مندوب في مهمة
            </div>
          </div>
        </div>
        <LiveMap branches={branches} />
      </div>

      <div className="grid-2">
        <BranchTable
          branches={branches}
          branchStats={branchStats}
          loading={loading}
          onRefresh={fetchDashboardData}
        />

        <LowStockAlerts alerts={lowStockAlerts} />

        <SalesChart data={categoryData} />
      </div>
    </div>
  )
}
