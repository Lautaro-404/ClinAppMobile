import 'dart:async';
import 'dart:math';

import 'package:clinapp/core/errors/app_exception.dart';

/// Política de timeouts y reintentos con exponential backoff + jitter
/// para llamadas a Supabase (PostgREST, Auth, Storage y Edge Functions).
abstract final class RetryPolicy {
  static const Duration defaultReadTimeout = Duration(seconds: 10);
  static const Duration defaultMutationTimeout = Duration(seconds: 15);
  static const Duration defaultBaseDelay = Duration(milliseconds: 350);

  static final Random _random = Random();

  /// Ejecuta [action] aplicando [timeout] en cada intento y reintentando hasta
  /// [maxAttempts] veces con backoff exponencial si el fallo es transitorio de red.
  ///
  /// Nunca reintenta errores de negocio, validación, autenticación ni permisos RLS.
  static Future<T> execute<T>(
    Future<T> Function() action, {
    int maxAttempts = 3,
    Duration timeout = defaultReadTimeout,
    Duration baseDelay = defaultBaseDelay,
    void Function(bool isOffline)? onConnectivityChanged,
  }) async {
    final int safeMaxAttempts = maxAttempts < 1 ? 1 : maxAttempts;
    Object? lastError;

    for (int attempt = 1; attempt <= safeMaxAttempts; attempt++) {
      try {
        final T result = await action().timeout(timeout);
        onConnectivityChanged?.call(false);
        return result;
      } on Object catch (error) {
        final AppException mapped = AppException.fromError(error);
        lastError = mapped;

        final bool isTransient = mapped is NetworkFailure;
        if (isTransient) {
          onConnectivityChanged?.call(true);
        }

        if (!isTransient || attempt >= safeMaxAttempts) {
          throw mapped;
        }

        final int exponentialMs =
            baseDelay.inMilliseconds * (1 << (attempt - 1));
        final int jitterMs = baseDelay.inMilliseconds > 0
            ? _random.nextInt((baseDelay.inMilliseconds ~/ 2) + 1)
            : 0;
        final Duration waitDuration = Duration(
          milliseconds: (exponentialMs + jitterMs).clamp(0, 5000),
        );

        if (waitDuration > Duration.zero) {
          await Future<void>.delayed(waitDuration);
        }
      }
    }

    throw AppException.fromError(
      lastError ?? const NetworkFailure('Error de red'),
    );
  }
}
