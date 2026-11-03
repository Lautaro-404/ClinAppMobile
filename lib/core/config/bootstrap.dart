import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:clinapp/core/config/env.dart';
import 'package:clinapp/core/config/secure_local_storage.dart';
import 'package:clinapp/core/utils/date_formatter.dart';

/// Inicialización previa a `runApp`: locale es_AR, zona horaria de Mendoza
/// y cliente de Supabase con persistencia en secure storage si las variables están configuradas.
///
/// Si no hay credenciales, se preserva el modo semilla/offline de la app.
Future<void> bootstrap({
  bool? isSupabaseConfiguredOverride,
  LocalStorage? localStorageOverride,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'es_AR';
  await initializeDateFormatting('es_AR');
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation(DateFormatter.zoneName));

  // Inicialización segura de Firebase para push notifications
  try {
    await Firebase.initializeApp();
  } on Object catch (error) {
    debugPrint('[Bootstrap] Firebase no disponible o sin credenciales: $error');
  }

  final bool isConfigured =
      isSupabaseConfiguredOverride ?? Env.isSupabaseConfigured;

  if (isConfigured) {
    final LocalStorage storage = localStorageOverride ?? SecureLocalStorage();
    final GotrueAsyncStorage? pkceStorage = switch (storage) {
      final GotrueAsyncStorage gas => gas,
      _ => null,
    };

    // ignore: deprecated_member_use
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: Env.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: storage,
        pkceAsyncStorage: pkceStorage,
      ),
    );
  }
}
