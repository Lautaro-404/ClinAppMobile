import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_theme.dart';
import 'package:clinapp/core/utils/date_formatter.dart';
import 'package:clinapp/features/orders/domain/orders_models.dart';
import 'package:clinapp/features/orders/presentation/widgets/order_receipt_sheet.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_AR');
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(DateFormatter.zoneName));
  });

  testWidgets(
    'OrderReceiptSheet formatea montos en ARS y muestra desglose real',
    (WidgetTester tester) async {
      final DateTime orderDate = DateTime(2026, 5, 12, 21, 30);
      final OrderSummary order = OrderSummary(
        id: 'ord-9988',
        shortCode: '#9988',
        merchantId: 'm-alv',
        merchantName: 'Parrilla Los Amigos',
        itemsSummary: '2x Vacío al asador',
        items: const <OrderLineItem>[
          OrderLineItem(
            productId: 'p-1',
            name: 'Vacío al asador',
            quantity: 2,
            unitPriceCents: 650000,
            totalPriceCents: 1300000,
          ),
        ],
        status: OrderStatus.entregado,
        createdAt: orderDate,
        subtotalCents: 1300000,
        deliveryFeeCents: 160000,
        discountCents: 200000,
        tipCents: 100000,
        totalCents: 1360000,
        deliveryAddress: 'Calle Intendente Morales 220',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(body: OrderReceiptSheet(order: order)),
        ),
      );
      await tester.pumpAndSettle();

      // Título y local
      expect(find.text(AppStrings.ordersReceiptTitle), findsOneWidget);
      expect(find.text('Parrilla Los Amigos · #9988'), findsOneWidget);

      // Ítems
      expect(find.text('2x Vacío al asador'), findsOneWidget);

      // Desglose formateado con punto de miles en ARS
      expect(find.text(r'$13.000'), findsWidgets); // Subtotal e ítem
      expect(find.text(r'$1.600'), findsOneWidget); // Envío
      expect(find.text(r'-$2.000'), findsOneWidget); // Descuento
      expect(find.text(r'$1.000'), findsOneWidget); // Propina
      expect(find.text(r'$13.600'), findsOneWidget); // Total

      // Dirección
      expect(
        find.textContaining('Calle Intendente Morales 220'),
        findsOneWidget,
      );
    },
  );
}
