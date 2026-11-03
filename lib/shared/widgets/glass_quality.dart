import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nivel de calidad gráfica para las superficies Liquid Glass.
enum GlassQuality {
  /// Usa `BackdropFilter` con blur en elementos estructurales (máx. 3 por pantalla).
  high,

  /// Desactiva `BackdropFilter` y usa superficies translúcidas con borde especular
  /// para equipos de gama baja o ahorro de batería.
  low;

  bool get usesBlur => this == GlassQuality.high;
}

/// Controlador del nivel de calidad de vidrio en toda la app.
class GlassQualityNotifier extends Notifier<GlassQuality> {
  @override
  GlassQuality build() => GlassQuality.high;

  // ignore: use_setters_to_change_properties
  void setQuality(GlassQuality quality) {
    state = quality;
  }

  void toggle() {
    state = state == GlassQuality.high ? GlassQuality.low : GlassQuality.high;
  }
}

/// Provider global de la calidad de vidrio.
final NotifierProvider<GlassQualityNotifier, GlassQuality>
glassQualityProvider = NotifierProvider<GlassQualityNotifier, GlassQuality>(
  GlassQualityNotifier.new,
);
