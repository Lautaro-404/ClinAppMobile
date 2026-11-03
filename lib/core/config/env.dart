/// Entornos de ejecución soportados por ClinApp.
enum AppEnvironment {
  dev,
  staging,
  prod;

  static AppEnvironment fromString(String raw) {
    final String normalized = raw.trim().toLowerCase();
    return switch (normalized) {
      'prod' || 'production' => AppEnvironment.prod,
      'staging' || 'stage' || 'qa' => AppEnvironment.staging,
      _ => AppEnvironment.dev,
    };
  }
}

/// Configuración por entorno inyectada mediante `--dart-define-from-file=.env.<entorno>`.
///
/// Solo debe contener valores públicos (URL y anon key pública).
/// Nunca almacenar secretos ni service_role key en el cliente.
abstract final class Env {
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String appDeepLinkScheme = String.fromEnvironment(
    'APP_DEEP_LINK_SCHEME',
    defaultValue: 'clinapp',
  );
  static const String appBaseUrl = String.fromEnvironment(
    'APP_BASE_URL',
    defaultValue: 'https://clin.app',
  );

  static AppEnvironment get appEnvironment =>
      AppEnvironment.fromString(environment);

  static bool get isDev => appEnvironment == AppEnvironment.dev;
  static bool get isStaging => appEnvironment == AppEnvironment.staging;
  static bool get isProd => appEnvironment == AppEnvironment.prod;

  /// Retorna `true` si tanto la URL como la Anon Key de Supabase fueron provistas.
  static bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  /// Permite usar sesión demo y repositorios semilla solo en desarrollo local
  /// cuando no se inyectaron credenciales de un proyecto Supabase.
  static bool get allowSeedFallback => isDev && !isSupabaseConfigured;

  /// Habilita el selector de rol de prueba únicamente en desarrollo.
  static bool get enableDemoRoleSwitcher => isDev;
}
