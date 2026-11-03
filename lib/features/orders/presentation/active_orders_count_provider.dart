import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cantidad de pedidos en curso para mostrar en el badge de la barra inferior.
///
/// En la Etapa 6 se conecta al stream Realtime de pedidos activos del usuario.
class ActiveOrdersCountNotifier extends Notifier<int> {
  @override
  int build() => 1;

  // ignore: use_setters_to_change_properties
  void setCount(int count) {
    state = count < 0 ? 0 : count;
  }
}

/// Provider del contador de pedidos activos en la barra de navegación.
final NotifierProvider<ActiveOrdersCountNotifier, int>
activeOrdersCountProvider = NotifierProvider<ActiveOrdersCountNotifier, int>(
  ActiveOrdersCountNotifier.new,
);
