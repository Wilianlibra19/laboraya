# Firebase Security Rules - LaboraYa App

## Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
    }
    
    // Jobs collection
    match /jobs/{jobId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (
        isOwner(resource.data.userId) || 
        request.auth.uid == resource.data.acceptedBy
      );
      allow delete: if isAuthenticated() && isOwner(resource.data.userId);
    }
    
    // Job Applications collection
    match /job_applications/{applicationId} {
      allow read: if isAuthenticated() && (
        request.auth.uid == resource.data.applicantId ||
        request.auth.uid == resource.data.jobOwnerId
      );
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (
        request.auth.uid == resource.data.applicantId ||
        request.auth.uid == resource.data.jobOwnerId
      );
      allow delete: if isAuthenticated() && request.auth.uid == resource.data.applicantId;
    }
    
    // Messages collection
    match /messages/{messageId} {
      allow read: if isAuthenticated() && (
        request.auth.uid == resource.data.senderId ||
        request.auth.uid == resource.data.receiverId
      );
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (
        request.auth.uid == resource.data.senderId ||
        request.auth.uid == resource.data.receiverId
      );
      allow delete: if isAuthenticated() && request.auth.uid == resource.data.senderId;
    }
    
    // Notifications collection
    match /notifications/{notificationId} {
      allow read: if isAuthenticated() && isOwner(resource.data.userId);
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && isOwner(resource.data.userId);
      allow delete: if isAuthenticated() && isOwner(resource.data.userId);
    }
    
    // Reviews collection
    match /reviews/{reviewId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && isOwner(resource.data.reviewerId);
      allow delete: if isAuthenticated() && isOwner(resource.data.reviewerId);
    }
    
    // Favorites collection
    match /favorites/{favoriteId} {
      allow read: if isAuthenticated() && isOwner(resource.data.userId);
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && isOwner(resource.data.userId);
      allow delete: if isAuthenticated() && isOwner(resource.data.userId);
    }
    
    // Reports collection
    match /reports/{reportId} {
      allow read: if isAuthenticated() && isOwner(resource.data.reporterId);
      allow create: if isAuthenticated();
      allow update: if false; // Solo admins pueden actualizar
      allow delete: if false; // Solo admins pueden eliminar
    }
    
    // Portfolio collection
    match /portfolio/{portfolioId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && isOwner(resource.data.userId);
      allow delete: if isAuthenticated() && isOwner(resource.data.userId);
    }
    
    // Verifications collection
    match /verifications/{verificationId} {
      allow read: if isAuthenticated() && isOwner(resource.data.userId);
      allow create: if isAuthenticated();
      allow update: if false; // Solo admins pueden actualizar
      allow delete: if false; // Solo admins pueden eliminar
    }
    
    // Referrals collection
    match /referrals/{referralId} {
      allow read: if isAuthenticated() && (
        request.auth.uid == resource.data.referrerId ||
        request.auth.uid == resource.data.referredUserId
      );
      allow create: if isAuthenticated();
      allow update: if false;
      allow delete: if false;
    }
  }
}
```

## Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isImage() {
      return request.resource.contentType.matches('image/.*');
    }
    
    function isUnder5MB() {
      return request.resource.size < 5 * 1024 * 1024;
    }
    
    // Profile photos
    match /profile_photos/{userId}/{fileName} {
      allow read: if true; // Públicas
      allow write: if isAuthenticated() && 
                     request.auth.uid == userId && 
                     isImage() && 
                     isUnder5MB();
    }
    
    // Job photos
    match /job_photos/{jobId}/{fileName} {
      allow read: if true; // Públicas
      allow write: if isAuthenticated() && isImage() && isUnder5MB();
    }
    
    // Portfolio photos
    match /portfolio/{userId}/{fileName} {
      allow read: if true; // Públicas
      allow write: if isAuthenticated() && 
                     request.auth.uid == userId && 
                     isImage() && 
                     isUnder5MB();
    }
    
    // Verification documents
    match /verifications/{userId}/{fileName} {
      allow read: if isAuthenticated() && request.auth.uid == userId;
      allow write: if isAuthenticated() && 
                     request.auth.uid == userId && 
                     isImage() && 
                     isUnder5MB();
    }
    
    // Chat media
    match /chat_media/{chatId}/{fileName} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && isImage() && isUnder5MB();
    }
  }
}
```

## Firestore Indexes Necesarios

### 1. Jobs - Búsqueda con filtros
```
Collection: jobs
Fields: 
  - status (Ascending)
  - district (Ascending)
  - category (Ascending)
  - createdAt (Descending)
```

### 2. Jobs - Por trabajador
```
Collection: jobs
Fields:
  - acceptedBy (Ascending)
  - jobStatus (Ascending)
  - completedAt (Descending)
```

### 3. Jobs - Por dueño
```
Collection: jobs
Fields:
  - userId (Ascending)
  - status (Ascending)
  - createdAt (Descending)
```

### 4. Messages - Chat ordenado
```
Collection: messages
Fields:
  - senderId (Ascending)
  - receiverId (Ascending)
  - timestamp (Descending)
```

### 5. Notifications - Por usuario
```
Collection: notifications
Fields:
  - userId (Ascending)
  - isRead (Ascending)
  - createdAt (Descending)
```

### 6. Reviews - Por usuario calificado
```
Collection: reviews
Fields:
  - reviewedUserId (Ascending)
  - createdAt (Descending)
```

### 7. Favorites - Por usuario
```
Collection: favorites
Fields:
  - userId (Ascending)
  - createdAt (Descending)
```

### 8. Portfolio - Por usuario
```
Collection: portfolio
Fields:
  - userId (Ascending)
  - createdAt (Descending)
```

### 9. Referrals - Por referidor
```
Collection: referrals
Fields:
  - referrerId (Ascending)
  - createdAt (Descending)
```

## Cómo Aplicar las Rules

### Firestore Rules
1. Ve a Firebase Console
2. Selecciona tu proyecto
3. Ve a Firestore Database > Rules
4. Copia y pega las reglas de Firestore
5. Haz clic en "Publicar"

### Storage Rules
1. Ve a Firebase Console
2. Selecciona tu proyecto
3. Ve a Storage > Rules
4. Copia y pega las reglas de Storage
5. Haz clic en "Publicar"

### Crear Índices
1. Ve a Firestore Database > Indexes
2. Haz clic en "Crear índice"
3. Agrega cada índice listado arriba
4. Espera a que se creen (puede tomar unos minutos)

## Notas de Seguridad

- ✅ Todas las operaciones requieren autenticación
- ✅ Los usuarios solo pueden modificar sus propios datos
- ✅ Los reportes y verificaciones solo pueden ser actualizados por admins
- ✅ Las imágenes tienen límite de 5MB
- ✅ Solo se permiten archivos de imagen
- ✅ Los mensajes solo son visibles para emisor y receptor
- ✅ Las notificaciones solo son visibles para el usuario destinatario

## Testing de Rules

Puedes probar las rules en Firebase Console:
1. Ve a Firestore Database > Rules
2. Haz clic en "Simulador de reglas"
3. Prueba diferentes operaciones con diferentes usuarios
