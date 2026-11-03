import 'package:flutter_test/flutter_test.dart';

import 'package:clinapp/core/utils/delivery_zone_validator.dart';

void main() {
  group('DeliveryZoneValidator Tests', () {
    test('acepta puntos dentro de la zona de General Alvear', () {
      // Centro de General Alvear (Km 0)
      const double centerLat = -34.9750;
      const double centerLng = -67.6950;
      expect(
        DeliveryZoneValidator.isInsideZone(lat: centerLat, lng: centerLng),
        isTrue,
      );

      // Cerca de Av. Alvear Oeste
      expect(
        DeliveryZoneValidator.isInsideZone(lat: -34.9741, lng: -67.6965),
        isTrue,
      );

      // Cerca de Plaza Carlos María de Alvear
      expect(
        DeliveryZoneValidator.isInsideZone(lat: -34.9722, lng: -67.6952),
        isTrue,
      );
    });

    test('rechaza puntos fuera de la zona de General Alvear', () {
      // Coordenadas en San Rafael, Mendoza
      expect(
        DeliveryZoneValidator.isInsideZone(lat: -34.6177, lng: -68.3301),
        isFalse,
      );

      // Coordenadas en Ciudad de Mendoza
      expect(
        DeliveryZoneValidator.isInsideZone(lat: -32.8895, lng: -68.8458),
        isFalse,
      );

      // Coordenadas en Buenos Aires
      expect(
        DeliveryZoneValidator.isInsideZone(lat: -34.6037, lng: -58.3816),
        isFalse,
      );
    });

    test('parseGeoJsonPolygon extrae correctamente los vértices', () {
      final Map<String, Object?> sampleGeoJson = <String, Object?>{
        'type': 'Polygon',
        'coordinates': <Object?>[
          <Object?>[
            <Object?>[-67.7150, -34.9600],
            <Object?>[-67.6800, -34.9600],
            <Object?>[-67.6800, -34.9900],
            <Object?>[-67.7150, -34.9900],
            <Object?>[-67.7150, -34.9600],
          ],
        ],
      };

      final List<List<double>> polygon =
          DeliveryZoneValidator.parseGeoJsonPolygon(sampleGeoJson);

      expect(polygon.length, 5);
      expect(polygon.first[0], -34.9600);
      expect(polygon.first[1], -67.7150);
    });
  });
}
