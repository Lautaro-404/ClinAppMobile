import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinapp/core/config/supabase_provider.dart';
import 'package:clinapp/features/notifications/data/repositories/supabase_push_subscription_repository.dart';
import 'package:clinapp/features/notifications/data/services/fake_push_service.dart';
import 'package:clinapp/features/notifications/data/services/firebase_push_service.dart';
import 'package:clinapp/features/notifications/domain/models/push_message.dart';
import 'package:clinapp/features/notifications/domain/repositories/push_subscription_repository.dart';
import 'package:clinapp/features/notifications/domain/services/push_service.dart';

/// Provider del repositorio de suscripciones push en Supabase.
final Provider<PushSubscriptionRepository> pushSubscriptionRepositoryProvider =
    Provider<PushSubscriptionRepository>((Ref ref) {
      final SupabaseClient? client = ref.watch(supabaseClientProvider);
      return SupabasePushSubscriptionRepository(client: client);
    });

/// Provider del servicio de notificaciones push de la app.
///
/// Si Firebase está inicializado en la plataforma (`Firebase.apps.isNotEmpty`),
/// provee [FirebasePushService]. En tests y entornos sin credenciales de Firebase,
/// recurre a [FakePushService] sin romper la ejecución.
final Provider<PushService> pushServiceProvider = Provider<PushService>((
  Ref ref,
) {
  final PushSubscriptionRepository repository = ref.watch(
    pushSubscriptionRepositoryProvider,
  );

  final bool hasFirebaseApp = Firebase.apps.isNotEmpty;
  final PushService service = hasFirebaseApp
      ? FirebasePushService(repository: repository)
      : FakePushService(repository: repository);

  ref.onDispose(service.dispose);
  return service;
});

/// Stream de notificaciones entrantes en primer plano.
final StreamProvider<PushMessage> foregroundNotificationStreamProvider =
    StreamProvider<PushMessage>((Ref ref) {
      final PushService service = ref.watch(pushServiceProvider);
      return service.onForegroundMessage;
    });
