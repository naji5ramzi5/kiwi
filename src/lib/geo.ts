import { booleanPointInPolygon } from '@turf/turf';
import type { Feature, MultiPolygon, Polygon } from 'geojson';

/**
 * Normalizes various geojson formats into a proper Feature with Polygon/MultiPolygon geometry.
 * Handles: Feature, GeometryObject, raw coordinate arrays, nested arrays.
 */
function normalizeGeojson(geojson: any): Feature<Polygon | MultiPolygon> | null {
  if (!geojson) return null;

  // Already a Feature with geometry
  if (geojson.type === 'Feature' && geojson.geometry) {
    const geom = geojson.geometry;
    if (geom.type === 'Polygon' || geom.type === 'MultiPolygon') {
      return geojson as Feature<Polygon | MultiPolygon>;
    }
  }

  // Raw GeometryObject (Polygon or MultiPolygon)
  if ((geojson.type === 'Polygon' || geojson.type === 'MultiPolygon') && geojson.coordinates) {
    return { type: 'Feature', geometry: geojson, properties: {} } as Feature<Polygon | MultiPolygon>;
  }

  // Raw coordinate array: [[lng, lat], [lng, lat], ...] — wrap as Polygon
  if (Array.isArray(geojson) && geojson.length >= 3) {
    // Check if it's an array of [lng, lat] pairs
    if (Array.isArray(geojson[0]) && geojson[0].length >= 2 && typeof geojson[0][0] === 'number') {
      // Ensure the ring is closed (first == last)
      const ring = [...geojson];
      const first = ring[0];
      const last = ring[ring.length - 1];
      if (first[0] !== last[0] || first[1] !== last[1]) {
        ring.push([...first]);
      }
      if (ring.length >= 4) {
        return {
          type: 'Feature',
          geometry: { type: 'Polygon', coordinates: [ring] },
          properties: {},
        } as Feature<Polygon>;
      }
    }

    // Check if it's a nested array (e.g., [[[lng, lat], [lng, lat], ...]])
    if (Array.isArray(geojson[0]) && Array.isArray(geojson[0][0])) {
      // Might be a Polygon coordinates array: [[[lng, lat], ...]]
      const coords = geojson;
      if (coords[0] && coords[0].length >= 4) {
        return {
          type: 'Feature',
          geometry: { type: 'Polygon', coordinates: coords },
          properties: {},
        } as Feature<Polygon>;
      }
    }
  }

  return null;
}

/**
 * Checks if a [lng, lat] point lies inside a GeoJSON polygon/multipolygon.
 * @param point  [longitude, latitude]
 * @param geojson Valid GeoJSON Feature (or GeometryObject) representing a polygon.
 */
export const isPointInZone = (
  point: [number, number],
  geojson: GeoJSON.Feature | GeoJSON.GeometryObject | any
): boolean => {
  try {
    const normalized = normalizeGeojson(geojson);
    if (!normalized) return false;
    // Turf expects [lng, lat]
    return booleanPointInPolygon(point, normalized);
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
  geojson: GeoJSON.Feature | GeoJSON.GeometryObject | any | null
) => {
  const point: [number, number] | null = latitude !== null && longitude !== null ? [longitude, latitude] : null;
  return Boolean(point && geojson && isPointInZone(point, geojson));
};
