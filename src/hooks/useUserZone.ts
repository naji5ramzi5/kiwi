import { useEffect, useState, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import { isPointInZone } from '../lib/geo';

/** Shape of a delivery zone as stored in Supabase */
export interface DeliveryZone {
  id: string;
  branch_id: string;
  branch_name?: string;
  name: string;
  color: string;
  delivery_fee: number;
  min_order: number;
  max_delivery_time: number;
  is_active: boolean;
  geojson: any; // GeoJSON Feature or GeometryObject
  created_at: string;
}

/**
 * Hook that returns the zone (if any) that contains the user's current location.
 * @param branchId Optional – if provided, only zones of this branch are checked.
 */
export const useUserZone = (branchId: string | null = null) => {
  const [matchingZone, setMatchingZone] = useState<DeliveryZone | null>(null);
  const [isInsideAnyZone, setIsInsideAnyZone] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [userLat, setUserLat] = useState<number | null>(null);
  const [userLng, setUserLng] = useState<number | null>(null);

  /** Fetch current location once (with permission handling). */
  const getUserLocation = useCallback(() => {
    if (!navigator.geolocation) {
      setError('الموقع الجغرافي غير مدعوم من قبل متصفحك');
      setLoading(false);
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setUserLat(pos.coords.latitude);
        setUserLng(pos.coords.longitude);
        setError(null);
      },
      (err) => {
        setError(`غير قادر على الحصول على الموقع: ${err.message}`);
        setLoading(false);
      }
    );
  }, []);

  /** Fetch zones (optionally filtered by branch) and test containment. */
  const checkZone = useCallback(async () => {
    if (userLat === null || userLng === null) {
      // Waiting for location
      setLoading(true);
      return;
    }

    setLoading(true);
    try {
      let query = supabase
        .from('delivery_zones')
        .select('*')
        .eq('is_active', true);

      if (branchId) {
        query = query.eq('branch_id', branchId);
      }

      const { data, error: dbError } = await query;
      if (dbError) throw dbError;

      const zones = (data as DeliveryZone[]) || [];
      const point = [userLng, userLat] as [number, number];

      // Find first zone that contains the point
      const found = zones.find((z) =>
        isPointInZone(point, z.geojson)
      );

      setMatchingZone(found ?? null);
      setIsInsideAnyZone(!!found);
    } catch (e: any) {
      console.error(e);
      setError(e.message ?? 'فشل فحص منطقة التوصيل');
      setMatchingZone(null);
      setIsInsideAnyZone(false);
    } finally {
      setLoading(false);
    }
  }, [branchId, userLat, userLng]);

  // -----------------------------------------------------------------
  // Effects
  // -----------------------------------------------------------------
  useEffect(() => {
    getUserLocation();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [getUserLocation]);

  useEffect(() => {
    // Re-run zone check whenever location or branchId changes
    checkZone();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [checkZone, branchId, userLat, userLng]);

  // Optional: real‑time zone updates (if zones change while user is on page)
  useEffect(() => {
    if (!branchId) return;
    const channel = supabase
      .channel(`delivery_zones_changes:${branchId}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'delivery_zones', filter: `branch_id=eq.${branchId}` },
        () => {
          // Refetch zones when any change occurs
          checkZone();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [branchId, checkZone]);

  // -----------------------------------------------------------------
  // Public API
  // -----------------------------------------------------------------
  const refetch = useCallback(() => {
    checkZone();
  }, [checkZone]);

  return {
    matchingZone,
    isInsideAnyZone,
    loading,
    error,
    refetch,
  };
};
