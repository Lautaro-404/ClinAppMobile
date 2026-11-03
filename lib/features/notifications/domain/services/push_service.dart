import 'dart:async';

import 'package:clinapp/features/notifications/domain/models/push_message.dart';

/// Contrato abstracto para el servicio de notificaciones push de ClinApp.
///
/// Aísla los SDKs nativos (Firebase Messaging, APNs) para permitir
/// implementaciones falsas (fakes) en tests y entornos de desarrollo.
abstract interface class PushService {
  /// Inicializa los escuchas de notificaciones en primer plano, segundo plano y app cerrada.
  ///
  /// Invoca [onNavigateToOrder] cuando el usuario interactúa con una notificación
  /// que contiene un identificador de pedido o deep link hacia `/pedidos/<id>`.
  Future<void> initialize({
    required void Function(String orderId) onNavigateToOrder,
  });

  /// Solicita permisos de notificación al sistema operativo (Android 13+, iOS APNs).
  ///
  /// Retorna `true` si el usuario concedió los permisos necesarios.
  Future<bool> requestPermission();

  /// Obtiene el token de registro del dispositivo (FCM / APNs).
  Future<String?> getDeviceToken();

  /// Registra o actualiza el token del dispositivo en la tabla `push_subscriptions`.
  Future<void> syncSubscription({required String userId});

  /// Elimina la suscripción del dispositivo de `push_subscriptions` al cerrar sesión.
  Future<void> deleteSubscription({required String userId});

  /// Flujo continuo de notificaciones recibidas con la app en primer plano.
  Stream<PushMessage> get onForegroundMessage;

  /// Libera recursos o controladores de flujo.
  void dispose();
}
