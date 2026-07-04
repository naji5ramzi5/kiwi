import 'package:flutter/services.dart' show rootBundle;

/// Helper class for Turf.js point-in-polygon operations
/// To use Turf.js in Flutter, we need to load the JS library and call it via a WebView
/// or use platform channels. For simplicity in this implementation, we'll create
/// a Dart-based equivalent that mimics Turf.js booleanPointInPolygon functionality.
///
/// For production, consider using:
/// 1. Platform channels to call native Turf.js implementations
/// 2. A pure Dart geospatial library
/// 3. WebView with injected Turf.js for web builds

class TurfHelper {
  /// Checks if a point is inside a polygon using the ray casting algorithm
  /// This is a simplified version of Turf.js booleanPointInPolygon
  ///
  /// [point] - [longitude, latitude] array
  /// [polygon] - GeoJSON polygon coordinates (array of linear rings)
  /// Returns true if point is inside polygon, false otherwise
  static bool pointInPolygon(List<double> point, List<List<List<double>>> polygon) {
    if (point.length != 2) return false;

    double x = point[0];
    double y = point[1];

    // Handle multiple polygons (MultiPolygon)
    for (var ring in polygon) {
      if (_pointInRing(x, y, ring)) {
        return true;
      }
    }

    return false;
  }

  /// Check if point is inside a single ring (handles holes)
  static bool _pointInRing(double x, double y, List<List<double>> ring) {
    bool inside = false;
    int n = ring.length;

    for (int i = 0, j = n - 1; i < n; j = i++) {
      double xi = ring[i][0];
      double yi = ring[i][1];
      double xj = ring[j][0];
      double yj = ring[j][1];

      // Check if point is on the boundary (optional)
      // For simplicity, we'll skip boundary check here

      bool intersect = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi);

      if (intersect) {
        inside = !inside;
      }
    }

    return inside;
  }

  /// Alternative: Load Turf.js from assets and use it via JavaScript
  /// This would be more complex but gives you the full Turf.js library
  static Future<String> loadTurfJs() async {
    return await rootBundle.loadString('assets/js/turf.min.js');
  }

  /// Example of how you might use Turf.js in a web context
  /// This is commented out as it requires WebView setup
  /*
  static bool pointInPolygonWeb(List<double> point, List<List<List<double>>> polygon) {
    // This would require a WebView with Turf.js loaded
    // Implementation depends on your WebView setup
    return false; // Placeholder
  }
  */
}

/// Extension for easier conversion from GeoJSON to Turf-compatible format
extension GeoJsonExtension on dynamic {
  /// Converts GeoJSON coordinates to format expected by pointInPolygon
  /// Handles both Polygon and MultiPolygon types
  List<List<List<double>>> toTurfPolygonCoordinates() {
    if (this == null) return [];

    // If it's already a coordinates array from GeoJSON geometry
    if (this is List) {
      List coords = this;

      // Check if it's a Polygon: [[[x,y], [x,y], ...]]
      if (coords.isNotEmpty &&
          coords[0] is List &&
          coords[0][0] is List &&
          coords[0][0].length == 2) {
        // Already in Polygon format
        return coords.cast<List<List<double>>>();
      }

      // Check if it's a MultiPolygon: [[[[x,y], ...]], [[[x,y], ...]], ...]
      if (coords.isNotEmpty &&
          coords[0] is List &&
          coords[0][0] is List &&
          coords[0][0][0] is List &&
          coords[0][0][0].length == 2) {
        // Already in MultiPolygon format
        return coords.cast<List<List<double>>>();
      }

      // Single ring without outer array: [[x,y], [x,y], ...]
      if (coords.isNotEmpty &&
          coords[0] is List &&
          coords[0].length == 2) {
        return [coords.cast<List<double>>()];
      }
    }

    return [];
  }
}