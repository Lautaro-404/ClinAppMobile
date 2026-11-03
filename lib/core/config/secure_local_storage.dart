import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementación personalizada de almacenamiento seguro para la sesión de Supabase Auth
/// y el almacenamiento PKCE utilizando [FlutterSecureStorage].
///
/// Incluye una memoria caché local y tolerancia ante ausencia de canales nativos
/// en entornos de pruebas automatizadas.
class SecureLocalStorage extends LocalStorage implements GotrueAsyncStorage {
  SecureLocalStorage({
    FlutterSecureStorage? storage,
    this.persistSessionKey = 'clinapp_supabase_auth_session',
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final String persistSessionKey;

  final Map<String, String> _memoryCache = <String, String>{};

  bool get _isTestEnvironment =>
      !kIsWeb &&
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  Future<void> initialize() async {
    // No requiere inicialización asíncrona bloqueante.
  }

  @override
  Future<bool> hasAccessToken() async {
    if (_memoryCache.containsKey(persistSessionKey)) {
      return true;
    }
    if (_isTestEnvironment) {
      return false;
    }
    try {
      final String? value = await _storage.read(key: persistSessionKey);
      return value != null && value.isNotEmpty;
    } on Object {
      return _memoryCache.containsKey(persistSessionKey);
    }
  }

  @override
  Future<String?> accessToken() async {
    if (_memoryCache.containsKey(persistSessionKey)) {
      return _memoryCache[persistSessionKey];
    }
    if (_isTestEnvironment) {
      return null;
    }
    try {
      final String? value = await _storage.read(key: persistSessionKey);
      if (value != null) {
        _memoryCache[persistSessionKey] = value;
      }
      return value;
    } on Object {
      return _memoryCache[persistSessionKey];
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    _memoryCache[persistSessionKey] = persistSessionString;
    if (_isTestEnvironment) {
      return;
    }
    try {
      await _storage.write(key: persistSessionKey, value: persistSessionString);
    } on Object {
      // Retiene en memoria si la plataforma nativa no responde
    }
  }

  @override
  Future<void> removePersistedSession() async {
    _memoryCache.remove(persistSessionKey);
    if (_isTestEnvironment) {
      return;
    }
    try {
      await _storage.delete(key: persistSessionKey);
    } on Object {
      // Removido de memoria
    }
  }

  // --- Implementación de GotrueAsyncStorage (PKCE verifier) ---

  @override
  Future<String?> getItem({required String key}) async {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }
    if (_isTestEnvironment) {
      return null;
    }
    try {
      final String? value = await _storage.read(key: key);
      if (value != null) {
        _memoryCache[key] = value;
      }
      return value;
    } on Object {
      return _memoryCache[key];
    }
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _memoryCache[key] = value;
    if (_isTestEnvironment) {
      return;
    }
    try {
      await _storage.write(key: key, value: value);
    } on Object {
      // Retiene en memoria
    }
  }

  @override
  Future<void> removeItem({required String key}) async {
    _memoryCache.remove(key);
    if (_isTestEnvironment) {
      return;
    }
    try {
      await _storage.delete(key: key);
    } on Object {
      // Removido de memoria
    }
  }
}
