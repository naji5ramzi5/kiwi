import { useEffect, useState, useCallback } from 'react'
import { supabase } from '../supabase'
import type { InventoryWithProduct } from '../types'

export function useInventory(branchId?: string) {
  const [inventory, setInventory] = useState<InventoryWithProduct[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetch = useCallback(async () => {
    setLoading(true)
    setError(null)
    let query = supabase.from('inventory').select('*, products(name, category, unit, price), branches(name)')
    if (branchId) query = query.eq('branch_id', branchId)
    const { data, error: err } = await query.order('updated_at', { ascending: false })
    if (err) { setError(err.message); setLoading(false); return }
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

  return { inventory, loading, error, refetch: fetch }
}
