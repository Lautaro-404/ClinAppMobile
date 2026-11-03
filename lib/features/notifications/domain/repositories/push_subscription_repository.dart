/// Contrato para gestionar el ciclo de vida de tokens de suscripción push en el backend.
abstract interface class PushSubscriptionRepository {
  /// Registra o actualiza el token del dispositivo para el usuario indicado.
  Future<void> registerSubscription({
    required String userId,
    required String token,
    String? platform,
  });

  /// Elimina una suscripción específica del usuario y dispositivo.
  Future<void> removeSubscription({
    required String userId,
    required String token,
  });

  /// Elimina todas las suscripciones asociadas al usuario indicado (opcional).
  Future<void> removeAllUserSubscriptions({required String userId});
}
