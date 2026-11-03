import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/router/app_routes.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_radii.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/features/auth/domain/auth_models.dart';
import 'package:clinapp/features/auth/domain/auth_validators.dart';
import 'package:clinapp/features/auth/presentation/auth_controller.dart';
import 'package:clinapp/features/auth/presentation/widgets/auth_hero_header.dart';
import 'package:clinapp/features/auth/presentation/widgets/password_strength_meter.dart';
import 'package:clinapp/features/auth/presentation/widgets/social_auth_buttons.dart';
import 'package:clinapp/shared/widgets/glass_background.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';
import 'package:clinapp/shared/widgets/glass_text_field.dart';

/// Pantalla Registro de nuevos clientes en General Alvear.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController(
    text: 'Lucas Benítez',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '40-1234',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'lucas.benitez@gmail.com',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'ClinAlvear2026!',
  );

  PasswordStrength _strength = PasswordStrength.strong;
  bool _termsAccepted = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    final PasswordStrength newStrength =
        AuthValidators.evaluatePasswordStrength(_passwordController.text);
    if (newStrength != _strength) {
      setState(() => _strength = newStrength);
    }
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSocialRegister(String provider) async {
    await ref.read(authControllerProvider.notifier).signInWithSocial(provider);
    if (!mounted) return;
    context.go(AppRoutes.profile);
  }

  Future<void> _handleRegister() async {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.validationAcceptTerms),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signUp(
            fullName: _nameController.text.trim(),
            localPhone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;
      final AsyncValue<AuthUserSession?> authState = ref.read(
        authControllerProvider,
      );
      if (authState.hasError) {
        final String friendlyError = AppException.fromError(authState.error!)
            .message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      context.go(AppRoutes.profile);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final double horizontalMargin = AppSpacing.marginFor(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalMargin,
              vertical: AppSpacing.sm,
            ),
            children: <Widget>[
              // Barra superior con botón volver
              Row(
                children: <Widget>[
                  GlassButton.icon(
                    icon: LucideIcons.chevronLeft,
                    semanticLabel: AppStrings.actionBack,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.login);
                      }
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      AppStrings.registerHeaderTitle,
                      style: AppTypography.headlineMd.copyWith(
                        color: palette.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Hero con mascota y beneficio
              AuthHeroHeader(
                title: AppStrings.registerTitle,
                subtitle: '',
                badgeText: AppStrings.registerHeroBadge,
                highlightSubtitle: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTypography.bodyMd.copyWith(
                      color: palette.textSecondary,
                    ),
                    children: const <TextSpan>[
                      TextSpan(text: AppStrings.registerPromoPrefix),
                      TextSpan(
                        text: AppStrings.registerPromoGift,
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: AppStrings.registerPromoMiddle),
                      TextSpan(
                        text: AppStrings.registerPromoCoupon,
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Formulario en tarjeta Liquid Glass
              GlassCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Nombre y Apellido
                      GlassTextField(
                        controller: _nameController,
                        labelText: AppStrings.registerFullNameLabel,
                        hintText: AppStrings.registerFullNameHint,
                        leadingIcon: LucideIcons.user,
                        validator: AuthValidators.validateFullName,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Teléfono celular con prefijo Alvear
                      Text(
                        AppStrings.registerPhoneLabel,
                        style: AppTypography.labelMd.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Flexible(
                            flex: 0,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: AppSpacing.minTapTarget,
                                maxWidth: 124,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.glassFill1,
                                  borderRadius: AppRadii.pillAll,
                                  border: Border.all(color: palette.rimMedium),
                                ),
                                alignment: Alignment.center,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      const Text(
                                        '🇦🇷',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppStrings.registerPhonePrefix,
                                        style: AppTypography.labelMd.copyWith(
                                          color: palette.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: GlassTextField(
                              controller: _phoneController,
                              hintText: AppStrings.registerPhoneHint,
                              keyboardType: TextInputType.phone,
                              validator: AuthValidators.validateAlvearPhone,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.xs,
                          left: AppSpacing.xs,
                        ),
                        child: Text(
                          AppStrings.registerPhoneHelper,
                          style: AppTypography.labelSm.copyWith(
                            color: palette.textTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Correo Electrónico
                      GlassTextField(
                        controller: _emailController,
                        labelText: AppStrings.registerEmailLabel,
                        hintText: AppStrings.registerEmailHint,
                        leadingIcon: LucideIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        validator: AuthValidators.validateEmail,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Contraseña y medidor
                      Text(
                        AppStrings.loginPasswordLabel,
                        style: AppTypography.labelMd.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      GlassTextField(
                        controller: _passwordController,
                        hintText: AppStrings.registerPasswordHint,
                        leadingIcon: LucideIcons.lock,
                        obscureText: true,
                        validator: AuthValidators.validatePassword,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      PasswordStrengthMeter(strength: _strength),
                      const SizedBox(height: AppSpacing.md),
                      // Términos y Condiciones
                      InkWell(
                        onTap: () {
                          setState(() => _termsAccepted = !_termsAccepted);
                        },
                        borderRadius: AppRadii.baseAll,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: AppSpacing.minTapTarget,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _termsAccepted,
                                    activeColor: AppColors.accent,
                                    checkColor: Colors.white,
                                    side: BorderSide(
                                      color: palette.rimMedium,
                                      width: 1.5,
                                    ),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: AppRadii.smAll,
                                    ),
                                    onChanged: (bool? val) {
                                      setState(
                                        () => _termsAccepted = val ?? false,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: AppTypography.bodySm.copyWith(
                                        color: palette.textSecondary,
                                      ),
                                      children: const <TextSpan>[
                                        TextSpan(
                                          text: AppStrings.registerTermsPrefix,
                                        ),
                                        TextSpan(
                                          text: AppStrings.registerTermsLink,
                                          style: TextStyle(
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.w600,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                        TextSpan(text: ' y la '),
                                        TextSpan(
                                          text: AppStrings.registerPrivacyLink,
                                          style: TextStyle(
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.w600,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                        TextSpan(
                                          text: AppStrings.registerTermsSuffix,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Botón crear cuenta
                      GlassButton.primary(
                        label: AppStrings.registerSubmitCta,
                        trailingIcon: LucideIcons.arrowRight,
                        expand: true,
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _handleRegister,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Botones sociales
              SocialAuthButtons(
                dividerText: AppStrings.registerOrSignUpWith,
                isLoading: _isSubmitting,
                onGooglePressed: () => _handleSocialRegister('google'),
                onApplePressed: () => _handleSocialRegister('apple'),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Enlace ya tenés cuenta con mínimo 48dp
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.xs,
                children: <Widget>[
                  Text(
                    AppStrings.registerHasAccountPrompt,
                    style: AppTypography.bodyMd.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: AppStrings.registerSignInLink,
                    child: InkWell(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.push(AppRoutes.login);
                        }
                      },
                      borderRadius: AppRadii.smAll,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: AppSpacing.minTapTarget,
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          widthFactor: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                            ),
                            child: Text(
                              AppStrings.registerSignInLink,
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Badge de soporte 24/7
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: palette.glassFill1,
                    borderRadius: AppRadii.pillAll,
                    border: Border.all(color: palette.rimMedium),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        LucideIcons.shieldCheck,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          AppStrings.registerSupportBadge,
                          style: AppTypography.labelSm.copyWith(
                            color: palette.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
