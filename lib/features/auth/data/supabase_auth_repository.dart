import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinapp/core/config/env.dart';
import 'package:clinapp/core/config/supabase_provider.dart';
import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/network/retry_policy.dart';
import 'package:clinapp/features/auth/data/secure_session_storage.dart';
import 'package:clinapp/features/auth/domain/auth_models.dart';
import 'package:clinapp/features/auth/domain/auth_repository.dart';

/// Implementación del repositorio de autenticación conectada a Supabase y Secure Storage.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required this.client,
    SessionStorage? storage,
    bool? allowSeedFallbackOverride,
  }) : _storage = storage ?? SecureSessionStorage(),
       _canUseSeedFallback =
           allowSeedFallbackOverride ??
           (client == null && Env.allowSeedFallback);

  final SupabaseClient? client;
  final SessionStorage _storage;
  final bool _canUseSeedFallback;

  /// Sesión por defecto del diseño de Google Stitch (Lautaro Ponzina, General Alvear).
  /// Solo se utiliza en entorno de desarrollo local sin backend configurado.
  static const AuthUserSession defaultDevSession = AuthUserSession(
    userId: 'alvear-dev-user-001',
    fullName: 'Lautaro Ponzina',
    email: 'ponzinalautaro6@gmail.com',
    phone: '+54 9 2625 401234',
    role: AppUserRole.admin,
    isVerified: true,
  );

  AuthUserSession? _inMemorySession;

  @override
  Future<AuthUserSession?> loadInitialSession() async {
    // 1. Revisar si hay sesión en storage seguro.
    final AuthUserSession? stored = await _storage.readSession();
    if (stored != null) {
      final bool isCachedDevSeed = stored.userId == defaultDevSession.userId;
      final bool shouldPurgeSession =
          (!_canUseSeedFallback && isCachedDevSeed) ||
          (client != null && client!.auth.currentUser == null && !Env.isDev);
      if (shouldPurgeSession) {
        await _storage.deleteSession();
      } else {
        _inMemorySession = stored;
        return stored;
      }
    }

    // 2. Si hay cliente de Supabase con sesión activa.
    final User? currentSupabaseUser = client?.auth.currentUser;
    if (currentSupabaseUser != null) {
      final AuthUserSession session = await _fetchProfileFromDb(
        currentSupabaseUser.id,
        currentSupabaseUser.email ?? '',
      );
      _inMemorySession = session;
      await _storage.writeSession(session);
      return session;
    }

    // 3. Fallback determinista solo para desarrollo local sin Supabase.
    if (_canUseSeedFallback) {
      _inMemorySession = defaultDevSession;
      await _storage.writeSession(defaultDevSession);
      return defaultDevSession;
    }

    _inMemorySession = null;
    return null;
  }

  Future<AuthUserSession> _fetchProfileFromDb(
    String userId,
    String email,
  ) async {
    final SupabaseClient? activeClient = client;
    if (activeClient == null) {
      return defaultDevSession;
    }
    try {
      final Map<String, Object?>? row =
          await RetryPolicy.execute<Map<String, Object?>?>(
            () => activeClient
                .from('profiles')
                .select('nombre, telefono, rol, avatar_url')
                .eq('id', userId)
                .maybeSingle(),
          );

      if (row != null) {
        final String? rawName = row['nombre'] as String?;
        return AuthUserSession(
          userId: userId,
          fullName: (rawName != null && rawName.trim().isNotEmpty)
              ? rawName.trim()
              : 'Usuario ClinApp',
          email: email,
          phone: row['telefono'] as String? ?? '+54 9 2625',
          role: AppUserRole.fromString(row['rol'] as String?),
          isVerified: true,
          avatarUrl: row['avatar_url'] as String?,
        );
      }
    } on PermissionDeniedFailure {
      rethrow;
    } on Object {
      // Si falla la consulta de perfil por red, retornar perfil básico autenticado
    }

    return AuthUserSession(
      userId: userId,
      fullName: 'Usuario ClinApp',
      email: email,
      phone: '+54 9 2625',
      role: AppUserRole.cliente,
      isVerified: true,
    );
  }

  @override
  Future<AuthUserSession> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    final String cleanIdentifier = identifier.trim();
    final SupabaseClient? activeClient = client;

    if (activeClient != null) {
      try {
        final AuthResponse response = await RetryPolicy.execute<AuthResponse>(
          () {
            if (cleanIdentifier.contains('@')) {
              return activeClient.auth.signInWithPassword(
                email: cleanIdentifier,
                password: password,
              );
            }
            final String digits = cleanIdentifier.replaceAll(RegExp(r'\D'), '');
            return activeClient.auth.signInWithPassword(
              phone: digits.startsWith('+') ? digits : '+549$digits',
              password: password,
            );
          },
          timeout: RetryPolicy.defaultMutationTimeout,
        );

        final User? user = response.user;
        if (user == null) {
          throw const AuthFailure(AppStrings.errorAuthCredentials);
        }

        final AuthUserSession session = await _fetchProfileFromDb(
          user.id,
          user.email ?? cleanIdentifier,
        );
        _inMemorySession = session;
        await _storage.writeSession(session);
        return session;
      } on Object catch (error) {
        throw AppException.fromError(error);
      }
    }

    if (!_canUseSeedFallback) {
      throw const AuthFailure(AppStrings.errorAuth);
    }

    // Modo local / pruebas sin Supabase
    final AuthUserSession session = defaultDevSession.copyWith(
      email: cleanIdentifier.contains('@')
          ? cleanIdentifier
          : defaultDevSession.email,
    );
    _inMemorySession = session;
    await _storage.writeSession(session);
    return session;
  }

  @override
  Future<AuthUserSession> signUp({
    required String fullName,
    required String localPhone,
    required String email,
    required String password,
  }) async {
    final String fullPhone = '+54 9 2625 $localPhone';
    final SupabaseClient? activeClient = client;

    if (activeClient != null) {
      try {
        final AuthResponse response = await RetryPolicy.execute<AuthResponse>(
          () => activeClient.auth.signUp(
            email: email.trim(),
            password: password,
            data: <String, dynamic>{
              'nombre': fullName,
              'full_name': fullName,
              'name': fullName,
              'telefono': fullPhone,
              'phone': fullPhone,
            },
          ),
          maxAttempts: 2,
          timeout: RetryPolicy.defaultMutationTimeout,
        );

        final User? user = response.user;
        if (user == null) {
          throw const AuthFailure(AppStrings.errorAuth);
        }

        final AuthUserSession session = AuthUserSession(
          userId: user.id,
          fullName: fullName,
          email: email.trim(),
          phone: fullPhone,
          role: AppUserRole.cliente,
          isVerified: true,
        );
        _inMemorySession = session;
        await _storage.writeSession(session);
        return session;
      } on Object catch (error) {
        throw AppException.fromError(error);
      }
    }

    if (!_canUseSeedFallback) {
      throw const AuthFailure(AppStrings.errorAuth);
    }

    final AuthUserSession session = AuthUserSession(
      userId: 'alvear-new-user-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      email: email.trim(),
      phone: fullPhone,
      role: AppUserRole.cliente,
      isVerified: true,
    );
    _inMemorySession = session;
    await _storage.writeSession(session);
    return session;
  }

  @override
  Future<AuthUserSession> signInWithSocial(String provider) async {
    if (!_canUseSeedFallback && client != null) {
      throw const AuthFailure(AppStrings.errorAuth);
    }

    final AuthUserSession session = defaultDevSession.copyWith(
      fullName: 'Lucas Benítez',
      email: 'lucas.benitez@gmail.com',
    );
    _inMemorySession = session;
    await _storage.writeSession(session);
    return session;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    final SupabaseClient? activeClient = client;
    if (activeClient != null) {
      try {
        await RetryPolicy.execute<void>(
          () => activeClient.auth.resetPasswordForEmail(email.trim()),
          maxAttempts: 2,
          timeout: RetryPolicy.defaultMutationTimeout,
        );
      } on Object catch (error) {
        throw AppException.fromError(error);
      }
    }
  }

  @override
  Future<AuthUserSession> updateActiveRole(AppUserRole role) async {
    if (!Env.enableDemoRoleSwitcher && !_canUseSeedFallback) {
      throw const PermissionDeniedFailure(AppStrings.errorPermissionDenied);
    }
    final AuthUserSession current = _inMemorySession ?? defaultDevSession;
    final AuthUserSession updated = current.copyWith(role: role);
    _inMemorySession = updated;
    await _storage.writeSession(updated);
    return updated;
  }

  @override
  Future<void> signOut() async {
    _inMemorySession = null;
    await _storage.deleteSession();
    if (client != null) {
      try {
        await client!.auth.signOut().timeout(RetryPolicy.defaultReadTimeout);
      } on Object {
        // Garantizar limpieza local incluso si la red falla al cerrar sesión
      }
    }
  }

  @override
  Future<void> deleteAccount() async {
    final SupabaseClient? activeClient = client;
    if (activeClient != null) {
      try {
        await RetryPolicy.execute<void>(
          () => activeClient.rpc<void>('delete_own_account'),
          maxAttempts: 1,
          timeout: RetryPolicy.defaultMutationTimeout,
        );
      } on Object catch (error) {
        throw AppException.fromError(error);
      }
    }

    await signOut();
  }
}

/// Provider del repositorio de autenticación.
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((Ref ref) {
      final SupabaseClient? client = ref.watch(supabaseClientProvider);
      return SupabaseAuthRepository(client: client);
    });
