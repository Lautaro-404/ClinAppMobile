import 'package:clinapp/features/auth/domain/auth_models.dart';

/// Contrato del repositorio de autenticación y sesión de ClinApp.
abstract class AuthRepository {
  /// Carga la sesión guardada localmente o la sesión activa de Supabase.
  Future<AuthUserSession?> loadInitialSession();

  /// Inicia sesión con correo electrónico o teléfono y contraseña.
  Future<AuthUserSession> signInWithIdentifier({
    required String identifier,
    required String password,
  });

  /// Registra un nuevo usuario en la plataforma.
  Future<AuthUserSession> signUp({
    required String fullName,
    required String localPhone,
    required String email,
    required String password,
  });

  /// Inicia sesión o registro con proveedores sociales (Google / Apple).
  Future<AuthUserSession> signInWithSocial(String provider);

  /// Solicita el restablecimiento de contraseña al correo especificado.
  Future<void> sendPasswordReset(String email);

  /// Actualiza el rol activo del usuario (para pruebas o sincronización).
  Future<AuthUserSession> updateActiveRole(AppUserRole role);

  /// Cierra la sesión activa y borra credenciales locales seguras.
  Future<void> signOut();

  /// Elimina permanentemente la cuenta del usuario autenticado y sus datos personales.
  Future<void> deleteAccount();
}
