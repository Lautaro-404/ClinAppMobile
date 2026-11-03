import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinapp/app.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/shared/widgets/glass_nav_bar.dart';

void main() {
  group('Navegación con StatefulShellRoute y GlassNavBar', () {
    testWidgets('recorre las 4 pestañas y preserva el estado entre ramas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: ClinApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Rama 0: Inicio.
      expect(find.textContaining(AppStrings.homeGreeting), findsOneWidget);
      expect(
        find.descendant(of: find.byType(GlassNavBar), matching: find.text('1')),
        findsOneWidget,
      );

      // Rama 1: Buscar — escribimos una búsqueda.
      await tester.tap(
        find.descendant(
          of: find.byType(GlassNavBar),
          matching: find.text(AppStrings.navSearch),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text(AppStrings.searchRecentTitle), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('search-query-field')),
        'Sándwich',
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.descendant(
          of: find.byKey(const Key('search-query-field')),
          matching: find.text('Sándwich'),
        ),
        findsOneWidget,
      );

      // Rama 2: Pedidos — cambiamos al tab Historial.
      await tester.tap(
        find.descendant(
          of: find.byType(GlassNavBar),
          matching: find.text(AppStrings.navOrders),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.ordersTitle), findsOneWidget);

      await tester.tap(find.text(AppStrings.ordersHistoryTab));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.ordersStatusDelivered), findsWidgets);

      // Rama 3: Perfil.
      await tester.tap(
        find.descendant(
          of: find.byType(GlassNavBar),
          matching: find.text(AppStrings.navProfile),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.profileSubtitle), findsOneWidget);

      // Volvemos a Buscar y verificamos que el texto ingresado sigue intacto.
      await tester.tap(
        find.descendant(
          of: find.byType(GlassNavBar),
          matching: find.text(AppStrings.navSearch),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('search-query-field')),
          matching: find.text('Sándwich'),
        ),
        findsOneWidget,
      );

      // Volvemos a Pedidos y verificamos que sigue en Historial.
      await tester.tap(
        find.descendant(
          of: find.byType(GlassNavBar),
          matching: find.text(AppStrings.navOrders),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.ordersStatusDelivered), findsWidgets);
    });

    testWidgets(
      'abre ruta fuera del shell (/checkout) sin GlassNavBar y vuelve',
      (WidgetTester tester) async {
        await tester.pumpWidget(const ProviderScope(child: ClinApp()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        await tester.drag(find.byType(ListView).first, const Offset(0, -250));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.homePromoCta));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.checkoutTitle), findsOneWidget);
        expect(find.byType(GlassNavBar), findsNothing);

        await tester.tap(find.bySemanticsLabel(AppStrings.actionBack));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.homePromoCta), findsOneWidget);
        expect(find.byType(GlassNavBar), findsOneWidget);
      },
    );

    testWidgets('oculta GlassNavBar cuando se abre el teclado del sistema', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(
            size: Size(390, 844),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: ProviderScope(child: ClinApp()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(GlassNavBar), findsNothing);
    });
  });
}
