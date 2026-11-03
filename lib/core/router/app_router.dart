import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clinapp/core/router/app_routes.dart';
import 'package:clinapp/features/auth/presentation/login_screen.dart';
import 'package:clinapp/features/auth/presentation/register_screen.dart';
import 'package:clinapp/features/checkout/presentation/checkout_screen.dart';
import 'package:clinapp/features/checkout/presentation/payment_result_screen.dart';
import 'package:clinapp/features/dev/presentation/component_catalog_screen.dart';
import 'package:clinapp/features/home/presentation/home_screen.dart';
import 'package:clinapp/features/orders/presentation/orders_screen.dart';
import 'package:clinapp/features/panels/presentation/admin/admin_panel_screen.dart';
import 'package:clinapp/features/panels/presentation/courier/courier_panel_screen.dart';
import 'package:clinapp/features/panels/presentation/merchant/merchant_panel_screen.dart';
import 'package:clinapp/features/search/presentation/search_screen.dart';
import 'package:clinapp/features/settings/presentation/profile_screen.dart';
import 'package:clinapp/shared/widgets/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Construye una instancia de [GoRouter] con las 4 ramas del shell y rutas modales.
GoRouter createAppRouter({String initialLocation = AppRoutes.home}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return AppShell(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.home,
                builder: (BuildContext context, GoRouterState state) =>
                    const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.search,
                builder: (BuildContext context, GoRouterState state) =>
                    const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.orders,
                builder: (BuildContext context, GoRouterState state) {
                  final String? orderId = state.uri.queryParameters['id'];
                  return OrdersScreen(initialOrderId: orderId);
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: ':id',
                    builder: (BuildContext context, GoRouterState state) {
                      final String? orderId = state.pathParameters['id'];
                      return OrdersScreen(initialOrderId: orderId);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.profile,
                builder: (BuildContext context, GoRouterState state) =>
                    const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.checkout,
        builder: (BuildContext context, GoRouterState state) =>
            const CheckoutScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.paymentResult,
        builder: (BuildContext context, GoRouterState state) {
          final String? orderId =
              state.uri.queryParameters['pedido'] ??
              state.uri.queryParameters['external_reference'];
          final String? statusHint =
              state.uri.queryParameters['estado'] ??
              state.uri.queryParameters['collection_status'] ??
              state.uri.queryParameters['status'];
          return PaymentResultScreen(orderId: orderId, statusHint: statusHint);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.login,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.register,
        builder: (BuildContext context, GoRouterState state) =>
            const RegisterScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.devCatalog,
        builder: (BuildContext context, GoRouterState state) =>
            const ComponentCatalogScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.courierPanel,
        builder: (BuildContext context, GoRouterState state) =>
            const CourierPanelScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.merchantPanel,
        builder: (BuildContext context, GoRouterState state) =>
            const MerchantPanelScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.adminPanel,
        builder: (BuildContext context, GoRouterState state) =>
            const AdminPanelScreen(),
      ),
    ],
  );
}

/// Provider del router principal de la aplicación.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final GoRouter router = createAppRouter();
  ref.onDispose(router.dispose);
  return router;
});
