import { useEffect, useState, useCallback } from 'react'
import { supabase } from './supabase'
import type { Branch, Product, Order, Driver, Profile, InventoryWithProduct, Purchase } from './types'

// ── Stats for Dashboard ──
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

  const fetch = useCallback(async () => {
    setLoading(true)
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    const [orders, branches, drivers, customers, products] = await Promise.all([
      supabase.from('orders').select('id, total_amount, status, created_at'),
      supabase.from('branches').select('id, status'),
      supabase.from('drivers').select('id, is_active'),
      supabase.from('profiles').select('id').eq('role', 'customer'),
      supabase.from('products').select('id').eq('is_active', true),
    ])

    const ordersData = orders.data || []
    const activeStatuses = ['قيد الانتظار', 'تحضير', 'توصيل']

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
  return { stats, loading, refetch: fetch }
}

// ── Orders ──
export function useOrders(limit = 100) {
  const [orders, setOrders] = useState<Order[]>([])
  const [loading, setLoading] = useState(true)

  const fetch = useCallback(async () => {
    setLoading(true)
    const { data } = await supabase
      .from('orders')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(limit)
    setOrders(data || [])
    setLoading(false)
  }, [limit])

  useEffect(() => {
    fetch()
    // Realtime subscription
    const channel = supabase
      .channel('orders-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'orders' }, () => fetch())
      .subscribe()
    return () => { supabase.removeChannel(channel) }
  }, [fetch])

  return { orders, loading, refetch: fetch }
}

// ── Branches ──
export function useBranches() {
  const [branches, setBranches] = useState<Branch[]>([])
  const [loading, setLoading] = useState(true)

  const fetch = useCallback(async () => {
    setLoading(true)
    const { data } = await supabase.from('branches').select('*').order('created_at', { ascending: false })
    setBranches(data || [])
    setLoading(false)
  }, [])

  useEffect(() => { fetch() }, [fetch])
  return { branches, loading, refetch: fetch }
}

// ── Products ──
export function useProducts() {
  const [products, setProducts] = useState<Product[]>([])
  const [loading, setLoading] = useState(true)

  const fetch = useCallback(async () => {
    setLoading(true)
    const { data } = await supabase.from('products').select('*').order('created_at', { ascending: false })
    setProducts(data || [])
    setLoading(false)
  }, [])

  useEffect(() => { fetch() }, [fetch])
  return { products, loading, refetch: fetch }
}

// ── Drivers ──
export function useDrivers() {
  const [drivers, setDrivers] = useState<(Driver & { profiles?: Pick<Profile, 'full_name' | 'phone'> | null })[]>([])
  const [loading, setLoading] = useState(true)

  const fetch = useCallback(async () => {
    setLoading(true)
    const { data } = await supabase
      .from('drivers')
      .select('*, profiles(full_name, phone)')
      .order('updated_at', { ascending: false })
    setDrivers(data || [])
    setLoading(false)
  }, [])

  useEffect(() => {
    fetch()
    const channel = supabase
      .channel('drivers-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'drivers' }, () => fetch())
      .subscribe()
    return () => { supabase.removeChannel(channel) }
  }, [fetch])

  return { drivers, loading, refetch: fetch }
}

// ── Customers ──
export function useCustomers() {
  const [customers, setCustomers] = useState<Profile[]>([])
  const [loading, setLoading] = useState(true)

  const fetch = useCallback(async () => {
    setLoading(true)
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'customer')
      .order('created_at', { ascending: false })
    setCustomers(data || [])
    setLoading(false)
  }, [])

  useEffect(() => { fetch() }, [fetch])
  return { customers, loading, refetch: fetch }
}

// ── Inventory ──
export function useInventory(branchId?: string) {
  const [inventory, setInventory] = useState<InventoryWithProduct[]>([])
  const [loading, setLoading] = useState(true)

  const fetch = useCallback(async () => {
    setLoading(true)
    let query = supabase.from('inventory').select('*, products(name, category, unit, price), branches(name)')
    if (branchId) query = query.eq('branch_id', branchId)
    const { data } = await query.order('updated_at', { ascending: false })
    setInventory((data as InventoryWithProduct[]) || [])
    setLoading(false)
  }, [branchId])

  useEffect(() => {
    fetch()
    const channel = supabase
      .channel('inventory-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'inventory' }, () => fetch())
      .subscribe()
    return () => { supabase.removeChannel(channel) }
  }, [fetch])

  return { inventory, loading, refetch: fetch }
}

// ── Purchases ──
export function usePurchases() {
  const [purchases, setPurchases] = useState<Purchase[]>([])
  const [loading, setLoading] = useState(true)

  const fetch = useCallback(async () => {
    setLoading(true)
    const { data } = await supabase.from('purchases').select('*').order('created_at', { ascending: false })
    setPurchases(data || [])
    setLoading(false)
  }, [])

  useEffect(() => { fetch() }, [fetch])
  return { purchases, loading, refetch: fetch }
}

// ── MUTATIONS ──

export async function updateOrderStatus(id: string, status: string) {
  return supabase.from('orders').update({ status }).eq('id', id)
}

export async function updateDriverStatus(id: string, current_status: string) {
  return supabase.from('drivers').update({ current_status, updated_at: new Date().toISOString() }).eq('id', id)
}

export async function createBranch(data: { name: string; address: string; city: string; phone: string }) {
  return supabase.from('branches').insert(data).select().single()
}

export async function updateBranchStatus(id: string, status: string) {
  return supabase.from('branches').update({ status }).eq('id', id)
}

export async function createProduct(data: { name: string; category: string; unit: string; price: number; cost?: number }) {
  return supabase.from('products').insert(data).select().single()
}

export async function updateProduct(id: string, data: Partial<{ name: string; category: string; unit: string; price: number; cost: number; is_active: boolean }>) {
  return supabase.from('products').update(data).eq('id', id)
}

export async function createPurchase(data: { branch_id: string; supplier_name: string; total_value: number; payment_status: string }) {
  return supabase.from('purchases').insert(data).select().single()
}

export async function updateInventoryStock(id: string, stock_quantity: number) {
  return supabase.from('inventory').update({ stock_quantity, updated_at: new Date().toISOString() }).eq('id', id)
}
