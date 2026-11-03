import 'package:flutter/foundation.dart';

/// Roles de usuario soportados en Supabase y ClinApp.
enum AppUserRole {
  cliente,
  local,
  repartidor,
  admin;

  /// Indica si el rol puede visualizar el Panel Admin.
  bool get canAccessAdminPanel => this == AppUserRole.admin;

  /// Indica si el rol puede visualizar Mi Local.
  bool get canAccessMerchantPanel =>
      this == AppUserRole.admin || this == AppUserRole.local;

  /// Indica si el rol puede visualizar el Panel Repartidor.
  bool get canAccessCourierPanel =>
      this == AppUserRole.admin || this == AppUserRole.repartidor;

  /// Parsea desde string de base de datos.
  static AppUserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return AppUserRole.admin;
      case 'local':
        return AppUserRole.local;
      case 'repartidor':
        return AppUserRole.repartidor;
      case 'cliente':
      default:
        return AppUserRole.cliente;
    }
  }

  /// Retorna el valor en string para la base de datos o almacenamiento.
  String toDatabaseValue() => name;
}

/// Nivel de fortaleza de una contraseña calculada en cliente.
enum PasswordStrength {
  empty(0),
  weak(1),
  fair(2),
  good(3),
  strong(4);

  const PasswordStrength(this.activeSegments);

  /// Cantidad de barras encendidas en el medidor (0 a 4).
  final int activeSegments;
}

/// Sesión activa del usuario autenticado en ClinApp.
@immutable
class AuthUserSession {
  const AuthUserSession({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.isVerified = true,
    this.avatarUrl,
  });

  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final AppUserRole role;
  final bool isVerified;
  final String? avatarUrl;

  /// Inicial con inicial mayúscula para el avatar.
  String get initialLetter {
    final String trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'U';
    return trimmed.substring(0, 1).toUpperCase();
  }

  AuthUserSession copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? phone,
    AppUserRole? role,
    bool? isVerified,
    String? avatarUrl,
  }) {
    return AuthUserSession(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'user_id': userId,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'role': role.toDatabaseValue(),
    'is_verified': isVerified,
    'avatar_url': avatarUrl,
  };

  factory AuthUserSession.fromJson(Map<String, dynamic> json) {
    return AuthUserSession(
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Usuario',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: AppUserRole.fromString(json['role'] as String?),
      isVerified: json['is_verified'] as bool? ?? true,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
