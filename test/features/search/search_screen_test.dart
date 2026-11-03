import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_theme.dart';
import 'package:clinapp/features/search/data/supabase_search_repository.dart';
import 'package:clinapp/features/search/domain/search_models.dart';
import 'package:clinapp/features/search/domain/search_repository.dart';
import 'package:clinapp/features/search/presentation/search_screen.dart';
import 'package:clinapp/features/search/presentation/widgets/search_filters_row.dart';
import 'package:clinapp/features/search/presentation/widgets/suggested_merchant_tile.dart';

class _ThrowingSearchRepository implements SearchRepository {
  @override
  Future<SearchCatalogData> fetchSearchCatalog({String? query}) async {
    throw const ServerFailure(AppStrings.errorServer);
  }

  @override
  Future<bool> toggleFavorite({
    required String merchantId,
    required bool currentValue,
  }) async {
    throw const ServerFailure(AppStrings.errorServer);
  }
}

void main() {
  group('SearchScreen (Etapa 5)', () {
    testWidgets(
      'renderiza búsquedas recientes, filtros y comercios sugeridos en pesos',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const Scaffold(body: SearchScreen()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Búsquedas recientes y acción de limpiar.
        expect(find.text(AppStrings.searchRecentTitle), findsOneWidget);
        expect(find.text(AppStrings.searchClearAll), findsOneWidget);
        expect(find.text('Lomito completo'), findsOneWidget);
        expect(find.text('Helado dulce de leche'), findsOneWidget);

        // Filtros.
        expect(find.text(AppStrings.searchFilterOpenNow), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(SearchFiltersRow),
            matching: find.text(AppStrings.searchFilterFreeDelivery),
          ),
          findsOneWidget,
        );
        expect(find.text(AppStrings.searchFilterTopRated), findsOneWidget);

        // Comercios sugeridos y precios de platos estrella en pesos.
        expect(find.text('La Esquina del Sándwich'), findsOneWidget);
        expect(find.text(r'$8.900'), findsOneWidget);
        expect(find.text('Parrilla Don Manuel'), findsOneWidget);
        expect(find.text(r'$14.600'), findsOneWidget);
      },
    );

    testWidgets(
      'aplica debounce de 250ms al escribir y limpia con el botón X',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const Scaffold(body: SearchScreen()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(SuggestedMerchantTile), findsNWidgets(3));

        // Ingresamos texto y verificamos que antes de 250ms aún no filtró.
        await tester.enterText(
          find.byKey(const Key('search-query-field')),
          'Asado',
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(SuggestedMerchantTile), findsNWidgets(3));

        // Al cumplirse los 250ms, filtra por plato o comercio ("Asado" -> Parrilla Don Manuel).
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(SuggestedMerchantTile), findsOneWidget);
        expect(find.text('Parrilla Don Manuel'), findsOneWidget);
        expect(find.text('La Esquina del Sándwich'), findsNothing);

        // Tocamos el botón X del campo de búsqueda para limpiar la consulta.
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('search-query-field')),
            matching: find.byType(IconButton),
          ),
        );
        await tester.pump();
        expect(find.byType(SuggestedMerchantTile), findsNWidgets(3));
      },
    );

    testWidgets(
      'selecciona una búsqueda reciente, elimina un chip individual y limpia el historial',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const Scaffold(body: SearchScreen()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Tocar una búsqueda reciente filtra de inmediato.
        await tester.tap(find.text('Lomito completo'));
        await tester.pump();
        expect(find.byType(SuggestedMerchantTile), findsOneWidget);
        expect(find.text('La Esquina del Sándwich'), findsOneWidget);

        // Limpiamos el campo para volver a ver todos los comercios.
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('search-query-field')),
            matching: find.byType(IconButton),
          ),
        );
        await tester.pump();
        expect(find.text(AppStrings.searchRecentTitle), findsOneWidget);

        // Eliminamos una búsqueda reciente individual ("Cerveza artesanal").
        await tester.tap(
          find.byKey(const Key('delete-chip-Cerveza artesanal')),
        );
        await tester.pump();
        expect(find.text('Cerveza artesanal'), findsNothing);

        // Limpiamos todo el historial.
        await tester.tap(find.text(AppStrings.searchClearAll));
        await tester.pump();
        expect(find.text(AppStrings.searchEmptyHistory), findsOneWidget);
      },
    );

    testWidgets('combina filtros de envío gratis y más rápido', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(body: SearchScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Desplazamos un poco la fila de filtros para que "Envío gratis" quede bien centrado.
      await tester.drag(find.byType(SearchFiltersRow), const Offset(-80, 0));
      await tester.pumpAndSettle();

      // Activamos "Envío gratis" -> solo Parrilla Don Manuel tiene deliveryFeeCents == 0.
      await tester.tap(
        find.descendant(
          of: find.byType(SearchFiltersRow),
          matching: find.text(AppStrings.searchFilterFreeDelivery),
        ),
      );
      await tester.pump();

      expect(find.byType(SuggestedMerchantTile), findsOneWidget);
      expect(find.text('Parrilla Don Manuel'), findsOneWidget);

      // Desplazamos la fila horizontal de filtros hasta el final para traer "Más rápido" a la vista.
      await tester.drag(find.byType(SearchFiltersRow), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Si además activamos "Más rápido" (ETA <= 25 min), no queda ninguno.
      await tester.tap(find.text(AppStrings.searchFilterFastest));
      await tester.pump();

      expect(find.byType(SuggestedMerchantTile), findsNothing);
      expect(find.text(AppStrings.catalogEmptyTitle), findsOneWidget);

      // Al tocar "Ver todos los comercios" en el estado vacío, vuelven los 3 comercios.
      await tester.tap(find.text(AppStrings.catalogExploreMerchants));
      await tester.pump();
      expect(find.byType(SuggestedMerchantTile), findsNWidgets(3));
    });

    testWidgets('muestra ErrorState cuando falla la carga del catálogo', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchRepositoryProvider.overrideWithValue(
              _ThrowingSearchRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(body: SearchScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.genericErrorTitle), findsOneWidget);
      expect(find.text(AppStrings.actionRetry), findsOneWidget);
    });
  });
}
