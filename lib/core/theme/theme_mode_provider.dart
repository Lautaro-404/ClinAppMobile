import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Notifier que administra el [ThemeMode] activo de la aplicación y lo persiste.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String _storageKey = 'clinapp_theme_mode';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  ThemeMode build() {
    _loadPersistedTheme();
    return ThemeMode.system;
  }

  Future<void> _loadPersistedTheme() async {
    try {
      final String? raw = await _storage.read(key: _storageKey);
      if (raw == null) return;
      state = switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' || _ => ThemeMode.system,
      };
    } catch (_) {
      // Si falla la lectura de almacenamiento seguro, se conserva ThemeMode.system.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final String value = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await _storage.write(key: _storageKey, value: value);
    } catch (_) {
      // Ignora errores de almacenamiento seguro para no bloquear la UI.
    }
  }
}

/// Provider global del modo de tema de ClinApp.
final NotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
