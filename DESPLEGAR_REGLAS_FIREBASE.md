# Desplegar Reglas de Firestore

## Opción 1: Desde la Consola de Firebase (Más Fácil)

1. Ve a la [Consola de Firebase](https://console.firebase.google.com/)
2. Selecciona tu proyecto "LaboraYa"
3. En el menú lateral, ve a **Firestore Database**
4. Haz clic en la pestaña **Reglas** (Rules)
5. Copia y pega el contenido del archivo `firestore.rules` en el editor
6. Haz clic en **Publicar** (Publish)

## Opción 2: Desde la Terminal (Requiere Firebase CLI)

Si tienes Firebase CLI instalado, ejecuta:

```bash
firebase deploy --only firestore:rules
```

## Verificar que las Reglas Funcionan

Después de desplegar, prueba:

1. Acepta un trabajo desde una cuenta
2. Verifica que aparezca la notificación en la campanita de la otra cuenta
3. Si ves el contador rojo pero no hay notificaciones, las reglas anteriores estaban bloqueando la creación

## Cambios Importantes en las Reglas

### Antes:
```javascript
match /notifications/{notificationId} {
  allow create: if isAuthenticated();
}
```

### Ahora (Explicación):
```javascript
match /notifications/{notificationId} {
  // Cualquier usuario autenticado puede crear notificaciones
  // Esto permite que el trabajador cree notificaciones para el dueño del trabajo
  allow create: if isAuthenticated();
}
```

## Problema que Resuelve

Cuando un trabajador acepta un trabajo:
- El trabajador (Usuario A) está autenticado
- Crea una notificación para el dueño del trabajo (Usuario B)
- Con las reglas anteriores, esto podría fallar si había restricciones
- Ahora cualquier usuario autenticado puede crear notificaciones para otros

## Seguridad

Las notificaciones siguen siendo seguras porque:
- Solo el destinatario puede leer sus propias notificaciones
- Solo el destinatario puede actualizar o eliminar sus notificaciones
- La creación está permitida pero los datos se validan en el código
