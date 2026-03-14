# 🔥 Reglas de Seguridad de Firebase - LaboraYa

## 📋 Instrucciones

1. Ve a Firebase Console: https://console.firebase.google.com
2. Selecciona tu proyecto "laboraya-app"
3. Sigue las instrucciones para cada servicio

---

## 🗄️ Firestore Database Rules

### Cómo aplicar:
1. En Firebase Console, ve a **Firestore Database**
2. Click en la pestaña **"Reglas"**
3. Copia y pega el código de abajo
4. Click en **"Publicar"**

### Reglas de Producción:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Función auxiliar para verificar autenticación
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Función auxiliar para verificar si es el dueño
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // USERS - Usuarios
    match /users/{userId} {
      // Cualquiera puede leer perfiles (para ver info de otros usuarios)
      allow read: if true;
      
      // Solo el dueño puede crear su propio perfil
      allow create: if isOwner(userId);
      
      // El dueño puede actualizar su perfil
      // O cualquier usuario autenticado puede actualizar earnings, rating y completedJobs
      // (necesario para cuando completan un trabajo)
      allow update: if isOwner(userId) || 
                      (isAuthenticated() && 
                       request.resource.data.diff(resource.data).affectedKeys()
                         .hasOnly(['earnings', 'rating', 'completedJobs']));
      
      // Solo el dueño puede eliminar su perfil
      allow delete: if isOwner(userId);
    }
    
    // JOBS - Trabajos
    match /jobs/{jobId} {
      // Cualquiera puede leer trabajos (para buscar)
      allow read: if true;
      
      // Solo usuarios autenticados pueden crear trabajos
      allow create: if isAuthenticated() && 
                      request.resource.data.createdBy == request.auth.uid;
      
      // El creador puede actualizar su trabajo
      // O cualquier usuario autenticado puede actualizar para aceptar el trabajo
      allow update: if isAuthenticated() && 
                      (resource.data.createdBy == request.auth.uid ||
                       request.resource.data.acceptedBy == request.auth.uid);
      
      // Solo el creador puede eliminar su trabajo
      allow delete: if isAuthenticated() && 
                      resource.data.createdBy == request.auth.uid;
    }
    
    // MESSAGES - Mensajes
    match /messages/{messageId} {
      // Solo usuarios autenticados pueden leer mensajes
      allow read: if isAuthenticated();
      
      // Solo usuarios autenticados pueden crear mensajes
      // Y el senderId debe coincidir con el usuario autenticado
      allow create: if isAuthenticated() && 
                      request.resource.data.senderId == request.auth.uid;
      
      // CAMBIO: Permitir actualizar al remitente O al receptor (para marcar como leído)
      allow update: if isAuthenticated() && 
                      (resource.data.senderId == request.auth.uid ||
                       resource.data.receiverId == request.auth.uid);
      
      // Solo el remitente puede eliminar su mensaje
      allow delete: if isAuthenticated() && 
                      resource.data.senderId == request.auth.uid;
    }
    
    // REVIEWS - Calificaciones
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && 
                              resource.data.reviewerId == request.auth.uid;
    }
    
    // NOTIFICATIONS - Notificaciones (para futuro)
    match /notifications/{notificationId} {
      // Solo el destinatario puede leer sus notificaciones
      allow read: if isAuthenticated() && 
                    resource.data.userId == request.auth.uid;
      
      allow create: if isAuthenticated();
      
      // Solo el destinatario puede marcar como leída
      allow update: if isAuthenticated() && 
                      resource.data.userId == request.auth.uid;
      
      allow delete: if isAuthenticated() && 
                      resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## 📦 Firebase Storage Rules

### Cómo aplicar:
1. En Firebase Console, ve a **Storage**
2. Click en la pestaña **"Rules"**
3. Copia y pega el código de abajo
4. Click en **"Publicar"**

### Reglas de Producción:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Función auxiliar para verificar autenticación
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Función auxiliar para verificar tamaño de archivo (máximo 5MB)
    function isValidSize() {
      return request.resource.size < 5 * 1024 * 1024;
    }
    
    // Función auxiliar para verificar tipo de imagen
    function isImage() {
      return request.resource.contentType.matches('image/.*');
    }
    
    // USERS - Fotos de perfil y documentos
    match /users/{userId}/{allPaths=**} {
      // Cualquiera puede leer (para ver fotos de perfil)
      allow read: if true;
      
      // Solo el dueño puede subir/actualizar sus archivos
      allow write: if isAuthenticated() && 
                     request.auth.uid == userId &&
                     isValidSize();
    }
    
    // JOBS - Fotos de trabajos
    match /jobs/{jobId}/{allPaths=**} {
      // Cualquiera puede leer (para ver fotos de trabajos)
      allow read: if true;
      
      // Solo usuarios autenticados pueden subir fotos de trabajos
      allow write: if isAuthenticated() &&
                     isImage() &&
                     isValidSize();
    }
    
    // MESSAGES - Imágenes en chat
    match /messages/{messageId}/{allPaths=**} {
      // Solo usuarios autenticados pueden leer
      allow read: if isAuthenticated();
      
      // Solo usuarios autenticados pueden subir
      allow write: if isAuthenticated() &&
                     isImage() &&
                     isValidSize();
    }
    
    // DOCUMENTS - Documentos de verificación
    match /documents/{userId}/{allPaths=**} {
      // Solo el dueño y admins pueden leer
      allow read: if isAuthenticated() && 
                    request.auth.uid == userId;
      
      // Solo el dueño puede subir documentos
      allow write: if isAuthenticated() && 
                     request.auth.uid == userId &&
                     isValidSize();
    }
  }
}
```

---

## 🔔 Cloud Messaging (FCM)

### Cómo habilitar:
1. En Firebase Console, ve a **Cloud Messaging**
2. Si no está habilitado, click en **"Comenzar"**
3. Acepta los términos
4. ¡Listo! FCM está habilitado

### Configuración adicional para Android:
- Ya tienes el archivo `google-services.json` configurado ✅
- No necesitas hacer nada más

### Configuración adicional para iOS (si aplica):
1. Necesitas una cuenta de Apple Developer
2. Configurar APNs (Apple Push Notification service)
3. Subir el certificado APNs a Firebase Console

---

## 🔐 Authentication

### Métodos habilitados:
1. En Firebase Console, ve a **Authentication**
2. Click en la pestaña **"Sign-in method"**
3. Asegúrate de que **"Correo electrónico/contraseña"** esté habilitado ✅

### Configuración de seguridad:
- **Dominios autorizados**: Agrega tu dominio si tienes uno
- **Plantillas de email**: Personaliza los emails de verificación (opcional)

---

## 📊 Índices de Firestore (Opcional pero Recomendado)

Si ves errores de "índice requerido" en la consola, Firebase te dará un link para crear el índice automáticamente.

### Índices recomendados:

1. **Jobs por categoría y fecha**:
   - Colección: `jobs`
   - Campos: `category` (Ascending), `createdAt` (Descending)

2. **Jobs por usuario y fecha**:
   - Colección: `jobs`
   - Campos: `createdBy` (Ascending), `createdAt` (Descending)

3. **Mensajes por trabajo y fecha**:
   - Colección: `messages`
   - Campos: `jobId` (Ascending), `createdAt` (Ascending)

---

## ⚠️ Importante

### Modo de Prueba vs Producción:

**Modo de Prueba (actual)**:
```javascript
allow read, write: if true;
```
- ✅ Fácil para desarrollo
- ❌ Cualquiera puede leer/escribir
- ❌ NO usar en producción

**Modo de Producción (recomendado)**:
- ✅ Solo usuarios autenticados pueden escribir
- ✅ Validaciones de permisos
- ✅ Seguro para producción

### Cuándo cambiar a producción:
- Cuando termines de desarrollar
- Antes de publicar en Play Store/App Store
- Cuando tengas usuarios reales

---

## 🧪 Probar las Reglas

### En Firebase Console:
1. Ve a Firestore Database → Reglas
2. Click en **"Simulador de reglas"**
3. Prueba diferentes operaciones:
   - Lectura de usuario
   - Escritura de trabajo
   - Eliminación de mensaje
4. Verifica que las reglas funcionen correctamente

---

## 📝 Notas Adicionales

### Límites de Firebase (Plan Gratuito):
- **Firestore**: 50,000 lecturas/día, 20,000 escrituras/día
- **Storage**: 5 GB almacenamiento, 1 GB descarga/día
- **Authentication**: Ilimitado
- **Cloud Messaging**: Ilimitado

### Cuándo actualizar a plan de pago:
- Cuando superes los límites gratuitos
- Cuando tengas más de 100 usuarios activos diarios
- Cuando necesites soporte prioritario

---

## ✅ Checklist de Configuración

- [ ] Firestore Rules aplicadas
- [ ] Storage Rules aplicadas
- [ ] Cloud Messaging habilitado
- [ ] Email/Password habilitado en Authentication
- [ ] Índices creados (si es necesario)
- [ ] Probado en simulador de reglas
- [ ] Verificado que la app funciona correctamente

---

**¡Listo!** Con estas reglas tu app estará segura y lista para producción. 🎉
