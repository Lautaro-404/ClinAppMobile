import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinapp/core/config/env.dart';
import 'package:clinapp/core/config/supabase_provider.dart';
import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/network/retry_policy.dart';
import 'package:clinapp/features/checkout/domain/checkout_models.dart';
import 'package:clinapp/features/checkout/domain/checkout_repository.dart';

/// Implementación de [CheckoutRepository] conectada a Supabase (DB, Edge Functions
/// `crear-pedido` y `crear-pago`, y Realtime) con fallback local para General Alvear.
class SupabaseCheckoutRepository implements CheckoutRepository {
  SupabaseCheckoutRepository({required this.client});

  final SupabaseClient? client;

  /// Caché en memoria de pedidos ya procesados por `clientRequestId` para
  /// garantizar idempotencia frente a reintentos o doble toque.
  final Map<String, CheckoutSubmissionResult> _processedRequests =
      <String, CheckoutSubmissionResult>{};

  /// Peticiones HTTP en vuelo para evitar llamadas duplicadas simultáneas por doble toque.
  final Map<String, Future<CheckoutSubmissionResult>> _inFlightRequests =
      <String, Future<CheckoutSubmissionResult>>{};

  static const Map<String, int> _seedProductPricesCents = <String, int>{
    'prod-bife-1': 1120000,
    'prod-ensalada-2': 240000,
    'prod-malbec-3': 380000,
  };

  @override
  Future<CheckoutInitialData> loadCheckoutSession() async {
    const List<CheckoutCartItem> items = <CheckoutCartItem>[
      CheckoutCartItem(
        productId: 'prod-bife-1',
        name: 'Ojo de bife con papas rústicas',
        unitPriceCents: 1120000,
        quantity: 1,
      ),
      CheckoutCartItem(
        productId: 'prod-ensalada-2',
        name: 'Ensalada mixta especial',
        unitPriceCents: 240000,
        quantity: 1,
      ),
      CheckoutCartItem(
        productId: 'prod-malbec-3',
        name: 'Vino Malbec Alvearense 750ml',
        unitPriceCents: 380000,
        quantity: 1,
      ),
    ];

    const List<DeliveryAddressOption> addresses = <DeliveryAddressOption>[
      DeliveryAddressOption(
        id: 'addr-alv-1',
        addressLine: 'Av. San Martín 450, Dpto 2B',
        city: 'General Alvear, Mendoza',
        etaRangeText: '30-40 min',
        lat: -34.9765,
        lng: -67.6908,
      ),
      DeliveryAddressOption(
        id: 'addr-alv-2',
        addressLine: 'Av. Alvear Oeste 320',
        city: 'General Alvear, Mendoza',
        etaRangeText: '25-35 min',
        lat: -34.9752,
        lng: -67.6940,
      ),
      DeliveryAddressOption(
        id: 'addr-alv-3',
        addressLine: 'Paso de los Andes 680',
        city: 'General Alvear, Mendoza',
        etaRangeText: '35-45 min',
        lat: -34.9790,
        lng: -67.6880,
      ),
    ];

    final CheckoutQuote initialQuote = await calculateServerQuote(
      merchantId: 'merch-don-manuel',
      addressId: addresses.first.id,
      items: items,
      couponCode: 'ALVEARYA',
    );

    final int clinpayBalance = await getClinPayBalance();

    return CheckoutInitialData(
      merchantId: 'merch-don-manuel',
      merchantName: 'Parrilla Don Manuel',
      merchantTagline: 'Cocina mendocina al fuego',
      items: items,
      addresses: addresses,
      selectedAddressId: addresses.first.id,
      initialRiderNotes: 'Tocar timbre blanco, no anda el portero',
      initialCouponCode: 'ALVEARYA',
      initialQuote: initialQuote,
      clinpayBalanceCents: clinpayBalance,
    );
  }

  @override
  Future<int> getClinPayBalance() async {
    final SupabaseClient? activeClient = client;
    final User? currentUser = activeClient?.auth.currentUser;
    if (activeClient != null && currentUser != null) {
      try {
        final Map<String, Object?>? row =
            await RetryPolicy.execute<Map<String, Object?>?>(
              () => activeClient
                  .from('profiles')
                  .select('wallet_balance')
                  .eq('id', currentUser.id)
                  .maybeSingle(),
            );
        if (row != null && row['wallet_balance'] != null) {
          return _readInt(row['wallet_balance'], fallback: 450000);
        }
      } on PermissionDeniedFailure {
        rethrow;
      } on Object {
        if (Env.isProd) {
          return 0;
        }
      }
    }
    return Env.isProd ? 0 : 450000;
  }

  @override
  Future<CheckoutQuote> calculateServerQuote({
    required String merchantId,
    required String addressId,
    required List<CheckoutCartItem> items,
    String? couponCode,
    int tipCents = 0,
  }) async {
    if (items.isEmpty) {
      return const CheckoutQuote(
        subtotalCents: 0,
        deliveryFeeCents: 0,
        discountCents: 0,
        tipCents: 0,
        totalCents: 0,
        isServerConfirmed: true,
      );
    }

    final SupabaseClient? activeClient = client;
    final User? currentUser = activeClient?.auth.currentUser;

    if (activeClient != null && currentUser != null) {
      try {
        return await _calculateRemoteQuote(
          activeClient: activeClient,
          items: items,
          couponCode: couponCode,
          tipCents: tipCents,
        );
      } on AppException {
        rethrow;
      } on Object {
        // Fallback al motor de reglas local si no hay conectividad en dev.
      }
    }

    return _calculateSeedQuote(
      items: items,
      couponCode: couponCode,
      tipCents: tipCents,
    );
  }

  Future<CheckoutQuote> _calculateRemoteQuote({
    required SupabaseClient activeClient,
    required List<CheckoutCartItem> items,
    String? couponCode,
    required int tipCents,
  }) async {
    final List<String> productIds = items
        .map((CheckoutCartItem item) => item.productId)
        .toSet()
        .toList();

    final List<Map<String, Object?>> productRows =
        await RetryPolicy.execute<List<Map<String, Object?>>>(
          () => activeClient
              .from('products')
              .select('id, price, is_available')
              .inFilter('id', productIds),
        );

    final Map<String, int> serverPrices = <String, int>{};
    for (final Map<String, Object?> row in productRows) {
      final String id = _readString(row['id']);
      final int price = _readInt(row['price']);
      if (id.isNotEmpty && price > 0) {
        serverPrices[id] = price;
      }
    }

    int subtotalCents = 0;
    for (final CheckoutCartItem item in items) {
      final int unitPrice =
          serverPrices[item.productId] ??
          _seedProductPricesCents[item.productId] ??
          item.unitPriceCents;
      subtotalCents += unitPrice * item.quantity;
    }

    AppliedCoupon? appliedCoupon;
    int discountCents = 0;
    final String normalizedCoupon = (couponCode ?? '').trim().toUpperCase();

    if (normalizedCoupon.isNotEmpty) {
      final Map<String, Object?>? couponRow =
          await RetryPolicy.execute<Map<String, Object?>?>(
            () => activeClient
                .from('coupons')
                .select(
                  'id, codigo, porcentaje, tope_centavos, monto_minimo_centavos, activo',
                )
                .eq('codigo', normalizedCoupon)
                .maybeSingle(),
          );

      if (couponRow != null && _readBool(couponRow['activo'], fallback: true)) {
        final int minSubtotal = _readInt(couponRow['monto_minimo_centavos']);
        if (subtotalCents < minSubtotal) {
          throw const ValidationFailure(AppStrings.checkoutCouponInvalid);
        }
        final int percentage = _readInt(couponRow['porcentaje']);
        final int? capCents = couponRow['tope_centavos'] != null
            ? _readInt(couponRow['tope_centavos'])
            : null;
        final int rawDiscount = (subtotalCents * percentage) ~/ 100;
        discountCents = capCents != null && rawDiscount > capCents
            ? capCents
            : rawDiscount;
        appliedCoupon = AppliedCoupon(
          id: _readString(couponRow['id'], fallback: 'coupon-remote'),
          code: normalizedCoupon,
          percentage: percentage,
          discountCents: discountCents,
          capCents: capCents,
          minSubtotalCents: minSubtotal,
        );
      } else {
        return _calculateSeedQuote(
          items: items,
          couponCode: normalizedCoupon,
          tipCents: tipCents,
        );
      }
    }

    final int deliveryFeeCents = normalizedCoupon == 'ALVEARYA' ? 0 : 0;
    final int safeTip = tipCents < 0 ? 0 : tipCents;
    final int totalCents =
        (subtotalCents + deliveryFeeCents + safeTip - discountCents).clamp(
          0,
          100000000,
        );

    return CheckoutQuote(
      subtotalCents: subtotalCents,
      deliveryFeeCents: deliveryFeeCents,
      discountCents: discountCents,
      tipCents: safeTip,
      totalCents: totalCents,
      isServerConfirmed: true,
      appliedCoupon: appliedCoupon,
    );
  }

  CheckoutQuote _calculateSeedQuote({
    required List<CheckoutCartItem> items,
    String? couponCode,
    required int tipCents,
  }) {
    int subtotalCents = 0;
    for (final CheckoutCartItem item in items) {
      final int authoritativeUnitPrice =
          _seedProductPricesCents[item.productId] ?? item.unitPriceCents;
      subtotalCents += authoritativeUnitPrice * item.quantity;
    }

    final String normalizedCode = (couponCode ?? '').trim().toUpperCase();
    AppliedCoupon? appliedCoupon;
    int discountCents = 0;

    if (normalizedCode.isNotEmpty) {
      if (normalizedCode == 'ALVEARYA') {
        const int percentage = 20;
        const int capCents = 280000;
        final int rawDiscount = (subtotalCents * percentage) ~/ 100;
        discountCents = rawDiscount > capCents ? capCents : rawDiscount;
        appliedCoupon = AppliedCoupon(
          id: 'coupon-alvearya',
          code: 'ALVEARYA',
          percentage: percentage,
          discountCents: discountCents,
          capCents: capCents,
        );
      } else if (normalizedCode == 'BIENVENIDA') {
        const int percentage = 15;
        const int capCents = 200000;
        final int rawDiscount = (subtotalCents * percentage) ~/ 100;
        discountCents = rawDiscount > capCents ? capCents : rawDiscount;
        appliedCoupon = AppliedCoupon(
          id: 'coupon-bienvenida',
          code: 'BIENVENIDA',
          percentage: percentage,
          discountCents: discountCents,
          capCents: capCents,
        );
      } else {
        throw const ValidationFailure(AppStrings.checkoutCouponInvalid);
      }
    }

    const int deliveryFeeCents = 0;
    final int safeTip = tipCents < 0 ? 0 : tipCents;
    final int totalCents =
        (subtotalCents + deliveryFeeCents + safeTip - discountCents).clamp(
          0,
          100000000,
        );

    return CheckoutQuote(
      subtotalCents: subtotalCents,
      deliveryFeeCents: deliveryFeeCents,
      discountCents: discountCents,
      tipCents: safeTip,
      totalCents: totalCents,
      isServerConfirmed: true,
      appliedCoupon: appliedCoupon,
    );
  }

  @override
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
  }) async {
    final CheckoutSubmissionResult? cached =
        _processedRequests[clientRequestId];
    if (cached != null) {
      return cached;
    }

    final Future<CheckoutSubmissionResult>? inFlight =
        _inFlightRequests[clientRequestId];
    if (inFlight != null) {
      return inFlight;
    }

    if (items.isEmpty) {
      throw const ValidationFailure(AppStrings.checkoutEmptyCartTitle);
    }

    final Future<CheckoutSubmissionResult> task = _executeSubmitOrder(
      clientRequestId: clientRequestId,
      merchantId: merchantId,
      addressId: addressId,
      items: items,
      paymentMethod: paymentMethod,
      couponCode: couponCode,
      riderNotes: riderNotes,
      changeForCents: changeForCents,
      tipCents: tipCents,
    );

    _inFlightRequests[clientRequestId] = task;

    try {
      final CheckoutSubmissionResult result = await task;
      _processedRequests[clientRequestId] = result;
      return result;
    } finally {
      unawaited(_inFlightRequests.remove(clientRequestId));
    }
  }

  Future<CheckoutSubmissionResult> _executeSubmitOrder({
    required String clientRequestId,
    required String merchantId,
    required String addressId,
    required List<CheckoutCartItem> items,
    required CheckoutPaymentMethod paymentMethod,
    String? couponCode,
    String? riderNotes,
    int? changeForCents,
    required int tipCents,
  }) async {
    final SupabaseClient? activeClient = client;
    final User? currentUser = activeClient?.auth.currentUser;

    if (activeClient != null && currentUser != null) {
      try {
        return await _submitRemoteOrder(
          activeClient: activeClient,
          clientRequestId: clientRequestId,
          merchantId: merchantId,
          addressId: addressId,
          items: items,
          paymentMethod: paymentMethod,
          couponCode: couponCode,
          riderNotes: riderNotes,
          changeForCents: changeForCents,
          tipCents: tipCents,
        );
      } on FunctionException catch (fe) {
        final String rawMsg = _extractFunctionError(fe);
        throw ServerFailure(_mapBusinessErrorMessage(rawMsg));
      } on AppException {
        rethrow;
      } on Object catch (error) {
        throw AppException.fromError(error);
      }
    }

    // Fallback de desarrollo / tests sin sesión remota activa.
    final CheckoutQuote serverQuote = await calculateServerQuote(
      merchantId: merchantId,
      addressId: addressId,
      items: items,
      couponCode: couponCode,
      tipCents: tipCents,
    );

    final String generatedOrderId = 'ord-alv-${clientRequestId.hashCode.abs()}';
    final bool usesGateway = paymentMethod.usesExternalGateway;

    return CheckoutSubmissionResult(
      orderId: generatedOrderId,
      clientRequestId: clientRequestId,
      serverSubtotalCents: serverQuote.subtotalCents,
      serverDeliveryFeeCents: serverQuote.deliveryFeeCents,
      serverDiscountCents: serverQuote.discountCents,
      serverTipCents: serverQuote.tipCents,
      serverTotalCents: serverQuote.totalCents,
      orderStatus: usesGateway ? 'pago_pendiente' : 'confirmado',
      preferenceId: usesGateway ? 'pref-$generatedOrderId' : null,
      checkoutUrl: usesGateway
          ? 'https://sandbox.mercadopago.com.ar/checkout/v1/redirect?pref_id=pref-$generatedOrderId'
          : null,
    );
  }

  Future<CheckoutSubmissionResult> _submitRemoteOrder({
    required SupabaseClient activeClient,
    required String clientRequestId,
    required String merchantId,
    required String addressId,
    required List<CheckoutCartItem> items,
    required CheckoutPaymentMethod paymentMethod,
    String? couponCode,
    String? riderNotes,
    int? changeForCents,
    required int tipCents,
  }) async {
    final List<Map<String, Object?>> serializedItems = items
        .map(
          (CheckoutCartItem item) => <String, Object?>{
            'product_id': item.productId,
            'cantidad': item.quantity,
            'opciones': item.selectedOptionIds,
            if (item.notes != null && item.notes!.isNotEmpty)
              'nota': item.notes,
          },
        )
        .toList();

    final Map<String, Object?> requestBody = <String, Object?>{
      'client_request_id': clientRequestId,
      'merchant_id': merchantId,
      'address_id': addressId,
      'items': serializedItems,
      'propina': tipCents,
      'metodo_pago': paymentMethod.backendValue,
      if (changeForCents != null && changeForCents > 0)
        'vuelto_para': changeForCents,
      if (couponCode != null && couponCode.trim().isNotEmpty)
        'codigo_cupon': couponCode.trim().toUpperCase(),
      if (riderNotes != null && riderNotes.trim().isNotEmpty)
        'special_instructions': riderNotes.trim(),
    };

    final FunctionResponse orderResp =
        await RetryPolicy.execute<FunctionResponse>(
          () =>
              activeClient.functions.invoke('crear-pedido', body: requestBody),
          maxAttempts: 3,
          timeout: RetryPolicy.defaultMutationTimeout,
        );

    final Map<String, Object?>? respMap = _asStringKeyMap(orderResp.data);
    final Map<String, Object?>? pedidoMap = _asStringKeyMap(respMap?['pedido']);

    if (pedidoMap == null) {
      final String errMsg = _readString(
        respMap?['error'],
        fallback: AppStrings.genericErrorMessage,
      );
      throw ServerFailure(_mapBusinessErrorMessage(errMsg));
    }

    final String orderId = _readString(pedidoMap['id']);
    final int serverSubtotal = _readInt(pedidoMap['subtotal']);
    final int serverEnvio = _readInt(pedidoMap['envio']);
    final int serverPropina = _readInt(pedidoMap['propina']);
    final int serverDescuento = _readInt(pedidoMap['descuento']);
    final int serverTotal = _readInt(pedidoMap['total']);
    final String orderStatus = _readString(
      pedidoMap['estado'],
      fallback: paymentMethod.usesExternalGateway
          ? 'pago_pendiente'
          : 'confirmado',
    );

    String? preferenceId;
    String? checkoutUrl;

    if (paymentMethod.usesExternalGateway) {
      final FunctionResponse paymentResp =
          await RetryPolicy.execute<FunctionResponse>(
            () => activeClient.functions.invoke(
              'crear-pago',
              body: <String, Object?>{'order_id': orderId},
            ),
            maxAttempts: 2,
            timeout: RetryPolicy.defaultMutationTimeout,
          );
      final Map<String, Object?>? paymentMap = _asStringKeyMap(
        paymentResp.data,
      );
      if (paymentMap == null || paymentMap['checkout_url'] == null) {
        final String mpErr = _readString(
          paymentMap?['error'],
          fallback: AppStrings.paymentRejectedSubtitle,
        );
        throw ServerFailure(mpErr);
      }
      preferenceId = _readString(paymentMap['preference_id']);
      checkoutUrl = _readString(paymentMap['checkout_url']);
    }

    return CheckoutSubmissionResult(
      orderId: orderId,
      clientRequestId: clientRequestId,
      serverSubtotalCents: serverSubtotal,
      serverDeliveryFeeCents: serverEnvio,
      serverDiscountCents: serverDescuento,
      serverTipCents: serverPropina,
      serverTotalCents: serverTotal,
      orderStatus: orderStatus,
      preferenceId: preferenceId,
      checkoutUrl: checkoutUrl,
    );
  }

  static String _extractFunctionError(FunctionException fe) {
    final Object? details = fe.details;
    if (details is Map) {
      final Object? errVal = details['error'];
      if (errVal is String && errVal.isNotEmpty) {
        return errVal;
      }
    }
    if (details is String && details.isNotEmpty) {
      return details;
    }
    if (fe.reasonPhrase != null && fe.reasonPhrase!.isNotEmpty) {
      return fe.reasonPhrase!;
    }
    return AppStrings.genericErrorMessage;
  }

  static String _mapBusinessErrorMessage(String raw) {
    final String lower = raw.toLowerCase();
    if (lower.contains('cerrado')) {
      return AppStrings.checkoutErrorStoreClosed;
    }
    if (lower.contains('no está disponible') ||
        lower.contains('no esta disponible')) {
      return AppStrings.checkoutErrorProductUnavailable;
    }
    if (lower.contains('cobertura')) {
      return AppStrings.checkoutErrorOutOfZone;
    }
    if (lower.contains('radio máximo') || lower.contains('radio maximo')) {
      return AppStrings.checkoutErrorMaxDistance;
    }
    if (lower.contains('primer pedido')) {
      return AppStrings.checkoutErrorFirstOrderCoupon;
    }
    if (lower.contains('cupón') || lower.contains('cupon')) {
      return AppStrings.checkoutCouponInvalid;
    }
    if (lower.contains('saldo insuficiente')) {
      return AppStrings.checkoutClinPayInsufficientBalance;
    }
    return raw;
  }

  @override
  Stream<PaymentProcessStatus> watchOrderPaymentStatus(String orderId) {
    final SupabaseClient? activeClient = client;
    if (activeClient == null || orderId.isEmpty) {
      return const Stream<PaymentProcessStatus>.empty();
    }

    final StreamController<PaymentProcessStatus> controller =
        StreamController<PaymentProcessStatus>.broadcast();
    Timer? pollingTimer;

    Future<void> checkStatusFromDb() async {
      try {
        final Map<String, Object?>? row = await activeClient
            .from('orders')
            .select('estado')
            .eq('id', orderId)
            .maybeSingle();
        if (row != null && !controller.isClosed) {
          final String rawStatus = _readString(row['estado']);
          final PaymentProcessStatus? mapped = _mapOrderStatus(rawStatus);
          if (mapped != null) {
            controller.add(mapped);
            if (mapped.isTerminal) {
              pollingTimer?.cancel();
            }
          }
        }
      } on Object {
        // Ignorar fallas transitorias de red en el polling de respaldo
      }
    }

    // Consulta inmediata inicial
    unawaited(checkStatusFromDb());

    // Polling de respaldo cada 3 segundos por si Realtime sufre suspensión en background
    pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(checkStatusFromDb());
    });

    final RealtimeChannel channel = activeClient
        .channel('public:orders:payment:$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (PostgresChangePayload payload) {
            final Map<String, Object?> newRecord = payload.newRecord;
            final String rawStatus = _readString(newRecord['estado']);
            final PaymentProcessStatus? mapped = _mapOrderStatus(rawStatus);
            if (mapped != null && !controller.isClosed) {
              controller.add(mapped);
              if (mapped.isTerminal) {
                pollingTimer?.cancel();
              }
            }
          },
        )
        .subscribe();

    controller.onCancel = () async {
      pollingTimer?.cancel();
      await activeClient.removeChannel(channel);
      if (!controller.isClosed) {
        await controller.close();
      }
    };

    return controller.stream;
  }

  static PaymentProcessStatus? _mapOrderStatus(String rawStatus) {
    if (rawStatus == 'confirmado' ||
        rawStatus == 'aceptado_por_local' ||
        rawStatus == 'en_preparacion' ||
        rawStatus == 'en_camino' ||
        rawStatus == 'entregado') {
      return PaymentProcessStatus.approved;
    }
    if (rawStatus == 'cancelado' || rawStatus == 'rechazado') {
      return PaymentProcessStatus.rejected;
    }
    if (rawStatus == 'pago_pendiente') {
      return PaymentProcessStatus.pending;
    }
    return null;
  }

  static Map<String, Object?>? _asStringKeyMap(Object? raw) {
    if (raw is Map<String, Object?>) {
      return raw;
    }
    if (raw is Map<Object?, Object?>) {
      final Map<String, Object?> converted = <String, Object?>{};
      for (final MapEntry<Object?, Object?> entry in raw.entries) {
        final Object? key = entry.key;
        if (key is String) {
          converted[key] = entry.value;
        }
      }
      return converted;
    }
    return null;
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String) {
      return value;
    }
    return fallback;
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static bool _readBool(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    return fallback;
  }
}

/// Provider del repositorio de Checkout.
final Provider<CheckoutRepository> checkoutRepositoryProvider =
    Provider<CheckoutRepository>((Ref ref) {
      final SupabaseClient? client = ref.watch(supabaseClientProvider);
      return SupabaseCheckoutRepository(client: client);
    });
