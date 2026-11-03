import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/features/auth/domain/auth_models.dart';

/// Funciones puras de validación para formularios de autenticación.
abstract final class AuthValidators {
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  /// Valida el identificador de inicio de sesión (correo electrónico o número de celular).
  static String? validateLoginIdentifier(String? value) {
    final String clean = value?.trim() ?? '';
    if (clean.isEmpty) {
      return AppStrings.validationRequiredIdentifier;
    }

    if (clean.contains('@')) {
      return _emailRegExp.hasMatch(clean)
          ? null
          : AppStrings.validationInvalidEmail;
    }

    // Si es teléfono, debe tener al menos 6 dígitos.
    final String digits = clean.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6 || digits.length > 13) {
      return AppStrings.validationInvalidIdentifier;
    }
    return null;
  }

  /// Valida el nombre y apellido en el registro.
  static String? validateFullName(String? value) {
    final String clean = value?.trim() ?? '';
    if (clean.isEmpty) {
      return AppStrings.validationRequiredName;
    }
    if (clean.length < 3) {
      return AppStrings.validationShortName;
    }
    return null;
  }

  /// Valida el número telefónico local en General Alvear (después del prefijo +54 9 2625).
  static String? validateAlvearPhone(String? value) {
    final String clean = value?.trim() ?? '';
    if (clean.isEmpty) {
      return AppStrings.validationRequiredPhone;
    }
    final String digits = clean.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6 || digits.length > 8) {
      return AppStrings.validationInvalidPhone;
    }
    return null;
  }

  /// Valida el formato de correo electrónico.
  static String? validateEmail(String? value) {
    final String clean = value?.trim() ?? '';
    if (clean.isEmpty) {
      return AppStrings.validationRequiredEmail;
    }
    if (!_emailRegExp.hasMatch(clean)) {
      return AppStrings.validationInvalidEmail;
    }
    return null;
  }

  /// Valida la contraseña según longitud mínima.
  static String? validatePassword(String? value, {int minLength = 8}) {
    final String clean = value ?? '';
    if (clean.isEmpty) {
      return AppStrings.validationRequiredPassword;
    }
    if (clean.length < minLength) {
      return AppStrings.validationShortPassword;
    }
    return null;
  }

  /// Evalúa la fortaleza de la contraseña para el indicador gráfico.
  static PasswordStrength evaluatePasswordStrength(String value) {
    if (value.isEmpty) {
      return PasswordStrength.empty;
    }
    int score = 0;
    if (value.length >= 8) score++;
    if (value.contains(RegExp(r'[A-Z]')) && value.contains(RegExp(r'[a-z]'))) {
      score++;
    }
    if (value.contains(RegExp(r'[0-9]'))) score++;
    if (value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'))) score++;

    switch (score) {
      case 4:
        return PasswordStrength.strong;
      case 3:
        return PasswordStrength.good;
      case 2:
        return PasswordStrength.fair;
      case 1:
      default:
        return PasswordStrength.weak;
    }
  }
}
