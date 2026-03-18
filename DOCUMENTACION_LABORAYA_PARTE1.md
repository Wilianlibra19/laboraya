# DOCUMENTACIÓN COMPLETA - LABORAYA APP

## INFORMACIÓN GENERAL

**Nombre:** LaboraYa
**Tipo:** Aplicación móvil de búsqueda y publicación de trabajos
**Plataforma:** Flutter (Android/iOS)
**Backend:** Firebase (Firestore, Authentication, Storage)
**Almacenamiento de imágenes:** Cloudinary

---

## ARQUITECTURA DEL PROYECTO

### Estructura de Carpetas

```
lib/
├── core/                    # Lógica de negocio
│   ├── models/             # Modelos de datos
│   ├── repositories/       # Acceso a datos
│   └── services/           # Servicios de negocio
├── data/                   # Capa de datos
│   ├── firebase/          # Implementación Firebase
│   ├── local/             # Almacenamiento local (Hive)
│   └── mock/              # Datos de prueba
├── screens/               # Pantallas de la app
├── widgets/               # Widgets reutilizables
└── utils/                 # Utilidades y constantes
```

---

## MODELOS DE DATOS (lib/core/models/)

### 1. UserModel
**Archivo:** `user_model.dart`
**Campos principales:**
- id, name, email, phone
- photo (URL de foto de perfil)
- rating, totalReviews
- totalEarnings, completedJobs
- skills (lista de habilidades)
- availability (disponibilidad)
- createdAt

### 2. JobModel
**Archivo:** `job_model.dart`
**Campos principales:**
- id, title, description, category
- payment, paymentType
- latitude, longitude, address
- createdBy, acceptedBy
- status ('available', 'accepted', 'on_the_way', 'in_progress', 'finished_by_worker', 'confirmed_by_client', 'completed')
- jobStatus (estado del trabajo)
- images (lista de URLs)
- ratingWorker, commentWorker
- ratingClient, commentClient
- createdAt, acceptedAt, completedAt

### 3. MessageModel
**Archivo:** `message_model.dart`
**Campos principales:**
- id, senderId, receiverId
- jobId (trabajo relacionado)
- text, imageUrl
- isRead, createdAt

### 4. JobApplicationModel
**Archivo:** `job_application_model.dart`
**Campos principales:**
- id, jobId, applicantId
- message (mensaje de solicitud)
- status ('pending', 'accepted', 'rejected')
- createdAt

### 5. FavoriteModel
**Archivo:** `favorite_model.dart`
**Campos principales:**
- id, userId, jobId
- createdAt

### 6. ReportModel
**Archivo:** `report_model.dart`
**Campos principales:**
- id, reporterId, reportedId
- reason, description
- status, createdAt

### 7. ReviewModel
**Archivo:** `review_model.dart`
**Campos principales:**
- id, jobId, reviewerId, reviewedId
- rating, comment
- createdAt

### 8. PortfolioItemModel
**Archivo:** `portfolio_item_model.dart`
**Campos principales:**
- id, userId, title, description
- images, createdAt

---

## SERVICIOS (lib/core/services/)

### 1. UserService
**Archivo:** `user_service.dart`
**Funciones principales:**
- `login(email, password)` - Autenticación
- `register(UserModel)` - Registro de usuario
- `updateProfile(UserModel)` - Actualizar perfil
- `refreshCurrentUser()` - Recargar datos del usuario actual
- `getUserById(userId)` - Obtener usuario por ID
- `logout()` - Cerrar sesión

### 2. JobService
**Archivo:** `job_service.dart`
**Funciones principales:**
- `createJob(JobModel)` - Crear trabajo
- `getJobs()` - Obtener todos los trabajos
- `getJobById(jobId)` - Obtener trabajo por ID
- `getMyJobs(userId)` - Trabajos publicados por usuario
- `getAcceptedJobs(userId)` - Trabajos aceptados por usuario
- `updateJob(JobModel)` - Actualizar trabajo
- `deleteJob(jobId)` - Eliminar trabajo

### 3. JobStatusService
**Archivo:** `job_status_service.dart`
**Funciones principales:**
- `acceptJob(jobId, workerId)` - Aceptar trabajo
- `markOnTheWay(jobId)` - Marcar "en camino"
- `startJob(jobId)` - Iniciar trabajo
- `finishJob(jobId)` - Terminar trabajo (trabajador)
- `confirmJob(jobId)` - Confirmar trabajo (cliente)
- `completeJob(jobId, rating, comment)` - Completar con calificación

### 4. JobApplicationService
**Archivo:** `job_application_service.dart`
**Funciones principales:**
- `applyToJob(jobId, applicant, message)` - Solicitar trabajo
- `getApplicationsForJob(jobId)` - Obtener solicitudes de un trabajo
- `acceptApplication(applicationId, jobId)` - Aceptar solicitud
- `rejectApplication(applicationId)` - Rechazar solicitud
- `hasUserApplied(jobId, userId)` - Verificar si ya aplicó

### 5. MessageService
**Archivo:** `message_service.dart`
**Funciones principales:**
- `sendMessage(MessageModel)` - Enviar mensaje
- `getMessages(jobId, userId, otherUserId)` - Obtener mensajes
- `markAsRead(messageId)` - Marcar como leído
- `getUnreadCount(userId)` - Contar mensajes no leídos

