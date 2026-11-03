/// Rutas nominales centralizadas de la app.
abstract final class AppRoutes {
  static const String home = '/inicio';
  static const String search = '/buscar';
  static const String orders = '/pedidos';
  static const String profile = '/perfil';

  // Rutas fuera de la barra inferior.
  static const String checkout = '/checkout';
  static const String paymentResult = '/pago/resultado';
  static const String login = '/login';
  static const String register = '/registro';
  static const String devCatalog = '/dev/catalogo';
  static const String courierPanel = '/panel/repartidor';
  static const String merchantPanel = '/panel/local';
  static const String adminPanel = '/panel/admin';
}
