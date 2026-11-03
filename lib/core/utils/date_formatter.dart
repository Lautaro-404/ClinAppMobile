import 'package:intl/intl.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Formateo de fechas siempre en America/Argentina/Mendoza.
abstract final class DateFormatter {
  static const String _locale = 'es_AR';
  static const String zoneName = 'America/Argentina/Mendoza';
  static bool _tzInitialized = false;

  static tz.Location get _location {
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }
    return tz.getLocation(zoneName);
  }

  /// Convierte [value] a la hora de Mendoza.
  static tz.TZDateTime toMendoza(DateTime value) =>
      tz.TZDateTime.from(value, _location);

  /// Ahora, en Mendoza.
  static tz.TZDateTime nowMendoza() => tz.TZDateTime.now(_location);

  /// `21:30`.
  static String time(DateTime value) =>
      DateFormat.Hm(_locale).format(toMendoza(value));

  /// `21:30 hs`.
  static String timeHs(DateTime value) => '${time(value)} hs';

  /// `12 de mayo · 21:40 hs`.
  static String dateAndTime(DateTime value) {
    final tz.TZDateTime local = toMendoza(value);
    final String date = DateFormat("d 'de' MMMM", _locale).format(local);
    return '$date · ${timeHs(value)}';
  }

  /// `Hoy, 21:30`, `Ayer, 21:30` o, si es más viejo, [dateAndTime].
  ///
  /// [now] es inyectable para poder testearlo.
  static String relativeDay(DateTime value, {DateTime? now}) {
    final tz.TZDateTime local = toMendoza(value);
    final tz.TZDateTime reference = toMendoza(now ?? DateTime.now());
    final tz.TZDateTime today = tz.TZDateTime(
      _location,
      reference.year,
      reference.month,
      reference.day,
    );
    final tz.TZDateTime day = tz.TZDateTime(
      _location,
      local.year,
      local.month,
      local.day,
    );
    final int diffDays = today.difference(day).inDays;
    if (diffDays == 0) {
      return 'Hoy, ${time(value)}';
    }
    if (diffDays == 1) {
      return 'Ayer, ${time(value)}';
    }
    return dateAndTime(value);
  }
}
