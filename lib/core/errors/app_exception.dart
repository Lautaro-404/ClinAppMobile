import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinapp/core/l10n/app_strings.dart';

/// Tipo de error propio de la aplicación con mensaje amigable en español rioplatense.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  /// Convierte cualquier excepción externa en una [AppException] tipada.
  factory AppException.fromError(Object error) {
    if (error is AppException) {
      return error;
    }
    if (error is AuthException) {
      return _mapAuthException(error);
    }
    if (error is PostgrestException) {
      return _mapPostgrestException(error);
    }
    if (error is FunctionException) {
      if (error.status == 401 || error.status == 403) {
        return const PermissionDeniedFailure(AppStrings.errorPermissionDenied);
      }
      return ServerFailure(error.details?.toString() ?? AppStrings.errorServer);
    }
    if (error is StorageException) {
      final String status = error.statusCode ?? '';
      if (status == '401' || status == '403') {
        return const PermissionDeniedFailure(AppStrings.errorPermissionDenied);
      }
      return ServerFailure(
        error.message.isNotEmpty ? error.message : AppStrings.errorServer,
        code: status,
      );
    }
    if (error is TimeoutException ||
        error.toString().toLowerCase().contains('timeoutexception') ||
        error.toString().toLowerCase().contains('timed out')) {
      return const NetworkFailure(AppStrings.errorTimeout);
    }
    if (error is SocketException ||
        error is HttpException ||
        error.toString().contains('SocketException') ||
        error.toString().contains('ClientException') ||
        error.toString().contains('Failed host lookup') ||
        error.toString().contains('Network is unreachable')) {
      return const NetworkFailure(AppStrings.errorNetwork);
    }
    return const NetworkFailure(AppStrings.genericErrorMessage);
  }

  static AuthFailure _mapAuthException(AuthException error) {
    final String msg = error.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid grant') ||
        msg.contains('invalid credential') ||
        msg.contains('invalid claim')) {
      return const AuthFailure(AppStrings.errorAuthCredentials);
    }
    if (msg.contains('user already registered') ||
        msg.contains('already exists')) {
      return const AuthFailure(AppStrings.errorAuthUserExists);
    }
    if (msg.contains('email not confirmed')) {
      return const AuthFailure(AppStrings.errorAuthEmailNotConfirmed);
    }
    return const AuthFailure(AppStrings.errorAuth);
  }

  static AppException _mapPostgrestException(PostgrestException error) {
    final String code = error.code ?? '';
    final String lowerMsg = error.message.toLowerCase();

    if (code == '42501' ||
        code == 'PGRST301' ||
        lowerMsg.contains('row-level security') ||
        lowerMsg.contains('no tenés permisos') ||
        lowerMsg.contains('no autorizado') ||
        lowerMsg.contains('permission denied') ||
        lowerMsg.contains('insufficient_privilege')) {
      return PermissionDeniedFailure(
        lowerMsg.contains('no tenés permisos')
            ? error.message
            : AppStrings.errorPermissionDenied,
        code: code.isNotEmpty ? code : '42501',
      );
    }

    if (code == 'P0001' && lowerMsg.contains('pedidos en curso')) {
      return const ValidationFailure(AppStrings.deleteAccountActiveOrdersError);
    }

    if (code == 'PGRST116') {
      return const ServerFailure(AppStrings.errorNotFound, code: 'PGRST116');
    }

    return ServerFailure(
      AppStrings.errorServer,
      code: error.code,
      details: error.details,
    );
  }

  @override
  String toString() => message;
}

/// Fallo de conectividad o red.
final class NetworkFailure extends AppException {
  const NetworkFailure(super.message);
}

/// Fallo del servidor o base de datos.
final class ServerFailure extends AppException {
  const ServerFailure(super.message, {this.code, this.details});

  final String? code;
  final Object? details;
}

/// Fallo por denegación de permisos o política RLS (42501 / 403).
final class PermissionDeniedFailure extends AppException {
  const PermissionDeniedFailure(super.message, {this.code});

  final String? code;
}

/// Alias para compatibilidad con la nomenclatura del dominio.
typedef ServerException = ServerFailure;

/// Alias de excepciones de red del dominio.
typedef NetworkException = NetworkFailure;

/// Alias de excepciones de autenticación del dominio.
typedef AuthCustomException = AuthFailure;

/// Fallo relacionado con autenticación o sesión.
final class AuthFailure extends AppException {
  const AuthFailure(super.message);
}

/// Fallo en validaciones de entrada de datos.
final class ValidationFailure extends AppException {
  const ValidationFailure(super.message);
}

/// Fallo cuando un recurso no es encontrado.
final class NotFoundFailure extends AppException {
  const NotFoundFailure(super.message);
}
