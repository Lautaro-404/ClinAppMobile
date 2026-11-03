import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_theme.dart';
import 'package:clinapp/features/checkout/data/supabase_checkout_repository.dart';
import 'package:clinapp/features/checkout/domain/checkout_models.dart';
import 'package:clinapp/features/checkout/domain/checkout_repository.dart';
import 'package:clinapp/core/services/url_launcher_service.dart';
import 'package:clinapp/features/checkout/presentation/checkout_screen.dart';
import 'package:clinapp/features/checkout/presentation/payment_result_screen.dart';
import 'package:clinapp/features/orders/presentation/active_orders_count_provider.dart';

class _FakeCheckoutRepository implements CheckoutRepository {
  _FakeCheckoutRepository({
    this.submitDelay = Duration.zero,
    this.serverTotalOverrideCents,
    this.quoteTotalOverrideCents,
    this.shouldFailLoad = false,
    this.submitException,
    this.clinpayBalance = 450000,
  });

  final Duration submitDelay;
  final int? serverTotalOverrideCents;
  final int? quoteTotalOverrideCents;
  final bool shouldFailLoad;
  final AppException? submitException;
  int clinpayBalance;

  final StreamController<PaymentProcessStatus> paymentStreamController =
      StreamController<PaymentProcessStatus>.broadcast();

  int submitCallCount = 0;
  final List<String> receivedClientRequestIds = <String>[];

  final SupabaseCheckoutRepository _delegate = SupabaseCheckoutRepository(
    client: null,
  );

  @override
  Future<int> getClinPayBalance() async => clinpayBalance;

  @override
  Future<CheckoutInitialData> loadCheckoutSession() async {
    if (shouldFailLoad) {
      throw const ServerFailure('No pudimos cargar el carrito.');
    }
    final CheckoutInitialData base = await _delegate.loadCheckoutSession();
    final CheckoutQuote quote = serverTotalOverrideCents != null
        ? base.initialQuote.copyWith(
            totalCents: serverTotalOverrideCents,
            isServerConfirmed: true,
          )
        : base.initialQuote;

    return CheckoutInitialData(
      merchantId: base.merchantId,
      merchantName: base.merchantName,
      merchantTagline: base.merchantTagline,
      items: base.items,
      addresses: base.addresses,
      selectedAddressId: base.selectedAddressId,
      initialRiderNotes: base.initialRiderNotes,
      initialCouponCode: base.initialCouponCode,
      initialQuote: quote,
      clinpayBalanceCents: clinpayBalance,
    );
  }

  @override
  Future<CheckoutQuote> calculateServerQuote({
    required String merchantId,
    required String addressId,
    required List<CheckoutCartItem> items,
    String? couponCode,
    int tipCents = 0,
  }) async {
    final CheckoutQuote base = await _delegate.calculateServerQuote(
      merchantId: merchantId,
      addressId: addressId,
      items: items,
      couponCode: couponCode,
      tipCents: tipCents,
    );
    if (quoteTotalOverrideCents != null) {
      return base.copyWith(
        totalCents: quoteTotalOverrideCents,
        isServerConfirmed: true,
      );
    }
    if (serverTotalOverrideCents != null) {
      return base.copyWith(
        totalCents: serverTotalOverrideCents,
        isServerConfirmed: true,
      );
    }
    return base;
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
    submitCallCount += 1;
    receivedClientRequestIds.add(clientRequestId);

    if (submitDelay > Duration.zero) {
      await Future<void>.delayed(submitDelay);
    }

    if (submitException != null) {
      throw submitException!;
    }

    final CheckoutSubmissionResult base = await _delegate.submitOrder(
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

    if (serverTotalOverrideCents != null) {
      return CheckoutSubmissionResult(
        orderId: base.orderId,
        clientRequestId: base.clientRequestId,
        serverSubtotalCents: base.serverSubtotalCents,
        serverDeliveryFeeCents: base.serverDeliveryFeeCents,
        serverDiscountCents: base.serverDiscountCents,
        serverTipCents: base.serverTipCents,
        serverTotalCents: serverTotalOverrideCents!,
        orderStatus: base.orderStatus,
        preferenceId: base.preferenceId,
        checkoutUrl: base.checkoutUrl,
      );
    }
    return base;
  }

  @override
  Stream<PaymentProcessStatus> watchOrderPaymentStatus(String orderId) {
    return paymentStreamController.stream;
  }

  Future<void> dispose() async {
    await paymentStreamController.close();
  }
}

class _FakeUrlLauncherService implements UrlLauncherService {
  String? lastOpenedUrl;

  @override
  Future<bool> openUrl(String url) async {
    lastOpenedUrl = url;
    return true;
  }
}

void main() {
  group('CheckoutScreen (Etapa 7)', () {
    late _FakeCheckoutRepository fakeRepo;
    late _FakeUrlLauncherService fakeLauncher;

    setUp(() {
      fakeRepo = _FakeCheckoutRepository();
      fakeLauncher = _FakeUrlLauncherService();
    });

    tearDown(() async {
      await fakeRepo.dispose();
    });

    testWidgets(
      'renderiza resumen de Parrilla Don Manuel, dirección, cupón ALVEARYA, desglose y PayBar sin exceder 3 blurs',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [checkoutRepositoryProvider.overrideWithValue(fakeRepo)],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const CheckoutScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Parrilla Don Manuel'), findsOneWidget);
        expect(find.text('3 platos'), findsOneWidget);
        expect(find.text('Ojo de bife con papas rústicas'), findsOneWidget);
        expect(find.text('Ensalada mixta especial'), findsOneWidget);
        expect(find.text('Vino Malbec Alvearense 750ml'), findsOneWidget);
        expect(find.text('Av. San Martín 450, Dpto 2B'), findsOneWidget);
        expect(find.text("CUPÓN 'ALVEARYA' APLICADO"), findsOneWidget);
        expect(find.text(r'$17.400'), findsOneWidget);
        expect(find.text('GRATIS'), findsOneWidget);
        expect(find.text(r'Pagar $14.600'), findsOneWidget);

        // Presupuesto de blur: máximo 3 BackdropFilter simultáneos.
        final int blurCount = tester
            .widgetList(find.byType(BackdropFilter))
            .length;
        expect(blurCount, lessThanOrEqualTo(3));
      },
    );

    testWidgets(
      'actualiza cantidades, valida cupones y el total en Pagar refleja siempre la verdad del servidor',
      (WidgetTester tester) async {
        final _FakeCheckoutRepository authoritativeRepo =
            _FakeCheckoutRepository(serverTotalOverrideCents: 1510000);
        addTearDown(authoritativeRepo.dispose);

        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(authoritativeRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const CheckoutScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // El servidor indica $15.100 como verdad autoritativa.
        expect(find.text(r'Pagar $15.100'), findsOneWidget);

        // Incrementamos un plato.
        await tester.tap(
          find.bySemanticsLabel(
            '${AppStrings.checkoutIncreaseQtySemantics} Ensalada mixta especial',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('4 platos'), findsOneWidget);
        expect(find.text(r'Pagar $15.100'), findsOneWidget);

        // Probamos un cupón inválido.
        await tester.enterText(
          find.widgetWithText(TextField, 'ALVEARYA'),
          'CUPONFALSO',
        );
        await tester.tap(find.text(AppStrings.checkoutCouponApply));
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.checkoutCouponInvalid), findsOneWidget);
      },
    );

    testWidgets(
      'protege contra doble toque (idempotencia) enviando un único submitOrder',
      (WidgetTester tester) async {
        final _FakeCheckoutRepository slowRepo = _FakeCheckoutRepository(
          submitDelay: const Duration(milliseconds: 200),
        );
        addTearDown(slowRepo.dispose);

        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [checkoutRepositoryProvider.overrideWithValue(slowRepo)],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const CheckoutScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final Finder payButton = find.text(r'Pagar $14.600');
        await tester.tap(payButton);
        await tester.pump(const Duration(milliseconds: 20));

        // Segundo toque mientras está procesando: el botón ya cambió a "Procesando..." y está deshabilitado.
        await tester.tap(
          find.text(AppStrings.checkoutSubmittingLabel),
          warnIfMissed: false,
        );
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pumpAndSettle();

        expect(slowRepo.submitCallCount, 1);
        expect(slowRepo.receivedClientRequestIds.length, 1);
      },
    );

    testWidgets(
      'procesa pago con Mercado Pago y actualiza estado por Realtime (esperando -> aprobado / rechazado)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        late ProviderContainer container;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container = ProviderContainer(
              overrides: [
                checkoutRepositoryProvider.overrideWithValue(fakeRepo),
                urlLauncherServiceProvider.overrideWithValue(fakeLauncher),
              ],
            ),
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const CheckoutScreen(),
            ),
          ),
        );
        addTearDown(container.dispose);
        await tester.pumpAndSettle();

        final int initialActiveOrders = container.read(
          activeOrdersCountProvider,
        );

        await tester.tap(find.text(AppStrings.checkoutMethodMpTitle));
        await tester.pumpAndSettle();

        await tester.tap(find.text(r'Pagar $14.600'));
        await tester.pumpAndSettle();

        // Se abre la hoja de estado esperando confirmación.
        expect(fakeLauncher.lastOpenedUrl, contains('mercadopago.com'));
        expect(find.text(AppStrings.paymentProcessingTitle), findsOneWidget);

        // Simulamos notificación Realtime del servidor: pago aprobado.
        fakeRepo.paymentStreamController.add(PaymentProcessStatus.approved);
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.paymentApprovedTitle), findsOneWidget);
        expect(find.text(AppStrings.paymentGoToOrdersAction), findsOneWidget);
        expect(
          container.read(activeOrdersCountProvider),
          initialActiveOrders + 1,
        );

        // Si llega un estado rechazado, ofrece reintentar con Mercado Pago o cambiar de medio.
        fakeRepo.paymentStreamController.add(PaymentProcessStatus.rejected);
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.paymentRejectedTitle), findsOneWidget);
        expect(
          find.text(AppStrings.paymentRetryMercadoPagoAction),
          findsOneWidget,
        );
        expect(find.text(AppStrings.paymentChangeMethodAction), findsOneWidget);
      },
    );

    testWidgets(
      'confirma directamente cuando se elige Efectivo contra entrega y soporta pantallas de 320px sin overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [checkoutRepositoryProvider.overrideWithValue(fakeRepo)],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const CheckoutScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.checkoutMethodCashTitle));
        await tester.pumpAndSettle();

        await tester.tap(find.text(r'Pagar $14.600'));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.paymentCashConfirmedMsg), findsOneWidget);
        expect(fakeRepo.submitCallCount, 1);
      },
    );

    testWidgets('muestra ErrorState cuando falla la carga inicial', (
      WidgetTester tester,
    ) async {
      final _FakeCheckoutRepository errorRepo = _FakeCheckoutRepository(
        shouldFailLoad: true,
      );
      addTearDown(errorRepo.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [checkoutRepositoryProvider.overrideWithValue(errorRepo)],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const CheckoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No pudimos cargar el carrito.'), findsOneWidget);
      expect(find.text(AppStrings.actionRetry), findsOneWidget);
    });

    testWidgets(
      'procesa pago con ClinPay cuando el saldo es suficiente y bloquea si es insuficiente',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final _FakeCheckoutRepository clinPayRepo = _FakeCheckoutRepository(
          clinpayBalance: 5000000, // $50.000 de saldo (suficiente para $14.600)
        );
        addTearDown(clinPayRepo.dispose);

        late ProviderContainer container;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container = ProviderContainer(
              overrides: [
                checkoutRepositoryProvider.overrideWithValue(clinPayRepo),
              ],
            ),
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const CheckoutScreen(),
            ),
          ),
        );
        addTearDown(container.dispose);
        await tester.pumpAndSettle();

        final int initialActiveOrders = container.read(
          activeOrdersCountProvider,
        );

        // Elegir ClinPay
        await tester.tap(find.text(AppStrings.checkoutMethodClinPayTitle));
        await tester.pumpAndSettle();

        // Tocar Pagar
        await tester.tap(find.text(r'Pagar $14.600'));
        await tester.pumpAndSettle();

        expect(
          find.text(AppStrings.checkoutPaymentClinPayConfirmedMsg),
          findsOneWidget,
        );
        expect(clinPayRepo.submitCallCount, 1);
        expect(
          container.read(activeOrdersCountProvider),
          initialActiveOrders + 1,
        );
      },
    );

    testWidgets(
      'muestra saldo insuficiente y bloquea envío si el saldo de ClinPay no cubre el total',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final _FakeCheckoutRepository lowBalanceRepo = _FakeCheckoutRepository(
          clinpayBalance: 100000, // $1.000 saldo insuficiente para $14.600
        );
        addTearDown(lowBalanceRepo.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(lowBalanceRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const CheckoutScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verifica que el tile de ClinPay muestre la advertencia
        expect(
          find.text(AppStrings.checkoutClinPayInsufficientBalance),
          findsOneWidget,
        );

        // Selecciona ClinPay
        await tester.tap(find.text(AppStrings.checkoutMethodClinPayTitle));
        await tester.pumpAndSettle();

        // Toca Pagar
        await tester.tap(find.text(r'Pagar $14.600'));
        await tester.pumpAndSettle();

        // No se envió el pedido y se muestra error
        expect(lowBalanceRepo.submitCallCount, 0);
        expect(
          find.text(AppStrings.checkoutClinPayInsufficientBalance),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'detecta discrepancia de total con el servidor, muestra diálogo y pide reconfirmación antes de crear pedido',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Inicialmente carga $14.600 pero el servidor cotiza $16.000 en el pre-flight
        final _FakeCheckoutRepository discrepancyRepo = _FakeCheckoutRepository(
          quoteTotalOverrideCents: 1600000,
        );
        addTearDown(discrepancyRepo.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(discrepancyRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const CheckoutScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // El usuario presiona pagar creyendo que son $14.600
        await tester.tap(find.text(r'Pagar $14.600'));
        await tester.pumpAndSettle();

        // No debe haberse enviado el pedido aún
        expect(discrepancyRepo.submitCallCount, 0);

        // Se abre la hoja modal de discrepancia
        expect(
          find.text(AppStrings.checkoutPriceDiscrepancyTitle),
          findsOneWidget,
        );
        expect(
          find.text(AppStrings.checkoutPriceDiscrepancySubtitle),
          findsOneWidget,
        );
        expect(find.text(r'$14.600'), findsWidgets);
        expect(find.text(r'$16.000'), findsOneWidget);
        expect(
          find.text(AppStrings.checkoutPriceDiscrepancyAccept),
          findsOneWidget,
        );

        // El usuario acepta el nuevo total autoritativo
        await tester.tap(find.text(AppStrings.checkoutPriceDiscrepancyAccept));
        await tester.pumpAndSettle();

        // Ahora sí se envía la orden con éxito
        expect(discrepancyRepo.submitCallCount, 1);
        expect(find.text(AppStrings.paymentCashConfirmedMsg), findsOneWidget);
      },
    );

    testWidgets(
      'muestra error amigable cuando la Edge Function falla por local cerrado o fuera de cobertura',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final _FakeCheckoutRepository closedRepo = _FakeCheckoutRepository(
          submitException: const ServerFailure(
            AppStrings.checkoutErrorStoreClosed,
          ),
        );
        addTearDown(closedRepo.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(closedRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const CheckoutScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(r'Pagar $14.600'));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.checkoutErrorStoreClosed), findsOneWidget);
      },
    );

    testWidgets('permite reintentar el pago con Mercado Pago tras un rechazo', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final _FakeCheckoutRepository retryRepo = _FakeCheckoutRepository();
      addTearDown(retryRepo.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checkoutRepositoryProvider.overrideWithValue(retryRepo),
            urlLauncherServiceProvider.overrideWithValue(fakeLauncher),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const CheckoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Seleccionar Mercado Pago
      await tester.tap(find.text(AppStrings.checkoutMethodMpTitle));
      await tester.pumpAndSettle();

      // Pagar primer intento
      await tester.tap(find.text(r'Pagar $14.600'));
      await tester.pumpAndSettle();

      expect(retryRepo.submitCallCount, 1);
      expect(find.text(AppStrings.paymentProcessingTitle), findsOneWidget);

      // Simulamos rechazo
      retryRepo.paymentStreamController.add(PaymentProcessStatus.rejected);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.paymentRejectedTitle), findsOneWidget);
      expect(
        find.text(AppStrings.paymentRetryMercadoPagoAction),
        findsOneWidget,
      );

      // Tocar Reintentar con Mercado Pago
      await tester.tap(find.text(AppStrings.paymentRetryMercadoPagoAction));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Debe haberse cerrado el sheet y disparado el reintento
      expect(retryRepo.submitCallCount, 2);

      // Simulamos aprobación en el reintento para finalizar el proceso
      retryRepo.paymentStreamController.add(PaymentProcessStatus.approved);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets(
      'permite cambiar a Efectivo desde la hoja de pago tras un rechazo',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final _FakeCheckoutRepository changeMethodRepo =
            _FakeCheckoutRepository();
        addTearDown(changeMethodRepo.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(changeMethodRepo),
              urlLauncherServiceProvider.overrideWithValue(fakeLauncher),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const CheckoutScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.checkoutMethodMpTitle));
        await tester.pumpAndSettle();

        await tester.tap(find.text(r'Pagar $14.600'));
        await tester.pumpAndSettle();

        // Rechazo
        changeMethodRepo.paymentStreamController.add(
          PaymentProcessStatus.rejected,
        );
        await tester.pumpAndSettle();

        // Cambiar medio de pago
        await tester.tap(find.text(AppStrings.paymentChangeMethodAction));
        await tester.pumpAndSettle();

        // Debe volver a la pantalla con Efectivo seleccionado
        await tester.tap(find.text(r'Pagar $14.600'));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.paymentCashConfirmedMsg), findsOneWidget);
      },
    );

    testWidgets(
      'muestra estado de cancelación y permite cambiar método cuando el usuario cancela en MP',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final _FakeCheckoutRepository cancelRepo = _FakeCheckoutRepository();
        addTearDown(cancelRepo.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(cancelRepo),
              urlLauncherServiceProvider.overrideWithValue(fakeLauncher),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const CheckoutScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.checkoutMethodMpTitle));
        await tester.pumpAndSettle();

        await tester.tap(find.text(r'Pagar $14.600'));
        await tester.pumpAndSettle();

        // Simulamos cancelación del usuario
        cancelRepo.paymentStreamController.add(
          PaymentProcessStatus.userCancelled,
        );
        await tester.pumpAndSettle();

        expect(
          find.text(AppStrings.paymentUserCancelledSubtitle),
          findsOneWidget,
        );
        expect(
          find.text(AppStrings.paymentRetryMercadoPagoAction),
          findsOneWidget,
        );
        expect(find.text(AppStrings.paymentChangeMethodAction), findsOneWidget);
      },
    );

    testWidgets(
      'muestra estado de timeout tras demora prolongada en acreditación',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final _FakeCheckoutRepository timeoutRepo = _FakeCheckoutRepository();
        addTearDown(timeoutRepo.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(timeoutRepo),
              urlLauncherServiceProvider.overrideWithValue(fakeLauncher),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const CheckoutScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.checkoutMethodMpTitle));
        await tester.pumpAndSettle();

        await tester.tap(find.text(r'Pagar $14.600'));
        await tester.pumpAndSettle();

        timeoutRepo.paymentStreamController.add(PaymentProcessStatus.timeout);
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.paymentTimeoutTitle), findsOneWidget);
        expect(find.text(AppStrings.paymentTimeoutSubtitle), findsOneWidget);
        expect(find.text(AppStrings.paymentGoToOrdersAction), findsOneWidget);
      },
    );

    testWidgets(
      'PaymentResultScreen procesa deep link con orderId y navega a pedidos al confirmarse',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final _FakeCheckoutRepository resultRepo = _FakeCheckoutRepository();
        addTearDown(resultRepo.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(resultRepo),
            ],
            child: const MaterialApp(
              home: PaymentResultScreen(
                orderId: 'ord-alv-12345678',
                statusHint: 'aprobado',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.paymentProcessingTitle), findsOneWidget);
        expect(find.text('Pedido: #ORD-ALV-'), findsOneWidget);

        // Simulamos aprobación por Realtime en la pantalla de resultado
        resultRepo.paymentStreamController.add(PaymentProcessStatus.approved);
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.paymentApprovedTitle), findsOneWidget);
        expect(find.text(AppStrings.paymentGoToOrdersAction), findsOneWidget);
      },
    );
  });
}
