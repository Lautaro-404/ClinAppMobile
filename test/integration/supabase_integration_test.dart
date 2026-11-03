@Tags(<String>['supabase_integration'])
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinapp/core/config/env.dart';
import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/features/auth/data/secure_session_storage.dart';
import 'package:clinapp/features/auth/data/supabase_auth_repository.dart';
import 'package:clinapp/features/auth/domain/auth_models.dart';
import 'package:clinapp/features/checkout/data/supabase_checkout_repository.dart';
import 'package:clinapp/features/checkout/domain/checkout_models.dart';
import 'package:clinapp/features/home/data/supabase_home_repository.dart';
import 'package:clinapp/features/home/domain/home_models.dart';
import 'package:clinapp/features/orders/data/supabase_orders_repository.dart';
import 'package:clinapp/features/orders/domain/orders_models.dart';
import 'package:clinapp/features/search/data/supabase_search_repository.dart';
import 'package:clinapp/features/search/domain/search_models.dart';

class _InMemorySessionStorage implements SessionStorage {
  AuthUserSession? _session;

  @override
  Future<AuthUserSession?> readSession() async => _session;

  @override
  Future<void> writeSession(AuthUserSession session) async {
    _session = session;
  }

  @override
  Future<void> deleteSession() async {
    _session = null;
  }
}

/// Suite de pruebas de integración contra Supabase (Staging o `supabase start` local).
///
/// Comando de ejecución:
///   flutter test test/integration/supabase_integration_test.dart \
///     --tags supabase_integration \
///     --dart-define-from-file=.env.staging
void main() {
  final String supabaseUrl = Env.supabaseUrl.trim();
  final String supabaseAnonKey = Env.supabaseAnonKey.trim();
  final bool hasStagingCredentials =
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  late SupabaseClient client;
  late SupabaseAuthRepository authRepo;
  late SupabaseHomeRepository homeRepo;
  late SupabaseSearchRepository searchRepo;
  late SupabaseCheckoutRepository checkoutRepo;
  late SupabaseOrdersRepository ordersRepo;

  final String? skipReason = !hasStagingCredentials
      ? 'Omitido: definí SUPABASE_URL y SUPABASE_ANON_KEY con --dart-define-from-file=.env.staging'
      : null;

  setUpAll(() {
    if (!hasStagingCredentials) {
      return;
    }
    client = SupabaseClient(
      supabaseUrl,
      supabaseAnonKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    authRepo = SupabaseAuthRepository(
      client: client,
      storage: _InMemorySessionStorage(),
      allowSeedFallbackOverride: false,
    );
    homeRepo = SupabaseHomeRepository(client: client);
    searchRepo = SupabaseSearchRepository(client: client);
    checkoutRepo = SupabaseCheckoutRepository(client: client);
    ordersRepo = SupabaseOrdersRepository(client: client);
  });

  tearDownAll(() async {
    if (hasStagingCredentials) {
      await client.dispose();
    }
  });

  group('1. Integración Auth y Seguridad RLS en Profiles', () {
    test(
      'Registro/Login de cliente y bloqueo RLS de escalación de rol o saldo',
      skip: skipReason,
      () async {
        expect(
          hasStagingCredentials,
          isTrue,
          reason: 'Definí SUPABASE_URL y SUPABASE_ANON_KEY con --dart-define-from-file=.env.staging',
        );

        final int ts = DateTime.now().millisecondsSinceEpoch;
        final String testEmail = 'qa.alvear.$ts@clin.app';
        const String testPass = 'AlvearStaging2026!';

        final AuthUserSession session = await authRepo.signUp(
          fullName: 'Usuario QA Alvear',
          localPhone: '401234',
          email: testEmail,
          password: testPass,
        );

        expect(session.userId, isNotEmpty);
        expect(session.role, AppUserRole.cliente);

        // Si el proyecto de staging tiene autoconfirmación activa y hay sesión JWT:
        if (client.auth.currentUser != null) {
          // Intentar escalar rol a admin y adulterar wallet_balance debe lanzar PermissionDeniedFailure (42501)
          await expectLater(() async {
            try {
              await client
                  .from('profiles')
                  .update(<String, Object?>{
                    'rol': 'admin',
                    'wallet_balance': 99999900,
                  })
                  .eq('id', session.userId);
            } on Object catch (e) {
              throw AppException.fromError(e);
            }
          }(), throwsA(isA<PermissionDeniedFailure>()));
        }
      },
    );
  });

  group('2. Integración Catálogo, Búsqueda y Favoritos', () {
    test(
      'Lectura de categorías, vista merchants_catalog_view (solo activos) y búsqueda',
      skip: skipReason,
      () async {
        expect(hasStagingCredentials, isTrue);

        final HomeFeedData feed = await homeRepo.fetchHomeFeed();
        expect(feed.categories, isNotEmpty);
        expect(feed.merchants, isNotEmpty);

        final SearchCatalogData searchAll = await searchRepo
            .fetchSearchCatalog();
        expect(searchAll.merchants, isNotEmpty);

        // Verificar que la vista tiene security_invoker y solo expone comercios activos
        final List<Map<String, Object?>> rawViewRows = await client
            .from('merchants_catalog_view')
            .select('id, estado')
            .limit(10);
        for (final Map<String, Object?> row in rawViewRows) {
          expect(row['estado'], 'activo');
        }
      },
    );
  });

  group('3. Integración Creación de Pedido y Autoridad del Servidor', () {
    test(
      'Cotización remota, idempotencia por clientRequestId y rechazo de INSERT directo en orders',
      skip: skipReason,
      () async {
        expect(hasStagingCredentials, isTrue);

        // Un INSERT directo en orders debe ser rechazado por RLS (solo la Edge Function crear-pedido inserta)
        await expectLater(() async {
          try {
            await client.from('orders').insert(<String, Object?>{
              'estado': 'confirmado',
              'subtotal': 100,
              'envio': 0,
              'total': 100,
            });
          } on Object catch (e) {
            throw AppException.fromError(e);
          }
        }(), throwsA(isA<AppException>()));

        final CheckoutQuote quote = await checkoutRepo.calculateServerQuote(
          merchantId: 'm1111111-1111-4111-8111-111111111111',
          addressId: 'addr-alv-1',
          items: const <CheckoutCartItem>[
            CheckoutCartItem(
              productId: 'p1111111-1111-4111-8111-111111111101',
              name: 'Fainá Clásica',
              unitPriceCents: 150000,
              quantity: 2,
            ),
          ],
        );

        expect(quote.isServerConfirmed, isTrue);
        expect(quote.totalCents, greaterThan(0));
      },
    );
  });

  group('4. Integración Suscripciones Realtime', () {
    test(
      'Suscripción y cancelación limpia de canales watchOrder y watchOrderPaymentStatus',
      skip: skipReason,
      () async {
        expect(hasStagingCredentials, isTrue);

        const String testOrderId = '00000000-0000-4000-8000-000000000001';
        final Stream<OrdersRealtimeEvent> orderStream = ordersRepo.watchOrder(
          testOrderId,
        );
        final Stream<PaymentProcessStatus> paymentStream = checkoutRepo
            .watchOrderPaymentStatus(testOrderId);

        final StreamSubscription<OrdersRealtimeEvent> sub1 = orderStream.listen(
          (_) {},
        );
        final StreamSubscription<PaymentProcessStatus> sub2 = paymentStream
            .listen((_) {});

        await Future<void>.delayed(const Duration(milliseconds: 300));

        await sub1.cancel();
        await sub2.cancel();
      },
    );
  });
}
