import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_theme.dart';
import 'package:clinapp/features/orders/domain/orders_models.dart';
import 'package:clinapp/features/orders/presentation/widgets/order_stepper.dart';

void main() {
  testWidgets('OrderStepper renderiza los 5 pasos visuales en orden correcto', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: OrderStepper(
            status: OrderStatus.listoParaRetirar,
            remainingMinutes: 15,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verifica que los 5 pasos existan en el árbol de widgets
    expect(find.text(AppStrings.ordersStepConfirmed), findsOneWidget);
    expect(find.text(AppStrings.ordersStepPreparing), findsOneWidget);
    expect(find.text(AppStrings.ordersStepReady), findsOneWidget);
    expect(find.text(AppStrings.ordersStepOnTheWay), findsOneWidget);
    expect(find.text(AppStrings.ordersStepDelivered), findsOneWidget);

    // Barra de tiempo restante
    expect(find.textContaining('15 min'), findsOneWidget);
  });

  testWidgets(
    'OrderStepper renderiza banner de error en pedido cancelado o rechazado',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: OrderStepper(status: OrderStatus.cancelado),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pedido cancelado'), findsOneWidget);
      expect(find.byIcon(LucideIcons.circleX), findsOneWidget);
    },
  );
}
