import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinapp/core/config/env.dart';

/// Provee el [SupabaseClient] activo si las credenciales fueron inyectadas
/// por `--dart-define` y Supabase está inicializado, o `null` cuando se ejecuta
/// en modo semilla con datos locales de prueba.
final Provider<SupabaseClient?> supabaseClientProvider =
    Provider<SupabaseClient?>((Ref ref) {
      if (!Env.isSupabaseConfigured) {
        return null;
      }
      try {
        return Supabase.instance.client;
      } on Object {
        return null;
      }
    });

/// Provee un booleano reactivo que indica si el backend de Supabase está efectivamente
/// configurado con credenciales válidas y el cliente está disponible.
final Provider<bool> isBackendConfiguredProvider = Provider<bool>((Ref ref) {
  final SupabaseClient? client = ref.watch(supabaseClientProvider);
  return client != null;
});
