import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clinapp/features/panels/data/mock_panels_repository.dart';
import 'package:clinapp/features/panels/domain/panel_models.dart';
import 'package:clinapp/features/panels/domain/panels_repository.dart';

/// Estado de la pantalla de panel del local.
@immutable
class MerchantPanelViewState {
  const MerchantPanelViewState({
    required this.dashboard,
    this.activeFilterIndex = 0,
  });

  final MerchantDashboardState dashboard;
  final int activeFilterIndex;

  MerchantPanelViewState copyWith({
    MerchantDashboardState? dashboard,
    int? activeFilterIndex,
  }) {
    return MerchantPanelViewState(
      dashboard: dashboard ?? this.dashboard,
      activeFilterIndex: activeFilterIndex ?? this.activeFilterIndex,
    );
  }
}

/// Controlador de operaciones del comercio con sincronización Realtime.
class MerchantPanelController extends AsyncNotifier<MerchantPanelViewState> {
  PanelsRepository get _repo => ref.read(panelsRepositoryProvider);
  StreamSubscription<MerchantDashboardState>? _dashSubscription;

  @override
  Future<MerchantPanelViewState> build() async {
    ref.onDispose(() {
      _dashSubscription?.cancel();
    });

    final MerchantDashboardState dash = await _repo.loadMerchantDashboard();

    await _dashSubscription?.cancel();
    _dashSubscription = _repo.watchMerchantDashboard().listen((
      MerchantDashboardState updated,
    ) {
      final MerchantPanelViewState? current = state.value;
      if (current != null) {
        state = AsyncData<MerchantPanelViewState>(
          current.copyWith(dashboard: updated),
        );
      }
    });

    return MerchantPanelViewState(dashboard: dash);
  }

  /// Cambia el filtro de vista (0: Nuevos, 1: En cocina, 2: Listos, 3: Menú y Stock).
  void setFilterTab(int index) {
    final MerchantPanelViewState? current = state.value;
    if (current == null) return;
    state = AsyncData<MerchantPanelViewState>(
      current.copyWith(activeFilterIndex: index),
    );
  }

  /// Alterna el comercio entre abierto y pausado.
  Future<void> toggleOpen(bool isOpen) async {
    final MerchantPanelViewState? current = state.value;
    if (current == null) return;

    state = const AsyncLoading<MerchantPanelViewState>();
    state = await AsyncValue.guard(() async {
      final MerchantDashboardState updated = await _repo.toggleMerchantStatus(
        isOpen: isOpen,
      );
      return current.copyWith(dashboard: updated);
    });
  }

  /// Acepta un pedido nuevo y lo envía a la cocina.
  Future<void> acceptOrder(String orderId) async {
    final MerchantPanelViewState? current = state.value;
    if (current == null) return;

    state = const AsyncLoading<MerchantPanelViewState>();
    state = await AsyncValue.guard(() async {
      final MerchantDashboardState updated = await _repo
          .updateMerchantOrderStatus(
            orderId: orderId,
            newStatus: MerchantOrderStatus.inKitchen,
          );
      return current.copyWith(dashboard: updated);
    });
  }

  /// Marca un pedido como listo para retirar por el repartidor.
  Future<void> markReady(String orderId) async {
    final MerchantPanelViewState? current = state.value;
    if (current == null) return;

    state = const AsyncLoading<MerchantPanelViewState>();
    state = await AsyncValue.guard(() async {
      final MerchantDashboardState updated = await _repo
          .updateMerchantOrderStatus(
            orderId: orderId,
            newStatus: MerchantOrderStatus.readyForPickup,
          );
      return current.copyWith(dashboard: updated);
    });
  }

  /// Registra la entrega del pedido al repartidor (completado por cocina).
  Future<void> dispatchOrder(String orderId) async {
    final MerchantPanelViewState? current = state.value;
    if (current == null) return;

    state = const AsyncLoading<MerchantPanelViewState>();
    state = await AsyncValue.guard(() async {
      final MerchantDashboardState updated = await _repo
          .updateMerchantOrderStatus(
            orderId: orderId,
            newStatus: MerchantOrderStatus.completed,
          );
      return current.copyWith(dashboard: updated);
    });
  }

  /// Alterna la disponibilidad de un plato en la carta.
  Future<void> toggleStock(String itemId, bool isAvailable) async {
    final MerchantPanelViewState? current = state.value;
    if (current == null) return;

    state = const AsyncLoading<MerchantPanelViewState>();
    state = await AsyncValue.guard(() async {
      final MerchantDashboardState updated = await _repo
          .toggleMenuItemAvailability(itemId: itemId, isAvailable: isAvailable);
      return current.copyWith(dashboard: updated);
    });
  }
}

/// Provider para el panel del local.
final AsyncNotifierProvider<MerchantPanelController, MerchantPanelViewState>
merchantPanelControllerProvider =
    AsyncNotifierProvider<MerchantPanelController, MerchantPanelViewState>(
      MerchantPanelController.new,
    );
