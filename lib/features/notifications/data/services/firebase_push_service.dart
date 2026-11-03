import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:clinapp/features/notifications/domain/models/push_message.dart';
import 'package:clinapp/features/notifications/domain/repositories/push_subscription_repository.dart';
import 'package:clinapp/features/notifications/domain/services/push_service.dart';

/// Manejador de notificaciones en segundo plano requerido por Firebase.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Manejo pasivo en segundo plano. Los datos ya vienen encapsulados por el SO.
}

/// Implementación de [PushService] basada en Firebase Cloud Messaging y APNs.
class FirebasePushService implements PushService {
  FirebasePushService({required this.repository, FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final PushSubscriptionRepository repository;
  final FirebaseMessaging _messaging;

  final StreamController<PushMessage> _foregroundController =
      StreamController<PushMessage>.broadcast();

  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  void Function(String orderId)? _onNavigateToOrder;
  String? _currentUserId;

  @override
  Future<void> initialize({
    required void Function(String orderId) onNavigateToOrder,
  }) async {
    _onNavigateToOrder = onNavigateToOrder;

    try {
      // Configuración de notificaciones en primer plano para iOS
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 1. Escucha en primer plano
      _onMessageSubscription = FirebaseMessaging.onMessage.listen((
        RemoteMessage message,
      ) {
        final PushMessage pushMessage = _mapRemoteMessage(message);
        _foregroundController.add(pushMessage);
      });

      // 2. Escucha cuando el usuario pulsa una notificación con la app en segundo plano
      _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp
          .listen((RemoteMessage message) {
            _handleMessageOpened(message);
          });

      // 3. Revisión de notificación inicial (app cerrada / terminada)
      final RemoteMessage? initialMessage = await _messaging
          .getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpened(initialMessage);
      }

      // 4. Renovación de token FCM
      // ignore: deprecated_member_use
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((
        String newToken,
      ) async {
        final String? userId = _currentUserId;
        if (userId != null && userId.isNotEmpty) {
          final String platformName = switch (defaultTargetPlatform) {
            TargetPlatform.iOS => 'ios',
            TargetPlatform.android => 'android',
            _ => 'mobile',
          };
          await repository.registerSubscription(
            userId: userId,
            token: newToken,
            platform: platformName,
          );
        }
      });
    } on Object catch (error) {
      debugPrint('[FirebasePushService] Error durante inicialización: $error');
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } on Object catch (error) {
      debugPrint('[FirebasePushService] Error solicitando permisos: $error');
      return false;
    }
  }

  @override
  Future<String?> getDeviceToken() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // En iOS se requiere token APNs antes de que FCM pueda emitir su token
        final String? apns = await _messaging.getAPNSToken();
        if (apns == null) {
          debugPrint(
            '[FirebasePushService] Token APNs aún no disponible en iOS.',
          );
        }
      }
      // ignore: deprecated_member_use
      return await _messaging.getToken();
    } on Object catch (error) {
      debugPrint('[FirebasePushService] Error obteniendo token: $error');
      return null;
    }
  }

  @override
  Future<void> syncSubscription({required String userId}) async {
    if (userId.isEmpty) return;
    _currentUserId = userId;

    final String? token = await getDeviceToken();
    if (token == null || token.isEmpty) return;

    final String platformName = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'mobile',
    };

    try {
      await repository.registerSubscription(
        userId: userId,
        token: token,
        platform: platformName,
      );
    } on Object catch (error) {
      debugPrint('[FirebasePushService] Error sincronizando token: $error');
    }
  }

  @override
  Future<void> deleteSubscription({required String userId}) async {
    _currentUserId = null;
    final String? token = await getDeviceToken();
    if (token != null && token.isNotEmpty) {
      try {
        await repository.removeSubscription(userId: userId, token: token);
      } on Object catch (error) {
        debugPrint('[FirebasePushService] Error eliminando token: $error');
      }
    }
  }

  @override
  Stream<PushMessage> get onForegroundMessage => _foregroundController.stream;

  void _handleMessageOpened(RemoteMessage message) {
    final PushMessage pushMessage = _mapRemoteMessage(message);
    final String? orderId = pushMessage.orderId;
    if (orderId != null && orderId.isNotEmpty) {
      _onNavigateToOrder?.call(orderId);
    }
  }

  PushMessage _mapRemoteMessage(RemoteMessage message) {
    return PushMessage.fromMap(
      data: message.data,
      title: message.notification?.title,
      body: message.notification?.body,
      id: message.messageId,
    );
  }

  @override
  void dispose() {
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    _foregroundController.close();
  }
}
