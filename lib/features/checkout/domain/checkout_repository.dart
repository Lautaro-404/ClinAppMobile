import 'package:clinapp/features/checkout/domain/checkout_models.dart';

/// Contrato del repositorio de Checkout y Pagos.
abstract interface class CheckoutRepository {
  /// Carga el comercio actual del carrito, platos, direcciones y cotización inicial del servidor.
  Future<CheckoutInitialData> loadCheckoutSession();

  /// Solicita al servidor el cálculo autoritativo de subtotal, envío, descuento y total.
  Future<CheckoutQuote> calculateServerQuote({
    required String merchantId,
    required String addressId,
    required List<CheckoutCartItem> items,
    String? couponCode,
    int tipCents = 0,
  });

  /// Crea el pedido a través de la Edge Function `crear-pedido` y, si corresponde,
  /// genera la preferencia de pago en `crear-pago`.
  /// Garantiza idempotencia mediante [clientRequestId].
  Future<CheckoutSubmissionResult> submitOrder({
    required String clientRequestId,
    required String merchantId,
    required String addressId,
    required List<CheckoutCartItem> items,
    required CheckoutPaymentMethod paymentMethod,
    String? couponCode,
    String? riderNotes,
    int? changeForCents,
    int tipCents = 0,
  });

  /// Obtiene el saldo disponible de ClinPay del usuario (en centavos).
  Future<int> getClinPayBalance();

  /// Escucha en tiempo real los cambios de estado del pedido asociado al pago.
  Stream<PaymentProcessStatus> watchOrderPaymentStatus(String orderId);
}
