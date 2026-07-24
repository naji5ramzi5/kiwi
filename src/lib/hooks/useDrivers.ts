import { useEffect, useState, useCallback } from 'react'
import { supabase } from '../supabase'
import type { Driver, Profile } from '../types'

export function useDrivers() {
  const [drivers, setDrivers] = useState<(Driver & { profiles?: Pick<Profile, 'full_name' | 'phone'> | null })[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetch = useCallback(async () => {
    setLoading(true)
    setError(null)
    const { data, error: err } = await supabase
      .from('drivers')
      .select('*, profiles(full_name, phone)')
      .order('updated_at', { ascending: false })
    if (err) { setError(err.message); setLoading(false); return }
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

  return { drivers, loading, error, refetch: fetch }
}
