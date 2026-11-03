import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clinapp/features/auth/data/supabase_auth_repository.dart';
import 'package:clinapp/features/auth/domain/auth_models.dart';
import 'package:clinapp/features/auth/domain/auth_repository.dart';
import 'package:clinapp/features/notifications/domain/services/push_service.dart';
import 'package:clinapp/features/notifications/presentation/push_service_provider.dart';

/// Controlador global de autenticación y sesión activa en ClinApp.
class AuthController extends AsyncNotifier<AuthUserSession?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<AuthUserSession?> build() async {
    final AuthUserSession? session = await _repository.loadInitialSession();
    if (session != null) {
      unawaited(_syncPushToken(session.userId));
    }
    return session;
  }

  /// Inicia sesión con identificador (teléfono/email) y contraseña.
  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    state = const AsyncValue<AuthUserSession?>.loading();
    final AsyncValue<AuthUserSession?> result = await AsyncValue.guard(
      () => _repository.signInWithIdentifier(
        identifier: identifier,
        password: password,
      ),
    );
    state = result;
    final AuthUserSession? session = result.value;
    if (session != null) {
      await _syncPushToken(session.userId);
    }
  }

  /// Registra una nueva cuenta.
  Future<void> signUp({
    required String fullName,
    required String localPhone,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue<AuthUserSession?>.loading();
    final AsyncValue<AuthUserSession?> result = await AsyncValue.guard(
      () => _repository.signUp(
        fullName: fullName,
        localPhone: localPhone,
        email: email,
        password: password,
      ),
    );
    state = result;
    final AuthUserSession? session = result.value;
    if (session != null) {
      await _syncPushToken(session.userId);
    }
  }

  /// Inicio de sesión social (Google / Apple).
  Future<void> signInWithSocial(String provider) async {
    state = const AsyncValue<AuthUserSession?>.loading();
    final AsyncValue<AuthUserSession?> result = await AsyncValue.guard(
      () => _repository.signInWithSocial(provider),
    );
    state = result;
    final AuthUserSession? session = result.value;
    if (session != null) {
      await _syncPushToken(session.userId);
    }
  }

  /// Envía enlace para restablecer la contraseña.
  Future<void> sendPasswordReset(String email) async {
    await _repository.sendPasswordReset(email);
  }

  /// Cambia el rol activo del usuario para pruebas o sincronización con el backend.
  Future<void> switchRole(AppUserRole role) async {
    final AuthUserSession? current = state.value;
    if (current == null) return;
    final AuthUserSession updated = await _repository.updateActiveRole(role);
    state = AsyncValue<AuthUserSession?>.data(updated);
  }

  /// Cierra la sesión activa y elimina la suscripción push del dispositivo.
  Future<void> signOut() async {
    final AuthUserSession? current = state.value;
    state = const AsyncValue<AuthUserSession?>.loading();
    if (current != null) {
      await _deletePushToken(current.userId);
    }
    await _repository.signOut();
    state = const AsyncValue<AuthUserSession?>.data(null);
  }

  /// Elimina permanentemente la cuenta del usuario autenticado y sus datos.
  Future<void> deleteAccount() async {
    final AuthUserSession? current = state.value;
    if (current != null) {
      await _deletePushToken(current.userId);
    }
    await _repository.deleteAccount();
    state = const AsyncValue<AuthUserSession?>.data(null);
  }

  Future<void> _syncPushToken(String userId) async {
    try {
      final PushService pushService = ref.read(pushServiceProvider);
      await pushService.syncSubscription(userId: userId);
    } on Object {
      // Ignorar fallos de sincronización para no bloquear autenticación
    }
  }

  Future<void> _deletePushToken(String userId) async {
    try {
      final PushService pushService = ref.read(pushServiceProvider);
      await pushService.deleteSubscription(userId: userId);
    } on Object {
      // Ignorar fallos al cerrar sesión
    }
  }
}

/// Provider global de autenticación.
final AsyncNotifierProvider<AuthController, AuthUserSession?>
authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUserSession?>(AuthController.new);

/// Provider derivado para verificar si el usuario tiene sesión activa.
final Provider<bool> isAuthenticatedProvider = Provider<bool>((Ref ref) {
  final AuthUserSession? session = ref.watch(authControllerProvider).value;
  return session != null;
});
