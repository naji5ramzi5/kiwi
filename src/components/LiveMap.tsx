import { useEffect } from 'react'
import { MapContainer, TileLayer, Marker, Popup, useMap, Polygon } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'
import L from 'leaflet'

// Custom Store Icon for the Map
const StoreIcon = L.divIcon({
  html: `
    <div style="
      background: var(--g600); 
      width: 40px; 
      height: 40px; 
      border-radius: 50%; 
      display: flex; 
      align-items: center; 
      justify-content: center; 
      border: 3px solid white; 
      box-shadow: 0 4px 10px rgba(0,0,0,0.2);
    ">
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m2 7 4.41-4.41A2 2 0 0 1 7.83 2h8.34a2 2 0 0 1 1.42.59L22 7"></path><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"></path><path d="M15 22v-4a2 2 0 0 0-2-2h-2a2 2 0 0 0-2 2v4"></path><path d="M2 7h20"></path><path d="M22 7v3a2 2 0 0 1-2 2v0a2.7 2.7 0 0 1-1.59-.63.7.7 0 0 0-.82 0A2.7 2.7 0 0 1 16 12a2.7 2.7 0 0 1-1.59-.63.7.7 0 0 0-.82 0A2.7 2.7 0 0 1 12 12a2.7 2.7 0 0 1-1.59-.63.7.7 0 0 0-.82 0A2.7 2.7 0 0 1 8 12a2.7 2.7 0 0 1-1.59-.63.7.7 0 0 0-.82 0A2.7 2.7 0 0 1 4 10V7"></path></svg>
    </div>
  `,
  className: 'custom-store-icon',
  iconSize: [40, 40],
  iconAnchor: [20, 40]
})

interface BranchLocation {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  status: string;
  location_url?: string;
  delivery_zones?: any[];
}

export default function LiveMap({ branches }: { branches: BranchLocation[] }) {
  const center: [number, number] = [33.3152, 44.3661] // Baghdad center

  return (
    <div style={{ height: '400px', width: '100%', borderRadius: '16px', overflow: 'hidden', boxShadow: '0 4px 20px rgba(0,0,0,0.08)' }}>
      <MapContainer center={center} zoom={12} style={{ height: '100%', width: '100%' }} scrollWheelZoom={false}>
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        {branches.map(branch => (
          <div key={branch.id}>
            <Marker position={[branch.latitude || 33.3152, branch.longitude || 44.3661]} icon={StoreIcon}>
              <Popup>
                <div style={{ textAlign: 'right', direction: 'rtl', fontFamily: 'inherit' }}>
                  <strong style={{ color: 'var(--g700)', display: 'block', marginBottom: '4px' }}>{branch.name}</strong>
                  <div style={{ fontSize: '12px', marginBottom: '8px' }}>الحالة: {branch.status}</div>
                  {branch.location_url && (
                    <a 
                      href={branch.location_url} 
                      target="_blank" 
                      rel="noopener noreferrer"
                      style={{ 
                        fontSize: '11px', 
                        color: 'white', 
                        background: 'var(--g600)', 
                        padding: '4px 8px', 
                        borderRadius: '4px', 
                        textDecoration: 'none',
                        display: 'inline-block'
                      }}
                    >
                      فتح في خرائط جوجل 📍
                    </a>
                  )}
                </div>
              </Popup>
            </Marker>

            {/* Render Delivery Zones (Polygons) for this branch */}
            {branch.delivery_zones && branch.delivery_zones.map((zone: any, idx: number) => {
              if (zone && zone.geometry && zone.geometry.coordinates) {
                const coords = zone.geometry.coordinates[0].map((coord: any) => [coord[1], coord[0]]);
                return (
                  <Polygon 
                    key={`${branch.id}-zone-${idx}`} 
                    positions={coords} 
                    pathOptions={{ color: '#10b981', fillOpacity: 0.15, weight: 2 }}
                  >
                    <Popup>
                      <div style={{ textAlign: 'right', direction: 'rtl', fontFamily: 'inherit' }}>
                        <strong>منطقة توصيل: {branch.name}</strong>
                      </div>
                    </Popup>
                  </Polygon>
                );
              }
              return null;
            })}
          </div>
        ))}
      </MapContainer>
    </div>
  )
}
