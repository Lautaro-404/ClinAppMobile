import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clinapp/features/panels/data/mock_panels_repository.dart';
import 'package:clinapp/features/panels/domain/panel_models.dart';
import 'package:clinapp/features/panels/domain/panels_repository.dart';

/// Estado de la pantalla de panel de administración.
@immutable
class AdminPanelViewState {
  const AdminPanelViewState({
    required this.dashboard,
    this.activeFilterIndex = 0,
  });

  final AdminDashboardState dashboard;
  final int activeFilterIndex;

  AdminPanelViewState copyWith({
    AdminDashboardState? dashboard,
    int? activeFilterIndex,
  }) {
    return AdminPanelViewState(
      dashboard: dashboard ?? this.dashboard,
      activeFilterIndex: activeFilterIndex ?? this.activeFilterIndex,
    );
  }
}

/// Controlador de operaciones administrativas de General Alvear con sincronización Realtime.
class AdminPanelController extends AsyncNotifier<AdminPanelViewState> {
  PanelsRepository get _repo => ref.read(panelsRepositoryProvider);
  StreamSubscription<AdminDashboardState>? _adminSubscription;

  @override
  Future<AdminPanelViewState> build() async {
    ref.onDispose(() {
      _adminSubscription?.cancel();
    });

    final AdminDashboardState dash = await _repo.loadAdminDashboard();

    await _adminSubscription?.cancel();
    _adminSubscription = _repo.watchAdminDashboard().listen((
      AdminDashboardState updated,
    ) {
      final AdminPanelViewState? current = state.value;
      if (current != null) {
        state = AsyncData<AdminPanelViewState>(
          current.copyWith(dashboard: updated),
        );
      }
    });

    return AdminPanelViewState(dashboard: dash);
  }

  /// Cambia la pestaña de administración (0: Resumen, 1: Comercios, 2: Repartidores, 3: Tarifas).
  void setFilterTab(int index) {
    final AdminPanelViewState? current = state.value;
    if (current == null) return;
    state = AsyncData<AdminPanelViewState>(
      current.copyWith(activeFilterIndex: index),
    );
  }

  /// Habilita o suspende un comercio desde la administración central.
  Future<void> toggleMerchant(String merchantId, bool isOpen) async {
    final AdminPanelViewState? current = state.value;
    if (current == null) return;

    state = const AsyncLoading<AdminPanelViewState>();
    state = await AsyncValue.guard(() async {
      final AdminDashboardState updated = await _repo.toggleMerchantAdminActive(
        merchantId: merchantId,
        isOpen: isOpen,
      );
      return current.copyWith(dashboard: updated);
    });
  }

  /// Actualiza la tarifa base de envío en General Alvear.
  Future<void> updateDeliveryFee(int newFeeCents) async {
    final AdminPanelViewState? current = state.value;
    if (current == null) return;

    state = const AsyncLoading<AdminPanelViewState>();
    state = await AsyncValue.guard(() async {
      final AdminDashboardState updated = await _repo.updateBaseDeliveryFee(
        newFeeCents: newFeeCents,
      );
      return current.copyWith(dashboard: updated);
    });
  }
}

/// Provider para el panel de administración.
final AsyncNotifierProvider<AdminPanelController, AdminPanelViewState>
adminPanelControllerProvider =
    AsyncNotifierProvider<AdminPanelController, AdminPanelViewState>(
      AdminPanelController.new,
    );
