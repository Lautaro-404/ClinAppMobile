import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Servicio para abrir enlaces externos o Custom Tabs en la aplicación.
class UrlLauncherService {
  const UrlLauncherService();

  /// Abre la URL en un In-App Browser (Custom Tabs en Android, Safari en iOS)
  /// con fallback a la aplicación externa de Mercado Pago o navegador del sistema.
  Future<bool> openUrl(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }

    try {
      final bool launchedInApp = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (launchedInApp) {
        return true;
      }

      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}

/// Provider del servicio de lanzamiento de URLs.
final Provider<UrlLauncherService> urlLauncherServiceProvider =
    Provider<UrlLauncherService>((Ref ref) => const UrlLauncherService());
