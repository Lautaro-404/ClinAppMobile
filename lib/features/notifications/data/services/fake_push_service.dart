import 'dart:async';

import 'package:clinapp/features/notifications/domain/models/push_message.dart';
import 'package:clinapp/features/notifications/domain/repositories/push_subscription_repository.dart';
import 'package:clinapp/features/notifications/domain/services/push_service.dart';

/// Implementación de prueba y modo offline de [PushService].
///
/// Permite simular la recepción de notificaciones, solicitudes de permiso,
/// cambios de token y navegación sin invocar los plugins nativos de Firebase.
class FakePushService implements PushService {
  FakePushService({
    String initialToken = 'fake-device-token-alvear-001',
    this.permissionGranted = true,
    this.repository,
  }) : _currentToken = initialToken;

  final PushSubscriptionRepository? repository;
  final bool permissionGranted;
  String? _currentToken;
  void Function(String orderId)? _onNavigateToOrder;

  final StreamController<PushMessage> _foregroundController =
      StreamController<PushMessage>.broadcast();

  final List<String> _syncedUserIds = <String>[];
  final List<String> _deletedUserIds = <String>[];

  List<String> get syncedUserIds => List<String>.unmodifiable(_syncedUserIds);
  List<String> get deletedUserIds => List<String>.unmodifiable(_deletedUserIds);

  @override
  Future<void> initialize({
    required void Function(String orderId) onNavigateToOrder,
  }) async {
    _onNavigateToOrder = onNavigateToOrder;
  }

  @override
  Future<bool> requestPermission() async {
    return permissionGranted;
  }

  @override
  Future<String?> getDeviceToken() async {
    return _currentToken;
  }

  @override
  Future<void> syncSubscription({required String userId}) async {
    if (userId.isEmpty) return;
    _syncedUserIds.add(userId);
    final String? token = _currentToken;
    if (token != null && repository != null) {
      await repository!.registerSubscription(
        userId: userId,
        token: token,
        platform: 'fake_test',
      );
    }
  }

  @override
  Future<void> deleteSubscription({required String userId}) async {
    if (userId.isEmpty) return;
    _deletedUserIds.add(userId);
    final String? token = _currentToken;
    if (token != null && repository != null) {
      await repository!.removeSubscription(userId: userId, token: token);
    }
  }

  @override
  Stream<PushMessage> get onForegroundMessage => _foregroundController.stream;

  /// Simula la llegada de un mensaje en primer plano para tests.
  void simulateForegroundMessage(PushMessage message) {
    if (!_foregroundController.isClosed) {
      _foregroundController.add(message);
    }
  }

  /// Simula la pulsación del usuario sobre una notificación nativa.
  void simulateNotificationClick(String orderId) {
    _onNavigateToOrder?.call(orderId);
  }

  /// Modifica el token actual para simular rotaciones o fallos.
  void updateToken(String? newToken) {
    _currentToken = newToken;
  }

  @override
  void dispose() {
    _foregroundController.close();
  }
}
