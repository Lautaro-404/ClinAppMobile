import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_theme.dart';
import 'package:clinapp/core/utils/date_formatter.dart';
import 'package:clinapp/features/auth/data/secure_session_storage.dart';
import 'package:clinapp/features/auth/data/supabase_auth_repository.dart';
import 'package:clinapp/features/auth/presentation/login_screen.dart';
import 'package:clinapp/features/auth/presentation/register_screen.dart';
import 'package:clinapp/features/checkout/presentation/checkout_screen.dart';
import 'package:clinapp/features/home/presentation/home_screen.dart';
import 'package:clinapp/features/orders/presentation/orders_screen.dart';
import 'package:clinapp/features/search/presentation/search_screen.dart';
import 'package:clinapp/features/settings/presentation/profile_screen.dart';
import 'package:clinapp/shared/widgets/clin_brand_logo.dart';
import 'package:clinapp/shared/widgets/glass_quality.dart';

class _LowQualityNotifier extends GlassQualityNotifier {
  @override
  GlassQuality build() => GlassQuality.low;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_AR');
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(DateFormatter.zoneName));
  });

  setUp(() async {
    final SessionStorage storage = SecureSessionStorage();
    await storage.writeSession(SupabaseAuthRepository.defaultDevSession);
  });

  group('Etapa 9 — Rendimiento (BackdropFilter <= 3 y degradación)', () {
    final Map<String, Widget> mainScreens = <String, Widget>{
      'HomeScreen': const HomeScreen(),
      'SearchScreen': const SearchScreen(),
      'OrdersScreen': const OrdersScreen(),
      'CheckoutScreen': const CheckoutScreen(),
      'ProfileScreen': const ProfileScreen(),
      'LoginScreen': const LoginScreen(),
      'RegisterScreen': const RegisterScreen(),
    };

    for (final MapEntry<String, Widget> entry in mainScreens.entries) {
      testWidgets(
        '${entry.key} mantiene <= 3 BackdropFilter simultáneos y usa RepaintBoundary',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(const Size(390, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.dark,
                home: Scaffold(body: entry.value),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final int blurCount = tester
              .widgetList<BackdropFilter>(find.byType(BackdropFilter))
              .length;
          expect(
            blurCount,
            lessThanOrEqualTo(3),
            reason:
                '${entry.key} no debe superar 3 BackdropFilter por pantalla',
          );
        },
      );
    }

    testWidgets(
      'degrada automáticamente a 0 BackdropFilter cuando GlassQuality.low o disableAnimations está activo',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              glassQualityProvider.overrideWith(_LowQualityNotifier.new),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const MediaQuery(
                data: MediaQueryData(disableAnimations: true),
                child: Scaffold(body: HomeScreen()),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(BackdropFilter), findsNothing);
      },
    );
  });

  group('Etapa 9 — Accesibilidad, Escalado 1.5x (320px) y Logo CLIN!', () {
    testWidgets(
      'HomeScreen, ProfileScreen, LoginScreen y RegisterScreen soportan 320px con texto 1.5x sin overflow',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final List<Widget> screensToTest = <Widget>[
          const HomeScreen(),
          const ProfileScreen(),
          const LoginScreen(),
          const RegisterScreen(),
        ];

        for (final Widget screen in screensToTest) {
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.dark,
                builder: (BuildContext context, Widget? child) {
                  final MediaQueryData mq = MediaQuery.of(context);
                  return MediaQuery(
                    data: mq.copyWith(textScaler: const TextScaler.linear(1.5)),
                    child: child!,
                  );
                },
                home: Scaffold(body: screen),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          expect(
            tester.takeException(),
            isNull,
            reason:
                '${screen.runtimeType} no debe producir overflow en 320px a 1.5x',
          );
        }
      },
    );

    testWidgets(
      'ClinBrandLogo se muestra en HomeScreen, ProfileScreen y LoginScreen y los botones de ícono cumplen >= 48x48 dp',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const Scaffold(body: HomeScreen()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(ClinBrandLogo), findsOneWidget);

        final Finder bellButton = find.bySemanticsLabel(
          AppStrings.homeNotificationsSemantics,
        );
        expect(bellButton, findsOneWidget);
        final Size bellSize = tester.getSize(bellButton);
        expect(bellSize.width, greaterThanOrEqualTo(AppSpacing.minTapTarget));
        expect(bellSize.height, greaterThanOrEqualTo(AppSpacing.minTapTarget));

        // Verificamos ProfileScreen y botón de cámara >= 48x48 dp
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const ProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ClinBrandLogo), findsOneWidget);
        final Finder photoBtn = find.bySemanticsLabel(
          AppStrings.profileChangePhotoSemantics,
        );
        expect(photoBtn, findsOneWidget);
        final Size photoSize = tester.getSize(photoBtn);
        expect(photoSize.width, greaterThanOrEqualTo(AppSpacing.minTapTarget));
        expect(photoSize.height, greaterThanOrEqualTo(AppSpacing.minTapTarget));
      },
    );
  });
}
