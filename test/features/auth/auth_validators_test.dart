import 'package:flutter_test/flutter_test.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/features/auth/domain/auth_models.dart';
import 'package:clinapp/features/auth/domain/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test(
      'validateLoginIdentifier acepta emails válidos y celulares argentinos',
      () {
        expect(
          AuthValidators.validateLoginIdentifier(null),
          AppStrings.validationRequiredIdentifier,
        );
        expect(
          AuthValidators.validateLoginIdentifier(''),
          AppStrings.validationRequiredIdentifier,
        );
        expect(
          AuthValidators.validateLoginIdentifier('correo-invalido@'),
          AppStrings.validationInvalidEmail,
        );
        expect(
          AuthValidators.validateLoginIdentifier('usuario@alvear.com.ar'),
          isNull,
        );

        // Teléfonos
        expect(
          AuthValidators.validateLoginIdentifier('123'),
          AppStrings.validationInvalidIdentifier,
        );
        expect(AuthValidators.validateLoginIdentifier('2625 401234'), isNull);
        expect(AuthValidators.validateLoginIdentifier('2625-458812'), isNull);
        expect(
          AuthValidators.validateLoginIdentifier('+54 9 2625 401234'),
          isNull,
        );
      },
    );

    test('validateFullName exige al menos 3 caracteres', () {
      expect(
        AuthValidators.validateFullName(''),
        AppStrings.validationRequiredName,
      );
      expect(
        AuthValidators.validateFullName('Lu'),
        AppStrings.validationShortName,
      );
      expect(AuthValidators.validateFullName('Lucas Benítez'), isNull);
    });

    test('validateAlvearPhone valida número local de 6 a 8 dígitos', () {
      expect(
        AuthValidators.validateAlvearPhone(''),
        AppStrings.validationRequiredPhone,
      );
      expect(
        AuthValidators.validateAlvearPhone('1234'),
        AppStrings.validationInvalidPhone,
      );
      expect(AuthValidators.validateAlvearPhone('40-1234'), isNull);
      expect(AuthValidators.validateAlvearPhone('458812'), isNull);
    });

    test('validateEmail valida formato estándar', () {
      expect(
        AuthValidators.validateEmail(''),
        AppStrings.validationRequiredEmail,
      );
      expect(
        AuthValidators.validateEmail('invalido'),
        AppStrings.validationInvalidEmail,
      );
      expect(AuthValidators.validateEmail('test@clinapp.com'), isNull);
    });

    test('validatePassword respeta longitud mínima', () {
      expect(
        AuthValidators.validatePassword(''),
        AppStrings.validationRequiredPassword,
      );
      expect(
        AuthValidators.validatePassword('12345'),
        AppStrings.validationShortPassword,
      );
      expect(AuthValidators.validatePassword('ClinAlvear2026!'), isNull);
    });

    test('evaluatePasswordStrength clasifica fortalezas correctamente', () {
      expect(
        AuthValidators.evaluatePasswordStrength(''),
        PasswordStrength.empty,
      );
      expect(
        AuthValidators.evaluatePasswordStrength('abc'),
        PasswordStrength.weak,
      );
      expect(
        AuthValidators.evaluatePasswordStrength('abcdefgh'),
        PasswordStrength.weak,
      );
      expect(
        AuthValidators.evaluatePasswordStrength('Abcdefgh'),
        PasswordStrength.fair,
      );
      expect(
        AuthValidators.evaluatePasswordStrength('Abcdefgh1'),
        PasswordStrength.good,
      );
      expect(
        AuthValidators.evaluatePasswordStrength('ClinAlvear2026!'),
        PasswordStrength.strong,
      );
    });
  });
}
