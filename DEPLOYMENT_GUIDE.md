# Guía de Deployment - LaboraYa App

## 📋 Checklist Pre-Deployment

### 1. Configuración de Firebase ✅
- [x] Proyecto Firebase creado
- [ ] Firebase Rules actualizadas (ver FIREBASE_RULES.md)
- [ ] Índices de Firestore creados
- [ ] Firebase Storage configurado
- [ ] Firebase Authentication habilitado
- [ ] Firebase Cloud Messaging configurado

### 2. Dependencias ✅
- [x] Todas las dependencias instaladas (`flutter pub get`)
- [x] shared_preferences agregado
- [x] Todos los paquetes actualizados

### 3. Configuración de la App
- [ ] Nombre de la app configurado
- [ ] Icono de la app configurado
- [ ] Splash screen configurado
- [ ] Versión de la app actualizada en pubspec.yaml

### 4. Pruebas
- [ ] Pruebas en dispositivo Android
- [ ] Pruebas en dispositivo iOS (si aplica)
- [ ] Pruebas de todas las funcionalidades
- [ ] Pruebas de modo oscuro
- [ ] Pruebas de notificaciones

## 🔧 Pasos de Configuración

### 1. Actualizar Firebase Rules

```bash
# Copiar las rules de FIREBASE_RULES.md
# Ir a Firebase Console > Firestore Database > Rules
# Pegar y publicar
```

### 2. Crear Índices de Firestore

Ir a Firebase Console > Firestore Database > Indexes y crear:

1. **Jobs - Búsqueda**
   - Collection: `jobs`
   - Fields: `status` (Asc), `district` (Asc), `category` (Asc), `createdAt` (Desc)

2. **Jobs - Por trabajador**
   - Collection: `jobs`
   - Fields: `acceptedBy` (Asc), `jobStatus` (Asc), `completedAt` (Desc)

3. **Messages - Chat**
   - Collection: `messages`
   - Fields: `senderId` (Asc), `receiverId` (Asc), `timestamp` (Desc)

4. **Notifications**
   - Collection: `notifications`
   - Fields: `userId` (Asc), `isRead` (Asc), `createdAt` (Desc)

5. **Reviews**
   - Collection: `reviews`
   - Fields: `reviewedUserId` (Asc), `createdAt` (Desc)

6. **Favorites**
   - Collection: `favorites`
   - Fields: `userId` (Asc), `createdAt` (Desc)

7. **Portfolio**
   - Collection: `portfolio`
   - Fields: `userId` (Asc), `createdAt` (Desc)

8. **Referrals**
   - Collection: `referrals`
   - Fields: `referrerId` (Asc), `createdAt` (Desc)

### 3. Configurar Cloudinary

```dart
// Ya configurado en lib/core/services/cloudinary_service.dart
// Asegúrate de tener las credenciales correctas:
// - Cloud Name
// - Upload Preset
```

### 4. Configurar Notificaciones Push

#### Android
1. Descargar `google-services.json` de Firebase Console
2. Colocar en `android/app/`
3. Verificar configuración en `android/app/build.gradle`

#### iOS (si aplica)
1. Descargar `GoogleService-Info.plist` de Firebase Console
2. Colocar en `ios/Runner/`
3. Configurar en Xcode

### 5. Configurar Iconos y Splash

```bash
# Generar iconos
flutter pub run flutter_launcher_icons

# El icono está en: assets/icons/app_icon.png
```

## 🚀 Build para Producción

### Android APK

```bash
# Build APK de release
flutter build apk --release

# El APK estará en: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (para Google Play)

```bash
# Build App Bundle
flutter build appbundle --release

# El bundle estará en: build/app/outputs/bundle/release/app-release.aab
```

### iOS (si aplica)

```bash
# Build para iOS
flutter build ios --release

# Abrir en Xcode para subir a App Store
open ios/Runner.xcworkspace
```

## 📱 Publicación en Stores

### Google Play Store

1. **Crear cuenta de desarrollador** ($25 USD único)
2. **Preparar assets:**
   - Icono de la app (512x512 px)
   - Feature graphic (1024x500 px)
   - Screenshots (mínimo 2, máximo 8)
   - Descripción corta (80 caracteres)
   - Descripción completa (4000 caracteres)

3. **Información requerida:**
   - Nombre de la app: "LaboraYa"
   - Categoría: "Productividad" o "Negocios"
   - Clasificación de contenido
   - Política de privacidad (URL)
   - Términos y condiciones (URL)

4. **Subir App Bundle:**
   - Ir a Google Play Console
   - Crear nueva aplicación
   - Subir `app-release.aab`
   - Completar información
   - Enviar para revisión

### Apple App Store (si aplica)

1. **Crear cuenta de desarrollador** ($99 USD/año)
2. **Preparar assets:**
   - Icono de la app (1024x1024 px)
   - Screenshots para diferentes dispositivos
   - Descripción
   - Keywords

3. **Subir con Xcode:**
   - Abrir proyecto en Xcode
   - Archive > Upload to App Store
   - Completar información en App Store Connect
   - Enviar para revisión

## 🔒 Seguridad

### Variables de Entorno

Crear archivo `.env` (no subir a Git):

```env
CLOUDINARY_CLOUD_NAME=tu_cloud_name
CLOUDINARY_UPLOAD_PRESET=tu_preset
FIREBASE_API_KEY=tu_api_key
```

### Ofuscar Código

```bash
# Build con ofuscación
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

## 📊 Analytics y Monitoreo

### Firebase Analytics

```dart
// Ya configurado en la app
// Ver eventos en Firebase Console > Analytics
```

### Crashlytics

```bash
# Agregar a pubspec.yaml
firebase_crashlytics: ^3.4.0

# Configurar en main.dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
```

## 🧪 Testing

### Pruebas Manuales

- [ ] Login/Registro
- [ ] Crear trabajo
- [ ] Buscar trabajos
- [ ] Aplicar a trabajo
- [ ] Aceptar solicitud
- [ ] Chat
- [ ] Notificaciones
- [ ] Calificaciones
- [ ] Favoritos
- [ ] Configuración
- [ ] Verificación
- [ ] Portafolio
- [ ] Estadísticas
- [ ] Referidos
- [ ] Modo oscuro

### Pruebas Automatizadas

```bash
# Ejecutar tests
flutter test

# Ejecutar tests con coverage
flutter test --coverage
```

## 📝 Documentación para Stores

### Descripción Corta (80 caracteres)
```
Encuentra trabajo cerca de ti. Conecta con trabajadores locales.
```

### Descripción Completa

```
LaboraYa - Tu Plataforma de Trabajo Local

¿Buscas trabajo? ¿Necesitas contratar a alguien? LaboraYa conecta a trabajadores con personas que necesitan servicios en su zona.

🔍 CARACTERÍSTICAS PRINCIPALES:

• Busca trabajos cerca de ti con filtros avanzados
• Publica trabajos y recibe solicitudes
• Chat en tiempo real con empleadores
• Sistema de calificaciones y reseñas
• Notificaciones instantáneas
• Mapa de trabajos disponibles
• Portafolio de trabajos realizados
• Estadísticas de ganancias
• Sistema de referidos
• Verificación de identidad

💼 CATEGORÍAS:

• Limpieza
• Construcción
• Plomería
• Electricidad
• Jardinería
• Pintura
• Carpintería
• Mudanzas
• Reparaciones
• Y muchas más...

✨ BENEFICIOS:

• Encuentra trabajo rápidamente
• Trabaja en tu zona
• Pagos seguros
• Construye tu reputación
• Gana dinero extra

📱 FÁCIL DE USAR:

1. Regístrate gratis
2. Completa tu perfil
3. Busca o publica trabajos
4. Conecta y trabaja

🔒 SEGURO Y CONFIABLE:

• Verificación de identidad
• Sistema de calificaciones
• Reportes de usuarios
• Soporte 24/7

Descarga LaboraYa ahora y empieza a trabajar hoy mismo.
```

### Keywords (Google Play)
```
trabajo, empleo, servicios, trabajadores, freelance, ganancias, local, cerca, plomero, electricista, limpieza, construcción
```

### Categoría
- Principal: Productividad
- Secundaria: Negocios

### Clasificación de Contenido
- Violencia: Ninguna
- Contenido sexual: Ninguno
- Lenguaje: Ninguno
- Drogas: Ninguno
- Edad mínima: 13+

## 🌐 URLs Necesarias

### Política de Privacidad
Crear en: `https://tudominio.com/privacy-policy`

### Términos y Condiciones
Crear en: `https://tudominio.com/terms-of-service`

### Sitio Web
Crear en: `https://tudominio.com`

## 📞 Soporte

### Email de Soporte
```
soporte@laboraya.com
```

### Redes Sociales
- Facebook: @LaboraYaPeru
- Instagram: @laboraya_peru
- Twitter: @LaboraYaPeru

## 🎯 Post-Launch

### Monitoreo
- [ ] Revisar Analytics diariamente
- [ ] Responder reseñas en stores
- [ ] Monitorear crashes
- [ ] Revisar feedback de usuarios

### Marketing
- [ ] Campaña en redes sociales
- [ ] Google Ads
- [ ] Facebook Ads
- [ ] Promociones de lanzamiento

### Actualizaciones
- [ ] Corregir bugs reportados
- [ ] Agregar nuevas funcionalidades
- [ ] Mejorar rendimiento
- [ ] Actualizar dependencias

## ✅ Checklist Final

- [ ] Firebase Rules actualizadas
- [ ] Índices de Firestore creados
- [ ] Cloudinary configurado
- [ ] Notificaciones push configuradas
- [ ] Iconos y splash configurados
- [ ] App testeada completamente
- [ ] Build de release generado
- [ ] Documentación para stores preparada
- [ ] Política de privacidad publicada
- [ ] Términos y condiciones publicados
- [ ] Cuenta de desarrollador creada
- [ ] App subida a stores
- [ ] Marketing preparado

## 🎉 ¡Listo para Lanzar!

Una vez completados todos los pasos, tu app estará lista para ser lanzada al mercado. ¡Éxito! 🚀
