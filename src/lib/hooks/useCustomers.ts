import { useEffect, useState, useCallback } from 'react'
import { supabase } from '../supabase'
import type { Profile } from '../types'

export function useCustomers() {
  const [customers, setCustomers] = useState<Profile[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetch = useCallback(async () => {
    setLoading(true)
    setError(null)
    const { data, error: err } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'customer')
      .order('created_at', { ascending: false })
    if (err) { setError(err.message); setLoading(false); return }
    setCustomers(data || [])
    setLoading(false)
  }, [])

  useEffect(() => { fetch() }, [fetch])
  return { customers, loading, error, refetch: fetch }
}
