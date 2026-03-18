# DOCUMENTACIÓN LABORAYA - PARTE 4

## PANTALLAS ADICIONALES

### CONFIGURACIÓN (settings/)

#### 1. SettingsScreen
**Archivo:** `settings_screen.dart`
**Función:** Configuración de la app
**Opciones:**
- Cambiar contraseña
- Notificaciones
- Usuarios bloqueados
- Cambiar correo electrónico (diálogo)
- Modo oscuro (toggle)
- Centro de ayuda (diálogo)
- Acerca de (diálogo)
- Términos y condiciones
- Política de privacidad
- **Eliminar cuenta:**
  * Pide contraseña para confirmar
  * Re-autentica usuario
  * Elimina TODOS los datos:
    - Trabajos publicados
    - Mensajes enviados/recibidos
    - Notificaciones
    - Solicitudes de trabajo
    - Favoritos
    - Reportes
    - Calificaciones
    - Bloqueos
    - Portafolio
    - Verificaciones
    - Referidos
  * Elimina documento de usuario en Firestore
  * Elimina cuenta de Authentication
  * Cierra sesión y redirige a WelcomeScreen

#### 2. ChangePasswordScreen
**Archivo:** `change_password_screen.dart`
**Función:** Cambiar contraseña
**Campos:**
- Contraseña actual
- Nueva contraseña
- Confirmar nueva contraseña
**Proceso:**
1. Re-autentica con contraseña actual
2. Actualiza contraseña en Firebase Auth

#### 3. BlockedUsersScreen
**Archivo:** `blocked_users_screen.dart`
**Función:** Ver y gestionar usuarios bloqueados
**Muestra:**
- Lista de usuarios bloqueados
- Foto, nombre
- Fecha de bloqueo
- Botón "Desbloquear"
**Datos en Firebase:**
- Colección: `blocked_users`
- Campos: {blockerId, blockedId, createdAt}

#### 4. NotificationSettingsScreen
**Archivo:** `notification_settings_screen.dart`
**Función:** Configurar notificaciones
**Opciones:**
- Notificaciones push (on/off)
- Sonido
- Vibración
- Tipos de notificaciones a recibir

---

### MAPA (map/)

#### MapScreen
**Archivo:** `map_screen.dart`
**Función:** Ver trabajos en mapa
**Elementos:**
- Mapa con flutter_map
- Marcadores de trabajos
- Ubicación actual del usuario
- Al tocar marcador: muestra info del trabajo
- Botón para ir a detalles

---

### ESTADÍSTICAS (stats/)

#### EarningsStatsScreen
**Archivo:** `earnings_stats_screen.dart`
**Función:** Estadísticas de ganancias
**Muestra:**
- Gráficos de ganancias por mes
- Total ganado
- Promedio por trabajo
- Trabajos completados
- Categorías más trabajadas

---

### VERIFICACIÓN (verification/)

#### 1. VerifyIdentityScreen
**Archivo:** `verify_identity_screen.dart`
**Función:** Verificar identidad
**Proceso:**
1. Seleccionar tipo de documento (DNI, Pasaporte, etc.)
2. Ingresar número de documento
3. Subir foto frontal
4. Subir foto posterior
5. Enviar para revisión
**Estados:**
- Pendiente
- Aprobado
- Rechazado

#### 2. VerifyPhoneScreen
**Archivo:** `verify_phone_screen.dart`
**Función:** Verificar número de teléfono
**NOTA:** Funcionalidad eliminada según instrucciones del usuario

---

### REFERIDOS (referrals/)

#### ReferralScreen
**Archivo:** `referral_screen.dart`
**Función:** Sistema de referidos
**Elementos:**
- Código de referido personal
- Botón para compartir código
- Lista de personas referidas
- Bonos ganados por referidos

---

### REPORTES (report/)

#### ReportScreen
**Archivo:** `report_screen.dart`
**Función:** Reportar usuario
**Campos:**
- Motivo (dropdown):
  * Comportamiento inapropiado
  * Fraude
  * Spam
  * Contenido ofensivo
  * Otro
- Descripción detallada
**Proceso:**
1. Valida campos
2. Guarda en colección `reports`
3. Envía notificación a administradores

---

### ONBOARDING (onboarding/)

#### OnboardingScreen
**Archivo:** `onboarding_screen.dart`
**Función:** Tutorial inicial
**Pantallas:**
1. Bienvenida a LaboraYa
2. Busca trabajos cerca de ti
3. Publica tus servicios
4. Chatea y coordina
**Muestra:**
- Solo después de crear cuenta nueva
- NO aparece al abrir la app
- Puede saltarse

---

### LEGAL (legal/)

#### 1. TermsScreen
**Archivo:** `terms_screen.dart`
**Función:** Términos y condiciones
**Muestra:** Texto legal de términos de uso

#### 2. PrivacyScreen
**Archivo:** `privacy_screen.dart`
**Función:** Política de privacidad
**Muestra:** Texto legal de privacidad

---

## WIDGETS REUTILIZABLES (lib/widgets/)

### COMMON (common/)

#### 1. CustomButton
**Archivo:** `custom_button.dart`
**Props:**
- text (String)
- onPressed (Function)
- color (Color, default: primary)
- icon (IconData, opcional)
- isLoading (bool, default: false)
**Diseño:**
- Botón con bordes redondeados
- Muestra loading spinner cuando isLoading=true
- Icono opcional a la izquierda

#### 2. WhatsAppIcon
**Archivo:** `whatsapp_icon.dart`
**Función:** Icono de WhatsApp personalizado
**Uso:** En perfiles de usuario para abrir chat de WhatsApp

---

### JOB (job/)

#### 1. JobCard
**Archivo:** `job_card.dart`
**Props:**
- job (JobModel)
- onTap (Function)
**Muestra:**
- Imagen o gradiente
- Título y categoría
- Pago
- Ubicación y distancia
- Badge "Urgente" si aplica
- Estado del trabajo

#### 2. JobActionButtons
**Archivo:** `job_action_buttons.dart`
**Props:**
- job (JobModel)
- currentUser (UserModel)
- onStatusChanged (Function)
**Función:** Botones dinámicos según estado del trabajo
**Estados y botones:**

**Para trabajador:**
- available: "Mensaje" + "Solicitar"
- accepted: "En camino" + "Chat"
- on_the_way: "Iniciar" + "Chat"
- in_progress: "Terminado" + "Chat"
- finished_by_worker: "Esperando confirmación" + "Chat"
- completed: "¡Completado!" + estrellas

**Para cliente (dueño):**
- available: "Esperando aceptación"
- accepted/on_the_way/in_progress: Estado + "Chat"
- finished_by_worker: "Confirmar" + "Chat"
- confirmed_by_client: "Calificar"
- completed: "¡Completado!"

**Diálogo de solicitud:**
- Pantalla completa (fullscreenDialog: true)
- Fondo azul degradado
- Icono grande del trabajo
- Consejos para destacar
- Campo de texto (8 líneas, 500 caracteres)
- Botón "Enviar Solicitud"

#### 3. JobProgressBar
**Archivo:** `job_progress_bar.dart`
**Props:**
- status (String)
**Muestra:** Barra de progreso visual del estado del trabajo

