import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_theme.dart';
import 'package:clinapp/core/utils/date_formatter.dart';
import 'package:clinapp/features/orders/data/supabase_orders_repository.dart';
import 'package:clinapp/features/orders/domain/orders_models.dart';
import 'package:clinapp/features/orders/domain/orders_repository.dart';
import 'package:clinapp/features/orders/presentation/widgets/order_chat_sheet.dart';

class _FakeChatOrdersRepository implements OrdersRepository {
  final StreamController<List<ChatMessage>> chatStreamController =
      StreamController<List<ChatMessage>>.broadcast();

  final List<String> sentMessages = <String>[];

  @override
  Stream<List<ChatMessage>> watchChatMessages(String orderId) {
    return chatStreamController.stream;
  }

  @override
  Future<void> sendChatMessage({
    required String orderId,
    required String content,
  }) async {
    sentMessages.add(content);
    chatStreamController.add(<ChatMessage>[
      ChatMessage(
        id: 'msg-${sentMessages.length}',
        orderId: orderId,
        senderId: 'me',
        content: content,
        createdAt: DateTime.now(),
        isMine: true,
      ),
    ]);
  }

  @override
  Future<OrdersPageData> fetchOrders({int page = 0, int pageSize = 4}) async =>
      const OrdersPageData(
        activeOrders: <OrderSummary>[],
        historyOrders: <OrderSummary>[],
        hasMoreHistory: false,
        currentPage: 0,
      );

  @override
  Stream<OrdersRealtimeEvent> watchActiveOrders() =>
      const Stream<OrdersRealtimeEvent>.empty();

  @override
  Stream<OrdersRealtimeEvent> watchOrder(String orderId) =>
      const Stream<OrdersRealtimeEvent>.empty();

  @override
  Future<ReorderValidationResult> revalidateOrderForRepeat(
    OrderSummary order,
  ) => throw UnimplementedError();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_AR');
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(DateFormatter.zoneName));
  });

  testWidgets(
    'OrderChatSheet muestra mensajes entrantes en tiempo real y permite enviar',
    (WidgetTester tester) async {
      final _FakeChatOrdersRepository fakeRepo = _FakeChatOrdersRepository();
      final OrderSummary order = OrderSummary(
        id: 'ord-1234',
        shortCode: '#1234',
        merchantId: 'm-1',
        merchantName: 'Pizzería Alvear',
        itemsSummary: '1x Pizza Especial',
        status: OrderStatus.enCamino,
        createdAt: DateTime.now(),
        subtotalCents: 1200000,
        deliveryFeeCents: 150000,
        totalCents: 1350000,
        courier: const CourierInfo(
          id: 'c-1',
          name: 'Lautaro',
          vehicle: 'Moto',
          plate: 'ABC 123',
          phone: '+54 9 2625 401234',
          lat: -34.975,
          lng: -67.690,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [ordersRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(body: OrderChatSheet(order: order)),
          ),
        ),
      );
      await tester.pump();

      // Estado vacío inicial
      fakeRepo.chatStreamController.add(<ChatMessage>[]);
      await tester.pumpAndSettle();
      expect(
        find.text('Escribile al repartidor para coordinar la entrega.'),
        findsOneWidget,
      );

      // Llega un mensaje en tiempo real por el stream
      fakeRepo.chatStreamController.add(<ChatMessage>[
        ChatMessage(
          id: 'msg-1',
          orderId: 'ord-1234',
          senderId: 'c-1',
          content: '¡Hola! Ya salí con tu pedido.',
          createdAt: DateTime.now(),
          senderName: 'Lautaro',
          isMine: false,
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('¡Hola! Ya salí con tu pedido.'), findsOneWidget);

      // Cliente escribe y envía una respuesta
      await tester.enterText(
        find.byType(TextField),
        'Buenísimo, te espero en la puerta.',
      );
      await tester.tap(find.text(AppStrings.ordersSendMessage));
      await tester.pumpAndSettle();

      expect(
        fakeRepo.sentMessages,
        contains('Buenísimo, te espero en la puerta.'),
      );
      expect(find.text('Buenísimo, te espero en la puerta.'), findsOneWidget);
    },
  );
}
