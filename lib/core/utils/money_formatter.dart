import 'package:intl/intl.dart';

/// Único formateador de montos de la app.
///
/// Los montos se guardan en **centavos** (enteros) y se formatean solo al
/// mostrarlos. Formato argentino: `$14.600`, `$14.600,50`, `-$2.800`.
abstract final class MoneyFormatter {
  static const String _locale = 'es_AR';
  static const String _symbol = r'$';
  static const int _centsPerPeso = 100;

  static final NumberFormat _integerFormat = NumberFormat.decimalPattern(
    _locale,
  );

  /// Formatea [cents] como pesos argentinos.
  ///
  /// Los centavos solo se muestran cuando el monto no es un peso entero.
  static String format(int cents) {
    final bool negative = cents < 0;
    final int absolute = cents.abs();
    final int pesos = absolute ~/ _centsPerPeso;
    final int remainder = absolute % _centsPerPeso;

    final StringBuffer buffer = StringBuffer();
    if (negative) {
      buffer.write('-');
    }
    buffer
      ..write(_symbol)
      ..write(_integerFormat.format(pesos));
    if (remainder != 0) {
      buffer
        ..write(',')
        ..write(remainder.toString().padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
