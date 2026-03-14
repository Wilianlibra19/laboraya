# Corrección: Guardar Documentos en Perfil

## Problema Reportado

En "Mis Documentos", cuando subes un documento:
- ❌ No hay botón de guardar
- ❌ Al salir de la pantalla, se borra
- ❌ Solo se ve el botón de eliminar
- ❌ Los documentos no se guardan en Firebase

## Solución Implementada

### 1. ✅ Botón de Guardar Visible

**Ahora verás:**
- Botón grande "Guardar Documentos" en la parte inferior
- Solo aparece cuando hay cambios sin guardar
- Badge "Sin guardar" en el AppBar

### 2. ✅ Subida a Cloudinary

**Proceso:**
1. Seleccionas documento → Se agrega a la lista (pendiente)
2. Presionas "Guardar" → Se sube a Cloudinary
3. URL se guarda en Firebase
4. Documento queda guardado permanentemente

### 3. ✅ Carga de Documentos Existentes

**Al abrir la pantalla:**
- Carga automáticamente tus documentos guardados
- Muestra icono verde si está subido
- Muestra icono naranja si está pendiente

### 4. ✅ Estados Visuales

**Documento Subido:**
```
🟢 [Icono nube con check verde]
   Nombre del archivo
   Tipo de documento
```

**Documento Pendiente:**
```
🟠 [Icono nube con flecha naranja]
   Nombre del archivo
   Tipo - Pendiente
```

### 5. ✅ Confirmación de Eliminación

**Antes de eliminar:**
- Muestra diálogo de confirmación
- "¿Estás seguro de eliminar este documento?"
- Botones: Cancelar / Eliminar

### 6. ✅ Mensajes Claros

**Al agregar documento:**
```
"CV agregado. Presiona 'Guardar' para subir."
```

**Al guardar:**
```
"✅ Documentos guardados exitosamente"
```

**Al eliminar:**
```
"Documento eliminado. Presiona 'Guardar' para confirmar."
```

## Flujo Completo

### Agregar Documento:

1. **Seleccionar tipo** (CV, DNI, Certificado, etc.)
2. **Elegir archivo** del dispositivo
3. **Ver en lista** con estado "Pendiente"
4. **Presionar "Guardar Documentos"**
5. **Esperar subida** (muestra loading)
6. **Ver confirmación** "✅ Documentos guardados"
7. **Documento guardado** con icono verde

### Eliminar Documento:

1. **Presionar icono de eliminar** (🗑️)
2. **Confirmar** en el diálogo
3. **Ver mensaje** "Presiona 'Guardar' para confirmar"
4. **Presionar "Guardar Documentos"**
5. **Documento eliminado** de Firebase

### Ver Documentos:

1. **Abrir "Mis Documentos"**
2. **Carga automática** de documentos guardados
3. **Ver lista** con iconos de estado
4. **Documentos persistentes** (no se borran al salir)

## Características Nuevas

### Badge "Sin Guardar"

En el AppBar, verás un badge naranja cuando:
- Agregaste un documento nuevo
- Eliminaste un documento
- Hay cambios pendientes de guardar

### Contador de Archivos

Muestra cuántos documentos tienes:
```
Documentos          3 archivo(s)
```

### Pantalla Vacía Mejorada

Si no tienes documentos:
```
📁 [Icono carpeta grande]
   No has subido documentos
   Agrega documentos para verificar tu perfil
```

### Loading States

- Loading al cargar documentos existentes
- Loading al guardar (botón deshabilitado)
- Indicador de progreso claro

## Archivos Modificados

### 1. `lib/screens/profile/my_documents_screen.dart`

**Agregado:**
- `_isLoading` - Estado de carga inicial
- `_isSaving` - Estado de guardado
- `_hasChanges` - Detecta cambios sin guardar
- `_loadDocuments()` - Carga documentos de Firebase
- `_saveDocuments()` - Sube a Cloudinary y guarda en Firebase
- `_deleteDocument()` - Elimina con confirmación
- Badge "Sin guardar" en AppBar
- Botón "Guardar Documentos" en la parte inferior
- Estados visuales (verde/naranja)
- Contador de archivos

### 2. `lib/core/services/user_service.dart`

**Agregado:**
- `updateUserDocuments()` - Método para actualizar documentos del usuario

## Tecnologías Usadas

- **Cloudinary**: Almacenamiento de documentos
- **Firebase Firestore**: Guardar URLs de documentos
- **file_picker**: Seleccionar archivos del dispositivo

## Tipos de Archivos Soportados

- PDF (.pdf)
- Imágenes (.jpg, .jpeg, .png)

## Tipos de Documentos

1. **Currículum Vitae** (CV)
2. **DNI** (Documento de identidad)
3. **Certificados** (Estudios, cursos)
4. **Licencias** (Profesionales, conducir)
5. **Fotos de trabajos** (Portfolio)

## Seguridad

- Documentos se suben a carpeta privada: `laboraya/documents/{userId}`
- Solo el usuario puede ver sus propios documentos
- URLs únicas y seguras de Cloudinary

## Resultado Final

Ahora cuando subes documentos:
1. ✅ Se guardan permanentemente
2. ✅ Puedes verlos cuando vuelvas
3. ✅ Botón de guardar visible
4. ✅ Estados claros (pendiente/guardado)
5. ✅ Confirmación antes de eliminar
6. ✅ Mensajes informativos
7. ✅ No se pierden al salir

¡Los documentos ahora funcionan correctamente!
