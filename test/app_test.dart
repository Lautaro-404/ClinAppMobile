import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinapp/app.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/shared/widgets/glass_nav_bar.dart';

void main() {
  testWidgets('ClinApp abre en Inicio con tema oscuro, es_AR y GlassNavBar', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(
      () => tester.platformDispatcher.clearPlatformBrightnessTestValue(),
    );

    await tester.pumpWidget(const ProviderScope(child: ClinApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining(AppStrings.homeGreetingPrefix), findsOneWidget);
    expect(find.byType(GlassNavBar), findsOneWidget);

    final ThemeData theme = Theme.of(
      tester.element(find.textContaining(AppStrings.homeGreetingPrefix)),
    );
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppColors.canvas);
    expect(theme.colorScheme.primary, AppColors.accent);

    final Locale locale = Localizations.localeOf(
      tester.element(find.textContaining(AppStrings.homeGreetingPrefix)),
    );
    expect(locale, ClinApp.locale);
  });

  testWidgets(
    'ClinApp adopta tema claro cuando el sistema está en modo claro',
    (WidgetTester tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(
        () => tester.platformDispatcher.clearPlatformBrightnessTestValue(),
      );

      await tester.pumpWidget(const ProviderScope(child: ClinApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final ThemeData theme = Theme.of(
        tester.element(find.textContaining(AppStrings.homeGreetingPrefix)),
      );
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF8F9FA));
    },
  );
}
