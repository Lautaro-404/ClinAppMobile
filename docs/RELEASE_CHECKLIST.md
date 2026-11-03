# Checklist de Release para Producción (Android e iOS) — ClinApp

Esta guía detalla todos los requisitos técnicos y regulatorios para compilar, verificar y publicar **ClinApp (General Alvear, Mendoza)** en Google Play Store y Apple App Store.

---

## 1. Separación de Entornos y Variables (`--dart-define-from-file`)

Nunca se debe incluir `SUPABASE_SERVICE_ROLE_KEY` ni tokens privados de Mercado Pago en la app móvil.

| Entorno | Archivo `.env` | Flavor Android | Application ID | Base URL Deep Links |
|---------|----------------|----------------|----------------|---------------------|
| Desarrollo | `.env.dev` | `dev` | `ar.com.clinapp.dev` | `https://dev.clin.app` |
| Staging / QA | `.env.staging` | `staging` | `ar.com.clinapp.staging` | `https://staging.clin.app` |
| Producción | `.env.prod` | `prod` | `ar.com.clinapp` | `https://clin.app` |

### Comandos de compilación por entorno
```bash
# Desarrollo local
flutter run --flavor dev --dart-define-from-file=.env.dev

# Staging / QA (APK para pruebas internas)
flutter build apk --release --flavor staging --dart-define-from-file=.env.staging

# Producción Android (App Bundle firmado para Google Play)
flutter build appbundle --release --flavor prod --dart-define-from-file=.env.prod

# Producción iOS (IPA para App Store Connect / TestFlight)
flutter build ipa --release --dart-define-from-file=.env.prod
```

---

## 2. Firma Digital

### Android (Google Play App Signing)
1. Generar el keystore de subida (fuera del repositorio o en ruta ignorada por git):
   ```bash
   keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Crear `android/key.properties` (ignorado en `.gitignore`):
   ```properties
   storePassword=<TU_STORE_PASSWORD>
   keyPassword=<TU_KEY_PASSWORD>
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```
3. Verificar que `android/app/build.gradle.kts` toma automáticamente el `signingConfig` `release` y aplica R8 (`proguard-rules.pro`).
4. Registrar las huellas **SHA-256** del certificado de subida y del certificado de Google Play App Signing en Firebase Console y en `.well-known/assetlinks.json`.

### iOS (App Store Connect)
1. Abrir `ios/Runner.xcworkspace` en Xcode.
2. En **Signing & Capabilities**:
   - Seleccionar el Team de Apple Developer.
   - Confirmar `Bundle Identifier`: `ar.com.clinapp`.
   - Agregar las capacidades:
     - **Push Notifications** (con clave `.p8` de APNs cargada en Firebase Cloud Messaging).
     - **Background Modes**: `Remote notifications` y `Background fetch`.
     - **Associated Domains**: `applinks:clin.app`.
3. Verificar que `ITSAppUsesNonExemptEncryption = false` está presente en `ios/Runner/Info.plist` para evitar el bloqueo de exportación en TestFlight.

---

## 3. Permisos Declarados (Principio de Mínimo Privilegio)

### Android (`android/app/src/main/AndroidManifest.xml`)
- `android.permission.INTERNET`: Comunicación HTTPS/WSS con Supabase y Mercado Pago.
- `android.permission.POST_NOTIFICATIONS`: Avisos de cambio de estado del pedido en Android 13+.
- `android.permission.VIBRATE`: Confirmación háptica de alertas de pedidos.
- *Nota*: No se solicita ubicación en segundo plano (`ACCESS_BACKGROUND_LOCATION`), evitando revisiones extendidas en Google Play.

### iOS (`ios/Runner/Info.plist` + `ios/Runner/PrivacyInfo.xcprivacy`)
- `NSPhotoLibraryUsageDescription`: Explicación clara en español rioplatense para subir el avatar del perfil.
- `NSCameraUsageDescription`: Explicación clara si el usuario toma una foto para su avatar.
- `PrivacyInfo.xcprivacy`: Manifiesto de privacidad de Apple declarando que **no se realiza tracking publicitario (`NSPrivacyTracking = false`)** y detallando los datos vinculados a la cuenta (nombre, correo, teléfono y dirección de entrega).

---

## 4. Deep Links (Retorno de Mercado Pago y Notificaciones)

### Esquemas soportados en [`AppRouter`](file:///C:/Users/World/OneDrive/Documentos/PROYECTOS/ClinAppMobile/lib/core/router/app_router.dart)
- Custom scheme: `clinapp://pago/resultado?status=approved&order_id=...` y `clinapp://pedidos`
- App Links / Universal Links: `https://clin.app/pago/resultado` y `https://clin.app/pedidos`

### Archivos requeridos en el dominio `https://clin.app`
1. **Android (`https://clin.app/.well-known/assetlinks.json`)**:
   ```json
   [
     {
       "relation": ["delegate_permission/common.handle_all_urls"],
       "target": {
         "namespace": "android_app",
         "package_name": "ar.com.clinapp",
         "sha256_cert_fingerprints": ["REEMPLAZAR_CON_SHA256_DE_PLAY_CONSOLE"]
       }
     }
   ]
   ```
2. **iOS (`https://clin.app/.well-known/apple-app-site-association`)**:
   ```json
   {
     "applinks": {
       "apps": [],
       "details": [
         {
           "appID": "TEAM_ID.ar.com.clinapp",
           "paths": ["/pago/resultado*", "/pedidos*"]
         }
       ]
     }
   }
   ```

---

## 5. Políticas de Privacidad y Borrado de Cuenta (Cumplimiento Tiendas)

1. **Política de Privacidad in-app y web**:
   - Disponible dentro de la app en **Perfil > Ayuda y soporte > Política de Privacidad y Uso de Datos**.
   - Publicar la misma política en `https://clin.app/privacidad` y cargarla en Google Play Console (*App Content > Privacy Policy*) y App Store Connect.
2. **Borrado de Cuenta (Apple Guideline 5.1.1(v) & Google Play User Data Policy)**:
   - **Dentro de la app**: **Perfil > Configuración > Zona de privacidad y cuenta > Eliminar mi cuenta** (con diálogo de confirmación de doble paso).
   - **En el servidor**: Ejecuta la función `public.delete_own_account()` (`SECURITY DEFINER`) que verifica que el usuario no tenga pedidos en curso y elimina de forma atómica sus suscripciones push, favoritos, notificaciones, direcciones, perfil y credencial en `auth.users`.
   - **URL web de baja de cuenta (exigida por Google Play Data Safety)**: Habilitar formulario o instrucciones directas en `https://clin.app/eliminar-cuenta`.
