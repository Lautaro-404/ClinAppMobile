import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;

import 'package:clinapp/core/utils/date_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_AR');
    tz_data.initializeTimeZones();
  });

  group('DateFormatter', () {
    // 2026-05-13 00:40 UTC == 12 de mayo 21:40 en Mendoza (UTC-3).
    final DateTime sample = DateTime.utc(2026, 5, 13, 0, 40);

    test('convierte de UTC a la hora de Mendoza', () {
      expect(DateFormatter.time(sample), '21:40');
      expect(DateFormatter.toMendoza(sample).day, 12);
    });

    test('formatea fecha y hora', () {
      expect(DateFormatter.dateAndTime(sample), '12 de mayo · 21:40 hs');
    });

    test('devuelve "Hoy" y "Ayer" según el día de Mendoza', () {
      // 13/5 15:00 en Mendoza.
      final DateTime now = DateTime.utc(2026, 5, 13, 18);
      expect(DateFormatter.relativeDay(sample, now: now), 'Ayer, 21:40');
      expect(
        DateFormatter.relativeDay(DateTime.utc(2026, 5, 13, 17), now: now),
        'Hoy, 14:00',
      );
    });

    test('usa fecha completa si pasaron más de dos días', () {
      final DateTime now = DateTime.utc(2026, 5, 20, 18);
      expect(
        DateFormatter.relativeDay(sample, now: now),
        '12 de mayo · 21:40 hs',
      );
    });
  });
}
