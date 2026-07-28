class TurfHelper {
  /// Checks if a point is inside a polygon using the ray casting algorithm
  /// [point] - [longitude, latitude] array
  /// [polygon] - GeoJSON polygon coordinates (array of linear rings)
  static bool pointInPolygon(List<double> point, List<List<List<double>>> polygon) {
    if (point.length != 2 || polygon.isEmpty) return false;

    double x = point[0];
    double y = point[1];

    if (!_pointInRing(x, y, polygon[0])) return false;

    for (int i = 1; i < polygon.length; i++) {
      if (_pointInRing(x, y, polygon[i])) return false;
    }

    return true;
  }

  /// Checks if a point is inside ANY polygon in a list of polygons
  static bool pointInAnyPolygon(List<double> point, List<List<List<List<double>>>> polygons) {
    for (final polygon in polygons) {
      if (pointInPolygon(point, polygon)) return true;
    }
    return false;
  }

  static bool _pointInRing(double x, double y, List<List<double>> ring) {
    bool inside = false;
    int n = ring.length;

    for (int i = 0, j = n - 1; i < n; j = i++) {
      double xi = ring[i][0];
      double yi = ring[i][1];
      double xj = ring[j][0];
      double yj = ring[j][1];

      bool intersect = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi);

      if (intersect) {
        inside = !inside;
      }
    }

    return inside;
  }
}
