import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clinapp/features/orders/data/supabase_orders_repository.dart';
import 'package:clinapp/features/orders/domain/orders_models.dart';
import 'package:clinapp/features/orders/domain/orders_repository.dart';
import 'package:clinapp/features/orders/presentation/active_orders_count_provider.dart';

/// Pestañas del selector segmentado de Pedidos.
enum OrdersTab { active, history }

/// Estado visual reactivo de la pantalla Pedidos.
@immutable
class OrdersViewState {
  const OrdersViewState({
    required this.activeOrders,
    required this.historyOrders,
    this.selectedTab = OrdersTab.active,
    this.hasMoreHistory = false,
    this.currentPage = 0,
    this.isLoadingMoreHistory = false,
    this.isRevalidating = false,
  });

  final OrdersTab selectedTab;
  final List<OrderSummary> activeOrders;
  final List<OrderSummary> historyOrders;
  final bool hasMoreHistory;
  final int currentPage;
  final bool isLoadingMoreHistory;
  final bool isRevalidating;

  OrderSummary? get primaryActiveOrder =>
      activeOrders.isNotEmpty ? activeOrders.first : null;

  OrdersViewState copyWith({
    OrdersTab? selectedTab,
    List<OrderSummary>? activeOrders,
    List<OrderSummary>? historyOrders,
    bool? hasMoreHistory,
    int? currentPage,
    bool? isLoadingMoreHistory,
    bool? isRevalidating,
  }) {
    return OrdersViewState(
      selectedTab: selectedTab ?? this.selectedTab,
      activeOrders: activeOrders ?? this.activeOrders,
      historyOrders: historyOrders ?? this.historyOrders,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMoreHistory: isLoadingMoreHistory ?? this.isLoadingMoreHistory,
      isRevalidating: isRevalidating ?? this.isRevalidating,
    );
  }
}

/// Controlador de la pantalla Pedidos con suscripción Realtime y paginación.
class OrdersController extends AsyncNotifier<OrdersViewState> {
  StreamSubscription<OrdersRealtimeEvent>? _realtimeSubscription;

  @override
  Future<OrdersViewState> build() async {
    ref.onDispose(() {
      _realtimeSubscription?.cancel();
    });

    final OrdersRepository repository = ref.watch(ordersRepositoryProvider);
    final OrdersPageData data = await repository.fetchOrders(page: 0);

    ref
        .read(activeOrdersCountProvider.notifier)
        .setCount(data.activeOrders.length);

    await _realtimeSubscription?.cancel();
    _realtimeSubscription = repository.watchActiveOrders().listen(
      _handleRealtimeEvent,
    );

    return OrdersViewState(
      activeOrders: data.activeOrders,
      historyOrders: data.historyOrders,
      hasMoreHistory: data.hasMoreHistory,
      currentPage: data.currentPage,
    );
  }

  void selectTab(OrdersTab tab) {
    final OrdersViewState? current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData<OrdersViewState>(current.copyWith(selectedTab: tab));
  }

  Future<void> loadMoreHistory() async {
    final OrdersViewState? current = state.value;
    if (current == null ||
        !current.hasMoreHistory ||
        current.isLoadingMoreHistory) {
      return;
    }

    state = AsyncData<OrdersViewState>(
      current.copyWith(isLoadingMoreHistory: true),
    );

    try {
      final OrdersRepository repository = ref.read(ordersRepositoryProvider);
      final int nextPage = current.currentPage + 1;
      final OrdersPageData data = await repository.fetchOrders(page: nextPage);

      final List<OrderSummary> combined = <OrderSummary>[
        ...current.historyOrders,
        ...data.historyOrders,
      ];

      state = AsyncData<OrdersViewState>(
        current.copyWith(
          historyOrders: combined,
          hasMoreHistory: data.hasMoreHistory,
          currentPage: nextPage,
          isLoadingMoreHistory: false,
        ),
      );
    } catch (_) {
      state = AsyncData<OrdersViewState>(
        current.copyWith(isLoadingMoreHistory: false),
      );
    }
  }

  void _handleRealtimeEvent(OrdersRealtimeEvent event) {
    final OrdersViewState? current = state.value;
    if (current == null) {
      return;
    }

    final List<OrderSummary> updatedActive = List<OrderSummary>.of(
      current.activeOrders,
    );
    final List<OrderSummary> updatedHistory = List<OrderSummary>.of(
      current.historyOrders,
    );

    bool modified = false;

    // Actualización de estado de pedido.
    if (event.updatedStatus != null && event.orderId.isNotEmpty) {
      final int activeIndex = updatedActive.indexWhere(
        (OrderSummary o) => o.id == event.orderId,
      );
      if (activeIndex >= 0) {
        final OrderSummary target = updatedActive[activeIndex];
        if (event.updatedStatus!.isTerminal) {
          updatedActive.removeAt(activeIndex);
          updatedHistory.insert(
            0,
            target.copyWith(status: event.updatedStatus),
          );
        } else {
          updatedActive[activeIndex] = target.copyWith(
            status: event.updatedStatus,
          );
        }
        modified = true;
      }
    }

    // Actualización de posición del repartidor en el pedido activo principal.
    if ((event.courierLat != null || event.remainingMinutes != null) &&
        updatedActive.isNotEmpty) {
      final OrderSummary first = updatedActive.first;
      final CourierInfo? currentCourier = first.courier;
      CourierInfo? updatedCourier = currentCourier;

      if (currentCourier != null &&
          event.courierLat != null &&
          event.courierLng != null) {
        updatedCourier = currentCourier.copyWith(
          lat: event.courierLat,
          lng: event.courierLng,
        );
      }

      updatedActive[0] = first.copyWith(
        courier: updatedCourier,
        remainingMinutes: event.remainingMinutes ?? first.remainingMinutes,
      );
      modified = true;
    }

    if (modified) {
      ref
          .read(activeOrdersCountProvider.notifier)
          .setCount(updatedActive.length);
      state = AsyncData<OrdersViewState>(
        current.copyWith(
          activeOrders: updatedActive,
          historyOrders: updatedHistory,
        ),
      );
    }
  }

  Future<ReorderValidationResult> revalidateReorder(OrderSummary order) async {
    final OrdersViewState? current = state.value;
    if (current != null) {
      state = AsyncData<OrdersViewState>(
        current.copyWith(isRevalidating: true),
      );
    }

    try {
      final OrdersRepository repository = ref.read(ordersRepositoryProvider);
      final ReorderValidationResult result = await repository
          .revalidateOrderForRepeat(order);

      if (current != null) {
        state = AsyncData<OrdersViewState>(
          current.copyWith(isRevalidating: false),
        );
      }
      return result;
    } catch (_) {
      if (current != null) {
        state = AsyncData<OrdersViewState>(
          current.copyWith(isRevalidating: false),
        );
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading<OrdersViewState>();
    state = await AsyncValue.guard(() async {
      final OrdersRepository repository = ref.read(ordersRepositoryProvider);
      final OrdersPageData data = await repository.fetchOrders(page: 0);

      ref
          .read(activeOrdersCountProvider.notifier)
          .setCount(data.activeOrders.length);

      return OrdersViewState(
        activeOrders: data.activeOrders,
        historyOrders: data.historyOrders,
        hasMoreHistory: data.hasMoreHistory,
        currentPage: data.currentPage,
      );
    });
  }
}

/// Provider del controlador de la pantalla Pedidos.
final AsyncNotifierProvider<OrdersController, OrdersViewState>
ordersControllerProvider =
    AsyncNotifierProvider<OrdersController, OrdersViewState>(
      OrdersController.new,
      retry: (int retryCount, Object error) => null,
    );
