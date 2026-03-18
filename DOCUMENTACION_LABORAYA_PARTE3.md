# DOCUMENTACIÓN LABORAYA - PARTE 3

## PANTALLAS DE TRABAJOS (Continuación)

#### 2. JobDetailScreen
**Archivo:** `job_detail_screen.dart`
**Función:** Detalles completos del trabajo
**Secciones:**
- Header con imagen o gradiente
- Título y categoría
- Pago y tipo de pago
- Descripción completa
- Ubicación con mapa
- Galería de imágenes
- **Perfil del usuario:**
  * Si el trabajo está disponible: muestra el publicador
  * Si está completado/en progreso: muestra el trabajador (acceptedBy)
  * Tarjeta grande con avatar 60px, nombre 28px, fondo gradiente azul
- Botones de acción (según estado)

#### 3. JobApplicationsScreen
**Archivo:** `job_applications_screen.dart`
**Función:** Ver solicitudes de un trabajo publicado
**Muestra:**
- Lista de aplicantes
- Foto, nombre, rating
- Mensaje de solicitud
- Botones: Aceptar / Rechazar
**Proceso al aceptar:**
1. Cambia estado del trabajo a 'accepted'
2. Asigna acceptedBy al aplicante
3. Rechaza automáticamente otras solicitudes
4. Envía notificación al trabajador

#### 4. MyJobApplicationsScreen
**Archivo:** `my_job_applications_screen.dart`
**Función:** Ver mis solicitudes enviadas
**Muestra:**
- Trabajos a los que apliqué
- Estado: Pendiente / Aceptado / Rechazado
- Información del trabajo

#### 5. CompleteJobScreen
**Archivo:** `complete_job_screen.dart`
**Función:** Completar trabajo y calificar
**Campos:**
- Calificación (1-5 estrellas)
- Comentario
**Proceso:**
1. Actualiza estado a 'completed'
2. Guarda calificación y comentario
3. Actualiza rating del usuario calificado
4. Actualiza totalEarnings y completedJobs
5. Recarga datos del usuario actual
6. Muestra diálogo de éxito

#### 6. RateWorkerScreen
**Archivo:** `rate_worker_screen.dart`
**Función:** Calificar al trabajador (cliente)
**Diseño:**
- **Pantalla completa** con fondo verde degradado
- Icono grande (150x150)
- Título "¡Trabajo Terminado!" (36px)
- Tarjeta blanca con información del trabajador
- Muestra nombre del trabajador que completó el trabajo
- Calificación con estrellas
- Campo de comentario

#### 7. RateJobScreen
**Archivo:** `rate_job_screen.dart`
**Función:** Calificar al cliente (trabajador)
**Similar a RateWorkerScreen pero para calificar al publicador**

---

### CHAT (chat/)

#### 1. ChatListScreen
**Archivo:** `chat_list_screen.dart`
**Función:** Lista de conversaciones
**Muestra:**
- Conversaciones activas
- Foto, nombre del otro usuario
- Último mensaje
- Badge con mensajes no leídos
- Ordenado por fecha del último mensaje

#### 2. ChatScreen
**Archivo:** `chat_screen.dart`
**Función:** Conversación individual
**Elementos:**
- Header con foto y nombre del otro usuario
- **Menú de 3 puntos** con opciones:
  * Bloquear usuario
  * Reportar usuario
- Lista de mensajes
- Campo de texto para enviar
- Botón para enviar imagen
- Marca mensajes como leídos automáticamente
**Funcionalidad de bloqueo:**
- Guarda en colección `blocked_users` en Firebase
- Estructura: {blockerId, blockedId, createdAt}

---

### PERFIL (profile/)

#### 1. ProfileScreen
**Archivo:** `profile_screen.dart`
**Función:** Perfil del usuario actual
**Secciones:**
- Header con foto, nombre, rating
- Estadísticas: Trabajos completados, Ganancias
- Botón de refrescar datos
- **NO tiene botones de WhatsApp ni Llamar**
- Menú de opciones:
  * Editar perfil
  * Mis trabajos publicados
  * Historial de trabajos
  * Favoritos
  * Documentos
  * Reseñas
  * Estadísticas de ganancias
  * Referidos
  * Configuración

#### 2. UserProfileScreen
**Archivo:** `user_profile_screen.dart`
**Función:** Ver perfil de otro usuario
**Elementos:**
- Foto, nombre, rating
- Habilidades
- Disponibilidad
- **Menú de 3 puntos** con opciones:
  * Bloquear usuario
  * Reportar usuario
- Botones: WhatsApp, Llamar, Chat
- Reseñas del usuario

#### 3. EditProfileScreen
**Archivo:** `edit_profile_screen.dart`
**Función:** Editar perfil
**Campos:**
- Foto de perfil (cambiar)
- Nombre
- Email (solo lectura)
- Teléfono
- Habilidades (chips)
- **Disponibilidad (dropdown):**
  * Disponible
  * No disponible
  * Disponible fines de semana
  * Disponible entre semana
- Biografía

#### 4. MyJobsScreen
**Archivo:** `my_jobs_screen.dart`
**Función:** Trabajos que publiqué
**Tabs:**
- Activos
- Completados
- Todos
**Acciones:**
- Ver detalles
- Ver solicitudes
- Editar
- Eliminar

#### 5. HistoryScreen
**Archivo:** `history_screen.dart`
**Función:** Historial de trabajos realizados
**Muestra:**
- Trabajos que acepté y completé
- Información del trabajo
- Calificación recibida
- Ganancia obtenida

#### 6. WorkHistoryScreen
**Archivo:** `work_history_screen.dart`
**Función:** Historial detallado de trabajos
**Similar a HistoryScreen con más detalles**

#### 7. ReviewsScreen
**Archivo:** `reviews_screen.dart`
**Función:** Ver reseñas recibidas
**Muestra:**
- Lista de calificaciones
- Foto y nombre del calificador
- Estrellas y comentario
- Fecha

#### 8. PortfolioScreen
**Archivo:** `portfolio_screen.dart`
**Función:** Portafolio de trabajos
**NOTA:** Eliminado del menú de perfil por redundancia
**Permite:**
- Agregar trabajos manualmente
- Subir fotos
- Descripción

---

### FAVORITOS (favorites/)

#### FavoritesScreen
**Archivo:** `favorites_screen.dart`
**Función:** Trabajos guardados como favoritos
**Muestra:**
- Lista de trabajos favoritos
- Botón para quitar de favoritos
- Acceso rápido a detalles

---

### NOTIFICACIONES (notifications/)

#### NotificationsScreen
**Archivo:** `notifications_screen.dart`
**Función:** Centro de notificaciones
**Tipos de notificaciones:**
- Nueva solicitud de trabajo
- Solicitud aceptada/rechazada
- Trabajo iniciado
- Trabajo completado
- Nuevo mensaje
- Calificación recibida
**Elementos:**
- Icono según tipo
- Título y mensaje
- Fecha
- Badge "no leída"
- Acción al tocar (navega a pantalla relevante)

