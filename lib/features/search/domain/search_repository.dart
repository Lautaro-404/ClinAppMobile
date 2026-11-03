import 'package:clinapp/features/search/domain/search_models.dart';

/// Contrato de repositorio para la pantalla Buscar.
abstract interface class SearchRepository {
  /// Obtiene las búsquedas recientes y el catálogo de comercios y platos.
  ///
  /// El parámetro opcional [query] permite filtrar en servidor por término de búsqueda.
  Future<SearchCatalogData> fetchSearchCatalog({String? query});

  /// Alterna el estado de favorito de un comercio (`public.favorites`).
  Future<bool> toggleFavorite({
    required String merchantId,
    required bool currentValue,
  });
}
