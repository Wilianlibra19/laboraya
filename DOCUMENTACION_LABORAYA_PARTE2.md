# DOCUMENTACIÓN LABORAYA - PARTE 2

## SERVICIOS (Continuación)

### 6. FavoriteService
**Archivo:** `favorite_service.dart`
**Funciones principales:**
- `addFavorite(userId, jobId)` - Agregar a favoritos
- `removeFavorite(userId, jobId)` - Quitar de favoritos
- `getFavorites(userId)` - Obtener favoritos del usuario
- `isFavorite(userId, jobId)` - Verificar si es favorito

### 7. NotificationService
**Archivo:** `notification_service.dart`
**Funciones principales:**
- `createNotification(userId, title, message, type)` - Crear notificación
- `getNotifications(userId)` - Obtener notificaciones
- `markAsRead(notificationId)` - Marcar como leída
- `getUnreadCount(userId)` - Contar no leídas

### 8. ReportService
**Archivo:** `report_service.dart`
**Funciones principales:**
- `reportUser(reporterId, reportedId, reason, description)` - Reportar usuario
- `getReports()` - Obtener reportes (admin)

### 9. VerificationService
**Archivo:** `verification_service.dart`
**Funciones principales:**
- `submitVerification(userId, idType, idNumber, frontImage, backImage)` - Enviar verificación
- `getVerificationStatus(userId)` - Estado de verificación

### 10. ReferralService
**Archivo:** `referral_service.dart`
**Funciones principales:**
- `generateReferralCode(userId)` - Generar código de referido
- `useReferralCode(userId, code)` - Usar código de referido
- `getReferrals(userId)` - Obtener referidos

### 11. PortfolioService
**Archivo:** `portfolio_service.dart`
**Funciones principales:**
- `addPortfolioItem(userId, title, description, images)` - Agregar item
- `getPortfolio(userId)` - Obtener portafolio
- `deletePortfolioItem(itemId)` - Eliminar item

### 12. CloudinaryService
**Archivo:** `cloudinary_service.dart`
**Funciones principales:**
- `uploadImage(imagePath, folder)` - Subir imagen
- `uploadMultipleImages(imagePaths, folder)` - Subir múltiples imágenes
- Configuración: Cloud name, API key, API secret

### 13. LocationService
**Archivo:** `location_service.dart`
**Funciones principales:**
- `getCurrentLocation()` - Obtener ubicación GPS actual
- `checkPermissions()` - Verificar permisos de ubicación
- `requestPermissions()` - Solicitar permisos

### 14. ThemeService
**Archivo:** `theme_service.dart`
**Funciones principales:**
- `toggleTheme()` - Cambiar entre modo claro/oscuro
- `isDarkMode` - Estado del tema actual
- Usa Provider para gestión de estado

---

## PANTALLAS PRINCIPALES (lib/screens/)

### AUTENTICACIÓN (auth/)

#### 1. SplashScreen
**Archivo:** `splash_screen.dart`
**Función:** Pantalla inicial con logo
**Flujo:**
- Muestra logo de LaboraYa
- Verifica si hay usuario autenticado
- Redirige a WelcomeScreen o MainScreen

#### 2. WelcomeScreen
**Archivo:** `welcome_screen.dart`
**Función:** Pantalla de bienvenida
**Elementos:**
- Logo grande
- Botones "Iniciar Sesión" y "Registrarse"

#### 3. LoginScreen
**Archivo:** `login_screen.dart`
**Función:** Inicio de sesión
**Campos:**
- Email
- Contraseña
**Acciones:**
- Login con Firebase Auth
- Enlace a recuperar contraseña
- Enlace a registro

#### 4. RegisterScreen
**Archivo:** `register_screen.dart`
**Función:** Registro de nuevo usuario
**Campos:**
- Nombre completo
- Email
- Teléfono (obligatorio, mínimo 9 caracteres)
- Contraseña
- Confirmar contraseña
**Proceso:**
1. Validar campos
2. Crear usuario en Firebase Auth
3. Crear documento en Firestore
4. Mostrar onboarding
5. Redirigir a MainScreen

---

### HOME (home/)

#### 1. HomeScreen
**Archivo:** `home_screen.dart`
**Función:** Pantalla principal
**Secciones:**
- Header con saludo y foto de perfil
- Barra de búsqueda
- Categorías (grid horizontal)
- Trabajos cercanos
- Todos los trabajos (lista)
**Filtros:**
- Por categoría
- Por distancia
- Por pago
- Por urgencia

#### 2. CategoryJobsScreen
**Archivo:** `category_jobs_screen.dart`
**Función:** Trabajos de una categoría específica
**Muestra:**
- Lista de trabajos filtrados por categoría
- Icono de la categoría en header

#### 3. NearbyJobsScreen
**Archivo:** `nearby_jobs_screen.dart`
**Función:** Trabajos cercanos a la ubicación actual
**Muestra:**
- Trabajos ordenados por distancia
- Distancia en km

#### 4. FilterScreen
**Archivo:** `filter_screen.dart`
**Función:** Filtros avanzados
**Opciones:**
- Rango de pago (min-max)
- Distancia máxima
- Categorías múltiples
- Solo urgentes
- Ordenar por (fecha, pago, distancia)

---

### TRABAJOS (job/)

#### 1. CreateJobScreen
**Archivo:** `create_job_screen.dart`
**Función:** Publicar nuevo trabajo
**NUEVO DISEÑO CON DOS MODOS:**

**A) TRABAJO PUNTUAL (diseño dinámico)**
- Información Básica: Título, Categoría
- Descripción
- Pago y Duración:
  * Monto (campo grande con gradiente verde)
  * Tipo de pago: Por trabajo completo / Por día / Por hora
  * Duración: Corto plazo / Mediano plazo / Largo plazo
- Ubicación: Dirección + botón GPS
- Fotos: Hasta 5 imágenes

**B) CONTRATO (diseño formal)**
- Información del Puesto: Título, Categoría, Descripción
- Condiciones Económicas:
  * Salario mensual
  * Frecuencia de pago: Semanal / Quincenal / Mensual / Pago único
  * Beneficios adicionales (opcional)
- Duración y Modalidad:
  * Tipo de vínculo: Temporal / Contrato fijo / Proyecto / Permanente
  * Duración: 1 mes / 3 meses / 6 meses / Indefinido
  * Modalidad: Presencial / Remoto / Híbrido
  * Horario esperado
- Requisitos: Experiencia, educación, habilidades
- Ubicación
- Archivos Adjuntos

**Selector al inicio:** Toggle entre "Trabajo puntual" y "Contrato"

