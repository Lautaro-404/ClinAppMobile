import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_theme.dart';
import 'package:clinapp/core/utils/date_formatter.dart';
import 'package:clinapp/features/home/data/supabase_home_repository.dart';
import 'package:clinapp/features/home/domain/home_models.dart';
import 'package:clinapp/features/home/domain/home_repository.dart';
import 'package:clinapp/features/home/presentation/home_screen.dart';

class _FailingThenRecoveringRepository implements HomeRepository {
  _FailingThenRecoveringRepository(this._delegate);

  final HomeRepository _delegate;
  bool shouldFail = true;

  @override
  Future<HomeFeedData> fetchHomeFeed() async {
    if (shouldFail) {
      throw const NetworkFailure(AppStrings.genericErrorMessage);
    }
    return _delegate.fetchHomeFeed();
  }

  @override
  Future<bool> toggleFavorite({
    required String merchantId,
    required bool currentValue,
  }) {
    return _delegate.toggleFavorite(
      merchantId: merchantId,
      currentValue: currentValue,
    );
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_AR');
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(DateFormatter.zoneName));
  });

  group('HomeScreen (Etapa 4)', () {
    testWidgets(
      'renderiza saludo, dirección, promo, último pedido y comercios con precios formateados',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const Scaffold(body: HomeScreen()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.textContaining('Hola, Lucas'), findsOneWidget);
        expect(find.text(AppStrings.homeDefaultAddress), findsOneWidget);
        expect(find.text(AppStrings.homePromoDefaultTitle), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Empanadas Don Pedro'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Empanadas Don Pedro'), findsOneWidget);
        expect(find.text(r'$12.400'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Pizzería La Alvearense'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Pizzería La Alvearense'), findsOneWidget);
        expect(find.text(r'Envío $850'), findsOneWidget);
      },
    );

    testWidgets(
      'filtra comercios por categoría y muestra estado vacío cuando no hay resultados',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const Scaffold(body: HomeScreen()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Filtramos por Hamburguesas.
        await tester.tap(find.text('Hamburguesas'));
        await tester.pump();

        await tester.scrollUntilVisible(
          find.text('Burgers Alvear Craft'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Burgers Alvear Craft'), findsOneWidget);
        expect(find.text('Pizzería La Alvearense'), findsNothing);

        // Volvemos arriba y seleccionamos Farmacia (sin locales).
        await tester.drag(find.byType(ListView), const Offset(0, 600));
        await tester.pump();
        await tester.scrollUntilVisible(
          find.text('Farmacia'),
          100,
          scrollable: find.byType(Scrollable).at(1),
        );
        await tester.tap(find.text('Farmacia'));
        await tester.pump();

        await tester.scrollUntilVisible(
          find.text(AppStrings.homeEmptyCategoryTitle),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(AppStrings.homeEmptyCategoryTitle), findsOneWidget);
      },
    );

    testWidgets(
      'permite alternar favorito de un comercio y reintentar ante error',
      (WidgetTester tester) async {
        final _FailingThenRecoveringRepository repo =
            _FailingThenRecoveringRepository(
              SupabaseHomeRepository(client: null),
            );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [homeRepositoryProvider.overrideWithValue(repo)],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const Scaffold(body: HomeScreen()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Primero muestra ErrorState.
        expect(find.text(AppStrings.genericErrorTitle), findsOneWidget);

        // Reintentamos con éxito.
        repo.shouldFail = false;
        await tester.tap(find.text(AppStrings.actionRetry));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        await tester.scrollUntilVisible(
          find.text('Pizzería La Alvearense'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        final Finder addFav = find.bySemanticsLabel(
          '${AppStrings.catalogFavoriteSemantics} Pizzería La Alvearense',
        );
        expect(addFav, findsOneWidget);

        await tester.tap(addFav);
        await tester.pump();

        expect(
          find.bySemanticsLabel(
            '${AppStrings.homeRemoveFavoriteSemantics} Pizzería La Alvearense',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
