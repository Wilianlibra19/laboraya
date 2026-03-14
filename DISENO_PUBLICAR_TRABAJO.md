# Diseño Detallado: Pantalla "Publicar Trabajo" - LaboraYa

## 🎨 INFORMACIÓN GENERAL

**Nombre de la pantalla:** Publicar Trabajo / Create Job Screen  
**Archivo:** `lib/screens/job/create_job_screen.dart`  
**Tipo:** Formulario con scroll vertical  
**Estilo:** Moderno, limpio, con cards separadas por secciones

---

## 🎯 ESTRUCTURA GENERAL

La pantalla está dividida en **5 secciones principales**, cada una en una card separada:

1. **Información Básica** (azul)
2. **Descripción** (verde)
3. **Pago y Duración** (naranja)
4. **Ubicación** (morado)
5. **Fotos** (rosa)

---

## 📐 LAYOUT Y ESPACIADO

### Fondo de la Pantalla
- **Color Modo Claro:** `Colors.grey[50]` (gris muy claro)
- **Color Modo Oscuro:** `Colors.grey[900]` (gris muy oscuro)

### AppBar
- **Color de fondo:** `AppColors.primary` (azul #2196F3)
- **Color de texto:** Blanco
- **Título:** "Publicar Trabajo"
- **Elevación:** 0 (sin sombra)
- **Icono de retroceso:** Flecha blanca

### Padding General
- **Padding exterior:** 16px en todos los lados
- **Espacio entre cards:** 16px

### Cards (Contenedores de Secciones)
- **Color Modo Claro:** Blanco
- **Color Modo Oscuro:** `Colors.grey[850]`
- **Border radius:** 16px (esquinas muy redondeadas)
- **Elevación:** 2 (sombra suave)
- **Padding interno:** 20px en todos los lados

---

## 📋 SECCIÓN 1: INFORMACIÓN BÁSICA

### Header de la Sección
- **Icono:** `Icons.info_outline` (círculo con i)
- **Color del icono:** Azul `Colors.blue`
- **Tamaño del icono:** 24px
- **Texto:** "Información Básica"
- **Tamaño de fuente:** 18px
- **Peso de fuente:** Bold (negrita)
- **Espacio después del header:** 20px

### Campo 1: Título del Trabajo
```
┌─────────────────────────────────────┐
│ 📝 Título del trabajo              │
│ Ej: Necesito plomero urgente...   │
└─────────────────────────────────────┘
```
- **Label:** "Título del trabajo"
- **Hint:** "Ej: Necesito plomero urgente..."
- **Icono:** `Icons.title` (📝)
- **Tipo:** TextField de una línea
- **Validación:** Requerido, mínimo 5 caracteres
- **Max caracteres:** 100

### Campo 2: Categoría (Autocomplete)
```
┌─────────────────────────────────────┐
│ 📂 Categoría *                     │
│ Escribe para buscar (ej: Plomero)│
│ Empieza a escribir para ver opciones│
│ 🔍                                  │
└─────────────────────────────────────┘
```
- **Label:** "Categoría *"
- **Hint:** "Escribe para buscar (ej: Plomero, Pintor, Ayudante)..."
- **Helper text:** "Empieza a escribir para ver opciones" (gris, 12px)
- **Icono izquierdo:** `Icons.category` (📂)
- **Icono derecho:** 
  - `Icons.search` (🔍) cuando está vacío
  - `Icons.clear` (X) cuando hay texto
- **Tipo:** Autocomplete
- **Validación:** Requerido, debe estar en la lista de 120+ categorías
- **Comportamiento:**
  - Campo vacío → No muestra opciones
  - Usuario escribe → Muestra opciones filtradas
  - Usuario selecciona → Se llena el campo

### Dropdown de Opciones (cuando escribe)
```
┌─────────────────────────────────────┐
│ 🔧 Plomero                         │
│ 🎨 Pintor                          │
│ ⚡ Electricista                    │
│ 👷 Ayudante de Construcción        │
└─────────────────────────────────────┘
```
- **Fondo Modo Claro:** Blanco
- **Fondo Modo Oscuro:** `Colors.grey[850]`
- **Border radius:** 12px
- **Elevación:** 8 (sombra pronunciada)
- **Max altura:** 250px
- **Cada opción:**
  - Icono específico de la categoría (20px)
  - Texto de la categoría (14px)
  - Padding: 12px vertical, 16px horizontal
  - Hover: Fondo gris claro

### Estilo de los Campos
- **Filled:** true (fondo de color)
- **Fill color Modo Claro:** `Colors.grey[50]`
- **Fill color Modo Oscuro:** `Colors.grey[800]`
- **Border radius:** 12px
- **Border normal:** `Colors.grey[300]` (modo claro) / `Colors.grey[700]` (modo oscuro)
- **Border focused:** `AppColors.primary` (azul), grosor 2px
- **Border error:** Rojo, grosor 2px
- **Padding interno:** 16px horizontal, 12px vertical

---

## 📋 SECCIÓN 2: DESCRIPCIÓN

### Header de la Sección
- **Icono:** `Icons.description_outlined`
- **Color del icono:** Verde `Colors.green`
- **Texto:** "Descripción"

### Campo: Descripción del Trabajo
```
┌─────────────────────────────────────┐
│ ✏️ Descripción                     │
│ Describe el trabajo en detalle... │
│                                     │
│                                     │
│                                     │
└─────────────────────────────────────┘
```
- **Label:** "Descripción"
- **Hint:** "Describe el trabajo en detalle..."
- **Icono:** `Icons.edit` (✏️)
- **Tipo:** TextField multilínea
- **Líneas:** 5 (altura fija)
- **Max caracteres:** 500
- **Validación:** Requerido, mínimo 20 caracteres

---

## 📋 SECCIÓN 3: PAGO Y DURACIÓN

### Header de la Sección
- **Icono:** `Icons.payments_outlined`
- **Color del icono:** Naranja `Colors.orange`
- **Texto:** "Pago y Duración"

### Campo 1: Pago
```
┌─────────────────────────────────────┐
│ 💰 Pago (S/)                       │
│ 100.00                             │
└─────────────────────────────────────┘
```
- **Label:** "Pago (S/)"
- **Hint:** "100.00"
- **Icono:** `Icons.attach_money` (💰)
- **Tipo:** TextField numérico
- **Teclado:** Números con decimales
- **Validación:** Requerido, mayor a 0

### Campo 2: Tipo de Pago (Dropdown)
```
┌─────────────────────────────────────┐
│ 💳 Tipo de pago                    │
│ Por trabajo completo            ▼  │
└─────────────────────────────────────┘
```
- **Label:** "Tipo de pago"
- **Icono:** `Icons.payment` (💳)
- **Opciones:**
  - "Por hora"
  - "Por trabajo completo"
- **Valor por defecto:** "Por trabajo completo"
- **Estilo del dropdown:**
  - Fondo igual que los campos
  - Border radius: 12px
  - Icono de flecha: `Icons.arrow_drop_down`

### Campo 3: Duración (Dropdown)
```
┌─────────────────────────────────────┐
│ ⏱️ Duración estimada               │
│ Medio día (4-6 horas)           ▼  │
└─────────────────────────────────────┘
```
- **Label:** "Duración estimada"
- **Icono:** `Icons.schedule` (⏱️)
- **Opciones:**
  - "1-2 horas"
  - "3-4 horas"
  - "Medio día (4-6 horas)"
  - "Día completo (8 horas)"
  - "2-3 días"
  - "1 semana"
  - "2 semanas"
  - "1 mes"
  - "Más de 1 mes"
- **Valor por defecto:** "Medio día (4-6 horas)"

---

## 📋 SECCIÓN 4: UBICACIÓN

### Header de la Sección
- **Icono:** `Icons.location_on_outlined`
- **Color del icono:** Morado `Colors.purple`
- **Texto:** "Ubicación"

### Botón: Obtener Ubicación Actual
```
┌─────────────────────────────────────┐
│ 📍 Obtener mi ubicación actual     │
└─────────────────────────────────────┘
```
- **Texto:** "Obtener mi ubicación actual"
- **Icono:** `Icons.my_location` (📍)
- **Color de fondo:** `AppColors.primary` (azul)
- **Color de texto:** Blanco
- **Border radius:** 12px
- **Padding:** 16px vertical
- **Ancho:** 100% (full width)
- **Comportamiento:**
  - Al presionar: Obtiene GPS
  - Muestra loading mientras carga
  - Llena automáticamente el campo de dirección con geocodificación inversa

### Campo: Dirección
```
┌─────────────────────────────────────┐
│ 📍 Dirección                       │
│ Av. Javier Prado Este 4200...     │
└─────────────────────────────────────┘
```
- **Label:** "Dirección"
- **Hint:** "Av. Javier Prado Este 4200, San Borja, Lima"
- **Icono:** `Icons.location_on` (📍)
- **Tipo:** TextField multilínea (2 líneas)
- **Validación:** Requerido
- **Comportamiento:**
  - Se llena automáticamente al obtener ubicación
  - Usuario puede editar manualmente

### Información de Coordenadas (Texto pequeño)
```
📌 Lat: -12.0464, Lng: -77.0428
```
- **Tamaño de fuente:** 12px
- **Color:** Gris `Colors.grey[600]`
- **Icono:** `Icons.pin_drop` (📌)
- **Muestra:** Solo si hay coordenadas

---

## 📋 SECCIÓN 5: FOTOS

### Header de la Sección
- **Icono:** `Icons.photo_library_outlined`
- **Color del icono:** Rosa `Colors.pink`
- **Texto:** "Fotos del Trabajo"

### Texto Informativo
```
Puedes subir hasta 10 fotos (opcional)
```
- **Tamaño de fuente:** 14px
- **Color:** Gris `Colors.grey[600]`
- **Espacio después:** 16px

### Botón: Agregar Fotos
```
┌─────────────────────────────────────┐
│ 📷 Agregar Fotos                   │
└─────────────────────────────────────┘
```
- **Texto:** "Agregar Fotos"
- **Icono:** `Icons.add_photo_alternate` (📷)
- **Color de fondo:** `Colors.grey[200]` (modo claro) / `Colors.grey[800]` (modo oscuro)
- **Color de texto:** `AppColors.primary` (azul)
- **Border:** Dashed (punteado), 2px, azul
- **Border radius:** 12px
- **Padding:** 20px vertical
- **Ancho:** 100%

### Grid de Fotos Seleccionadas
```
┌─────┐ ┌─────┐ ┌─────┐
│ 📷  │ │ 📷  │ │ 📷  │
│  X  │ │  X  │ │  X  │
└─────┘ └─────┘ └─────┘
```
- **Layout:** Grid de 3 columnas
- **Espacio entre fotos:** 8px
- **Cada foto:**
  - **Tamaño:** 100x100px
  - **Border radius:** 12px
  - **Fit:** Cover (recorta para llenar)
  - **Botón eliminar:**
    - Posición: Esquina superior derecha
    - Icono: X blanca
    - Fondo: Rojo semi-transparente
    - Tamaño: 24x24px
    - Border radius: 12px (solo esquina superior derecha)

---

## 🔘 BOTÓN DE PUBLICAR (Parte inferior)

### Botón Principal
```
┌─────────────────────────────────────┐
│     ✅ Publicar Trabajo            │
└─────────────────────────────────────┘
```
- **Texto:** "Publicar Trabajo"
- **Icono:** `Icons.check_circle` (✅)
- **Color de fondo:** `AppColors.primary` (azul #2196F3)
- **Color de texto:** Blanco
- **Border radius:** 12px
- **Padding:** 16px vertical
- **Ancho:** 100%
- **Elevación:** 4 (sombra)
- **Posición:** Fijo en la parte inferior
- **Fondo del contenedor:**
  - Color: Blanco (modo claro) / `Colors.grey[850]` (modo oscuro)
  - Sombra hacia arriba
  - Padding: 16px
  - SafeArea: true

### Estado Loading
```
┌─────────────────────────────────────┐
│     ⏳ Publicando...               │
└─────────────────────────────────────┘
```
- **Texto:** "Publicando..."
- **Icono:** CircularProgressIndicator (spinner blanco)
- **Botón deshabilitado:** true
- **Opacidad:** 0.7

---

## 🎨 PALETA DE COLORES

### Colores Principales
- **Primary (Azul):** `#2196F3` - Botones principales, borders focused
- **Verde:** `#4CAF50` - Sección de descripción
- **Naranja:** `#FF9800` - Sección de pago
- **Morado:** `#9C27B0` - Sección de ubicación
- **Rosa:** `#E91E63` - Sección de fotos
- **Rojo:** `#F44336` - Errores, botón eliminar

### Colores de Fondo
**Modo Claro:**
- Pantalla: `Colors.grey[50]` (#FAFAFA)
- Cards: `Colors.white` (#FFFFFF)
- Campos: `Colors.grey[50]` (#FAFAFA)

**Modo Oscuro:**
- Pantalla: `Colors.grey[900]` (#212121)
- Cards: `Colors.grey[850]` (#303030)
- Campos: `Colors.grey[800]` (#424242)

### Colores de Texto
**Modo Claro:**
- Texto principal: `Colors.black` (#000000)
- Texto secundario: `Colors.grey[600]` (#757575)
- Hints: `Colors.grey[400]` (#BDBDBD)

**Modo Oscuro:**
- Texto principal: `Colors.white` (#FFFFFF)
- Texto secundario: `Colors.grey[400]` (#BDBDBD)
- Hints: `Colors.grey[600]` (#757575)

---

## 📏 TIPOGRAFÍA

### Tamaños de Fuente
- **Título de sección:** 18px, Bold
- **Labels de campos:** 16px, Normal
- **Texto de campos:** 16px, Normal
- **Hints:** 14px, Normal
- **Helper text:** 12px, Normal
- **Texto de botón:** 16px, Bold

### Familia de Fuente
- **Por defecto:** Roboto (Android) / San Francisco (iOS)

---

## 🔄 COMPORTAMIENTO Y ANIMACIONES

### Validación en Tiempo Real
- **Borde rojo:** Aparece al intentar enviar con errores
- **Mensaje de error:** Aparece debajo del campo (rojo, 12px)
- **Shake animation:** Campos con error se sacuden

### Loading States
1. **Al obtener ubicación:**
   - Botón muestra spinner
   - Texto cambia a "Obteniendo ubicación..."
   - Botón deshabilitado

2. **Al publicar:**
   - Botón principal muestra spinner
   - Texto cambia a "Publicando..."
   - Todos los campos deshabilitados
   - No se puede hacer scroll

### Transiciones
- **Scroll:** Suave, con bounce effect
- **Aparición de cards:** Fade in de arriba hacia abajo
- **Focus en campos:** Border cambia de gris a azul (300ms)
- **Dropdown:** Slide down (200ms)

---

## 📱 RESPONSIVE

### Pantallas Pequeñas (< 360px)
- Padding reducido a 12px
- Tamaño de fuente reducido en 2px
- Grid de fotos: 2 columnas en lugar de 3

### Pantallas Grandes (> 600px)
- Max width: 600px (centrado)
- Padding aumentado a 24px

---

## ✅ VALIDACIONES

### Campos Requeridos (*)
1. **Título:** Mínimo 5 caracteres
2. **Categoría:** Debe estar en la lista
3. **Descripción:** Mínimo 20 caracteres
4. **Pago:** Mayor a 0
5. **Dirección:** No vacío

### Mensajes de Error
- "Este campo es requerido"
- "Mínimo 5 caracteres"
- "Selecciona una categoría válida de la lista"
- "Mínimo 20 caracteres"
- "El pago debe ser mayor a 0"
- "Ingresa una dirección"

---

## 🎯 FLUJO DE USUARIO

1. Usuario abre "Publicar Trabajo"
2. Llena título
3. Escribe en categoría → Ve opciones → Selecciona
4. Escribe descripción
5. Ingresa pago y selecciona tipo
6. Selecciona duración
7. Presiona "Obtener mi ubicación" → Se llena dirección
8. (Opcional) Agrega fotos
9. Presiona "Publicar Trabajo"
10. Validación → Si hay errores, muestra mensajes
11. Si todo OK → Sube fotos a Cloudinary
12. Guarda en Firebase
13. Muestra mensaje "✅ Trabajo publicado"
14. Vuelve a pantalla anterior

---

## 📝 NOTAS ADICIONALES

- **Scroll:** Toda la pantalla hace scroll, excepto AppBar y botón inferior
- **Keyboard:** Al abrir teclado, scroll automático al campo activo
- **Back button:** Muestra diálogo de confirmación si hay cambios sin guardar
- **Orientación:** Solo portrait (vertical)
- **Accesibilidad:** Todos los campos tienen labels y hints claros

---

## 🔗 INTEGRACIÓN

### Servicios Usados
- **Cloudinary:** Subida de fotos
- **Firebase Firestore:** Guardar trabajo
- **Google Maps / Geolocator:** Obtener ubicación
- **Geocoding:** Convertir coordenadas a dirección

### Datos Guardados
```json
{
  "id": "uuid",
  "title": "string",
  "description": "string",
  "category": "string",
  "payment": "double",
  "paymentType": "string",
  "duration": "string",
  "latitude": "double",
  "longitude": "double",
  "address": "string",
  "images": ["url1", "url2"],
  "createdBy": "userId",
  "createdAt": "timestamp",
  "status": "available"
}
```

---

Este diseño está optimizado para ser moderno, intuitivo y fácil de usar, con validaciones claras y feedback visual inmediato.
