import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinapp/features/auth/data/supabase_auth_repository.dart';
import 'package:clinapp/features/auth/domain/auth_models.dart';
import 'package:clinapp/features/auth/domain/auth_repository.dart';
import 'package:clinapp/features/auth/presentation/auth_controller.dart';
import 'package:clinapp/features/notifications/data/services/fake_push_service.dart';
import 'package:clinapp/features/notifications/domain/models/push_message.dart';
import 'package:clinapp/features/notifications/presentation/push_service_provider.dart';

class _MockAuthRepository implements AuthRepository {
  AuthUserSession? currentSession;

  @override
  Future<AuthUserSession?> loadInitialSession() async => currentSession;

  @override
  Future<AuthUserSession> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    final AuthUserSession session = AuthUserSession(
      userId: 'test-user-123',
      fullName: 'Lautaro Ponzina',
      email: identifier,
      phone: '+5492625123456',
      role: AppUserRole.cliente,
      isVerified: true,
    );
    currentSession = session;
    return session;
  }

  @override
  Future<AuthUserSession> signUp({
    required String fullName,
    required String localPhone,
    required String email,
    required String password,
  }) async {
    final AuthUserSession session = AuthUserSession(
      userId: 'test-user-new',
      fullName: fullName,
      email: email,
      phone: localPhone,
      role: AppUserRole.cliente,
      isVerified: true,
    );
    currentSession = session;
    return session;
  }

  @override
  Future<AuthUserSession> signInWithSocial(String provider) async {
    const AuthUserSession session = AuthUserSession(
      userId: 'test-user-social',
      fullName: 'Social User',
      email: 'social@clin.com.ar',
      phone: '+5492625123456',
      role: AppUserRole.cliente,
      isVerified: true,
    );
    currentSession = session;
    return session;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<AuthUserSession> updateActiveRole(AppUserRole role) async {
    final AuthUserSession updated =
        currentSession?.copyWith(role: role) ??
        AuthUserSession(
          userId: 'test-user-123',
          fullName: 'Lautaro',
          email: 'test@clin.com.ar',
          phone: '',
          role: role,
          isVerified: true,
        );
    currentSession = updated;
    return updated;
  }

  @override
  Future<void> signOut() async {
    currentSession = null;
  }

  @override
  Future<void> deleteAccount() async {
    currentSession = null;
  }
}

void main() {
  group('PushMessage parser', () {
    test('extrae orderId desde campo explicito order_id', () {
      final PushMessage msg = PushMessage.fromMap(
        data: <String, dynamic>{
          'order_id': 'ord-123',
          'title': 'Pedido Listo',
          'body': 'Tu pedido ya salió.',
        },
      );
      expect(msg.orderId, equals('ord-123'));
      expect(msg.title, equals('Pedido Listo'));
      expect(msg.body, equals('Tu pedido ya salió.'));
    });

    test('extrae orderId parseando url /pedidos/:id de send-push', () {
      final PushMessage msg = PushMessage.fromMap(
        data: <String, dynamic>{
          'url': '/pedidos/ord-alvear-99',
          'title': '¡Pedido Confirmado!',
          'body': 'El local confirmó tu pedido.',
        },
      );
      expect(msg.orderId, equals('ord-alvear-99'));
      expect(msg.url, equals('/pedidos/ord-alvear-99'));
    });

    test('soporta campo pedido_id como fallback', () {
      final PushMessage msg = PushMessage.fromMap(
        data: <String, dynamic>{
          'pedido_id': 'ped-456',
          'title': '¡En Camino!',
          'message': 'El repartidor está cerca.',
        },
      );
      expect(msg.orderId, equals('ped-456'));
      expect(msg.body, equals('El repartidor está cerca.'));
    });
  });

  group('FakePushService', () {
    test('obtiene token simulado y concede permisos', () async {
      final FakePushService service = FakePushService(
        initialToken: 'test-token-alvear',
      );

      expect(await service.getDeviceToken(), equals('test-token-alvear'));
      expect(await service.requestPermission(), isTrue);
    });

    test('emite notificaciones en primer plano a través del Stream', () async {
      final FakePushService service = FakePushService();
      final List<PushMessage> received = <PushMessage>[];

      final streamSub = service.onForegroundMessage.listen(received.add);

      const PushMessage msg = PushMessage(
        title: '¡Tu hamburguesa está lista!',
        body: 'El delivery llegará en 10 minutos.',
        orderId: 'ord-888',
      );

      service.simulateForegroundMessage(msg);
      await pumpEventQueue();

      expect(received.length, equals(1));
      expect(received.first.orderId, equals('ord-888'));
      expect(received.first.title, equals('¡Tu hamburguesa está lista!'));

      await streamSub.cancel();
      service.dispose();
    });

    test('invoca onNavigateToOrder al pulsar una notificación', () async {
      final FakePushService service = FakePushService();
      String? navigatedOrderId;

      await service.initialize(
        onNavigateToOrder: (String orderId) {
          navigatedOrderId = orderId;
        },
      );

      service.simulateNotificationClick('ord-click-123');

      expect(navigatedOrderId, equals('ord-click-123'));
      service.dispose();
    });
  });

  group('AuthController y PushService integration', () {
    test(
      'sincroniza token al iniciar sesion y lo elimina al cerrar sesion',
      () async {
        final FakePushService fakePush = FakePushService(
          initialToken: 'fcm-device-lautaro',
        );
        final _MockAuthRepository mockAuth = _MockAuthRepository();

        final ProviderContainer container = ProviderContainer(
          overrides: [
            pushServiceProvider.overrideWithValue(fakePush),
            authRepositoryProvider.overrideWithValue(mockAuth),
          ],
        );
        addTearDown(container.dispose);

        // Al crear el controlador e iniciar sesión
        final AuthController controller = container.read(
          authControllerProvider.notifier,
        );

        await controller.signIn(
          identifier: 'lautaro@clin.com.ar',
          password: 'Password123!',
        );

        expect(fakePush.syncedUserIds, contains('test-user-123'));

        // Al cerrar sesión
        await controller.signOut();

        expect(fakePush.deletedUserIds, contains('test-user-123'));
      },
    );
  });
}
