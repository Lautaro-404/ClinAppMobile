# ClinApp — Pedidos a Domicilio en General Alvear, Mendoza 🇦🇷

**ClinApp** es la plataforma móvil de pedidos a domicilio (*delivery*) diseñada para **General Alvear, Mendoza, Argentina**, construida en **Flutter** (Android e iOS) bajo el sistema de diseño **Liquid Glass (iOS 26)** y conectada a **Supabase** + **Mercado Pago**.

---

## Características principales

- **Identidad local rioplatense (`es_AR`)**: voseo argentino (*"Pedí"*, *"Elegí"*, *"Seguilo"*, *"Buscá"*), montos expresados en centavos y formateados como `$14.600` (punto de miles) y zona horaria fija en `America/Argentina/Mendoza`.
- **Sistema de diseño Liquid Glass**: tema oscuro profundo (`#07090E`) con manchas de luz cálida (`#E8523A`), superficies translúcidas con borde especular de `1px`, degradación automática de desenfoque (`GlassQuality`) y presupuesto estricto de `<= 3` `BackdropFilter` por pantalla con aislamiento `RepaintBoundary`.
- **Arquitectura Feature-First + Riverpod**:
  - `lib/core`: tema, tokens de diseño, formateadores (`MoneyFormatter`, `DateFormatter`), router (`go_router`), errores tipados (`AppException`) y textos centralizados (`AppStrings`).
  - `lib/shared/widgets`: sistema de componentes `GlassSurface`, `GlassCard`, `GlassButton`, `GlassChip`, `GlassTextField`, `GlassSheet`, `GlassNavBar` y `ClinBrandLogo`.
  - `lib/features/home`: pantalla Inicio con ubicación en General Alvear, banner promocional, repetición de último pedido y catálogo de comercios locales.
  - `lib/features/search` y `lib/features/catalog`: buscador con *debounce*, tendencias locales, filtros combinables, detalle de comercio y hoja de personalización de producto.
  - `lib/features/checkout`: carrito sincronizado y checkout con cotización autoritativa desde la Edge Function `quote_order` y creación de preferencia de Mercado Pago vía `create_mp_preference` (nunca se calculan totales finales solo en el cliente).
  - `lib/features/orders`: historial y seguimiento en tiempo real (*Supabase Realtime*) de los 5 estados del pedido (`Confirmado` → `En la cocina` → `En camino` → `En la puerta` → `Entregado`).
  - `lib/features/auth` y `lib/features/settings`: inicio de sesión, registro con prefijo `+54 9 2625`, persistencia segura en `flutter_secure_storage`, perfil de usuario y paneles por rol (`Admin`, `Comercio`, `Repartidor`).

---

## Configuración de variables de entorno

Copiá `.env.example` a `.env` en la raíz del proyecto (nunca subas `.env` al repositorio):

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key-publica
MERCADO_PAGO_PUBLIC_KEY=APP_USR-tu-public-key
APP_ENV=development
```

> **Nota para desarrollo local**: Si ejecutás `flutter run` sin `--dart-define-from-file=.env`, la app inicia automáticamente en **modo catálogo local de General Alvear** con datos realistas para poder probar todas las pantallas sin requerir conexión al backend.

---

## Comandos habituales

### Ejecutar la aplicación
```bash
# Modo desarrollo instantáneo (datos semilla de General Alvear)
flutter run

# Conectado a tu proyecto de Supabase
flutter run --dart-define-from-file=.env
```

### Calidad de código y pruebas
```bash
# Formatear todo el código
dart format .

# Análisis estático estricto (strict-casts, strict-inference, strict-raw-types)
flutter analyze

# Ejecutar toda la suite de tests unitarios y de widgets
flutter test
```
