import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:clinapp/features/auth/domain/auth_models.dart';

/// Contrato para almacenamiento seguro de la sesión de usuario.
abstract class SessionStorage {
  Future<void> writeSession(AuthUserSession session);
  Future<AuthUserSession?> readSession();
  Future<void> deleteSession();
}

/// Implementación respaldada por [FlutterSecureStorage] con fallback en memoria
/// para pruebas automáticas y entornos sin canales nativos.
class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _sessionKey = 'clinapp_user_session_v1';
  final FlutterSecureStorage _storage;

  // Fallback en memoria si la plataforma no cuenta con el canal nativo (ej. widget tests).
  static final Map<String, String> _memoryCache = <String, String>{};

  bool get _isTestEnvironment {
    return !kIsWeb &&
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  @override
  Future<void> writeSession(AuthUserSession session) async {
    final String raw = jsonEncode(session.toJson());
    _memoryCache[_sessionKey] = raw;
    if (_isTestEnvironment) {
      return;
    }
    try {
      await _storage.write(key: _sessionKey, value: raw);
    } on MissingPluginException {
      // Ignorar en entorno sin plugin
    } on Object {
      // Ignorar excepciones de canal nativo
    }
  }

  @override
  Future<AuthUserSession?> readSession() async {
    String? raw = _memoryCache[_sessionKey];
    if (!_isTestEnvironment && (raw == null || raw.isEmpty)) {
      try {
        raw = await _storage.read(key: _sessionKey);
      } on MissingPluginException {
        raw = _memoryCache[_sessionKey];
      } on Object {
        raw = _memoryCache[_sessionKey];
      }
    }

    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AuthUserSession.fromJson(decoded);
      }
    } on Object {
      return null;
    }
    return null;
  }

  @override
  Future<void> deleteSession() async {
    _memoryCache.remove(_sessionKey);
    if (_isTestEnvironment) {
      return;
    }
    try {
      await _storage.delete(key: _sessionKey);
    } on MissingPluginException {
      // Ignorar en entorno sin plugin nativo
    } on Object {
      // Ignorar excepciones de plataforma en test
    }
  }
}
