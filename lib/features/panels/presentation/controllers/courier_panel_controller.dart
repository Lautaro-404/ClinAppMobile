import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clinapp/features/panels/data/mock_panels_repository.dart';
import 'package:clinapp/features/panels/domain/panel_models.dart';
import 'package:clinapp/features/panels/domain/panels_repository.dart';

/// Estado de la pantalla de panel de repartidor.
@immutable
class CourierPanelViewState {
  const CourierPanelViewState({
    required this.shift,
    this.activeFilterIndex = 0,
  });

  final CourierShiftState shift;
  final int activeFilterIndex;

  CourierPanelViewState copyWith({
    CourierShiftState? shift,
    int? activeFilterIndex,
  }) {
    return CourierPanelViewState(
      shift: shift ?? this.shift,
      activeFilterIndex: activeFilterIndex ?? this.activeFilterIndex,
    );
  }
}

/// Controlador para las operaciones de repartidor con sincronización Realtime.
class CourierPanelController extends AsyncNotifier<CourierPanelViewState> {
  PanelsRepository get _repo => ref.read(panelsRepositoryProvider);
  StreamSubscription<CourierShiftState>? _shiftSubscription;

  @override
  Future<CourierPanelViewState> build() async {
    ref.onDispose(() {
      _shiftSubscription?.cancel();
    });

    final CourierShiftState shift = await _repo.loadCourierShift();

    await _shiftSubscription?.cancel();
    _shiftSubscription = _repo.watchCourierShift().listen((
      CourierShiftState updated,
    ) {
      final CourierPanelViewState? current = state.value;
      if (current != null) {
        state = AsyncData<CourierPanelViewState>(
          current.copyWith(shift: updated),
        );
      }
    });

    return CourierPanelViewState(shift: shift);
  }

  /// Cambia el índice del filtro activo (0: Asignados, 1: En preparación, 2: Disponibles, 3: Historial).
  void setFilterTab(int index) {
    final CourierPanelViewState? current = state.value;
    if (current == null) return;
    state = AsyncData<CourierPanelViewState>(
      current.copyWith(activeFilterIndex: index),
    );
  }

  /// Alterna el turno entre activo y pausado.
  Future<void> toggleShift(bool isOnline) async {
    final CourierPanelViewState? current = state.value;
    if (current == null) return;

    state = const AsyncLoading<CourierPanelViewState>();
    state = await AsyncValue.guard(() async {
      final CourierShiftState updated = await _repo.toggleCourierShift(
        isOnline: isOnline,
      );
      return current.copyWith(shift: updated);
    });
  }

  /// Cambia el estado de una entrega a 'en camino' (retirada del local).
  Future<void> markPickedUp(String deliveryId) async {
    final CourierPanelViewState? current = state.value;
    if (current == null) return;

    state = const AsyncLoading<CourierPanelViewState>();
    state = await AsyncValue.guard(() async {
      final CourierShiftState updated = await _repo.updateDeliveryStatus(
        deliveryId: deliveryId,
        newStatus: CourierDeliveryStatus.onTheWay,
      );
      return current.copyWith(shift: updated);
    });
  }

  /// Cambia el estado de una entrega a 'entregado'.
  Future<void> markDelivered(String deliveryId) async {
    final CourierPanelViewState? current = state.value;
    if (current == null) return;

    state = const AsyncLoading<CourierPanelViewState>();
    state = await AsyncValue.guard(() async {
      final CourierShiftState updated = await _repo.updateDeliveryStatus(
        deliveryId: deliveryId,
        newStatus: CourierDeliveryStatus.delivered,
      );
      return current.copyWith(shift: updated);
    });
  }
}

/// Provider para el panel del repartidor.
final AsyncNotifierProvider<CourierPanelController, CourierPanelViewState>
courierPanelControllerProvider =
    AsyncNotifierProvider<CourierPanelController, CourierPanelViewState>(
      CourierPanelController.new,
    );
