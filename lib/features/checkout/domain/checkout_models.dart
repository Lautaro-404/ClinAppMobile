/// Método de pago seleccionable en el Checkout.
enum CheckoutPaymentMethod {
  cash(
    backendValue: 'efectivo',
    usesExternalGateway: false,
    isAvailableInPhase: true,
  ),
  clinPay(
    backendValue: 'clinpay',
    usesExternalGateway: false,
    isAvailableInPhase: true,
  ),
  mercadoPago(
    backendValue: 'mercado_pago',
    usesExternalGateway: true,
    isAvailableInPhase: true,
  ),
  debitCard(
    backendValue: 'mercado_pago',
    usesExternalGateway: true,
    isAvailableInPhase: true,
  );

  const CheckoutPaymentMethod({
    required this.backendValue,
    required this.usesExternalGateway,
    required this.isAvailableInPhase,
  });

  /// Valor esperado por la Edge Function `crear-pedido`.
  final String backendValue;

  /// Indica si requiere crear preferencia en la Edge Function `crear-pago`.
  final bool usesExternalGateway;

  /// Indica si el método de pago está habilitado en la fase actual de ClinApp.
  final bool isAvailableInPhase;
}

/// Estado del proceso de pago del pedido actual.
enum PaymentProcessStatus {
  idle,
  submittingOrder,
  awaitingExternalPayment,
  approved,
  pending,
  rejected,
  userCancelled,
  timeout;

  bool get isTerminal =>
      this == PaymentProcessStatus.approved ||
      this == PaymentProcessStatus.rejected ||
      this == PaymentProcessStatus.userCancelled ||
      this == PaymentProcessStatus.timeout;
}

/// Ítem del carrito dentro de la sesión de Checkout.
class CheckoutCartItem {
  const CheckoutCartItem({
    required this.productId,
    required this.name,
    required this.unitPriceCents,
    required this.quantity,
    this.imageUrl,
    this.selectedOptionIds = const <String>[],
    this.notes,
  });

  final String productId;
  final String name;
  final int unitPriceCents;
  final int quantity;
  final String? imageUrl;
  final List<String> selectedOptionIds;
  final String? notes;

  int get lineTotalCents => unitPriceCents * quantity;

  CheckoutCartItem copyWith({
    String? productId,
    String? name,
    int? unitPriceCents,
    int? quantity,
    String? imageUrl,
    List<String>? selectedOptionIds,
    String? notes,
  }) {
    return CheckoutCartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
      notes: notes ?? this.notes,
    );
  }
}

/// Dirección de entrega disponible para el usuario en General Alvear.
class DeliveryAddressOption {
  const DeliveryAddressOption({
    required this.id,
    required this.addressLine,
    required this.city,
    required this.etaRangeText,
    this.lat,
    this.lng,
  });

  final String id;
  final String addressLine;
  final String city;
  final String etaRangeText;
  final double? lat;
  final double? lng;
}

/// Cupón de descuento validado contra las reglas del servidor.
class AppliedCoupon {
  const AppliedCoupon({
    required this.id,
    required this.code,
    required this.percentage,
    required this.discountCents,
    this.capCents,
    this.minSubtotalCents = 0,
  });

  final String id;
  final String code;
  final int percentage;
  final int discountCents;
  final int? capCents;
  final int minSubtotalCents;
}

/// Desglose económico del pedido (estimación local o confirmación del servidor).
class CheckoutQuote {
  const CheckoutQuote({
    required this.subtotalCents,
    required this.deliveryFeeCents,
    required this.discountCents,
    required this.tipCents,
    required this.totalCents,
    required this.isServerConfirmed,
    this.appliedCoupon,
  });

  final int subtotalCents;
  final int deliveryFeeCents;
  final int discountCents;
  final int tipCents;
  final int totalCents;
  final bool isServerConfirmed;
  final AppliedCoupon? appliedCoupon;

  /// Indica si el total del servidor difiere del total estimado en la app.
  bool hasDiscrepancyWith(int otherTotalCents) => totalCents != otherTotalCents;

  /// Diferencia en centavos entre este total y otro (positivo si este es mayor).
  int discrepancyWith(int otherTotalCents) => totalCents - otherTotalCents;

  CheckoutQuote copyWith({
    int? subtotalCents,
    int? deliveryFeeCents,
    int? discountCents,
    int? tipCents,
    int? totalCents,
    bool? isServerConfirmed,
    AppliedCoupon? appliedCoupon,
    bool clearCoupon = false,
  }) {
    return CheckoutQuote(
      subtotalCents: subtotalCents ?? this.subtotalCents,
      deliveryFeeCents: deliveryFeeCents ?? this.deliveryFeeCents,
      discountCents: discountCents ?? this.discountCents,
      tipCents: tipCents ?? this.tipCents,
      totalCents: totalCents ?? this.totalCents,
      isServerConfirmed: isServerConfirmed ?? this.isServerConfirmed,
      appliedCoupon: clearCoupon ? null : (appliedCoupon ?? this.appliedCoupon),
    );
  }
}

/// Datos iniciales cargados al abrir la pantalla de Checkout.
class CheckoutInitialData {
  const CheckoutInitialData({
    required this.merchantId,
    required this.merchantName,
    required this.merchantTagline,
    required this.items,
    required this.addresses,
    required this.selectedAddressId,
    required this.initialRiderNotes,
    required this.initialCouponCode,
    required this.initialQuote,
    this.clinpayBalanceCents = 450000,
  });

  final String merchantId;
  final String merchantName;
  final String merchantTagline;
  final List<CheckoutCartItem> items;
  final List<DeliveryAddressOption> addresses;
  final String selectedAddressId;
  final String initialRiderNotes;
  final String? initialCouponCode;
  final CheckoutQuote initialQuote;
  final int clinpayBalanceCents;
}

/// Respuesta autoritativa del servidor luego de crear el pedido (y la preferencia MP si aplica).
class CheckoutSubmissionResult {
  const CheckoutSubmissionResult({
    required this.orderId,
    required this.clientRequestId,
    required this.serverSubtotalCents,
    required this.serverDeliveryFeeCents,
    required this.serverDiscountCents,
    required this.serverTipCents,
    required this.serverTotalCents,
    required this.orderStatus,
    this.preferenceId,
    this.checkoutUrl,
  });

  final String orderId;
  final String clientRequestId;
  final int serverSubtotalCents;
  final int serverDeliveryFeeCents;
  final int serverDiscountCents;
  final int serverTipCents;
  final int serverTotalCents;
  final String orderStatus;
  final String? preferenceId;
  final String? checkoutUrl;
}
