import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/features/checkout/data/supabase_checkout_repository.dart';
import 'package:clinapp/features/checkout/domain/checkout_models.dart';
import 'package:clinapp/features/checkout/domain/checkout_repository.dart';
import 'package:clinapp/features/orders/presentation/active_orders_count_provider.dart';

/// Estado de vista de la pantalla de Checkout.
class CheckoutViewState {
  const CheckoutViewState({
    required this.merchantId,
    required this.merchantName,
    required this.merchantTagline,
    required this.items,
    required this.addresses,
    required this.selectedAddressId,
    required this.riderNotes,
    required this.paymentMethod,
    required this.couponInput,
    required this.quote,
    required this.activeClientRequestId,
    this.clinpayBalanceCents = 450000,
    this.changeForCents,
    this.pendingDiscrepancyQuote,
    this.couponError,
    this.isValidatingCoupon = false,
    this.isSubmitting = false,
    this.paymentStatus = PaymentProcessStatus.idle,
    this.lastSubmissionResult,
    this.submissionError,
  });

  final String merchantId;
  final String merchantName;
  final String merchantTagline;
  final List<CheckoutCartItem> items;
  final List<DeliveryAddressOption> addresses;
  final String selectedAddressId;
  final String riderNotes;
  final CheckoutPaymentMethod paymentMethod;
  final String couponInput;
  final String? couponError;
  final bool isValidatingCoupon;
  final CheckoutQuote quote;
  final String activeClientRequestId;
  final int clinpayBalanceCents;
  final int? changeForCents;
  final CheckoutQuote? pendingDiscrepancyQuote;
  final bool isSubmitting;
  final PaymentProcessStatus paymentStatus;
  final CheckoutSubmissionResult? lastSubmissionResult;
  final String? submissionError;

  bool get hasPendingDiscrepancy => pendingDiscrepancyQuote != null;

  int get totalItemsCount => items.fold<int>(
    0,
    (int sum, CheckoutCartItem item) => sum + item.quantity,
  );

  DeliveryAddressOption get selectedAddress {
    for (final DeliveryAddressOption addr in addresses) {
      if (addr.id == selectedAddressId) {
        return addr;
      }
    }
    return addresses.first;
  }

  CheckoutViewState copyWith({
    String? merchantId,
    String? merchantName,
    String? merchantTagline,
    List<CheckoutCartItem>? items,
    List<DeliveryAddressOption>? addresses,
    String? selectedAddressId,
    String? riderNotes,
    CheckoutPaymentMethod? paymentMethod,
    String? couponInput,
    String? couponError,
    bool clearCouponError = false,
    bool? isValidatingCoupon,
    CheckoutQuote? quote,
    String? activeClientRequestId,
    int? clinpayBalanceCents,
    int? changeForCents,
    bool clearChangeFor = false,
    CheckoutQuote? pendingDiscrepancyQuote,
    bool clearPendingDiscrepancy = false,
    bool? isSubmitting,
    PaymentProcessStatus? paymentStatus,
    CheckoutSubmissionResult? lastSubmissionResult,
    String? submissionError,
    bool clearSubmissionError = false,
  }) {
    return CheckoutViewState(
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      merchantTagline: merchantTagline ?? this.merchantTagline,
      items: items ?? this.items,
      addresses: addresses ?? this.addresses,
      selectedAddressId: selectedAddressId ?? this.selectedAddressId,
      riderNotes: riderNotes ?? this.riderNotes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      couponInput: couponInput ?? this.couponInput,
      couponError: clearCouponError ? null : (couponError ?? this.couponError),
      isValidatingCoupon: isValidatingCoupon ?? this.isValidatingCoupon,
      quote: quote ?? this.quote,
      activeClientRequestId:
          activeClientRequestId ?? this.activeClientRequestId,
      clinpayBalanceCents: clinpayBalanceCents ?? this.clinpayBalanceCents,
      changeForCents: clearChangeFor
          ? null
          : (changeForCents ?? this.changeForCents),
      pendingDiscrepancyQuote: clearPendingDiscrepancy
          ? null
          : (pendingDiscrepancyQuote ?? this.pendingDiscrepancyQuote),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      lastSubmissionResult: lastSubmissionResult ?? this.lastSubmissionResult,
      submissionError: clearSubmissionError
          ? null
          : (submissionError ?? this.submissionError),
    );
  }
}

/// Controlador de estado para el flujo de Checkout y Pagos.
class CheckoutController extends AsyncNotifier<CheckoutViewState> {
  StreamSubscription<PaymentProcessStatus>? _paymentSubscription;
  Timer? _paymentTimeoutTimer;
  int _requestSequence = 1;
  bool _isDisposed = false;

  @override
  Future<CheckoutViewState> build() async {
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
      unawaited(_paymentSubscription?.cancel());
      _paymentTimeoutTimer?.cancel();
    });

    final CheckoutRepository repository = ref.watch(checkoutRepositoryProvider);
    final CheckoutInitialData initial = await repository.loadCheckoutSession();

    return CheckoutViewState(
      merchantId: initial.merchantId,
      merchantName: initial.merchantName,
      merchantTagline: initial.merchantTagline,
      items: initial.items,
      addresses: initial.addresses,
      selectedAddressId: initial.selectedAddressId,
      riderNotes: initial.initialRiderNotes,
      paymentMethod: CheckoutPaymentMethod.cash,
      couponInput: initial.initialCouponCode ?? '',
      quote: initial.initialQuote,
      activeClientRequestId: _generateClientRequestId(),
      clinpayBalanceCents: initial.clinpayBalanceCents,
    );
  }

  String _generateClientRequestId() {
    final int sequence = _requestSequence++;
    return 'req-alv-$sequence';
  }

  /// Actualiza el monto con el que abona el cliente para preparar el vuelto en efectivo.
  void updateChangeFor(int? cents) {
    final CheckoutViewState? current = state.value;
    if (current == null || current.isSubmitting) {
      return;
    }
    state = AsyncData<CheckoutViewState>(
      current.copyWith(changeForCents: cents),
    );
  }

  /// Acepta el nuevo total calculado por el servidor y envía el pedido.
  Future<CheckoutSubmissionResult?> acceptPriceDiscrepancy() async {
    final CheckoutViewState? current = state.value;
    if (current == null || current.pendingDiscrepancyQuote == null) {
      return null;
    }

    final CheckoutQuote newQuote = current.pendingDiscrepancyQuote!;
    state = AsyncData<CheckoutViewState>(
      current.copyWith(quote: newQuote, clearPendingDiscrepancy: true),
    );

    return submitOrder(forceSubmit: true);
  }

  /// Descarta la reconfirmación para que el usuario pueda revisar su pedido con los precios del servidor.
  void dismissPriceDiscrepancy() {
    final CheckoutViewState? current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData<CheckoutViewState>(
      current.copyWith(
        quote: current.pendingDiscrepancyQuote ?? current.quote,
        clearPendingDiscrepancy: true,
        isSubmitting: false,
      ),
    );
  }

  /// Actualiza la cantidad de un ítem del carrito (+1 o -1).
  /// Muestra primero una estimación reactiva y luego confirma con el servidor.
  Future<void> updateItemQuantity(String productId, int delta) async {
    final CheckoutViewState? current = state.value;
    if (current == null || current.isSubmitting) {
      return;
    }

    final List<CheckoutCartItem> updatedItems = <CheckoutCartItem>[];
    for (final CheckoutCartItem item in current.items) {
      if (item.productId == productId) {
        final int nextQty = item.quantity + delta;
        if (nextQty > 0) {
          updatedItems.add(item.copyWith(quantity: nextQty));
        }
      } else {
        updatedItems.add(item);
      }
    }

    final int estimatedSubtotal = updatedItems.fold<int>(
      0,
      (int sum, CheckoutCartItem item) => sum + item.lineTotalCents,
    );
    final int estimatedDiscount = current.quote.appliedCoupon != null
        ? _estimateDiscount(estimatedSubtotal, current.quote.appliedCoupon!)
        : 0;
    final int estimatedTotal =
        (estimatedSubtotal +
                current.quote.deliveryFeeCents +
                current.quote.tipCents -
                estimatedDiscount)
            .clamp(0, 100000000);

    final CheckoutQuote estimatedQuote = current.quote.copyWith(
      subtotalCents: estimatedSubtotal,
      discountCents: estimatedDiscount,
      totalCents: estimatedTotal,
      isServerConfirmed: false,
    );

    state = AsyncData<CheckoutViewState>(
      current.copyWith(
        items: updatedItems,
        quote: estimatedQuote,
        activeClientRequestId: _generateClientRequestId(),
      ),
    );

    await _refreshServerQuote(
      items: updatedItems,
      couponCode: current.quote.appliedCoupon?.code,
    );
  }

  int _estimateDiscount(int subtotalCents, AppliedCoupon coupon) {
    if (subtotalCents <= 0) {
      return 0;
    }
    final int raw = (subtotalCents * coupon.percentage) ~/ 100;
    if (coupon.capCents != null && raw > coupon.capCents!) {
      return coupon.capCents!;
    }
    return raw;
  }

  /// Cambia la dirección de entrega seleccionada y recalcula la cotización del servidor.
  Future<void> selectAddress(String addressId) async {
    final CheckoutViewState? current = state.value;
    if (current == null || current.isSubmitting) {
      return;
    }

    state = AsyncData<CheckoutViewState>(
      current.copyWith(
        selectedAddressId: addressId,
        activeClientRequestId: _generateClientRequestId(),
      ),
    );

    await _refreshServerQuote(
      addressId: addressId,
      couponCode: current.quote.appliedCoupon?.code,
    );
  }

  /// Actualiza las notas para el repartidor.
  void updateRiderNotes(String notes) {
    final CheckoutViewState? current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData<CheckoutViewState>(current.copyWith(riderNotes: notes));
  }

  /// Selecciona el método de pago.
  void selectPaymentMethod(CheckoutPaymentMethod method) {
    final CheckoutViewState? current = state.value;
    if (current == null || current.isSubmitting) {
      return;
    }
    state = AsyncData<CheckoutViewState>(
      current.copyWith(
        paymentMethod: method,
        paymentStatus: PaymentProcessStatus.idle,
        clearSubmissionError: true,
      ),
    );
  }

  /// Aplica y valida un cupón de descuento contra el servidor.
  Future<void> applyCoupon(String rawCode) async {
    final CheckoutViewState? current = state.value;
    if (current == null || current.isSubmitting) {
      return;
    }

    final String code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      state = AsyncData<CheckoutViewState>(
        current.copyWith(couponError: AppStrings.checkoutCouponInvalid),
      );
      return;
    }

    state = AsyncData<CheckoutViewState>(
      current.copyWith(
        couponInput: code,
        isValidatingCoupon: true,
        clearCouponError: true,
      ),
    );

    try {
      final CheckoutRepository repository = ref.read(
        checkoutRepositoryProvider,
      );
      final CheckoutQuote serverQuote = await repository.calculateServerQuote(
        merchantId: current.merchantId,
        addressId: current.selectedAddressId,
        items: current.items,
        couponCode: code,
      );

      final CheckoutViewState? latest = state.value;
      if (latest == null) {
        return;
      }

      state = AsyncData<CheckoutViewState>(
        latest.copyWith(
          couponInput: code,
          isValidatingCoupon: false,
          clearCouponError: true,
          quote: serverQuote,
          activeClientRequestId: _generateClientRequestId(),
        ),
      );
    } on AppException catch (error) {
      final CheckoutViewState? latest = state.value;
      if (latest == null) {
        return;
      }
      state = AsyncData<CheckoutViewState>(
        latest.copyWith(isValidatingCoupon: false, couponError: error.message),
      );
    } on Object {
      final CheckoutViewState? latest = state.value;
      if (latest == null) {
        return;
      }
      state = AsyncData<CheckoutViewState>(
        latest.copyWith(
          isValidatingCoupon: false,
          couponError: AppStrings.checkoutCouponInvalid,
        ),
      );
    }
  }

  /// Quita el cupón aplicado actualmente y refresca el total con el servidor.
  Future<void> removeCoupon() async {
    final CheckoutViewState? current = state.value;
    if (current == null || current.isSubmitting) {
      return;
    }

    state = AsyncData<CheckoutViewState>(
      current.copyWith(
        couponInput: '',
        clearCouponError: true,
        quote: current.quote.copyWith(
          discountCents: 0,
          totalCents:
              current.quote.subtotalCents +
              current.quote.deliveryFeeCents +
              current.quote.tipCents,
          isServerConfirmed: false,
          clearCoupon: true,
        ),
        activeClientRequestId: _generateClientRequestId(),
      ),
    );

    await _refreshServerQuote(couponCode: null);
  }

  Future<void> _refreshServerQuote({
    List<CheckoutCartItem>? items,
    String? addressId,
    String? couponCode,
  }) async {
    final CheckoutViewState? current = state.value;
    if (current == null) {
      return;
    }

    try {
      final CheckoutRepository repository = ref.read(
        checkoutRepositoryProvider,
      );
      final CheckoutQuote serverQuote = await repository.calculateServerQuote(
        merchantId: current.merchantId,
        addressId: addressId ?? current.selectedAddressId,
        items: items ?? current.items,
        couponCode: couponCode,
      );

      final CheckoutViewState? latest = state.value;
      if (latest == null) {
        return;
      }
      state = AsyncData<CheckoutViewState>(latest.copyWith(quote: serverQuote));
    } on Object {
      // Mantiene la estimación si ocurre un fallo transitorio de red.
    }
  }

  /// Envía el pedido al servidor protegiendo contra doble toque y validando discrepancia.
  Future<CheckoutSubmissionResult?> submitOrder({
    bool forceSubmit = false,
  }) async {
    final CheckoutViewState? current = state.value;
    if (current == null || current.isSubmitting || current.items.isEmpty) {
      return null;
    }

    // Validación de saldo ClinPay si se abona con billetera
    if (current.paymentMethod == CheckoutPaymentMethod.clinPay) {
      if (current.clinpayBalanceCents < current.quote.totalCents) {
        state = AsyncData<CheckoutViewState>(
          current.copyWith(
            submissionError: AppStrings.checkoutClinPayInsufficientBalance,
            paymentStatus: PaymentProcessStatus.rejected,
          ),
        );
        return null;
      }
    }

    // Pre-flight: verificación autoritativa con el servidor si no fue forzado
    final CheckoutRepository repository = ref.read(checkoutRepositoryProvider);

    if (!forceSubmit) {
      try {
        final CheckoutQuote preflightQuote = await repository
            .calculateServerQuote(
              merchantId: current.merchantId,
              addressId: current.selectedAddressId,
              items: current.items,
              couponCode: current.quote.appliedCoupon?.code,
              tipCents: current.quote.tipCents,
            );

        if (preflightQuote.hasDiscrepancyWith(current.quote.totalCents)) {
          state = AsyncData<CheckoutViewState>(
            current.copyWith(
              isSubmitting: false,
              paymentStatus: PaymentProcessStatus.idle,
              pendingDiscrepancyQuote: preflightQuote,
            ),
          );
          return null;
        }
      } on Object {
        // En caso de fallo en el pre-flight, continúa hacia submitOrder
      }
    }

    state = AsyncData<CheckoutViewState>(
      current.copyWith(
        isSubmitting: true,
        paymentStatus: PaymentProcessStatus.submittingOrder,
        clearSubmissionError: true,
      ),
    );

    try {
      final CheckoutSubmissionResult submission = await repository.submitOrder(
        clientRequestId: current.activeClientRequestId,
        merchantId: current.merchantId,
        addressId: current.selectedAddressId,
        items: current.items,
        paymentMethod: current.paymentMethod,
        couponCode: current.quote.appliedCoupon?.code,
        riderNotes: current.riderNotes,
        changeForCents: current.changeForCents,
        tipCents: current.quote.tipCents,
      );

      if (_isDisposed) {
        return submission;
      }
      final CheckoutViewState? latest = state.value;
      if (latest == null) {
        return submission;
      }

      // El total del servidor siempre manda.
      final CheckoutQuote authoritativeQuote = latest.quote.copyWith(
        subtotalCents: submission.serverSubtotalCents,
        deliveryFeeCents: submission.serverDeliveryFeeCents,
        discountCents: submission.serverDiscountCents,
        tipCents: submission.serverTipCents,
        totalCents: submission.serverTotalCents,
        isServerConfirmed: true,
      );

      if (!latest.paymentMethod.usesExternalGateway) {
        final int currentActiveCount = ref.read(activeOrdersCountProvider);
        ref
            .read(activeOrdersCountProvider.notifier)
            .setCount(currentActiveCount + 1);

        state = AsyncData<CheckoutViewState>(
          latest.copyWith(
            isSubmitting: false,
            quote: authoritativeQuote,
            paymentStatus: PaymentProcessStatus.approved,
            lastSubmissionResult: submission,
            clearPendingDiscrepancy: true,
          ),
        );
        return submission;
      }

      await _paymentSubscription?.cancel();
      _paymentTimeoutTimer?.cancel();
      _paymentTimeoutTimer = Timer(const Duration(seconds: 120), () {
        final CheckoutViewState? current = state.value;
        if (current != null &&
            (current.paymentStatus ==
                    PaymentProcessStatus.awaitingExternalPayment ||
                current.paymentStatus == PaymentProcessStatus.pending)) {
          state = AsyncData<CheckoutViewState>(
            current.copyWith(paymentStatus: PaymentProcessStatus.timeout),
          );
        }
      });

      _paymentSubscription = repository
          .watchOrderPaymentStatus(submission.orderId)
          .listen(handlePaymentResult);

      state = AsyncData<CheckoutViewState>(
        latest.copyWith(
          isSubmitting: false,
          quote: authoritativeQuote,
          paymentStatus: PaymentProcessStatus.awaitingExternalPayment,
          lastSubmissionResult: submission,
          clearPendingDiscrepancy: true,
        ),
      );
      return submission;
    } on AppException catch (error) {
      if (_isDisposed) return null;
      final CheckoutViewState? latest = state.value;
      if (latest != null) {
        state = AsyncData<CheckoutViewState>(
          latest.copyWith(
            isSubmitting: false,
            paymentStatus: PaymentProcessStatus.rejected,
            submissionError: error.message,
            activeClientRequestId: _generateClientRequestId(),
          ),
        );
      }
      return null;
    } on Object catch (error) {
      if (_isDisposed) return null;
      final AppException mapped = AppException.fromError(error);
      final CheckoutViewState? latest = state.value;
      if (latest != null) {
        state = AsyncData<CheckoutViewState>(
          latest.copyWith(
            isSubmitting: false,
            paymentStatus: PaymentProcessStatus.rejected,
            submissionError: mapped.message,
            activeClientRequestId: _generateClientRequestId(),
          ),
        );
      }
      return null;
    }
  }

  /// Procesa el resultado de pago proveniente de Realtime o del deep link de retorno.
  void handlePaymentResult(PaymentProcessStatus resultStatus) {
    if (_isDisposed) return;
    final CheckoutViewState? current = state.value;
    if (current == null) {
      return;
    }

    if (resultStatus.isTerminal) {
      _paymentTimeoutTimer?.cancel();
    }

    if (resultStatus == PaymentProcessStatus.approved &&
        current.paymentStatus != PaymentProcessStatus.approved) {
      final int currentActiveCount = ref.read(activeOrdersCountProvider);
      ref
          .read(activeOrdersCountProvider.notifier)
          .setCount(currentActiveCount + 1);
    }

    state = AsyncData<CheckoutViewState>(
      current.copyWith(
        paymentStatus: resultStatus,
        activeClientRequestId: resultStatus == PaymentProcessStatus.rejected
            ? _generateClientRequestId()
            : current.activeClientRequestId,
      ),
    );
  }

  /// Cancela el proceso de pago indicando que el usuario regresó sin completar la transacción.
  void markPaymentCancelledByUser() {
    if (_isDisposed) return;
    final CheckoutViewState? current = state.value;
    if (current == null) return;
    _paymentTimeoutTimer?.cancel();
    state = AsyncData<CheckoutViewState>(
      current.copyWith(
        paymentStatus: PaymentProcessStatus.userCancelled,
        activeClientRequestId: _generateClientRequestId(),
      ),
    );
  }

  /// Reinicia el proceso de pago para reintentar con Mercado Pago.
  Future<CheckoutSubmissionResult?> retryExternalPayment() async {
    final CheckoutViewState? current = state.value;
    if (current == null) return null;
    state = AsyncData<CheckoutViewState>(
      current.copyWith(
        activeClientRequestId: _generateClientRequestId(),
        paymentStatus: PaymentProcessStatus.idle,
        clearSubmissionError: true,
      ),
    );
    return submitOrder(forceSubmit: true);
  }
}

/// Provider principal del controlador de Checkout.
final AsyncNotifierProvider<CheckoutController, CheckoutViewState>
checkoutControllerProvider =
    AsyncNotifierProvider<CheckoutController, CheckoutViewState>(
      CheckoutController.new,
    );
