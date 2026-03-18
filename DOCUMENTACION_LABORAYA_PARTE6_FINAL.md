# DOCUMENTACIÓN LABORAYA - PARTE 6 (FINAL)

## FIREBASE RULES (Reglas de Seguridad)

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Jobs
    match /jobs/{jobId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        (resource.data.createdBy == request.auth.uid || 
         resource.data.acceptedBy == request.auth.uid);
    }
    
    // Messages
    match /messages/{messageId} {
      allow read: if request.auth != null && 
        (resource.data.senderId == request.auth.uid || 
         resource.data.receiverId == request.auth.uid);
      allow create: if request.auth != null && 
        request.resource.data.senderId == request.auth.uid;
      allow update: if request.auth != null && 
        resource.data.receiverId == request.auth.uid;
    }
    
    // Job Applications
    match /job_applications/{applicationId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
        request.resource.data.applicantId == request.auth.uid;
      allow update: if request.auth != null;
    }
    
    // Favorites
    match /favorites/{favoriteId} {
      allow read, write: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
    
    // Notifications
    match /notifications/{notificationId} {
      allow read: if request.auth != null && 
        resource.data.userId == request.auth.uid;
      allow write: if request.auth != null;
    }
    
    // Reports
    match /reports/{reportId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
        request.resource.data.reporterId == request.auth.uid;
    }
    
    // Blocked Users
    match /blocked_users/{blockId} {
      allow read: if request.auth != null;
      allow create, delete: if request.auth != null && 
        request.resource.data.blockerId == request.auth.uid;
    }
    
    // Reviews
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if request.auth != null && 
        request.resource.data.reviewerId == request.auth.uid;
    }
    
    // Portfolio
    match /portfolio/{portfolioId} {
      allow read: if true;
      allow write: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
    
    // Verifications
    match /verifications/{verificationId} {
      allow read, write: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
    
    // Referrals
    match /referrals/{referralId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
  }
}
```

---

## DEPENDENCIAS (pubspec.yaml)

### Principales
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  firebase_storage: ^11.6.0
  cloud_firestore: ^4.14.0
  
  # State Management
  provider: ^6.1.1
  
  # UI
  cupertino_icons: ^1.0.2
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  confetti: ^0.7.0
  
  # Maps & Location
  flutter_map: ^6.1.0
  latlong2: ^0.9.0
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  
  # Images
  image_picker: ^1.0.7
  http: ^1.2.0
  crypto: ^3.0.3
  
  # Utils
  uuid: ^4.3.3
  intl: ^0.18.1
  url_launcher: ^6.2.4
  share_plus: ^7.2.1
  
  # Charts
  fl_chart: ^0.66.0
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.2
```

---

## CONSTANTES (lib/utils/constants.dart)

### AppColors
```dart
class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03A9F4);
  static const Color accent = Color(0xFFFF9800);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
}
```

### CategoryIcons
```dart
class CategoryIcons {
  static const Map<String, IconData> icons = {
    'Construcción': Icons.construction,
    'Limpieza': Icons.cleaning_services,
    'Plomería': Icons.plumbing,
    'Electricidad': Icons.electrical_services,
    'Carpintería': Icons.carpenter,
    'Pintura': Icons.format_paint,
    'Jardinería': Icons.yard,
    'Mudanza': Icons.local_shipping,
    'Reparaciones': Icons.build,
    'Tecnología': Icons.computer,
    // ... más categorías
  };
}
```

---

## HELPERS (lib/utils/helpers.dart)

### Funciones Útiles
```dart
class Helpers {
  // Formatear moneda
  static String formatCurrency(double amount) {
    return 'S/ ${amount.toStringAsFixed(2)}';
  }
  
  // Formatear fecha
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  // Formatear fecha relativa
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return formatDate(date);
    } else if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minutos';
    } else {
      return 'Ahora';
    }
  }
  
  // Calcular distancia
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2
  ) {
    // Fórmula de Haversine
    // Retorna distancia en km
  }
  
  // Abrir WhatsApp
  static Future<void> openWhatsApp(String phone) async {
    final url = 'https://wa.me/$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
  
  // Hacer llamada
  static Future<void> makeCall(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
```

---

## TEMA (lib/utils/app_theme.dart)

### Light Theme
```dart
ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: Colors.grey[50],
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primary,
    elevation: 0,
  ),
  // ... más configuraciones
);
```

### Dark Theme
```dart
ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: Colors.grey[900],
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey[850],
    elevation: 0,
  ),
  // ... más configuraciones
);
```

---

## NAVEGACIÓN

### MainScreen (Bottom Navigation)
**Archivo:** `main_screen.dart`
**Tabs:**
1. Home (HomeScreen)
2. Mapa (MapScreen)
3. Publicar (CreateJobScreen)
4. Mensajes (ChatListScreen)
5. Perfil (ProfileScreen)

**Badge de notificaciones:**
- En tab de Mensajes: muestra cantidad de mensajes no leídos
- En tab de Perfil: muestra cantidad de notificaciones no leídas

---

## CARACTERÍSTICAS ESPECIALES

### 1. Modo Oscuro
- Toggle en Configuración
- Persiste con SharedPreferences
- Cambia todos los colores automáticamente
- Campos de texto oscuros en modo oscuro

### 2. Ubicación en Tiempo Real
- Solicita permisos de ubicación
- Obtiene coordenadas GPS
- Convierte a dirección legible
- Calcula distancia a trabajos

### 3. Subida de Imágenes
- Usa Cloudinary para almacenamiento
- Comprime imágenes antes de subir
- Genera URLs públicas
- Máximo 5 imágenes por trabajo

### 4. Notificaciones en Tiempo Real
- Usa Firestore streams
- Actualiza automáticamente
- Badge con contador
- Navega a pantalla relevante al tocar

### 5. Chat en Tiempo Real
- Mensajes instantáneos con Firestore
- Marca como leído automáticamente
- Soporte para imágenes
- Indicador de mensajes no leídos

### 6. Sistema de Calificaciones
- Estrellas de 1 a 5
- Comentarios opcionales
- Actualiza promedio del usuario
- Muestra en perfil

### 7. Búsqueda y Filtros
- Búsqueda por texto
- Filtro por categoría
- Filtro por rango de pago
- Filtro por distancia
- Ordenar por fecha/pago/distancia

---

## NOTAS IMPORTANTES

### Correcciones Realizadas
1. ✅ Onboarding solo después de registro, no al abrir app
2. ✅ En trabajos completados, mostrar trabajador (acceptedBy) no publicador
3. ✅ Tarjeta de usuario ocupa toda la pantalla (avatar 60px, nombre 28px)
4. ✅ Sistema de bloqueo con menú de 3 puntos en Chat y Perfil
5. ✅ Pantalla de usuarios bloqueados en Configuración
6. ✅ Eliminado "Mi Portafolio" del menú de perfil
7. ✅ Eliminados botones WhatsApp y Llamar del perfil propio
8. ✅ Mejoradas pantallas de configuración
9. ✅ Actualización de ganancias y calificaciones con refreshCurrentUser()
10. ✅ Diálogo "Trabajo Terminado" pantalla completa con diseño verde
11. ✅ Función eliminar cuenta completa (elimina TODOS los datos)
12. ✅ Disponibilidad como selector (no texto libre)
13. ✅ Teléfono obligatorio en registro
14. ✅ Pantalla "Solicitar Trabajo" fullscreen con diseño profesional
15. ✅ Rediseño de "Publicar Trabajo" con dos modos: Trabajo Puntual y Contrato

### Funcionalidades NO Implementadas
- ❌ Sistema de pagos (excluido explícitamente)
- ❌ Verificación de teléfono (eliminada)

### Configuración Requerida
1. Firebase project configurado
2. Cloudinary account con credenciales
3. Permisos de ubicación en AndroidManifest.xml / Info.plist
4. Firebase Rules actualizadas
5. Google Maps API key (para mapas)

---

## COMANDOS ÚTILES

```bash
# Ejecutar app
flutter run

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Limpiar proyecto
flutter clean

# Obtener dependencias
flutter pub get

# Generar código (para modelos)
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## FIN DE LA DOCUMENTACIÓN

Esta documentación cubre TODA la aplicación LaboraYa, incluyendo:
- Arquitectura y estructura
- Todos los modelos de datos
- Todos los servicios
- Todas las pantallas y sus funciones
- Todos los flujos de usuario
- Estructura de Firebase
- Reglas de seguridad
- Dependencias
- Constantes y utilidades
- Características especiales
- Correcciones realizadas

Puedes usar esta documentación para:
- Pasar a GPT para continuar desarrollo
- Onboarding de nuevos desarrolladores
- Referencia técnica
- Documentación de proyecto

