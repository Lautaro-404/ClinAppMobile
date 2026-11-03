/// Modelo inmutable para representar un mensaje de notificación push entrante.
class PushMessage {
  const PushMessage({
    required this.title,
    required this.body,
    this.id,
    this.orderId,
    this.url,
    this.data = const <String, dynamic>{},
  });

  /// Crea un [PushMessage] extrayendo de forma segura datos crudos de FCM o WebPush.
  factory PushMessage.fromMap({
    required Map<String, dynamic> data,
    String? title,
    String? body,
    String? id,
  }) {
    final String resolvedTitle =
        (title ?? data['title'] as String?)?.trim() ?? '';
    final String resolvedBody =
        (body ?? data['body'] as String? ?? data['message'] as String?)
            ?.trim() ??
        '';
    final String? resolvedUrl = data['url'] as String?;

    // Detección de orderId a partir de campos explícitos o parseando la URL '/pedidos/<id>'
    String? resolvedOrderId =
        data['order_id'] as String? ??
        data['pedido_id'] as String? ??
        data['orderId'] as String?;

    if ((resolvedOrderId == null || resolvedOrderId.isEmpty) &&
        resolvedUrl != null) {
      final RegExp match = RegExp(r'/pedidos/([^/?#]+)');
      final RegExpMatch? found = match.firstMatch(resolvedUrl);
      if (found != null && found.groupCount >= 1) {
        resolvedOrderId = found.group(1);
      }
    }

    return PushMessage(
      id: id ?? data['id'] as String?,
      title: resolvedTitle,
      body: resolvedBody,
      orderId: resolvedOrderId,
      url: resolvedUrl,
      data: data,
    );
  }

  final String? id;
  final String title;
  final String body;
  final String? orderId;
  final String? url;
  final Map<String, dynamic> data;

  @override
  String toString() =>
      'PushMessage(id: $id, title: $title, orderId: $orderId, url: $url)';
}
