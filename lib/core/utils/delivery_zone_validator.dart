/// Validador de zona de entrega para General Alvear, Mendoza.
///
/// Utiliza el algoritmo de ray-casting (point-in-polygon) sobre las coordenadas
/// de `delivery_zones` para garantizar que toda dirección guardada esté dentro
/// del área de cobertura oficial de ClinApp.
abstract final class DeliveryZoneValidator {
  /// Polígono predeterminado de cobertura para el Centro de General Alvear
  /// según `supabase/seed.sql` (pares `[latitud, longitud]`).
  static const List<List<double>> defaultAlvearPolygon = <List<double>>[
    <double>[-34.9600, -67.7150],
    <double>[-34.9600, -67.6800],
    <double>[-34.9900, -67.6800],
    <double>[-34.9900, -67.7150],
  ];

  /// Coordenada central de General Alvear (Km 0 - Av. Alvear Oeste y San Martín).
  static const double defaultCenterLat = -34.9750;
  static const double defaultCenterLng = -67.6950;

  /// Evalúa si un punto `[lat, lng]` está dentro de un polígono de zona de entrega.
  ///
  /// Si [polygon] es nulo o vacío, utiliza [defaultAlvearPolygon].
  static bool isInsideZone({
    required double lat,
    required double lng,
    List<List<double>>? polygon,
  }) {
    final List<List<double>> vertices = (polygon != null && polygon.length >= 3)
        ? polygon
        : defaultAlvearPolygon;

    return _isPointInPolygon(lat, lng, vertices);
  }

  /// Extrae el polígono desde un objeto GeoJSON de `public.delivery_zones`.
  static List<List<double>> parseGeoJsonPolygon(Map<String, Object?>? geojson) {
    if (geojson == null) {
      return defaultAlvearPolygon;
    }

    try {
      final Object? coordinates = geojson['coordinates'];
      if (coordinates is List<Object?> && coordinates.isNotEmpty) {
        final Object? ring = coordinates.first;
        if (ring is List<Object?>) {
          final List<List<double>> polygon = <List<double>>[];
          for (final Object? point in ring) {
            if (point is List<Object?> && point.length >= 2) {
              final double lng = (point[0] as num).toDouble();
              final double lat = (point[1] as num).toDouble();
              polygon.add(<double>[lat, lng]);
            }
          }
          if (polygon.length >= 3) {
            return polygon;
          }
        }
      }
    } on Object {
      // Fallback ante GeoJSON malformado
    }

    return defaultAlvearPolygon;
  }

  /// Algoritmo de ray-casting para determinar si un punto se encuentra dentro de un polígono.
  static bool _isPointInPolygon(
    double lat,
    double lng,
    List<List<double>> polygon,
  ) {
    bool inside = false;
    final int count = polygon.length;

    for (int i = 0, j = count - 1; i < count; j = i++) {
      final double xi = polygon[i][1];
      final double yi = polygon[i][0];
      final double xj = polygon[j][1];
      final double yj = polygon[j][0];

      final bool intersect =
          ((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi);

      if (intersect) {
        inside = !inside;
      }
    }

    return inside;
  }
}
