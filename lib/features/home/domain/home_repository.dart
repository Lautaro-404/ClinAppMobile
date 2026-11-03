import 'package:clinapp/features/home/domain/home_models.dart';

/// Contrato de repositorio para los datos de la pantalla Inicio.
abstract interface class HomeRepository {
  /// Obtiene las categorías, banner promocional, último pedido y comercios.
  Future<HomeFeedData> fetchHomeFeed();

  /// Alterna el estado de favorito de un comercio (`public.favorites`) y
  /// devuelve el nuevo valor confirmado.
  Future<bool> toggleFavorite({
    required String merchantId,
    required bool currentValue,
  });
}
