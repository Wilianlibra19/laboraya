# Instrucciones para Configurar Firebase

## 1. Actualizar Reglas de Firestore

Las reglas ya están actualizadas en el archivo `firestore.rules`. Para aplicarlas:

```bash
firebase deploy --only firestore:rules
```

O desde la consola de Firebase:
1. Ve a Firestore Database
2. Haz clic en "Reglas"
3. Copia y pega el contenido de `firestore.rules`
4. Haz clic en "Publicar"

## 2. Crear Índices Compuestos

Firebase necesita índices para consultas complejas. Crea estos índices:

### Índice 1: Solicitudes por Trabajo y Estado
- **Colección:** `job_applications`
- **Campos:**
  - `jobId` (Ascendente)
  - `status` (Ascendente)
  - `appliedAt` (Descendente)

### Índice 2: Notificaciones por Usuario
- **Colección:** `notifications`
- **Campos:**
  - `userId` (Ascendente)
  - `isRead` (Ascendente)
  - `createdAt` (Descendente)

### Cómo crear índices:

**Opción 1: Desde la Consola**
1. Ve a Firestore Database
2. Haz clic en "Índices"
3. Haz clic en "Crear índice"
4. Agrega los campos según la lista arriba
5. Haz clic en "Crear"

**Opción 2: Automático**
Cuando ejecutes la app, Firebase te mostrará un error con un enlace directo para crear el índice. Haz clic en el enlace y se creará automáticamente.

**Opción 3: Archivo firestore.indexes.json**
Crea un archivo `firestore.indexes.json` con:

```json
{
  "indexes": [
    {
      "collectionGroup": "job_applications",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "jobId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "appliedAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "isRead",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Luego ejecuta:
```bash
firebase deploy --only firestore:indexes
```

## 3. Verificar Colecciones

Asegúrate de que estas colecciones existan en Firestore:
- ✅ `users`
- ✅ `jobs`
- ✅ `messages`
- ✅ `notifications`
- ✅ `reviews`
- ✅ `job_applications` (nueva)

## 4. Estructura de Datos

### Colección: `job_applications`
```javascript
{
  id: "auto-generated",
  jobId: "job123",
  applicantId: "user456",
  applicantName: "Juan Pérez",
  applicantPhoto: "https://...",
  applicantRating: 4.5,
  applicantCompletedJobs: 15,
  message: "Tengo experiencia en...",
  appliedAt: Timestamp,
  status: "pending" // "pending", "accepted", "rejected"
}
```

### Colección: `users` (campos actualizados)
```javascript
{
  // ... campos existentes
  totalEarnings: 1500.00,      // Total acumulado
  monthlyEarnings: 500.00,     // Del mes actual
  completedJobs: 25,           // Trabajos completados
  rating: 4.7,                 // Promedio de calificaciones
  totalReviews: 25             // Total de calificaciones recibidas
}
```

### Colección: `jobs` (campos actualizados)
```javascript
{
  // ... campos existentes
  acceptedBy: "user789",       // ID del trabajador aceptado
  jobStatus: "available",      // Estado del trabajo
  acceptedAt: Timestamp,       // Cuándo fue aceptado
  startedAt: Timestamp,        // Cuándo inició
  finishedAt: Timestamp,       // Cuándo terminó
  confirmedAt: Timestamp,      // Cuándo confirmó el cliente
  completedAt: Timestamp,      // Cuándo se completó totalmente
  ratingWorker: 5.0,           // Calificación al trabajador
  commentWorker: "Excelente"   // Comentario al trabajador
}
```

## 5. Migración de Datos Existentes

Si ya tienes trabajos en la base de datos, ejecuta este script para agregar los campos faltantes:

```javascript
// En Firebase Console > Firestore > Ejecutar consulta
const firestore = firebase.firestore();

// Actualizar usuarios sin campos de ganancias
firestore.collection('users').get().then(snapshot => {
  const batch = firestore.batch();
  
  snapshot.docs.forEach(doc => {
    const data = doc.data();
    if (!data.totalEarnings) {
      batch.update(doc.ref, {
        totalEarnings: 0,
        monthlyEarnings: 0,
        totalReviews: data.totalReviews || 0
      });
    }
  });
  
  return batch.commit();
}).then(() => {
  console.log('✅ Usuarios actualizados');
});
```

## 6. Probar el Sistema

### Prueba 1: Solicitar Trabajo
1. Usuario A publica un trabajo
2. Usuario B hace clic en "Solicitar"
3. Usuario B escribe un mensaje
4. Usuario B envía solicitud
5. Verificar que aparece en Firestore: `job_applications`

### Prueba 2: Aceptar Solicitud
1. Usuario A ve el botón de solicitudes (con badge)
2. Usuario A hace clic y ve la lista
3. Usuario A acepta una solicitud
4. Verificar que:
   - El trabajo cambia a `jobStatus: "accepted"`
   - El campo `acceptedBy` se actualiza
   - Otras solicitudes cambian a `status: "rejected"`

### Prueba 3: Completar Trabajo
1. Trabajador marca como terminado
2. Cliente confirma
3. Cliente califica (1-5 estrellas)
4. Verificar que se actualizan:
   - `users.totalEarnings` += pago
   - `users.monthlyEarnings` += pago
   - `users.completedJobs` += 1
   - `users.rating` = nuevo promedio
   - `jobs.jobStatus` = "completed"

### Prueba 4: Ver Ganancias
1. Ir al perfil del trabajador
2. Verificar que se muestran:
   - Ganancias del mes
   - Ganancias totales
   - Trabajos completados
   - Rating actualizado

## 7. Monitoreo

### Consultas Útiles en Firestore Console:

**Ver solicitudes pendientes de un trabajo:**
```
job_applications
  where jobId == "job123"
  where status == "pending"
  order by appliedAt desc
```

**Ver ganancias de un usuario:**
```
users
  where id == "user456"
  select totalEarnings, monthlyEarnings, completedJobs
```

**Ver trabajos completados:**
```
jobs
  where jobStatus == "completed"
  order by completedAt desc
```

## 8. Solución de Problemas

### Error: "Missing index"
- Haz clic en el enlace del error
- O crea el índice manualmente (ver sección 2)

### Error: "Permission denied"
- Verifica que las reglas estén actualizadas
- Verifica que el usuario esté autenticado
- Revisa los logs de Firebase

### Las ganancias no se actualizan
- Verifica que `completeJobWithRating` se esté llamando
- Revisa los logs en la consola
- Verifica que el campo `payment` exista en el trabajo

### Las solicitudes no aparecen
- Verifica que el índice esté creado
- Verifica que `jobId` sea correcto
- Revisa las reglas de seguridad

## 9. Comandos Útiles

```bash
# Desplegar todo
firebase deploy

# Solo reglas
firebase deploy --only firestore:rules

# Solo índices
firebase deploy --only firestore:indexes

# Ver logs
firebase functions:log

# Emulador local
firebase emulators:start
```

## 10. Checklist Final

- [ ] Reglas de Firestore actualizadas
- [ ] Índices creados
- [ ] Colección `job_applications` creada
- [ ] Campos de ganancias en `users` verificados
- [ ] Prueba de solicitar trabajo exitosa
- [ ] Prueba de aceptar solicitud exitosa
- [ ] Prueba de completar trabajo exitosa
- [ ] Ganancias se muestran en perfil
- [ ] Notificaciones funcionando
- [ ] Sin errores en consola

## 🎉 ¡Listo!

Una vez completados todos los pasos, el sistema estará funcionando completamente.
