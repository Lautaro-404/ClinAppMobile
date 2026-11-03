import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clinapp/features/orders/presentation/active_orders_count_provider.dart';
import 'package:clinapp/shared/widgets/glass_background.dart';
import 'package:clinapp/shared/widgets/glass_nav_bar.dart';
import 'package:clinapp/shared/widgets/offline_banner.dart';

/// Contenedor raíz de las 4 pestañas principales con fondo Liquid Glass
/// único, banner de estado sin conexión y barra inferior flotante persistente.
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int activeOrdersCount = ref.watch(activeOrdersCountProvider);
    final bool isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Column(
              children: <Widget>[
                const OfflineBanner(),
                Expanded(child: navigationShell),
              ],
            ),
            if (!isKeyboardOpen)
              Align(
                alignment: Alignment.bottomCenter,
                child: RepaintBoundary(
                  child: GlassNavBar(
                    currentIndex: navigationShell.currentIndex,
                    activeOrdersCount: activeOrdersCount,
                    onTap: _onDestinationSelected,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
