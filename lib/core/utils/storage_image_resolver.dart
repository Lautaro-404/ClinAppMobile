import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinapp/core/errors/app_exception.dart';
import 'package:clinapp/core/l10n/app_strings.dart';

/// Utilidad para resolver URLs de imágenes públicas alojadas en Supabase Storage,
/// aplicar límites de dimensión y validar archivos antes de subirlos.
abstract final class StorageImageResolver {
  static const String localesBucket = 'locales';
  static const String productosBucket = 'productos';
  static const String avatarsBucket = 'avatars';

  /// Límite de tamaño de imagen definido en la migración M3 de Supabase Storage (2 MB).
  static const int maxUploadBytes = 2 * 1024 * 1024;

  /// Tipos MIME permitidos por la política de Supabase Storage.
  static const Set<String> allowedMimeTypes = <String>{
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  /// Valida en cliente el tamaño y formato de un archivo antes de subirlo a Storage.
  static void validateAvatarUpload({
    required Uint8List bytes,
    required String mimeType,
  }) {
    final String normalizedMime = mimeType.trim().toLowerCase();
    if (!allowedMimeTypes.contains(normalizedMime)) {
      throw const ValidationFailure(AppStrings.errorAvatarInvalidMime);
    }
    if (bytes.isEmpty || bytes.lengthInBytes > maxUploadBytes) {
      throw const ValidationFailure(AppStrings.errorAvatarTooLarge);
    }
  }

  /// Resuelve la URL pública para una imagen de comercio (banner o logo).
  static String? resolveMerchantImage(
    String? rawPath, {
    SupabaseClient? client,
    int? width,
    int? height,
  }) {
    return resolvePublicUrl(
      rawPath,
      bucket: localesBucket,
      client: client,
      width: width,
      height: height,
    );
  }

  /// Resuelve la URL pública para una imagen de producto.
  static String? resolveProductImage(
    String? rawPath, {
    SupabaseClient? client,
    int? width,
    int? height,
  }) {
    return resolvePublicUrl(
      rawPath,
      bucket: productosBucket,
      client: client,
      width: width,
      height: height,
    );
  }

  /// Resuelve una URL pública en el bucket especificado.
  ///
  /// Si el valor es nulo, vacío o un placeholder local sin servidor, retorna null.
  /// Si es una URL absoluta HTTP/HTTPS, la conserva.
  /// Si es una ruta relativa de Storage y [client] está disponible, genera la URL pública.
  static String? resolvePublicUrl(
    String? rawPath, {
    required String bucket,
    SupabaseClient? client,
    int? width,
    int? height,
    int quality = 80,
  }) {
    if (rawPath == null) {
      return null;
    }
    final String trimmed = rawPath.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    if (trimmed.startsWith('/placeholder') || trimmed.startsWith('assets/')) {
      return trimmed;
    }

    if (client == null) {
      return null;
    }

    try {
      final String cleanPath = trimmed.startsWith('/')
          ? trimmed.substring(1)
          : trimmed;
      final TransformOptions? transform = (width != null || height != null)
          ? TransformOptions(width: width, height: height, quality: quality)
          : null;
      return client.storage
          .from(bucket)
          .getPublicUrl(cleanPath, transform: transform);
    } on Object {
      return null;
    }
  }
}
