# 📱 ClinApp — Resumen Integral del Proyecto

> **Fecha de actualización**: 24 de octubre de 2026  
> **Ubicación objetivo**: General Alvear, Mendoza, Argentina 🇦🇷  
> **Plataformas**: Android & iOS (Flutter)  
> **Estado de compilación y pruebas**: 74 tests unitarios y de widgets superados con éxito (**100% passing**), análisis estático estricto en cero advertencias (**0 warnings**).

---

## 1. 📌 Ficha Técnica y Visión del Producto

**ClinApp** es una aplicación móvil de pedidos a domicilio (*delivery*) creada específicamente para la comunidad y comercios de **General Alvear, Mendoza**. Combina una experiencia de usuario de nivel internacional inspirada en la estética **Liquid Glass (iOS 26)** con una identidad profundamente local.

### Especificaciones de Identidad y Negocio
* **Idioma y tono**: Español rioplatense con voseo nativo (*"Pedí"*, *"Elegí"*, *"Seguilo"*, *"Buscá"*). Textos 100% centralizados en [`AppStrings`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/core/l10n/app_strings.dart).
* **Moneda**: Pesos argentinos (ARS). Los montos se modelan y almacenan en centavos (enteros) y se renderizan formateados con punto separador de miles (ej. `$14.600`) mediante [`MoneyFormatter`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/core/utils/money_formatter.dart).
* **Zona Horaria y Localización**: `America/Argentina/Mendoza` (vía paquete `timezone`) y locale fijado en `es_AR`.
* **Cálculo de Totales**: Principio de autoridad del backend: la app muestra estimaciones y la Edge Function del servidor valida y determina los montos finales.

---

## 2. 🛠️ Stack Tecnológico

| Capa | Tecnologías |
| :--- | :--- |
| **Framework & Lenguaje** | Flutter 3.x / Dart 3.13+ con Sound Null Safety y modos estrictos (`strict-casts`, `strict-inference`, `strict-raw-types`). |
| **Gestión de Estado** | Riverpod (`flutter_riverpod` v3.4+) con Notifiers y separación estricta de controladores de UI. |
| **Navegación** | GoRouter (`go_router` v18.1+) con navegación indexada persistente (`StatefulShellRoute`). |
| **Backend & Base de Datos** | Supabase (PostgreSQL 15+, Supabase Auth, Row Level Security, Supabase Realtime, Storage). |
| **Pagos & Checkout** | Mercado Pago Marketplace integrado mediante Supabase Edge Functions (`crear-pago`, `webhook-mercadopago`, `mp-oauth`). |
| **Almacenamiento Seguro** | `flutter_secure_storage` para tokens de sesión y preferencias de tema. |
| **Iconografía & Tipografía** | `lucide_icons_flutter` (Lucide Icons) y tipografía empaquetada **Inter** en assets. |
| **Internacionalización** | `intl` (`es_AR`) y `timezone`. |
| **Testing & Calidad** | `flutter_test`, `flutter_lints` con reglas estrictas de tipado. |

---

## 3. 🏛️ Arquitectura del Software (Feature-First)

El proyecto sigue una estructura limpia por funcionalidades (*feature-first*), garantizando desacoplamiento, facilidad para pruebas y mantenimiento:

```
lib/
├── app.dart                   # Widget raíz ClinApp con MaterialApp.router y AppTheme
├── main.dart                  # Punto de entrada con inicialización bootstrap()
├── core/                      # Infraestructura global compartida
│   ├── config/                # Variables de entorno (Env), bootstrap y cliente Supabase
│   ├── errors/                # Tipos de error de dominio (AppException, ServerException, etc.)
│   ├── l10n/                  # Textos y constantes de idioma rioplatense (AppStrings)
│   ├── router/                # Rutas nominales (AppRoutes) y configuración de GoRouter
│   ├── theme/                 # Paleta adaptable, tokens Liquid Glass, modo oscuro/claro y tipografía
│   └── utils/                 # Formateador de dinero (MoneyFormatter) y fechas de Mendoza
├── shared/widgets/            # Componentes reutilizables de UI (Liquid Glass)
└── features/                  # Módulos de funcionalidad independientes
    ├── auth/                  # Inicio de sesión, registro y validadores
    ├── home/                  # Portada, comercios alvearenses, carrusel y último pedido
    ├── search/                # Buscador con debounce, filtros e historial persistente
    ├── checkout/              # Carrito, cupones, dirección y cotización autoritativa
    ├── orders/                # Stepper de estados, seguimiento Realtime y comprobantes
    ├── settings/              # Perfil de usuario, direcciones, saldo ClinPay y selector de tema
    ├── panels/                # Paneles de gestión por rol (Admin, Local y Repartidor)
    └── dev/                   # Catálogo interactivo de componentes para desarrollo
```

---

## 4. 🎨 Sistema de Diseño: Liquid Glass (iOS 26) y Modo Dual

ClinApp implementa un lenguaje visual translúcido adaptativo para día y noche, fundamentado en los diseños de Google Stitch:

### 4.1 Modos de Visualización (Claro / Oscuro / Sistema)
* **Modo Oscuro (*Deep Glass*)**: Fondo espacial profundo (`#07090E`), orbes de luz naranja-coral (`#E8523A`), tarjetas de vidrio oscuro con reflejos especulares de 1px.
* **Modo Claro (*Daylight Glass*)**: Fondo off-white luminoso (`#F8F9FA`), orbes suaves coral/durazno, superficies translúcidas blancas (`rgba(255,255,255,0.7)`) y tipografía oscura `#0F172A` de alto contraste.
* **Selector Dinámico**: Configurado en la pantalla de Perfil con 3 alternativas (`Claro`, `Oscuro`, `Sistema`), administrado por [`ThemeModeNotifier`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/core/theme/theme_mode_provider.dart) y respaldado en almacenamiento seguro.
* **Tokens Dinámicos**: Implementados mediante `ThemeExtension<AppPalette>`, permitiendo a cualquier widget acceder a `context.palette` con soporte inmediato de temas sin romper la estética de vidrio.

### 4.2 Presupuesto y Eficiencia de Rendimiento
* `BackdropFilter` es un widget costoso en dispositivos móviles. ClinApp incluye [`GlassQuality`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/shared/widgets/glass_quality.dart), que aplica un límite estricto de **máximo 3 blurs por pantalla** y aísla capas con `RepaintBoundary` para garantizar 60 fps constantes.

### 4.3 Catálogo de Componentes de Vidrio Compartidos
Ubicados en [`lib/shared/widgets/`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/shared/widgets/):
* [`GlassSurface`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/shared/widgets/glass_surface.dart): Base para superficies con desenfoque, gradiente translúcido y borde brillante.
* [`GlassCard`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/shared/widgets/glass_card.dart): Tarjetas con esquinas curvas (20–28dp) e interacción táctil.
* [`GlassButton`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/shared/widgets/glass_button.dart): Botones píldora (primarios en coral, secundarios de vidrio translúcido).
* [`GlassTextField`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/shared/widgets/glass_text_field.dart): Campos de texto con foco translúcido y validación visual.
* [`GlassChip`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/shared/widgets/glass_chip.dart): Chips interactivos para filtros y categorías.
* [`GlassSheet`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/shared/widgets/glass_sheet.dart): Hojas inferiores modales translúcidas para detalles y recibos.
* [`GlassNavBar`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/shared/widgets/glass_nav_bar.dart): Barra de navegación flotante inferior de 4 iconos con animación de píldora activa.
* Componentes de soporte: [`EmptyState`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/shared/widgets/empty_state.dart), [`ErrorState`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/shared/widgets/error_state.dart), [`LoadingSkeleton`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/shared/widgets/loading_skeleton.dart), [`PriceText`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/shared/widgets/price_text.dart), [`RatingPill`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/shared/widgets/rating_pill.dart) y [`StatusBadge`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/shared/widgets/status_badge.dart).

---

## 5. 📱 Módulos y Pantallas Implementadas

### 5.1 Shell Principal de Navegación (`AppShell`)
Contenedor con `StatefulShellRoute` que mantiene vivas las 4 ramas primarias del usuario, flotando sobre ellas la `GlassNavBar`.

#### 🏠 1. Inicio (`/inicio` — [`HomeScreen`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/features/home/presentation/home_screen.dart))
* **Top Bar**: Isologotipo ClinApp, selector de ubicación local (*"General Alvear, Mendoza"*), campana de avisos y avatar.
* **Banner de Saludo y Promo**: *"¡Buenas tardes, Lautaro! ¿Qué te pedimos hoy?"* y promociones locales destacadas.
* **Repetir Último Pedido (`LastOrderCard`)**: Tarjeta de acceso rápido con items previos, total en pesos y botón de reorden de un toque.
* **Carrusel de Categorías (`CategoryCarousel`)**: Iconos interactivos de gastronomía alvearense (Pizzas, Empanadas, Lomos, Vinos Alvearenses, etc.).
* **Comercios Sugeridos (`MerchantCard`)**: Tarjetas de locales con imagen de portada, badge de tiempo estimado, calificación y costo de envío.

#### 🔍 2. Buscar (`/buscar` — [`SearchScreen`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/features/search/presentation/search_screen.dart))
* **Barra con Debounce**: Entrada rápida con botón para limpiar consulta.
* **Búsquedas Recientes**: Historial en memoria/repositorio con borrado individual o limpieza masiva (*"Borrar todo"*).
* **Chips de Filtrado Rápido**: Filtros combinables de *Envío gratis*, *Más rápido*, *Mejor valorados* y *Promociones*.
* **Comercios Sugeridos & Plato Insignia**: Resultados en tiempo real mostrando platos insignia del local y precios en centavos formateados.

#### 📦 3. Pedidos (`/pedidos` — [`OrdersScreen`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/features/orders/presentation/orders_screen.dart))
* **Selector Segmentado**: Alternador entre pedido *Activo* e *Historial*.
* **Seguimiento en Vivo (5 etapas)**: Stepper visual adaptativo:
  1. `Confirmado` ➜ 2. `En la cocina` ➜ 3. `En camino` ➜ 4. `En la puerta` ➜ 5. `Entregado`.
* **Tarjeta de Seguimiento Activo**: Mapa simulado, datos del repartidor alvearense con moto y tiempo estimado de llegada.
* **Banner de Ayuda/Soporte**: Enlace directo a atención y soporte alvearense.
* **Historial Completo & Recibo**: Listado de compras pasadas y modal [`OrderReceiptSheet`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/features/orders/presentation/widgets/order_receipt_sheet.dart) con desglose fiscal y botón para descargar/compartir comprobante.

#### 👤 4. Perfil y Ajustes (`/perfil` — [`ProfileScreen`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/features/settings/presentation/profile_screen.dart))
* **Encabezado de Usuario**: Foto de perfil, nombre, teléfono (`+54 9 2625 ...`) y badge de verificación.
* **Fila de Métricas**: Saldo en ClinPay ($12.000), puntos acumulados (480 pts) y total de pedidos realizados.
* **Grupos de Ajustes (`AccountSettingsGroup`)**:
  * *Mis Direcciones*: Modal de domicilios guardados con alias (*Casa*, *Trabajo*).
  * *Métodos de Pago*: Tarjetas guardadas y billeteras digitales.
  * *Configuración de la App*: Selector modal del tema (**Claro**, **Oscuro**, **Sistema**) con actualización inmediata.
  * *Ayuda y Preguntas Frecuentes*.
* **Roles Especiales**: Accesos directos condicionales a los paneles de gestión según el rol de la cuenta.

---

### 5.2 Flujos Adicionales (Rutas Modales)

#### 🛒 Carrito y Checkout (`/checkout` — [`CheckoutScreen`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/features/checkout/presentation/checkout_screen.dart))
* Resumen de items del carrito con control de cantidades.
* Tarjeta de dirección de entrega en General Alvear.
* Canje de cupones de descuento con validación.
* Selector de medios de pago: Mercado Pago, Efectivo contra entrega o Saldo ClinPay.
* Desglose de importes: Subtotal, Costo de entrega, Descuento y Total en centavos.
* Botón de pago protegido que solicita la cotización oficial y abre la hoja de confirmación.

#### 🔐 Autenticación (`/login` y `/registro`)
* [`LoginScreen`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/features/auth/presentation/login_screen.dart): Ingreso con correo electrónico y contraseña o acceso con Google/Apple.
* [`RegisterScreen`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/features/auth/presentation/register_screen.dart): Formulario con validación en vivo del formato telefónico de General Alvear (`+54 9 2625 ...`) e indicador gráfico de robustez de contraseña ([`PasswordStrengthIndicator`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/features/auth/presentation/widgets/password_strength_indicator.dart)).

#### 🛠️ Paneles de Gestión por Rol (`lib/features/panels/`)
* **Panel de Repartidor (`/panel/repartidor`)**: Toggle de turno (En servicio / Fuera de servicio), pedidos asignados listos para retirar, mapa de ruta hasta el domicilio del cliente y balance de ganancias del día con opción de liquidación.
* **Panel de Comercio (`/panel/local`)**: Conmutador de estado del restaurante (Abierto / Pausado), cola de comandas entrantes, tiempos de preparación y métricas de facturación del turno.
* **Panel de Administrador (`/panel/admin`)**: Vista global de General Alvear con métricas de facturación bruta, comisiones de la plataforma, comercios activos y estado de la flota de repartidores.

#### 🧪 Catálogo de Componentes Dev (`/dev/catalogo`)
* Pantalla de laboratorio interna para verificar el comportamiento de todos los componentes Liquid Glass en diferentes resoluciones (desde 320px hasta 430px de ancho) y bajo diferentes factores de accesibilidad de escala de texto (hasta 1.5x).

---

## 6. 🗄️ Backend y Base de Datos (Supabase)

El backend está modelado con más de 25 migraciones SQL en [`supabase/migrations/`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/supabase/migrations/):

### 6.1 Tablas y Esquema Relacional
* **`profiles`**: Usuarios con nombre, teléfono alvearense, avatar y rol asignado (`cliente`, `repartidor`, `comercio`, `admin`).
* **`merchants`**: Comercios locales (nombre, rubro, logo, portada, horarios de atención, coordenadas y estado operativo).
* **`products` & `categories`**: Menús de cada comercio con variantes y precios en centavos.
* **`orders` & `order_items`**: Pedidos con estados de seguimiento, repartidor asignado, comercio, importes y método de pago.
* **`delivery_zones`**: Geocercas y radios de envío en General Alvear.
* **`chat_messages`**: Mensajería directa entre cliente y repartidor durante la entrega.
* **`push_subscriptions`**: Tokens para notificaciones de cambio de estado.

### 6.2 Seguridad y Row Level Security (RLS)
* Políticas RLS activas en el 100% de las tablas. Los clientes solo leen sus propios pedidos; los comercios solo acceden a sus ventas; los repartidores solo visualizan los pedidos asignados o disponibles en su zona.

### 6.3 Edge Functions (`supabase/functions/`)
* `crear-pedido`: Valida los precios actuales en la base de datos y calcula los totales oficiales.
* `crear-pago`: Genera la preferencia oficial de Mercado Pago asociada al pedido.
* `webhook-mercadopago`: Escucha las notificaciones IPN para confirmar el cobro y mover el pedido a `Confirmado`.
* `mp-oauth`: Flujo de conexión para que los comercios de Alvear cobren en sus cuentas de Mercado Pago.
* `send-push`: Envío automático de notificaciones a través de FCM/APNs en transiciones de estado.

### 6.4 Modo Semilla / Desarrollo Autónomo
* La app detecta si faltan las variables en `.env` e inicia de forma transparente en **modo de catálogo local de General Alvear**, permitiendo navegar y probar todas las vistas sin necesidad de una instancia activa de Supabase.

---

## 7. 🧪 Pruebas Automatizadas y Calidad

El proyecto posee una suite completa de pruebas unitarias y de integración de widgets en [`test/`](file:///c:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/test/):

* **74 tests automatizados**:
  * Navegación y preservación de estado con `StatefulShellRoute` y `GlassNavBar`.
  * Modo claro, modo oscuro y persistencia de `ThemeModeNotifier`.
  * Correcta renderización y formato de moneda en `$14.600` sin decimales sueltos.
  * Formateo de fechas y horas en zona de Mendoza.
  * Comportamiento de búsqueda, debounce, filtros cruzados y borrado de historial.
  * Stepper y ciclo de vida de pedidos en tiempo real.
  * Validación en vivo de formularios de registro y fortaleza de contraseñas.
  * Paneles de Repartidor, Comercio y Admin.
  * Pruebas de accesibilidad y ausencia de overflow en pantallas pequeñas (320px) con escalado de texto al 150%.
* **Análisis estático (`flutter analyze`)**: 0 errores y 0 advertencias con la configuración más estricta de Dart.

---

## 8. 🚀 Cómo Ejecutar y Probar la Aplicación

### Comandos Principales
```bash
# 1. Modo desarrollo local (con datos semilla de General Alvear)
flutter run

# 2. Conectado al backend de Supabase
flutter run --dart-define-from-file=.env

# 3. Ejecución de toda la suite de pruebas
flutter test

# 4. Verificación de análisis estático estricto
flutter analyze

# 5. Formateo de código Dart
dart format .
```

### Rutas recomendadas para inspeccionar en la app:
* `/inicio`: Exploración de la vidriera comercial alvearense.
* `/buscar`: Búsqueda interactiva y filtrado de productos.
* `/pedidos`: Monitoreo del pedido activo con el stepper de 5 etapas.
* `/perfil`: Métricas y cambio de tema (Claro / Oscuro / Sistema).
* `/checkout`: Flujo de confirmación y pago.
* `/dev/catalogo`: Catálogo técnico de componentes Liquid Glass.
* `/panel/repartidor`, `/panel/local` y `/panel/admin`: Herramientas de operación por rol.
