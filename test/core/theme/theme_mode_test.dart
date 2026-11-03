import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_theme.dart';
import 'package:clinapp/core/theme/theme_mode_provider.dart';
import 'package:clinapp/features/auth/domain/auth_models.dart';
import 'package:clinapp/features/settings/presentation/widgets/profile_detail_sheets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeMode & Liquid Glass Light Tests', () {
    test('themeModeProvider inicializa por defecto en ThemeMode.system', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final ThemeMode mode = container.read(themeModeProvider);
      expect(mode, equals(ThemeMode.system));
    });

    test('themeModeProvider cambia a claro y oscuro', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), equals(ThemeMode.light));

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
    });

    test('AppPalette.light y AppPalette.dark exponen tokens coherentes', () {
      expect(AppPalette.light.brightness, equals(Brightness.light));
      expect(AppPalette.dark.brightness, equals(Brightness.dark));

      expect(AppPalette.light.textPrimary, equals(const Color(0xFF0F172A)));
      expect(AppPalette.dark.textPrimary, equals(const Color(0xFFFFFFFF)));

      expect(AppPalette.light.canvas, equals(const Color(0xFFF8F9FA)));
      expect(AppTheme.light.brightness, equals(Brightness.light));
      expect(AppTheme.dark.brightness, equals(Brightness.dark));
    });

    testWidgets(
      'Selector de tema muestra las 3 opciones (Sistema, Claro, Oscuro) y permite cambiarlo',
      (WidgetTester tester) async {
        final ProviderContainer container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: ThemeMode.system,
              home: Scaffold(
                body: Consumer(
                  builder: (BuildContext context, WidgetRef ref, _) {
                    return ElevatedButton(
                      onPressed: () => ProfileDetailSheets.showAppSettings(
                        context,
                        ref: ref,
                        currentRole: AppUserRole.cliente,
                      ),
                      child: const Text('Abrir Ajustes'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Abre el sheet de ajustes de la app
        await tester.tap(find.text('Abrir Ajustes'));
        await tester.pumpAndSettle();

        // Verifica que aparezca el selector con las 3 opciones
        expect(find.text(AppStrings.profileThemeModeTitle), findsOneWidget);
        expect(find.text(AppStrings.profileThemeModeSystem), findsOneWidget);
        expect(find.text(AppStrings.profileThemeModeLight), findsOneWidget);
        expect(find.text(AppStrings.profileThemeModeDark), findsOneWidget);

        // Selecciona modo Claro
        await tester.tap(find.text(AppStrings.profileThemeModeLight));
        await tester.pumpAndSettle();

        expect(container.read(themeModeProvider), equals(ThemeMode.light));

        // Selecciona modo Oscuro
        await tester.tap(find.text(AppStrings.profileThemeModeDark));
        await tester.pumpAndSettle();

        expect(container.read(themeModeProvider), equals(ThemeMode.dark));

        // Vuelve a Sistema
        await tester.tap(find.text(AppStrings.profileThemeModeSystem));
        await tester.pumpAndSettle();

        expect(container.read(themeModeProvider), equals(ThemeMode.system));
      },
    );
  });
}
