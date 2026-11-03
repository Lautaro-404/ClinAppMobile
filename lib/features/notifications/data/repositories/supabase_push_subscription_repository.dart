import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/network/retry_policy.dart';
import 'package:clinapp/features/notifications/domain/repositories/push_subscription_repository.dart';

/// Implementación de [PushSubscriptionRepository] sobre Supabase PostgreSQL.
class SupabasePushSubscriptionRepository implements PushSubscriptionRepository {
  SupabasePushSubscriptionRepository({required this.client});

  final SupabaseClient? client;

  @override
  Future<void> registerSubscription({
    required String userId,
    required String token,
    String? platform,
  }) async {
    final SupabaseClient? activeClient = client;
    if (activeClient == null || userId.isEmpty || token.isEmpty) {
      return;
    }

    try {
      await RetryPolicy.execute<void>(
        () => activeClient.from('push_subscriptions').upsert(<String, dynamic>{
          'user_id': userId,
          'endpoint': token,
          'p256dh': platform ?? 'fcm',
          'auth': 'fcm',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'endpoint'),
        maxAttempts: 2,
        timeout: RetryPolicy.defaultMutationTimeout,
      );
    } on Object catch (error) {
      throw AppException.fromError(error);
    }
  }

  @override
  Future<void> removeSubscription({
    required String userId,
    required String token,
  }) async {
    final SupabaseClient? activeClient = client;
    if (activeClient == null || userId.isEmpty || token.isEmpty) {
      return;
    }

    try {
      await RetryPolicy.execute<void>(
        () => activeClient
            .from('push_subscriptions')
            .delete()
            .eq('user_id', userId)
            .eq('endpoint', token),
        maxAttempts: 2,
        timeout: RetryPolicy.defaultMutationTimeout,
      );
    } on Object catch (error) {
      throw AppException.fromError(error);
    }
  }

  @override
  Future<void> removeAllUserSubscriptions({required String userId}) async {
    final SupabaseClient? activeClient = client;
    if (activeClient == null || userId.isEmpty) {
      return;
    }

    try {
      await RetryPolicy.execute<void>(
        () => activeClient
            .from('push_subscriptions')
            .delete()
            .eq('user_id', userId),
        maxAttempts: 2,
        timeout: RetryPolicy.defaultMutationTimeout,
      );
    } on Object catch (error) {
      throw AppException.fromError(error);
    }
  }
}
