# Guía de Configuración Manual: Notificaciones Push (Firebase FCM & APNs)

Esta guía detalla los pasos manuales para habilitar las notificaciones push en producción para Android e iOS en **ClinApp**.

---

## 1. Configuración del Proyecto en Firebase Console

1. Accedé a [Firebase Console](https://console.firebase.google.com/) y creá un nuevo proyecto (o seleccioná el existente para ClinApp).
2. Asegurate de habilitar **Cloud Messaging** (FCM).

---

## 2. Configuración para Android

1. En la consola de Firebase, seleccioná **Agregar app** -> icono de **Android**.
2. **Nombre de paquete**: ingresá `ar.com.clinapp` (coincidente con `android/app/build.gradle.kts`).
3. (Opcional recomendado) Agregá las huellas digitales SHA-1 y SHA-256 de tu clave de firma (para debug podés obtenerlas con `cd android && ./gradlew signingReport`).
4. Descargá el archivo **`google-services.json`**.
5. Colocalo en:
   ```text
   android/app/google-services.json
   ```
   *(Este archivo ya está ignorado en `.gitignore` para no filtrar credenciales).*
6. El archivo `android/app/build.gradle.kts` ya está preparado para aplicar automáticamente `com.google.gms.google-services` en cuanto detecta la presencia de este archivo.

---

## 3. Configuración para iOS (Apple Developer & APNs)

### A. Crear clave de autenticación APNs (.p8)
1. Entrá al [Apple Developer Portal](https://developer.apple.com/account/) con tu cuenta de desarrollador.
2. Navegá a **Certificates, Identifiers & Profiles** -> **Keys**.
3. Creá una nueva clave, asignale un nombre (ej. `ClinApp APNs Key`) y tildá **Apple Push Notifications service (APNs)**.
4. Descargá el archivo `.p8` y anotá tu **Key ID** y el **Team ID** de tu cuenta de Apple.

### B. Vincular APNs en Firebase
1. En Firebase Console, andá a **Configuración del proyecto** (icono de engranaje) -> solapa **Cloud Messaging**.
2. Bajá hasta la sección **Configuración de apps para Apple**.
3. En la sección **Clave de autenticación de APNs**, hacé clic en **Subir**.
4. Cargá el archivo `.p8`, ingresá el **Key ID** y el **Team ID**.

### C. Descargar y registrar GoogleService-Info.plist
1. En Firebase Console, registrá la app de iOS con Bundle ID `ar.com.clinapp` (o el configurado en Xcode).
2. Descargá **`GoogleService-Info.plist`**.
3. Abrí el proyecto en Xcode (`open ios/Runner.xcworkspace`).
4. Arrastrá el archivo `GoogleService-Info.plist` a la carpeta `Runner` dentro del navegador de Xcode, asegurándote de marcar la casilla **"Copy items if needed"** y agregar al target **`Runner`**.
   *(La ruta en disco debe ser `ios/Runner/GoogleService-Info.plist`, la cual ya está protegida en `.gitignore`).*

### D. Capacidades en Xcode
1. En Xcode, seleccioná el target `Runner` y andá a la pestaña **Signing & Capabilities**.
2. Hacé clic en **+ Capability**:
   - Agregá **Push Notifications**.
   - Agregá **Background Modes** y verificá que estén tildadas:
     - `Remote notifications`
     - `Background fetch`
   *(Estas opciones ya se encuentran declaradas en `ios/Runner/Info.plist`).*

---

## 4. Configuración del Backend (Supabase Edge Function)

La función `send-push` (`supabase/functions/send-push/index.ts`) despacha notificaciones automáticamente a los clientes según el tipo de suscripción:
- Navegadores Web: protocolo estándar `web-push` (VAPID).
- Dispositivos móviles (Android/iOS): Firebase Cloud Messaging (FCM).

### Secretos requeridos en Supabase:
Configurá tu clave de servidor de Firebase en los secretos de Supabase mediante el CLI:
```bash
supabase secrets set FCM_SERVER_KEY="TU_CLAVE_DE_SERVIDOR_FCM"
```
*(Podés obtener la clave de servidor en Firebase Console -> Configuración del proyecto -> Cloud Messaging -> Cloud Messaging API heredada / Server Key).*

### Migraciones de Base de Datos:
Asegurate de aplicar la migración que habilita la actualización RLS de suscripciones:
```bash
supabase db push
```
O ejecutá en el SQL Editor de Supabase:
```sql
CREATE POLICY "Usuarios pueden actualizar sus propias suscripciones"
ON public.push_subscriptions FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
```

---

## 5. Modo de Desarrollo y Tests Automatizados

Para asegurar que los tests unitarios y el desarrollo local no dependan de credenciales de Firebase:
- Si `Firebase.initializeApp()` no encuentra las credenciales o no fue inicializado (ej. en `flutter test`), el sistema conmuta automáticamente a **`FakePushService`**.
- Los tests corren 100% aislados en memoria sin requerir conexión a internet ni tokens reales.
