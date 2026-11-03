import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_theme.dart';
import 'package:clinapp/features/auth/domain/auth_models.dart';
import 'package:clinapp/features/auth/presentation/login_screen.dart';
import 'package:clinapp/features/auth/presentation/register_screen.dart';
import 'package:clinapp/features/auth/presentation/widgets/password_strength_meter.dart';
import 'package:clinapp/features/auth/presentation/widgets/social_auth_buttons.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(theme: AppTheme.dark, home: child),
    );
  }

  group('LoginScreen (Etapa 8)', () {
    testWidgets('renderiza hero oficial, campos y botones sociales', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.loginHeaderTitle), findsOneWidget);
      expect(find.text(AppStrings.loginWelcomeTitle), findsOneWidget);
      expect(find.text(AppStrings.loginIdentifierLabel), findsOneWidget);
      expect(find.text(AppStrings.loginPasswordLabel), findsOneWidget);
      expect(find.text(AppStrings.loginSubmitCta), findsOneWidget);
      expect(find.byType(SocialAuthButtons), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text(AppStrings.loginLocalSeal), findsOneWidget);
    });

    testWidgets('abre hoja de recuperación de contraseña', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.loginForgotPassword));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.loginResetPasswordTitle), findsOneWidget);
      expect(find.text(AppStrings.loginResetAction), findsOneWidget);
    });
  });

  group('RegisterScreen (Etapa 8)', () {
    testWidgets(
      'renderiza formulario completo con medidor de clave y términos',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestableWidget(const RegisterScreen()));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.registerHeaderTitle), findsOneWidget);
        expect(find.text(AppStrings.registerTitle), findsOneWidget);

        final RichText promoRichText = tester.widget<RichText>(
          find.byWidgetPredicate(
            (Widget w) =>
                w is RichText &&
                w.text.toPlainText().contains(AppStrings.registerPromoGift),
          ),
        );
        expect(
          promoRichText.text.toPlainText(),
          contains(AppStrings.registerPromoCoupon),
        );

        expect(find.text(AppStrings.registerFullNameLabel), findsOneWidget);
        expect(find.text(AppStrings.registerPhonePrefix), findsOneWidget);
        expect(find.text(AppStrings.registerEmailLabel), findsOneWidget);
        expect(find.byType(PasswordStrengthMeter), findsOneWidget);
        expect(find.byType(Checkbox), findsOneWidget);
        expect(find.text(AppStrings.registerSubmitCta), findsOneWidget);
      },
    );

    testWidgets('actualiza medidor de clave al escribir', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      // Buscamos el campo de contraseña
      final Finder pwdField = find.byWidgetPredicate(
        (Widget widget) => widget is EditableText && widget.obscureText == true,
      );
      expect(pwdField, findsOneWidget);

      await tester.enterText(pwdField, '123');
      await tester.pumpAndSettle();

      final PasswordStrengthMeter meter = tester.widget<PasswordStrengthMeter>(
        find.byType(PasswordStrengthMeter),
      );
      expect(meter.strength, equals(PasswordStrength.weak));
    });
  });
}
