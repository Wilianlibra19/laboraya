# DOCUMENTACIÓN LABORAYA - PARTE 5

## FLUJOS PRINCIPALES DE LA APLICACIÓN

### FLUJO 1: REGISTRO Y AUTENTICACIÓN

1. **Splash Screen**
   - Muestra logo
   - Verifica autenticación
   - Si no hay usuario → WelcomeScreen
   - Si hay usuario → MainScreen

2. **Registro**
   - Usuario ingresa datos (nombre, email, teléfono, contraseña)
   - Teléfono es OBLIGATORIO (mínimo 9 caracteres)
   - Crea cuenta en Firebase Auth
   - Crea documento en Firestore con datos del usuario
   - Muestra OnboardingScreen
   - Redirige a MainScreen

3. **Login**
   - Usuario ingresa email y contraseña
   - Autentica con Firebase Auth
   - Carga datos del usuario desde Firestore
   - Redirige a MainScreen

---

### FLUJO 2: PUBLICAR TRABAJO

1. **Seleccionar tipo de publicación**
   - Toggle: "Trabajo puntual" o "Contrato"

2. **Si es Trabajo Puntual:**
   - Llenar: Título, Categoría, Descripción
   - Configurar pago: Monto, Tipo (por trabajo/día/hora)
   - Seleccionar duración: Corto/Mediano/Largo plazo
   - Agregar ubicación (manual o GPS)
   - Subir fotos (opcional, máx 5)
   - Publicar

3. **Si es Contrato:**
   - Llenar: Título, Categoría, Descripción del puesto
   - Condiciones económicas: Salario, Frecuencia de pago, Beneficios
   - Duración y modalidad: Tipo de vínculo, Duración, Modalidad (presencial/remoto/híbrido), Horario
   - Requisitos: Experiencia, educación, habilidades
   - Ubicación
   - Archivos adjuntos
   - Publicar

4. **Proceso de guardado:**
   - Sube imágenes a Cloudinary
   - Crea JobModel con todos los datos
   - Guarda en Firestore colección `jobs`
   - Muestra mensaje de éxito
   - Regresa a pantalla anterior

---

### FLUJO 3: SOLICITAR TRABAJO

1. **Usuario ve trabajo disponible**
   - Entra a JobDetailScreen
   - Presiona botón "Solicitar"

2. **Pantalla de solicitud (fullscreen)**
   - Muestra título del trabajo
   - Consejos para destacar
   - Campo de mensaje (8 líneas, 500 caracteres)
   - Usuario escribe por qué es el indicado

3. **Envío de solicitud:**
   - Verifica que no haya aplicado antes
   - Crea JobApplicationModel
   - Guarda en colección `job_applications`
   - Envía notificación al publicador
   - Muestra mensaje de éxito

4. **Publicador revisa solicitudes:**
   - Ve lista en JobApplicationsScreen
   - Revisa perfil y mensaje de cada aplicante
   - Acepta una solicitud

5. **Al aceptar:**
   - Cambia estado del trabajo a 'accepted'
   - Asigna acceptedBy al trabajador
   - Rechaza automáticamente otras solicitudes
   - Envía notificación al trabajador aceptado
   - Envía notificaciones a rechazados

---

### FLUJO 4: REALIZAR TRABAJO (Estados)

**Estado 1: ACCEPTED (Aceptado)**
- Trabajador ve botón "En camino"
- Cliente ve "Trabajo aceptado" + Chat

**Estado 2: ON_THE_WAY (En camino)**
- Trabajador presiona "En camino"
- Actualiza jobStatus a 'on_the_way'
- Trabajador ve botón "Iniciar"
- Cliente ve "En camino" + Chat

**Estado 3: IN_PROGRESS (En progreso)**
- Trabajador presiona "Iniciar"
- Actualiza jobStatus a 'in_progress'
- Trabajador ve botón "Terminado"
- Cliente ve "En progreso" + Chat

**Estado 4: FINISHED_BY_WORKER (Terminado por trabajador)**
- Trabajador presiona "Terminado"
- Actualiza jobStatus a 'finished_by_worker'
- Trabajador ve "Esperando confirmación"
- Cliente ve botón "Confirmar"

**Estado 5: CONFIRMED_BY_CLIENT (Confirmado por cliente)**
- Cliente presiona "Confirmar"
- Actualiza jobStatus a 'confirmed_by_client'
- Cliente ve botón "Calificar"
- Trabajador ve "Completado"

**Estado 6: COMPLETED (Completado)**
- Cliente califica al trabajador
- Guarda rating y comentario
- Actualiza rating del trabajador
- Actualiza totalEarnings y completedJobs
- Actualiza jobStatus a 'completed'
- Ambos ven "¡Completado!" con estrellas

---

### FLUJO 5: CALIFICACIÓN

**Calificar al trabajador (Cliente):**
1. Trabajo en estado 'confirmed_by_client'
2. Cliente presiona "Calificar"
3. Abre RateWorkerScreen (pantalla completa)
4. Muestra diálogo verde con:
   - Icono grande de éxito
   - "¡Trabajo Terminado!" (36px)
   - Tarjeta con info del trabajador
   - Estrellas para calificar (1-5)
   - Campo de comentario
5. Cliente califica y envía
6. Actualiza:
   - job.ratingWorker
   - job.commentWorker
   - user.rating (promedio)
   - user.totalReviews
   - user.completedJobs
   - user.totalEarnings
7. Cambia estado a 'completed'
8. Recarga datos del usuario

**Calificar al cliente (Trabajador):**
- Similar pero califica al publicador
- Actualiza job.ratingClient y job.commentClient

---

### FLUJO 6: CHAT

1. **Iniciar conversación:**
   - Desde JobDetailScreen presiona "Mensaje"
   - Abre ChatScreen con jobId y otherUserId

2. **Enviar mensaje:**
   - Usuario escribe texto
   - Presiona enviar
   - Crea MessageModel
   - Guarda en colección `messages`
   - Envía notificación al receptor

3. **Recibir mensajes:**
   - Stream en tiempo real desde Firestore
   - Marca como leído automáticamente
   - Actualiza badge de no leídos

4. **Opciones adicionales:**
   - Menú de 3 puntos
   - Bloquear usuario
   - Reportar usuario

---

### FLUJO 7: BLOQUEAR USUARIO

1. **Desde Chat o Perfil:**
   - Usuario presiona menú de 3 puntos
   - Selecciona "Bloquear usuario"

2. **Confirmación:**
   - Muestra diálogo de confirmación
   - Explica que no podrán contactarse

3. **Proceso:**
   - Crea documento en colección `blocked_users`
   - Estructura: {blockerId, blockedId, createdAt}
   - Guarda en Firebase

4. **Ver bloqueados:**
   - Configuración → Usuarios bloqueados
   - Lista de usuarios bloqueados
   - Opción para desbloquear

---

### FLUJO 8: REPORTAR USUARIO

1. **Desde Chat o Perfil:**
   - Usuario presiona menú de 3 puntos
   - Selecciona "Reportar usuario"

2. **Formulario de reporte:**
   - Selecciona motivo (dropdown)
   - Escribe descripción detallada
   - Presiona "Enviar reporte"

3. **Proceso:**
   - Crea ReportModel
   - Guarda en colección `reports`
   - Envía notificación a administradores
   - Muestra mensaje de confirmación

---

### FLUJO 9: ELIMINAR CUENTA

1. **Configuración → Eliminar cuenta**
2. **Confirmación con contraseña:**
   - Muestra diálogo pidiendo contraseña
   - Usuario ingresa contraseña actual
3. **Re-autenticación:**
   - Verifica contraseña con Firebase Auth
4. **Eliminación de datos:**
   - Elimina trabajos publicados
   - Elimina mensajes (enviados y recibidos)
   - Elimina notificaciones
   - Elimina solicitudes de trabajo
   - Elimina favoritos
   - Elimina reportes
   - Elimina calificaciones
   - Elimina bloqueos
   - Elimina portafolio
   - Elimina verificaciones
   - Elimina referidos
   - Elimina documento de usuario en Firestore
5. **Elimina cuenta de Authentication**
6. **Cierra sesión**
7. **Redirige a WelcomeScreen**

---

## FIREBASE STRUCTURE

### Collections (Colecciones)

#### 1. users
```
{
  id: string
  name: string
  email: string
  phone: string
  photo: string (URL)
  rating: number
  totalReviews: number
  totalEarnings: number
  completedJobs: number
  skills: array<string>
  availability: string
  createdAt: timestamp
}
```

#### 2. jobs
```
{
  id: string
  title: string
  description: string
  category: string
  payment: number
  paymentType: string
  latitude: number
  longitude: number
  address: string
  createdBy: string (userId)
  acceptedBy: string (userId, nullable)
  status: string
  jobStatus: string
  images: array<string>
  ratingWorker: number (nullable)
  commentWorker: string (nullable)
  ratingClient: number (nullable)
  commentClient: string (nullable)
  createdAt: timestamp
  acceptedAt: timestamp (nullable)
  completedAt: timestamp (nullable)
}
```

#### 3. messages
```
{
  id: string
  senderId: string
  receiverId: string
  jobId: string
  text: string
  imageUrl: string (nullable)
  isRead: boolean
  createdAt: timestamp
}
```

#### 4. job_applications
```
{
  id: string
  jobId: string
  applicantId: string
  message: string
  status: string ('pending', 'accepted', 'rejected')
  createdAt: timestamp
}
```

#### 5. favorites
```
{
  id: string
  userId: string
  jobId: string
  createdAt: timestamp
}
```

#### 6. notifications
```
{
  id: string
  userId: string
  title: string
  message: string
  type: string
  isRead: boolean
  createdAt: timestamp
}
```

#### 7. reports
```
{
  id: string
  reporterId: string
  reportedId: string
  reason: string
  description: string
  status: string
  createdAt: timestamp
}
```

#### 8. blocked_users
```
{
  id: string
  blockerId: string
  blockedId: string
  createdAt: timestamp
}
```

#### 9. reviews
```
{
  id: string
  jobId: string
  reviewerId: string
  reviewedId: string
  rating: number
  comment: string
  createdAt: timestamp
}
```

#### 10. portfolio
```
{
  id: string
  userId: string
  title: string
  description: string
  images: array<string>
  createdAt: timestamp
}
```

#### 11. verifications
```
{
  id: string
  userId: string
  idType: string
  idNumber: string
  frontImage: string
  backImage: string
  status: string
  createdAt: timestamp
}
```

#### 12. referrals
```
{
  id: string
  referrerId: string
  referredId: string
  code: string
  createdAt: timestamp
}
```

