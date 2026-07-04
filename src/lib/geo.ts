import { booleanPointInPolygon } from '@turf/turf';
import type { Feature, MultiPolygon, Polygon } from 'geojson';

/**
 * Checks if a [lng, lat] point lies inside a GeoJSON polygon/multipolygon.
 * @param point  [longitude, latitude]
 * @param geojson Valid GeoJSON Feature (or GeometryObject) representing a polygon.
 */
export const isPointInZone = (
  point: [number, number],
  geojson: GeoJSON.Feature | GeoJSON.GeometryObject
): boolean => {
  try {
    // Turf expects [lng, lat]
    return booleanPointInPolygon(point, geojson as Polygon | MultiPolygon | Feature<Polygon | MultiPolygon>);
  } catch (e) {
    console.error('Turf.js error:', e);
    return false;
  }
};

/**
 * Memoized version that avoids re‑creating the point array on every render.
 * Use inside a component with useMemo.
 */
export const usePointInZone = (
  latitude: number | null,
  longitude: number | null,
  geojson: GeoJSON.Feature | GeoJSON.GeometryObject | null
) => {
  const point: [number, number] | null = latitude !== null && longitude !== null ? [longitude, latitude] : null;
  return Boolean(point && geojson && isPointInZone(point, geojson));
};
