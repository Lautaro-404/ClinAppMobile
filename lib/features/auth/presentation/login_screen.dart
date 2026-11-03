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
import 'package:clinapp/features/auth/presentation/widgets/social_auth_buttons.dart';
import 'package:clinapp/shared/widgets/glass_background.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_card.dart';
import 'package:clinapp/shared/widgets/glass_sheet.dart';
import 'package:clinapp/shared/widgets/glass_text_field.dart';

/// Pantalla Iniciar Sesión de ClinApp en General Alvear.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController(
    text: '2625 401234',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'ClinAlvear2026!',
  );
  final TextEditingController _resetEmailController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(
            identifier: _idController.text,
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

      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.profile);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    await ref.read(authControllerProvider.notifier).signInWithSocial(provider);
    if (!mounted) return;
    context.go(AppRoutes.profile);
  }

  void _openForgotPasswordSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final AppPalette sheetPalette = sheetContext.palette;
        return GlassSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                AppStrings.loginResetPasswordTitle,
                style: AppTypography.headlineMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: sheetPalette.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppStrings.loginResetPasswordSubtitle,
                style: AppTypography.bodySm.copyWith(
                  color: sheetPalette.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GlassTextField(
                controller: _resetEmailController,
                labelText: AppStrings.registerEmailLabel,
                hintText: AppStrings.registerEmailHint,
                leadingIcon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassButton.primary(
                label: AppStrings.loginResetAction,
                expand: true,
                onPressed: () async {
                  final String email = _resetEmailController.text.trim();
                  if (email.isNotEmpty) {
                    await ref
                        .read(authControllerProvider.notifier)
                        .sendPasswordReset(email);
                  }
                  if (!sheetContext.mounted) return;
                  Navigator.of(sheetContext).pop();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.loginResetPasswordSent),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
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
                        context.go(AppRoutes.home);
                      }
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      AppStrings.loginHeaderTitle,
                      style: AppTypography.headlineMd.copyWith(
                        color: palette.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Hero oficial de la mascota Clin
              const AuthHeroHeader(
                title: AppStrings.loginWelcomeTitle,
                subtitle: AppStrings.loginWelcomeSubtitle,
                badgeText: AppStrings.loginHeroBadge,
              ),
              const SizedBox(height: AppSpacing.md),
              // Tarjeta Liquid Glass con formulario
              GlassCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      GlassTextField(
                        controller: _idController,
                        labelText: AppStrings.loginIdentifierLabel,
                        hintText: AppStrings.loginIdentifierHint,
                        leadingIcon: LucideIcons.atSign,
                        keyboardType: TextInputType.emailAddress,
                        validator: AuthValidators.validateLoginIdentifier,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.xs,
                        children: <Widget>[
                          Text(
                            AppStrings.loginPasswordLabel,
                            style: AppTypography.labelMd.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: AppStrings.loginForgotPassword,
                            child: InkWell(
                              onTap: _openForgotPasswordSheet,
                              borderRadius: AppRadii.smAll,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: AppSpacing.minTapTarget,
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  widthFactor: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                    ),
                                    child: Text(
                                      AppStrings.loginForgotPassword,
                                      style: AppTypography.labelSm.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      GlassTextField(
                        controller: _passwordController,
                        hintText: AppStrings.loginPasswordHint,
                        leadingIcon: LucideIcons.lock,
                        obscureText: true,
                        validator: (String? val) =>
                            AuthValidators.validatePassword(val, minLength: 6),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GlassButton.primary(
                        label: AppStrings.loginSubmitCta,
                        trailingIcon: LucideIcons.arrowRight,
                        expand: true,
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _handleLogin,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SocialAuthButtons(
                        dividerText: AppStrings.loginOrContinueWith,
                        isLoading: _isSubmitting,
                        onGooglePressed: () => _handleSocialLogin('google'),
                        onApplePressed: () => _handleSocialLogin('apple'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Enlace para crear cuenta con área táctil >= 48dp
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  Text(
                    AppStrings.loginNoAccountPrompt,
                    style: AppTypography.bodyMd.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: AppStrings.loginCreateAccountLink,
                    child: InkWell(
                      onTap: () => context.push(AppRoutes.register),
                      borderRadius: AppRadii.smAll,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: AppSpacing.minTapTarget,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                AppStrings.loginCreateAccountLink,
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(
                                LucideIcons.chevronRight,
                                size: 16,
                                color: AppColors.accent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // Sello de General Alvear
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
                  child: Text(
                    AppStrings.loginLocalSeal,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSm.copyWith(
                      color: palette.textSecondary,
                    ),
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
