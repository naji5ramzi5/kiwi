import { useEffect, useState, useCallback } from 'react'
import { supabase } from '../supabase'
import type { Order } from '../types'

export function useOrders(limit = 100) {
  const [orders, setOrders] = useState<Order[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetch = useCallback(async () => {
    setLoading(true)
    setError(null)
    const { data, error: err } = await supabase
      .from('orders')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(limit)
    if (err) { setError(err.message); setLoading(false); return }
    setOrders(data || [])
    setLoading(false)
  }, [limit])

  useEffect(() => {
    fetch()
    const channel = supabase
      .channel('orders-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'orders' }, () => fetch())
      .subscribe()
    return () => { supabase.removeChannel(channel) }
  }, [fetch])

  return { orders, loading, error, refetch: fetch }
}
