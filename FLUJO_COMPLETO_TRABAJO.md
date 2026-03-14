# Flujo Completo de un Trabajo - LaboraYa

## 📊 Estados del Trabajo

| Estado | Descripción | Quién lo activa |
|--------|-------------|-----------------|
| `available` | Trabajo publicado, esperando | Dueño (al publicar) |
| `accepted` | Trabajo aceptado | Trabajador |
| `on_the_way` | Trabajador va en camino | Trabajador |
| `in_progress` | Trabajo iniciado | Trabajador |
| `finished_by_worker` | Trabajador terminó | Trabajador |
| `confirmed_by_client` | Dueño confirmó | Dueño |
| `completed` | Trabajo completado y calificado | Dueño |

## 🔄 Flujo Completo

### 1️⃣ PUBLICAR TRABAJO
**Quién:** Dueño (Usuario A)
**Estado:** `available`

```
Usuario A publica: "Necesito plomero"
↓
Trabajo visible en el mapa y lista
↓
Estado: available
```

### 2️⃣ ACEPTAR TRABAJO
**Quién:** Trabajador (Usuario B)
**Estado:** `available` → `accepted`

```
Usuario B ve el trabajo
↓
Presiona "Aceptar"
↓
Estado: accepted
↓
Notificación a Usuario A: "Usuario B quiere trabajar en tu trabajo"
```

**Botones para Usuario B:**
- 🚗 Voy en camino
- 💬 Chatear con cliente

**Botones para Usuario A:**
- 💬 Chatear con trabajador

### 3️⃣ EN CAMINO
**Quién:** Trabajador (Usuario B)
**Estado:** `accepted` → `on_the_way`

```
Usuario B presiona "Voy en camino"
↓
Estado: on_the_way
↓
Notificación a Usuario A: "Usuario B va en camino"
```

**Botones para Usuario B:**
- 🔨 Iniciar trabajo
- 💬 Chatear con cliente

**Botones para Usuario A:**
- 💬 Chatear con trabajador
- Ve: "Trabajador en camino 🚗"

### 4️⃣ TRABAJO INICIADO
**Quién:** Trabajador (Usuario B)
**Estado:** `on_the_way` → `in_progress`

```
Usuario B llega y presiona "Iniciar trabajo"
↓
Estado: in_progress
↓
Notificación a Usuario A: "Usuario B ha iniciado el trabajo"
```

**Botones para Usuario B:**
- ✅ Marcar como terminado
- 💬 Chatear con cliente

**Botones para Usuario A:**
- 💬 Chatear con trabajador
- Ve: "Trabajo en progreso 🔨"

### 5️⃣ TRABAJO TERMINADO
**Quién:** Trabajador (Usuario B)
**Estado:** `in_progress` → `finished_by_worker`

```
Usuario B termina y presiona "Marcar como terminado"
↓
Estado: finished_by_worker
↓
Notificación a Usuario A: "Usuario B ha terminado. ¡Confirma el trabajo!"
```

**Botones para Usuario B:**
- ⏳ Esperando confirmación del cliente
- 💬 Chatear con cliente

**Botones para Usuario A:**
- ✔️ Confirmar trabajo
- 💬 Chatear con trabajador

### 6️⃣ TRABAJO CONFIRMADO
**Quién:** Dueño (Usuario A)
**Estado:** `finished_by_worker` → `confirmed_by_client`

```
Usuario A revisa el trabajo
↓
Presiona "Confirmar trabajo"
↓
Estado: confirmed_by_client
↓
Notificación a Usuario B: "Usuario A ha confirmado el trabajo. ¡Ahora puedes calificar!"
```

**Botones para Usuario B:**
- 🎉 Trabajo completado
- Ve su calificación (si Usuario A ya calificó)

**Botones para Usuario A:**
- ⭐ Calificar trabajador

### 7️⃣ CALIFICACIÓN Y COMPLETADO
**Quién:** Dueño (Usuario A)
**Estado:** `confirmed_by_client` → `completed`

```
Usuario A presiona "Calificar trabajador"
↓
Pone estrellas (1-5) y comentario
↓
Estado: completed
↓
Se actualiza el perfil de Usuario B:
  - rating promedio
  - trabajos completados
  - ganancias
```

**Resultado final:**
- ✅ Trabajo completado
- ⭐ Trabajador calificado
- 💰 Ganancias actualizadas
- 📊 Estadísticas actualizadas

## 🔍 Dónde Ver el Progreso

### Para el TRABAJADOR:

1. **Desde Inicio:**
   - Ve a "Inicio"
   - Busca el trabajo que aceptaste
   - Toca el trabajo
   - Verás el progreso y botones

2. **Desde Perfil:**
   - Ve a "Perfil"
   - Toca "Mis Trabajos" (si existe)
   - Verás trabajos activos

3. **Desde Notificaciones:**
   - Recibes notificaciones de cada cambio
   - Toca la notificación para ir al trabajo

### Para el DUEÑO:

1. **Desde Inicio:**
   - Ve a "Inicio"
   - Busca el trabajo que publicaste
   - Toca el trabajo
   - Verás el progreso y botones

2. **Desde Perfil:**
   - Ve a "Perfil"
   - Toca "Mis Publicaciones" (si existe)
   - Verás trabajos publicados

3. **Desde Notificaciones:**
   - Recibes notificaciones de cada cambio
   - Toca la notificación para ir al trabajo

## 📱 Barra de Progreso Visual

En la pantalla de detalle del trabajo, verás una barra de progreso:

```
Aceptado → En camino → En progreso → Terminado → Confirmado → Completado
   ✅         ⚪           ⚪            ⚪           ⚪           ⚪
```

A medida que avanza el trabajo, se van llenando los círculos.

## 💬 Chat Durante el Proceso

En cualquier momento, tanto el trabajador como el dueño pueden chatear:

- 💬 Botón "Chatear" siempre disponible
- Enviar mensajes de texto
- Enviar fotos
- Coordinar detalles

## 🔔 Notificaciones

Ambos usuarios reciben notificaciones en cada cambio:

| Evento | Quién recibe | Mensaje |
|--------|--------------|---------|
| Trabajo aceptado | Dueño | "X quiere trabajar en tu trabajo" |
| En camino | Dueño | "X va en camino" |
| Trabajo iniciado | Dueño | "X ha iniciado el trabajo" |
| Trabajo terminado | Dueño | "X ha terminado. ¡Confirma!" |
| Trabajo confirmado | Trabajador | "X ha confirmado el trabajo" |

## ⚠️ Importante

### Para el TRABAJADOR:
- ✅ Marca cada paso en orden
- ✅ Comunícate con el cliente
- ✅ Espera la confirmación antes de irte
- ✅ Tu calificación depende del trabajo bien hecho

### Para el DUEÑO:
- ✅ Revisa bien el trabajo antes de confirmar
- ✅ Comunícate con el trabajador
- ✅ Califica honestamente
- ✅ Tu calificación ayuda a otros usuarios

## 🎯 Resumen Rápido

1. **Aceptar** → Vuelve a entrar al trabajo para ver botones
2. **Voy en camino** → Cuando salgas hacia el lugar
3. **Iniciar trabajo** → Cuando llegues y empieces
4. **Marcar como terminado** → Cuando termines
5. **Esperar confirmación** → El dueño debe confirmar
6. **Completado** → Trabajo finalizado

## 📍 Cómo Volver al Trabajo

Después de aceptar:

1. Ve a "Inicio"
2. Busca el trabajo (puedes usar el buscador)
3. Toca el trabajo
4. Verás los botones según el estado actual

O espera la notificación del siguiente paso y tócala para ir directamente.
