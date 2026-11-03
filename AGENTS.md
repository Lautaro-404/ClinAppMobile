# Contexto del proyecto
ClinApp es una app móvil de pedidos a domicilio (delivery) para General Alvear,
Mendoza, Argentina. Plataformas: Android e iOS (Flutter).
Idioma de la interfaz: español rioplatense (voseo: "Pedí", "Elegí",
"Seguilo", "Buscá").
Moneda: pesos argentinos (ARS). Formato: $14.600 (punto como separador de
miles).
Zona horaria: America/Argentina/Mendoza.
Locale: es_AR.

# Stack
- Flutter (último estable) + Dart 3 con null safety y sound mode
- Backend: Supabase (PostgreSQL, Auth, Realtime, Storage, Edge Functions)
  con el paquete `supabase_flutter`
- Pagos: Mercado Pago. La preferencia de pago se crea SIEMPRE en una Edge
  Function de Supabase, nunca en la app.
- Estado y datos del servidor: Riverpod (`flutter_riverpod` + `riverpod_annotation`)
- Navegación: `go_router`
- Modelos: `freezed` + `json_serializable`
- Formularios y validación: `reactive_forms` o `Form` nativo con validadores propios
- Formato de montos y fechas: `intl` (es_AR) y `timezone`
- Íconos: `lucide_icons` (o `lucide_icons_flutter`)
- Tipografía: Inter con `google_fonts` (o empaquetada en assets)
- Almacenamiento seguro: `flutter_secure_storage`
- Mapas (seguimiento): `flutter_map` u opción equivalente acordada antes de agregarla
- Tests: `flutter_test`, `mocktail`

# Reglas de código
- Dart estricto: prohibido usar `dynamic` y `as` sin validar. Activar
  `strict-casts`, `strict-inference` y `strict-raw-types` en
  `analysis_options.yaml`.
- Usar `flutter_lints` o `very_good_analysis`. Cero warnings.
- Widgets pequeños y composables. Un widget público por archivo.
  Preferir `StatelessWidget` / `ConsumerWidget`. Usar `StatefulWidget` solo
  para estado puramente local de UI (controladores, animaciones).
- Usar `const` siempre que se pueda.
- Estructura por funcionalidad (feature-first):
  lib/features/<nombre>/{data,domain,presentation}
  - data: repositorios, fuentes de datos (Supabase), DTOs
  - domain: entidades y contratos de repositorio
  - presentation: pantallas, widgets, providers/controladores
- Código compartido:
  - lib/core: tema, constantes, router, utilidades, errores, config
  - lib/shared/widgets: componentes de UI reutilizables (incluye los de Liquid Glass)
- Todo el texto visible va en español rioplatense. Nada de texto en inglés
  en la UI. Centralizar los textos (l10n con `.arb` o archivo de strings), no
  dejarlos dispersos en los widgets.
- Los montos se guardan en centavos (enteros) y se formatean solo al
  mostrarlos, con un único formateador en lib/core.
- NUNCA calcular totales de un pedido solo en el cliente: el servidor es la
  fuente de verdad. La app solo muestra una estimación y confirma con la
  respuesta del servidor.
- NUNCA hardcodear claves o secretos. Usar `--dart-define` o
  `--dart-define-from-file` y mantener un `.env.example` documentado.
  Nunca commitear `.env` ni claves privadas. Solo la anon key pública de
  Supabase puede ir en el cliente.
- Manejo de errores: nada de `catch` vacíos. Usar tipos de error propios y
  mostrar mensajes amigables en español. Estados de carga, vacío y error en
  cada pantalla que consuma datos.
- Sin lógica de negocio dentro de los widgets: va en controladores/providers y
  repositorios.
- Fechas siempre convertidas a America/Argentina/Mendoza al mostrarlas.

# Diseño (Liquid Glass)
- La fuente de verdad visual son los diseños de Google Stitch ubicados en
  la carpeta `/design` (capturas y/o HTML exportado). Respetarlos.
- Estilo Liquid Glass inspirado en iOS 26: tema oscuro, fondo en degradado
  profundo con manchas de luz rojo-naranja, superficies de vidrio translúcido
  (blur de fondo, transparencia 10-18%, borde de 1px blanco al 15-25%, brillo
  especular superior), esquinas muy redondeadas (24-32), botones tipo píldora.
- Color de acento: rojo-naranja #E8523A aprox. Tipografía: Inter.
- Mobile first: diseñar para 390px de ancho. Soportar pantallas chicas y
  grandes sin overflow, y respetar `SafeArea` y el teclado.
- Definir tokens de diseño (colores, radios, espaciados de 8px, sombras,
  estilos de texto) en lib/core/theme. Prohibido usar valores mágicos sueltos
  en los widgets.
- Crear widgets de vidrio reutilizables en lib/shared/widgets
  (ej. `GlassCard`, `GlassButton`, `GlassNavBar`, `GlassChip`,
  `GlassTextField`) basados en `BackdropFilter` + `ImageFilter.blur`.
- Rendimiento: `BackdropFilter` es costoso. Limitar su cantidad por pantalla,
  usar `RepaintBoundary` donde corresponda, evitar blur dentro de listas
  largas sin necesidad y verificar con DevTools que no haya jank.
- Barra de navegación inferior flotante de vidrio en forma de píldora.

# Accesibilidad
- Botones con solo ícono: `Semantics`/`tooltip` con etiqueta en español.
- Áreas táctiles de al menos 48x48 dp.
- Contraste de texto suficiente sobre el vidrio (verificar sobre fondos
  claros y oscuros del degradado).
- Foco y estados visibles. Respetar el escalado de texto del sistema.

# Seguridad
- Row Level Security (RLS) activo en todas las tablas de Supabase.
- Validar toda entrada del usuario en cliente Y en servidor.
- No registrar datos personales ni tokens en logs.

# Flujo de trabajo
- Antes de escribir código, explicá brevemente el plan en 3 a 6 líneas.
- Hacé cambios pequeños y enfocados. No refactorices archivos que no sean
  parte de la tarea.
- Para tareas grandes, primero presentá un plan por etapas y esperá
  confirmación antes de implementar.
- Al terminar, corré y corregí los errores de:
  1. `dart format .`
  2. `flutter analyze`
  3. `flutter test`
  4. Si hay generación de código: `dart run build_runner build --delete-conflicting-outputs`
- Si algo no está claro, preguntá antes de asumir.
- Al final, listá los archivos creados o modificados y cómo probar el
  cambio (comando para correr la app y qué pantalla/flujo verificar).