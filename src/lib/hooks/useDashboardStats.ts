import { useEffect, useState, useCallback } from 'react'
import { supabase } from '../supabase'
import { ORDER_STATUS } from '../orderStatus'

export interface DashboardStats {
  totalOrders: number
  activeOrders: number
  totalRevenue: number
  todayRevenue: number
  activeBranches: number
  activeDrivers: number
  totalCustomers: number
  totalProducts: number
}

export function useDashboardStats() {
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetch = useCallback(async () => {
    setLoading(true)
    setError(null)
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    const [orders, branches, drivers, customers, products] = await Promise.all([
      supabase.from('orders').select('id, total_amount, status, created_at'),
      supabase.from('branches').select('id, status'),
      supabase.from('drivers').select('id, is_active'),
      supabase.from('profiles').select('id').eq('role', 'customer'),
      supabase.from('products').select('id').eq('is_active', true),
    ])

    const firstError = [orders, branches, drivers, customers, products].find(r => r.error)
    if (firstError?.error) {
      setError(firstError.error.message)
      setLoading(false)
      return
    }

    const ordersData = orders.data || []
    const activeStatuses = [ORDER_STATUS.PENDING, ORDER_STATUS.PREPARING, ORDER_STATUS.DELIVERING]

    setStats({
      totalOrders: ordersData.length,
      activeOrders: ordersData.filter(o => activeStatuses.includes(o.status)).length,
      totalRevenue: ordersData.filter(o => o.status === 'مكتمل').reduce((s, o) => s + Number(o.total_amount), 0),
      todayRevenue: ordersData.filter(o => o.status === 'مكتمل' && new Date(o.created_at) >= today).reduce((s, o) => s + Number(o.total_amount), 0),
      activeBranches: (branches.data || []).filter(b => b.status === 'نشط').length,
      activeDrivers: (drivers.data || []).filter(d => d.is_active).length,
      totalCustomers: (customers.data || []).length,
      totalProducts: (products.data || []).length,
    })
    setLoading(false)
  }, [])

  useEffect(() => { fetch() }, [fetch])
  return { stats, loading, error, refetch: fetch }
}
