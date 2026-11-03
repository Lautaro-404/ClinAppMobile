import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_theme.dart';
import 'package:clinapp/features/dev/presentation/component_catalog_screen.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';
import 'package:clinapp/shared/widgets/glass_chip.dart';
import 'package:clinapp/shared/widgets/glass_quality.dart';
import 'package:clinapp/shared/widgets/glass_text_field.dart';

Widget _wrapWithApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('GlassSurface y GlassQuality', () {
    testWidgets('usa BackdropFilter solo con enableBlur y calidad alta', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithApp(
          const GlassCard(enableBlur: true, child: Text('Tarjeta con blur')),
        ),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.text('Tarjeta con blur')),
      );
      container
          .read(glassQualityProvider.notifier)
          .setQuality(GlassQuality.low);
      await tester.pump();

      expect(find.byType(BackdropFilter), findsNothing);
    });
  });

  group('GlassButton', () {
    testWidgets('respeta tamaño táctil mínimo de 48x48 y semántica', (
      WidgetTester tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        _wrapWithApp(
          GlassButton.icon(
            icon: LucideIcons.heart,
            semanticLabel: AppStrings.catalogFavoriteSemantics,
            onPressed: () => tapped = true,
          ),
        ),
      );

      final Size size = tester.getSize(find.byType(GlassButton));
      expect(size.width, greaterThanOrEqualTo(AppSpacing.minTapTarget));
      expect(size.height, greaterThanOrEqualTo(AppSpacing.minTapTarget));
      expect(
        find.bySemanticsLabel(AppStrings.catalogFavoriteSemantics),
        findsOneWidget,
      );

      await tester.tap(find.byType(GlassButton));
      expect(tapped, isTrue);
    });
  });

  group('GlassChip', () {
    testWidgets('ejecuta onTap y onDeleted con área mínima de 48dp de alto', (
      WidgetTester tester,
    ) async {
      bool selected = false;
      bool deleted = false;
      await tester.pumpWidget(
        _wrapWithApp(
          GlassChip(
            label: AppStrings.catalogChipPizzas,
            onTap: () => selected = true,
            onDeleted: () => deleted = true,
          ),
        ),
      );

      final Size size = tester.getSize(find.byType(GlassChip));
      expect(size.height, greaterThanOrEqualTo(AppSpacing.minTapTarget));

      await tester.tap(find.text(AppStrings.catalogChipPizzas));
      expect(selected, isTrue);

      await tester.tap(find.byIcon(LucideIcons.x));
      expect(deleted, isTrue);
    });
  });

  group('GlassTextField', () {
    testWidgets('permite alternar visibilidad de contraseña', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithApp(
          const GlassTextField(
            hintText: AppStrings.catalogPasswordHint,
            obscureText: true,
          ),
        ),
      );

      EditableText editable = tester.widget(find.byType(EditableText));
      expect(editable.obscureText, isTrue);

      await tester.tap(find.byIcon(LucideIcons.eye));
      await tester.pump();

      editable = tester.widget(find.byType(EditableText));
      expect(editable.obscureText, isFalse);
    });
  });

  group('ComponentCatalogScreen layout y rendimiento', () {
    testWidgets(
      'renderiza sin overflow en 320px y 430px con texto a 1.5x y máx. 3 blur',
      (WidgetTester tester) async {
        for (final double width in <double>[320, 430]) {
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: Size(width, 844),
                textScaler: const TextScaler.linear(1.5),
              ),
              child: ProviderScope(
                child: MaterialApp(
                  theme: AppTheme.dark,
                  home: const ComponentCatalogScreen(),
                ),
              ),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(
            find.byType(BackdropFilter).evaluate().length,
            lessThanOrEqualTo(3),
          );

          await tester.drag(find.byType(ListView), const Offset(0, -600));
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
      },
    );
  });
}
