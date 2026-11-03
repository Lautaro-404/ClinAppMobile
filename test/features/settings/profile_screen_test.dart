import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_theme.dart';
import 'package:clinapp/features/auth/data/secure_session_storage.dart';
import 'package:clinapp/features/auth/data/supabase_auth_repository.dart';
import 'package:clinapp/features/auth/domain/auth_models.dart';
import 'package:clinapp/features/auth/domain/auth_repository.dart';
import 'package:clinapp/features/settings/presentation/profile_screen.dart';
import 'package:clinapp/features/settings/presentation/widgets/profile_metrics_row.dart';

class _MockMemoryAuthRepository implements AuthRepository {
  _MockMemoryAuthRepository({required AuthUserSession initialSession})
    : _session = initialSession;

  AuthUserSession? _session;

  @override
  Future<AuthUserSession?> loadInitialSession() async => _session;

  @override
  Future<AuthUserSession> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    _session = SupabaseAuthRepository.defaultDevSession;
    return _session!;
  }

  @override
  Future<AuthUserSession> signUp({
    required String fullName,
    required String localPhone,
    required String email,
    required String password,
  }) async {
    _session = AuthUserSession(
      userId: 'test-user-1',
      fullName: fullName,
      email: email,
      phone: localPhone,
      role: AppUserRole.cliente,
    );
    return _session!;
  }

  @override
  Future<AuthUserSession> signInWithSocial(String provider) async {
    _session = SupabaseAuthRepository.defaultDevSession;
    return _session!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<AuthUserSession> updateActiveRole(AppUserRole role) async {
    _session =
        _session?.copyWith(role: role) ??
        SupabaseAuthRepository.defaultDevSession.copyWith(role: role);
    return _session!;
  }

  @override
  Future<void> signOut() async {
    _session = null;
  }

  @override
  Future<void> deleteAccount() async {
    _session = null;
  }
}

void main() {
  setUp(() async {
    final SessionStorage storage = SecureSessionStorage();
    await storage.writeSession(SupabaseAuthRepository.defaultDevSession);
  });

  Widget buildTestableWidget({AuthUserSession? session}) {
    final AuthUserSession activeSession =
        session ?? SupabaseAuthRepository.defaultDevSession;
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _MockMemoryAuthRepository(initialSession: activeSession),
        ),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: const ProfileScreen()),
    );
  }

  group('ProfileScreen (Etapa 8)', () {
    testWidgets(
      'renderiza datos del diseño Stitch (Lautaro Ponzina, \$12.000, 3 métricas)',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        expect(find.text('Lautaro Ponzina'), findsOneWidget);
        expect(find.text('ponzinalautaro6@gmail.com'), findsOneWidget);
        expect(find.text(AppStrings.profileVerifiedBadge), findsOneWidget);

        expect(find.byType(ProfileMetricsRow), findsOneWidget);
        expect(find.text('6'), findsOneWidget);
        expect(find.text(r'$12.000'), findsOneWidget);
        expect(find.text('5,0'), findsOneWidget);

        expect(find.text(AppStrings.profileManagementSection), findsOneWidget);
        expect(find.text(AppStrings.profileAdminPanelTitle), findsOneWidget);
        expect(find.text(AppStrings.profileMerchantPanelTitle), findsOneWidget);
        expect(find.text(AppStrings.profileCourierPanelTitle), findsOneWidget);

        expect(find.text(AppStrings.profileAccountSection), findsOneWidget);
        expect(find.text(AppStrings.profileAddressesTitle), findsOneWidget);
        expect(
          find.text(AppStrings.profilePaymentMethodsTitle),
          findsOneWidget,
        );
        expect(find.text(AppStrings.profileFavoritesTitle), findsOneWidget);

        // Desplazamos para ver la sección inferior de la lista
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.profileSignOutCta), findsOneWidget);
        expect(find.text(AppStrings.profileVersionFooter), findsOneWidget);
      },
    );

    testWidgets(
      'oculta sección de gestión cuando el usuario tiene rol cliente',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        const AuthUserSession clientSession = AuthUserSession(
          userId: 'client-user',
          fullName: 'Lucas Benítez',
          email: 'lucas@gmail.com',
          phone: '+54 9 2625 401234',
          role: AppUserRole.cliente,
        );

        await tester.pumpWidget(buildTestableWidget(session: clientSession));
        await tester.pumpAndSettle();

        expect(find.text('Lucas Benítez'), findsOneWidget);
        expect(find.text(AppStrings.profileManagementSection), findsNothing);
        expect(find.text(AppStrings.profileAdminPanelTitle), findsNothing);
      },
    );

    testWidgets(
      'abre hoja de mis direcciones y muestra direcciones guardadas',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.profileAddressesTitle));
        await tester.pumpAndSettle();

        expect(find.text('Av. San Martín 450, Dpto 2B'), findsOneWidget);
        expect(find.text(AppStrings.profileNewAddressAction), findsOneWidget);
      },
    );

    testWidgets(
      'cerrar sesión limpia la sesión y muestra botón de inicio de sesión',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.profileSignOutCta));
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
        expect(find.text(AppStrings.loginSubmitCta), findsOneWidget);
        expect(find.text('Lautaro Ponzina'), findsNothing);
        expect(find.text(AppStrings.loginSubmitCta), findsOneWidget);
        expect(find.text('Lautaro Ponzina'), findsNothing);
      },
    );
  });
}
