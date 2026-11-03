import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinapp/core/config/bootstrap.dart';
import 'package:clinapp/core/config/env.dart';
import 'package:clinapp/core/config/secure_local_storage.dart';
import 'package:clinapp/core/config/supabase_provider.dart';
import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/network/retry_policy.dart';
import 'package:clinapp/core/utils/storage_image_resolver.dart';
import 'package:clinapp/features/auth/data/supabase_auth_repository.dart';
import 'package:clinapp/features/auth/domain/auth_models.dart';
import 'package:clinapp/features/home/data/supabase_home_repository.dart';
import 'package:clinapp/features/home/domain/home_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supabase Base Config & Seed Mode Tests', () {
    test('Sin .env/defines, Env.isSupabaseConfigured es false', () {
      // En entorno de tests sin inyección por CLI, los defines están vacíos.
      expect(Env.isSupabaseConfigured, isFalse);
    });

    test('supabaseClientProvider es null e isBackendConfiguredProvider es false sin backend', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final SupabaseClient? client = container.read(supabaseClientProvider);
      final bool isConfigured = container.read(isBackendConfiguredProvider);

      expect(client, isNull);
      expect(isConfigured, isFalse);
    });

    test('bootstrap() con isSupabaseConfiguredOverride=false mantiene modo semilla', () async {
      await bootstrap(isSupabaseConfiguredOverride: false);

      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(supabaseClientProvider), isNull);
      expect(container.read(isBackendConfiguredProvider), isFalse);
    });

    test(
      'SupabaseHomeRepository retorna seed data cuando el cliente es null',
      () async {
        final SupabaseHomeRepository repo = SupabaseHomeRepository(
          client: null,
        );
        final HomeFeedData feed = await repo.fetchHomeFeed();

        expect(feed.categories, isNotEmpty);
        expect(feed.merchants, isNotEmpty);
        expect(
          feed.merchants.any(
            (MerchantSummary m) => m.name.contains('La Alvearense'),
          ),
          isTrue,
        );
      },
    );

    test(
      'SupabaseAuthRepository retorna defaultDevSession en modo semilla',
      () async {
        final SupabaseAuthRepository repo = SupabaseAuthRepository(
          client: null,
        );
        final AuthUserSession? session = await repo.loadInitialSession();

        expect(session, isNotNull);
        expect(session?.fullName, 'Lautaro Ponzina');
        expect(session?.email, 'ponzinalautaro6@gmail.com');
        expect(session?.role, AppUserRole.admin);
      },
    );
  });

  group('SecureLocalStorage Tests', () {
    test(
      'Persistencia de sesión: guardar, leer, verificar existencia y borrar',
      () async {
        final SecureLocalStorage storage = SecureLocalStorage(
          persistSessionKey: 'test_session_key',
        );

        expect(await storage.hasAccessToken(), isFalse);
        expect(await storage.accessToken(), isNull);

        await storage.persistSession('token_jwt_prueba_alvear');

        expect(await storage.hasAccessToken(), isTrue);
        expect(await storage.accessToken(), 'token_jwt_prueba_alvear');

        await storage.removePersistedSession();

        expect(await storage.hasAccessToken(), isFalse);
        expect(await storage.accessToken(), isNull);
      },
    );

    test(
      'GotrueAsyncStorage (PKCE): guardar, consultar y remover ítem',
      () async {
        final SecureLocalStorage storage = SecureLocalStorage();

        expect(await storage.getItem(key: 'code_verifier_1'), isNull);

        await storage.setItem(
          key: 'code_verifier_1',
          value: 'secret_verifier_abc',
        );
        expect(
          await storage.getItem(key: 'code_verifier_1'),
          'secret_verifier_abc',
        );

        await storage.removeItem(key: 'code_verifier_1');
        expect(await storage.getItem(key: 'code_verifier_1'), isNull);
      },
    );
  });

  group('Mapeo de excepciones en AppException.fromError', () {
    test(
      'PostgrestException genérica se mapea a ServerException / ServerFailure',
      () {
        const PostgrestException pgError = PostgrestException(
          message: 'relation does not exist',
          code: '42P01',
        );

        final AppException exception = AppException.fromError(pgError);

        expect(exception, isA<ServerFailure>());
        expect(exception, isA<ServerException>());
        expect(exception.message, AppStrings.errorServer);
        expect((exception as ServerFailure).code, '42P01');
      },
    );

    test(
      'PostgrestException PGRST116 se mapea a ServerFailure con errorNotFound',
      () {
        const PostgrestException pgError = PostgrestException(
          message: 'JSON object requested, multiple (or no) rows returned',
          code: 'PGRST116',
        );

        final AppException exception = AppException.fromError(pgError);

        expect(exception, isA<ServerFailure>());
        expect(exception.message, AppStrings.errorNotFound);
      },
    );

    test(
      'AuthException de credenciales incorrectas se mapea a AuthFailure',
      () {
        const AuthException authError = AuthException(
          'Invalid login credentials',
        );

        final AppException exception = AppException.fromError(authError);

        expect(exception, isA<AuthFailure>());
        expect(exception.message, AppStrings.errorAuthCredentials);
      },
    );

    test(
      'AuthException de usuario existente se mapea a errorAuthUserExists',
      () {
        const AuthException authError = AuthException(
          'User already registered',
        );

        final AppException exception = AppException.fromError(authError);

        expect(exception, isA<AuthFailure>());
        expect(exception.message, AppStrings.errorAuthUserExists);
      },
    );

    test('AuthException de email no confirmado se mapea a errorAuthEmailNotConfirmed', () {
      const AuthException authError = AuthException('Email not confirmed');

      final AppException exception = AppException.fromError(authError);

      expect(exception, isA<AuthFailure>());
      expect(exception.message, AppStrings.errorAuthEmailNotConfirmed);
    });

    test('AuthException genérica se mapea con errorAuth', () {
      const AuthException authError = AuthException('Some random auth failure');

      final AppException exception = AppException.fromError(authError);

      expect(exception, isA<AuthFailure>());
      expect(exception.message, AppStrings.errorAuth);
    });

    test(
      'SocketException y de red se mapean a NetworkFailure con errorNetwork',
      () {
        const SocketException socketError = SocketException(
          'Failed host lookup',
        );

        final AppException exception = AppException.fromError(socketError);

        expect(exception, isA<NetworkFailure>());
        expect(exception, isA<NetworkException>());
        expect(exception.message, AppStrings.errorNetwork);
      },
    );

    test('TimeoutException se mapea a NetworkFailure con errorTimeout', () {
      final TimeoutException timeoutError = TimeoutException(
        'Connection timed out',
        const Duration(seconds: 10),
      );

      final AppException exception = AppException.fromError(timeoutError);

      expect(exception, isA<NetworkFailure>());
      expect(exception.message, AppStrings.errorTimeout);
    });

    test('AppException existente se preserva tal cual', () {
      const ServerFailure original = ServerFailure('Error personalizado');
      final AppException mapped = AppException.fromError(original);

      expect(identical(mapped, original), isTrue);
    });

    test(
      'PostgrestException 42501 / RLS se mapea a PermissionDeniedFailure',
      () {
        const PostgrestException rlsError = PostgrestException(
          message:
              'new row violates row-level security policy for table "orders"',
          code: '42501',
        );

        final AppException exception = AppException.fromError(rlsError);

        expect(exception, isA<PermissionDeniedFailure>());
        expect(exception.message, AppStrings.errorPermissionDenied);
      },
    );

    test('RetryPolicy reintenta ante NetworkFailure y no reintenta ante PermissionDeniedFailure', () async {
      int networkCalls = 0;
      final String result = await RetryPolicy.execute<String>(
        () async {
          networkCalls++;
          if (networkCalls < 3) {
            throw const SocketException('Temporary failure');
          }
          return 'ok';
        },
        maxAttempts: 3,
        baseDelay: const Duration(milliseconds: 5),
      );

      expect(result, 'ok');
      expect(networkCalls, 3);

      int rlsCalls = 0;
      await expectLater(
        () => RetryPolicy.execute<void>(
          () async {
            rlsCalls++;
            throw const PostgrestException(
              message: 'permission denied',
              code: '42501',
            );
          },
          maxAttempts: 3,
          baseDelay: const Duration(milliseconds: 5),
        ),
        throwsA(isA<PermissionDeniedFailure>()),
      );
      expect(rlsCalls, 1);
    });

    test(
      'StorageImageResolver.validateAvatarUpload valida MIME y límite de 2 MB',
      () {
        final Uint8List validBytes = Uint8List(1024);
        expect(
          () => StorageImageResolver.validateAvatarUpload(
            bytes: validBytes,
            mimeType: 'image/webp',
          ),
          returnsNormally,
        );

        expect(
          () => StorageImageResolver.validateAvatarUpload(
            bytes: validBytes,
            mimeType: 'application/pdf',
          ),
          throwsA(isA<ValidationFailure>()),
        );

        final Uint8List oversizedBytes = Uint8List(
          StorageImageResolver.maxUploadBytes + 1,
        );
        expect(
          () => StorageImageResolver.validateAvatarUpload(
            bytes: oversizedBytes,
            mimeType: 'image/jpeg',
          ),
          throwsA(isA<ValidationFailure>()),
        );
      },
    );

    test('AppEnvironment.fromString distingue dev, staging y prod; y deshabilita seed fallback en staging/prod', () async {
      expect(AppEnvironment.fromString('dev'), AppEnvironment.dev);
      expect(AppEnvironment.fromString('staging'), AppEnvironment.staging);
      expect(AppEnvironment.fromString('prod'), AppEnvironment.prod);

      final SupabaseAuthRepository prodRepo = SupabaseAuthRepository(
        client: null,
        allowSeedFallbackOverride: false,
      );
      final AuthUserSession? session = await prodRepo.loadInitialSession();
      expect(session, isNull);
    });
  });
}
