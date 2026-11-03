import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_theme.dart';
import 'package:clinapp/features/panels/data/mock_panels_repository.dart';
import 'package:clinapp/features/panels/presentation/admin/admin_panel_screen.dart';
import 'package:clinapp/features/panels/presentation/courier/courier_panel_screen.dart';
import 'package:clinapp/features/panels/presentation/merchant/merchant_panel_screen.dart';

Widget _buildTestApp({required Widget home, ThemeMode mode = ThemeMode.dark}) {
  return ProviderScope(
    overrides: [
      panelsRepositoryProvider.overrideWith(
        (Ref ref) => MockPanelsRepository(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: home,
    ),
  );
}

void main() {
  void setMobileViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
  }

  group('CourierPanelScreen Tests', () {
    testWidgets(
      'renderiza correctamente en modo oscuro y muestra datos de General Alvear',
      (WidgetTester tester) async {
        setMobileViewport(tester);
        await tester.pumpWidget(
          _buildTestApp(home: const CourierPanelScreen(), mode: ThemeMode.dark),
        );
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.courierPanelTitle), findsOneWidget);
        expect(find.text(AppStrings.courierPanelBadge), findsOneWidget);
        expect(
          find.textContaining(AppStrings.courierShiftActive),
          findsOneWidget,
        );
        expect(find.textContaining('Burger Bros'), findsWidgets);
        expect(
          find.text(AppStrings.courierActionOrderDelivered),
          findsOneWidget,
        );
        expect(find.text(AppStrings.courierEarningsTodayTitle), findsOneWidget);
      },
    );

    testWidgets('renderiza correctamente en modo claro', (
      WidgetTester tester,
    ) async {
      setMobileViewport(tester);
      await tester.pumpWidget(
        _buildTestApp(home: const CourierPanelScreen(), mode: ThemeMode.light),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.courierPanelTitle), findsOneWidget);
      expect(find.text(AppStrings.courierGpsActive), findsOneWidget);
    });

    testWidgets('cambia filtros por chip y entrega pedido', (
      WidgetTester tester,
    ) async {
      setMobileViewport(tester);
      await tester.pumpWidget(_buildTestApp(home: const CourierPanelScreen()));
      await tester.pumpAndSettle();

      // Botón Entregué el pedido
      final Finder deliverBtn = find.text(
        AppStrings.courierActionOrderDelivered,
      );
      expect(deliverBtn, findsOneWidget);
      await tester.tap(deliverBtn);
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.courierOrderDeliveredSuccess),
        findsOneWidget,
      );

      // Cambiar al filtro 'Historial'
      final Finder historyChip = find.textContaining(
        AppStrings.courierTabHistory,
      );
      expect(historyChip, findsOneWidget);
      await tester.ensureVisible(historyChip);
      await tester.tap(historyChip);
      await tester.pumpAndSettle();

      // Debe haber pedidos en el historial
      expect(find.textContaining('Burger Bros'), findsWidgets);
    });
  });

  group('MerchantPanelScreen Tests', () {
    testWidgets(
      'renderiza correctamente en modo oscuro y muestra pedidos y caja',
      (WidgetTester tester) async {
        setMobileViewport(tester);
        await tester.pumpWidget(
          _buildTestApp(
            home: const MerchantPanelScreen(),
            mode: ThemeMode.dark,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.merchantPanelHeaderTitle), findsOneWidget);
        expect(find.text(AppStrings.merchantPanelBadge), findsOneWidget);
        expect(find.text(AppStrings.merchantAvgPrepTime), findsOneWidget);
        expect(find.text(AppStrings.merchantTodayRevenue), findsOneWidget);
        expect(
          find.text(AppStrings.merchantActionAcceptKitchen),
          findsOneWidget,
        );
      },
    );

    testWidgets('cambia a la pestaña de menú y stock', (
      WidgetTester tester,
    ) async {
      setMobileViewport(tester);
      await tester.pumpWidget(_buildTestApp(home: const MerchantPanelScreen()));
      await tester.pumpAndSettle();

      final Finder menuChip = find.textContaining(AppStrings.merchantTabMenu);
      expect(menuChip, findsOneWidget);
      await tester.ensureVisible(menuChip);
      await tester.tap(menuChip);
      await tester.pumpAndSettle();

      expect(find.text('Burger Doble Cheddar'), findsOneWidget);
      expect(find.text('Combo Clin Familiar'), findsOneWidget);
    });
  });

  group('AdminPanelScreen Tests', () {
    testWidgets('renderiza KPIs globales y volumen del día', (
      WidgetTester tester,
    ) async {
      setMobileViewport(tester);
      await tester.pumpWidget(
        _buildTestApp(home: const AdminPanelScreen(), mode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.adminPanelHeaderTitle), findsOneWidget);
      expect(find.text(AppStrings.adminPanelBadge), findsOneWidget);
      expect(find.text(AppStrings.adminKpiActiveOrders), findsOneWidget);
      expect(find.text(AppStrings.adminKpiActiveCouriers), findsOneWidget);
      expect(find.text(AppStrings.adminGmvTitle), findsOneWidget);
    });

    testWidgets('navega a comercios y tarifas', (WidgetTester tester) async {
      setMobileViewport(tester);
      await tester.pumpWidget(_buildTestApp(home: const AdminPanelScreen()));
      await tester.pumpAndSettle();

      // Pestaña comercios
      final Finder merchantsChip = find.textContaining(
        AppStrings.adminTabMerchants,
      );
      expect(merchantsChip, findsOneWidget);
      await tester.ensureVisible(merchantsChip);
      await tester.tap(merchantsChip);
      await tester.pumpAndSettle();

      expect(find.text('Burger Bros'), findsOneWidget);
      expect(find.text('Pizzería Don José'), findsOneWidget);

      // Pestaña tarifas
      final Finder ratesChip = find.text(AppStrings.adminTabRates);
      expect(ratesChip, findsOneWidget);
      await tester.ensureVisible(ratesChip);
      await tester.tap(ratesChip);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.adminBaseDeliveryFee), findsOneWidget);
    });
  });
}
