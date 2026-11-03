import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clinapp/core/config/env.dart';

/// Controlador reactivo del estado de conectividad de la aplicación.
class ConnectivityNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Actualiza el estado `isOffline` según el resultado de llamadas de red.
  void setOffline(bool isOffline) {
    if (state != isOffline) {
      state = isOffline;
    }
  }

  /// Verifica conectividad activa contra el host de Supabase o DNS público.
  Future<bool> checkConnection() async {
    try {
      final Uri? supabaseUri = Uri.tryParse(Env.supabaseUrl);
      final String host =
          (supabaseUri != null && supabaseUri.host.trim().isNotEmpty)
          ? supabaseUri.host
          : 'supabase.co';

      final List<InternetAddress> result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 4));

      final bool online =
          result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      state = !online;
      return online;
    } on Object {
      state = true;
      return false;
    }
  }
}

/// Provider global que indica si el dispositivo se encuentra sin conexión (`true` = offline).
final NotifierProvider<ConnectivityNotifier, bool> isOfflineProvider =
    NotifierProvider<ConnectivityNotifier, bool>(ConnectivityNotifier.new);
