import { useEffect, useRef } from 'react';
import { MapContainer, TileLayer, FeatureGroup, Polygon, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import 'leaflet-draw/dist/leaflet.draw.css';
import 'leaflet-draw';

interface ZoneMapProps {
  center: [number, number];
  zones: any[];
  onZonesChange: (zones: any[]) => void;
}

// Custom Draw Control to bypass react-leaflet-draw ESM import issues in Vite
function CustomDrawControl({ onCreated, onEdited, onDeleted, featureGroupRef, zones }: any) {
  const map = useMap();
  const drawControlRef = useRef<any>(null);

  useEffect(() => {
    if (!featureGroupRef.current) return;

    // Create the Draw Control
    const drawControl = new (L as any).Control.Draw({
      position: 'topright',
      edit: {
        featureGroup: featureGroupRef.current,
        remove: true
      },
      draw: {
        rectangle: false,
        circle: false,
        polyline: false,
        circlemarker: false,
        marker: false,
        polygon: {
          allowIntersection: false,
          drawError: {
            color: '#e1e1e1',
            message: '<strong>Error:</strong> Polygon edges cannot cross!'
          },
          shapeOptions: {
            color: '#10b981',
            fillOpacity: 0.2
          }
        }
      }
    });

    map.addControl(drawControl);
    drawControlRef.current = drawControl;

    // Event listeners
    const handleCreated = (e: any) => {
      const { layerType, layer } = e;
      if (layerType === 'polygon') {
        featureGroupRef.current.addLayer(layer);
        const geojson = layer.toGeoJSON();
        onCreated(geojson);
      }
    };

    const handleEdited = () => {
      const newZones: any[] = [];
      featureGroupRef.current.eachLayer((layer: any) => {
        newZones.push(layer.toGeoJSON());
      });
      onEdited(newZones);
    };

    const handleDeleted = () => {
      const newZones: any[] = [];
      featureGroupRef.current.eachLayer((layer: any) => {
        newZones.push(layer.toGeoJSON());
      });
      onDeleted(newZones);
    };

    map.on((L as any).Draw.Event.CREATED, handleCreated);
    map.on((L as any).Draw.Event.EDITED, handleEdited);
    map.on((L as any).Draw.Event.DELETED, handleDeleted);

    return () => {
      map.removeControl(drawControl);
      map.off((L as any).Draw.Event.CREATED, handleCreated);
      map.off((L as any).Draw.Event.EDITED, handleEdited);
      map.off((L as any).Draw.Event.DELETED, handleDeleted);
    };
  }, [map, featureGroupRef, onCreated, onEdited, onDeleted]);

  // Load existing zones into the FeatureGroup when they change
  useEffect(() => {
    if (!featureGroupRef.current) return;
    
    // Clear existing layers to avoid duplication
    featureGroupRef.current.clearLayers();

    zones.forEach((zone: any) => {
      if (zone && zone.geometry && zone.geometry.coordinates) {
        const coords = zone.geometry.coordinates[0].map((coord: any) => [coord[1], coord[0]]);
        const polygon = L.polygon(coords, { color: '#10b981', fillOpacity: 0.2 });
        featureGroupRef.current.addLayer(polygon);
      }
    });
  }, [zones, featureGroupRef]);

  return null;
}

export default function ZoneMap({ center, zones, onZonesChange }: ZoneMapProps) {
  const featureGroupRef = useRef<any>(null);

  useEffect(() => {
    // Fix leaflet icon issue
    delete (L.Icon.Default.prototype as any)._getIconUrl;
    L.Icon.Default.mergeOptions({
      iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
      iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
      shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
    });
  }, []);

  const handleCreated = (geojson: any) => {
    onZonesChange([...zones, geojson]);
  };

  const handleEditedOrDeleted = (newZones: any[]) => {
    onZonesChange(newZones);
  };

  return (
    <div style={{ height: '400px', width: '100%', borderRadius: '12px', overflow: 'hidden', border: '1px solid #e2e8f0' }}>
      <MapContainer center={center} zoom={13} style={{ height: '100%', width: '100%' }}>
        <TileLayer
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        />
        <FeatureGroup ref={featureGroupRef}>
          <CustomDrawControl 
            onCreated={handleCreated} 
            onEdited={handleEditedOrDeleted}
            onDeleted={handleEditedOrDeleted}
            featureGroupRef={featureGroupRef}
            zones={zones}
          />
        </FeatureGroup>
      </MapContainer>
    </div>
  );
}
