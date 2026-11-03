import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/router/app_router.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_theme.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/theme/theme_mode_provider.dart';
import 'package:clinapp/features/notifications/domain/models/push_message.dart';
import 'package:clinapp/features/notifications/domain/services/push_service.dart';
import 'package:clinapp/features/notifications/presentation/push_service_provider.dart';

/// Raíz de la aplicación conectada a [appRouterProvider], [themeModeProvider]
/// y al servicio de notificaciones push en primer plano y segundo plano.
class ClinApp extends ConsumerStatefulWidget {
  const ClinApp({super.key});

  static const Locale locale = Locale('es', 'AR');

  @override
  ConsumerState<ClinApp> createState() => _ClinAppState();
}

class _ClinAppState extends ConsumerState<ClinApp> {
  StreamSubscription<PushMessage>? _foregroundSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPushNotifications();
    });
  }

  void _initPushNotifications() {
    final GoRouter router = ref.read(appRouterProvider);
    final PushService pushService = ref.read(pushServiceProvider);

    pushService.initialize(
      onNavigateToOrder: (String orderId) {
        router.go('/pedidos/$orderId');
      },
    );

    _foregroundSubscription = pushService.onForegroundMessage.listen((
      PushMessage message,
    ) {
      _showForegroundBanner(message);
    });
  }

  void _showForegroundBanner(PushMessage message) {
    final BuildContext? context = ref
        .read(appRouterProvider)
        .routerDelegate
        .navigatorKey
        .currentContext;
    if (context == null) return;

    final String title = message.title.isNotEmpty
        ? message.title
        : AppStrings.notificationDefaultTitle;
    final String body = message.body;
    final String? orderId = message.orderId;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceRest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.rimSoft),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: AppTypography.labelMd.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (body.isNotEmpty) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                body,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        action: orderId != null && orderId.isNotEmpty
            ? SnackBarAction(
                label: AppStrings.notificationViewOrder,
                textColor: AppColors.accent,
                onPressed: () {
                  ref.read(appRouterProvider).go('/pedidos/$orderId');
                },
              )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _foregroundSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = ref.watch(appRouterProvider);
    final ThemeMode themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: ClinApp.locale,
      supportedLocales: const <Locale>[ClinApp.locale],
      localizationsDelegates: const <LocalizationsDelegate<Object?>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
