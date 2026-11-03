# Plan de Implementación: Modo Claro ("Liquid Glass Light") en ClinApp

## Decisiones confirmadas
- **Tema inicial por defecto**: Modo del sistema (`ThemeMode.system`).
- **Ubicación del selector**: En el panel de Configuración de la pantalla de Perfil (`ProfileDetailSheets.showAppSettings`).
- **Opciones disponibles**: 3 opciones (`Claro`, `Oscuro`, `Sistema`).

---

## 1. Análisis de los Archivos de Diseño (`desing/stitch_clinapp_delivery_mendoza/`)
Se exploraron los 15 archivos y 8 carpetas exportados de Google Stitch:
- `liquid_glass_light/DESIGN.md`: Especificación de tokens de luz diurna, transparencias y sombras.
- `inicio_clinapp_light/`: Pantalla de inicio con fondo off-white (`#F8F9FA`), orbes coral/durazno, tarjetas de locales y carrusel de categorías.
- `buscar_clinapp_light/`: Buscador con chips de filtros rápidos, historial reciente y locales sugeridos con plato insignia.
- `pedidos_clinapp_light/`: Segmented tab, stepper de 4 etapas, mapa de seguimiento y tarjeta de repartidor.
- `panel_de_pago_clinapp_light/`: Resumen de pedido, selector de pagos, cupón y barra de pago inferior flotante.
- `perfil_clinapp_light/`: Métricas de usuario, grupos de gestión y opciones de cuenta en vidrio blanco translúcido.
- `iniciar_sesi_n_clinapp_light/` y `registro_clinapp_light/`: Formularios de autenticación con mascota oficial, textos oscuros `#0F172A` y botones píldora.

---

## 2. Plan Técnico y Arquitectura
- **Gestión de Tema**: `NotifierProvider<ThemeModeNotifier, ThemeMode>` con Riverpod y persistencia en `FlutterSecureStorage`.
- **Tokens Dinámicos**: `ThemeExtension<AppPalette>` que suministra colores semánticos, rellenos de vidrio (`glassFill1..3`, `glassFillFloating`), bordes especulares y sombras según el brillo activo (`dark` vs `light`).
- **Compatibilidad**: Los widgets leen la paleta adaptativa sin perder el estilo Liquid Glass ni generar saltos visuales.

---

## 3. Fases de Ejecución
- **Fase 1**: Definición de `AppPalette`, `AppTheme.light`, `themeModeProvider` y conexión en `ClinApp` (`lib/app.dart`).
- **Fase 2**: Adaptación de widgets base (`GlassBackground`, `GlassSurface`, `GlassNavBar`, `GlassButton`, `GlassCard`, `GlassChip`, `GlassTextField`, `GlassSheet`).
- **Fase 3**: Integración del selector de tema de 3 opciones en Configuración y adaptación de pantallas de Auth y Perfil.
- **Fase 4**: Ajustes de contraste en Inicio, Búsqueda, Pedidos y Checkout.
- **Fase 5**: Validación estricta con `dart format .`, `flutter analyze` y `flutter test`.
