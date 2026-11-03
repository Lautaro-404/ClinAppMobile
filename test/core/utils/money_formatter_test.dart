import 'package:flutter_test/flutter_test.dart';

import 'package:clinapp/core/utils/money_formatter.dart';

void main() {
  group('MoneyFormatter.format', () {
    test('formatea pesos enteros con punto de miles', () {
      expect(MoneyFormatter.format(1460000), r'$14.600');
      expect(MoneyFormatter.format(285000), r'$2.850');
      expect(MoneyFormatter.format(980000), r'$9.800');
    });

    test('formatea cero y montos chicos', () {
      expect(MoneyFormatter.format(0), r'$0');
      expect(MoneyFormatter.format(100), r'$1');
      expect(MoneyFormatter.format(85000), r'$850');
    });

    test('formatea millones con dos separadores', () {
      expect(MoneyFormatter.format(123456700), r'$1.234.567');
    });

    test('muestra centavos solo si no es peso entero', () {
      expect(MoneyFormatter.format(1460050), r'$14.600,50');
      expect(MoneyFormatter.format(1460005), r'$14.600,05');
    });

    test('formatea descuentos negativos', () {
      expect(MoneyFormatter.format(-280000), r'-$2.800');
      expect(MoneyFormatter.format(-50), r'-$0,50');
    });
  });
}
