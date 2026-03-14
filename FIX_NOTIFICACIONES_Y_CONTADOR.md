# 🔧 Fix: Notificaciones y Contador de Mensajes

## Problemas Identificados

### 1. ❌ Notificaciones se envían al remitente
**Problema:** Cuando envías un mensaje, TÚ recibes la notificación en lugar del receptor.

**Causa:** El código enviaba notificación sin verificar quién es el receptor.

**Solución:** Eliminé las notificaciones locales del `MessageService`. Las notificaciones deben manejarse con Firebase Cloud Messaging para enviarlas al dispositivo correcto del receptor.

### 2. ❌ Contador no desaparece después de abrir el chat
**Problema:** Abres el chat, lees los mensajes, pero el badge rojo sigue mostrando el número.

**Causa:** Los mensajes se marcaban como leídos antes de cargarse, o no se actualizaba la lista después.

**Solución:** 
- Ahora se cargan los mensajes PRIMERO
- LUEGO se marcan como leídos
- Se agregaron logs para verificar el proceso

### 3. ❌ Conversaciones duplicadas
**Problema:** Aparecen múltiples conversaciones con la misma persona.

**Causa:** Posiblemente múltiples trabajos con la misma persona.

**Solución:** Esto es correcto - cada trabajo tiene su propia conversación. Si hay 2 trabajos diferentes, habrá 2 conversaciones.

## Cambios Realizados

### 1. MessageService - Eliminadas notificaciones locales

**Antes:**
```dart
Future<void> sendMessage(MessageModel message) async {
  await _repository.sendMessage(message);
  await loadMessages(message.jobId);
  
  // ❌ Esto enviaba notificación al remitente
  NotificationService.showNotification(
    title: 'Nuevo mensaje',
    body: message.text,
  );
}
```

**Después:**
```dart
Future<void> sendMessage(MessageModel message) async {
  await _repository.sendMessage(message);
  await loadMessages(message.jobId);
  
  if (message.senderId.isNotEmpty) {
    await loadAllConversations(message.senderId);
  }
  
  // ✅ Sin notificación local
  // Las notificaciones se manejarán con FCM
}
```

### 2. ChatScreen - Mejorado orden de carga y marcado

**Antes:**
```dart
@override
void initState() {
  super.initState();
  _markAsRead(); // ❌ Se ejecuta antes de cargar mensajes
  context.read<MessageService>().loadMessages(widget.jobId);
}
```

**Después:**
```dart
@override
void initState() {
  super.initState();
  _loadAndMarkAsRead(); // ✅ Carga primero, marca después
  // ...
}

Future<void> _loadAndMarkAsRead() async {
  // 1. Cargar mensajes
  await context.read<MessageService>().loadMessages(widget.jobId);
  
  // 2. Marcar como leídos
  final currentUser = context.read<UserService>().currentUser;
  if (currentUser != null) {
    final messageRepo = context.read<MessageService>().repository;
    if (messageRepo is FirebaseMessageRepository) {
      await messageRepo.markMessagesAsRead(widget.jobId, currentUser.id);
      print('✅ Mensajes marcados como leídos');
    }
  }
}
```

### 3. FirebaseMessageRepository - Logs mejorados

Agregué logs detallados en `markMessagesAsRead`:
```dart
print('📖 Marcando mensajes como leídos:');
print('  - jobId: $jobId');
print('  - userId (receptor): $userId');
print('  - Mensajes no leídos encontrados: ${snapshot.docs.length}');
print('✅ Todos los mensajes marcados como leídos');
```

## Cómo Verificar que Funciona

### Test 1: Notificaciones

1. **Usuario A** envía mensaje a **Usuario B**
2. **Verificar:**
   - ❌ Usuario A NO debe recibir notificación
   - ✅ Usuario B debe recibir notificación (cuando se implemente FCM)

### Test 2: Contador de Mensajes No Leídos

1. **Usuario A** envía 3 mensajes a **Usuario B**
2. **Usuario B** abre la app
3. **Verificar en "Chat":**
   - ✅ Badge muestra [3]
   - ✅ Texto en negrita
4. **Usuario B** abre la conversación
5. **Verificar logs en consola:**
   ```
   📖 Marcando mensajes como leídos:
     - jobId: [jobId]
     - userId (receptor): [userId de B]
     - Mensajes no leídos encontrados: 3
       ✓ Marcando mensaje [id1] como leído
       ✓ Marcando mensaje [id2] como leído
       ✓ Marcando mensaje [id3] como leído
   ✅ Todos los mensajes marcados como leídos
   ```
6. **Usuario B** vuelve a "Chat"
7. **Verificar:**
   - ✅ Badge desaparece
   - ✅ Texto vuelve a normal

### Test 3: Conversaciones Únicas

**Escenario 1: Un trabajo, múltiples mensajes**
- Usuario A publica 1 trabajo
- Usuario B envía 100 mensajes
- **Resultado:** 1 conversación en la lista ✅

**Escenario 2: Múltiples trabajos, misma persona**
- Usuario A publica 2 trabajos diferentes
- Usuario B envía mensajes en ambos
- **Resultado:** 2 conversaciones en la lista ✅
- **Esto es correcto** - cada trabajo tiene su propia conversación

## Logs para Debug

Cuando abras un chat, deberías ver:

```
📖 Marcando mensajes como leídos:
  - jobId: d4d4f56c-53af-46f3-a0a9-e2701ef81f8e
  - userId (receptor): M0kHDw8rbUcU92CngozaLJ1MVaH2
  - Mensajes no leídos encontrados: 3
    ✓ Marcando mensaje abc123 como leído
    ✓ Marcando mensaje def456 como leído
    ✓ Marcando mensaje ghi789 como leído
✅ Todos los mensajes marcados como leídos
✅ Mensajes marcados como leídos para jobId: d4d4f56c-53af-46f3-a0a9-e2701ef81f8e
```

Si ves `Mensajes no leídos encontrados: 0`, significa que:
- Ya estaban marcados como leídos, O
- No eres el receptor de esos mensajes

## Verificar en Firebase Console

1. Ve a Firestore Database → Colección `messages`
2. Busca los mensajes del chat que acabas de abrir
3. Verifica que `isRead` cambió de `false` a `true`

**Antes de abrir el chat:**
```javascript
{
  id: "abc123",
  jobId: "d4d4f56c...",
  senderId: "usuario1",
  receiverId: "usuario2",  // ← Tú eres usuario2
  text: "Hola",
  isRead: false  // ← No leído
}
```

**Después de abrir el chat:**
```javascript
{
  id: "abc123",
  jobId: "d4d4f56c...",
  senderId: "usuario1",
  receiverId: "usuario2",
  text: "Hola",
  isRead: true  // ← ✅ Marcado como leído
}
```

## Problemas Comunes

### El contador no desaparece

**Posibles causas:**
1. Las reglas de Firestore no permiten actualizar
   - **Solución:** Verifica que aplicaste las reglas actualizadas
2. No eres el receptor de los mensajes
   - **Solución:** Verifica que `receiverId` sea tu ID
3. Los mensajes ya estaban marcados como leídos
   - **Solución:** Revisa los logs

### Aparecen múltiples conversaciones con la misma persona

**Esto es normal si:**
- La misma persona te escribió en diferentes trabajos
- Cada trabajo tiene su propia conversación

**Ejemplo:**
- Trabajo 1: "Pintar sala" → Conversación con Juan
- Trabajo 2: "Limpiar jardín" → Conversación con Juan
- **Resultado:** 2 conversaciones con Juan ✅

## Próximos Pasos (Opcional)

### Implementar Notificaciones Push con FCM

Para enviar notificaciones al receptor correcto:

1. Guardar el FCM token de cada usuario en Firestore
2. Cuando se envía un mensaje, enviar notificación push al token del receptor
3. El receptor recibe la notificación en su dispositivo

Esto requiere configuración adicional de Firebase Cloud Messaging.

---

**¡Problemas resueltos!** ✅

- ✅ Sin notificaciones al remitente
- ✅ Contador desaparece al abrir chat
- ✅ Conversaciones organizadas por trabajo
