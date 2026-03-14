# 🌐 Configurar GitHub Pages para LaboraYa

## 📋 Requisitos

- Cuenta de GitHub
- Repositorio de LaboraYa en GitHub

---

## 🚀 Pasos para Configurar GitHub Pages

### 1. Subir el Código a GitHub

Si aún no tienes el repositorio en GitHub:

```bash
# Inicializar git (si no lo has hecho)
git init

# Agregar todos los archivos
git add .

# Hacer commit
git commit -m "Agregar páginas legales para Play Store"

# Crear repositorio en GitHub y conectar
git remote add origin https://github.com/TU_USUARIO/laboraya.git

# Subir código
git push -u origin main
```

### 2. Activar GitHub Pages

1. Ve a tu repositorio en GitHub
2. Click en **Settings** (Configuración)
3. En el menú lateral, click en **Pages**
4. En **Source** (Fuente), selecciona:
   - Branch: `main`
   - Folder: `/docs`
5. Click en **Save** (Guardar)

### 3. Esperar Despliegue

- GitHub Pages tardará 1-2 minutos en desplegar
- Verás un mensaje: "Your site is published at https://TU_USUARIO.github.io/laboraya/"

---

## 🔗 URLs Resultantes

Una vez desplegado, tus URLs serán:

### Página Principal
```
https://TU_USUARIO.github.io/laboraya/
```

### Términos y Condiciones
```
https://TU_USUARIO.github.io/laboraya/terminos.html
```

### Política de Privacidad
```
https://TU_USUARIO.github.io/laboraya/privacidad.html
```

---

## 📱 Usar en Play Store Console

Cuando subas tu app a Play Store, te pedirán:

### 1. Privacy Policy URL (Obligatorio)
```
https://TU_USUARIO.github.io/laboraya/privacidad.html
```

### 2. Terms of Service URL (Opcional pero recomendado)
```
https://TU_USUARIO.github.io/laboraya/terminos.html
```

---

## ✅ Verificar que Funciona

1. Abre las URLs en tu navegador
2. Verifica que se vean correctamente
3. Prueba en móvil (responsive)
4. Verifica que los enlaces funcionen

---

## 🎨 Personalizar (Opcional)

Si quieres cambiar el diseño:

1. Edita los archivos en `docs/`
2. Haz commit y push:
   ```bash
   git add docs/
   git commit -m "Actualizar diseño de páginas legales"
   git push
   ```
3. GitHub Pages se actualizará automáticamente en 1-2 minutos

---

## 🔧 Solución de Problemas

### Problema: "404 - Page not found"

**Solución:**
1. Verifica que la carpeta `docs/` esté en la rama `main`
2. Verifica que los archivos se llamen exactamente:
   - `index.html`
   - `terminos.html`
   - `privacidad.html`
3. Espera 2-3 minutos después de activar GitHub Pages

### Problema: "Los estilos no se ven"

**Solución:**
- Los estilos están inline en el HTML, deberían funcionar siempre
- Limpia la caché del navegador (Ctrl + F5)

### Problema: "No puedo acceder a Settings"

**Solución:**
- Debes ser el dueño del repositorio
- Si es un repositorio privado, GitHub Pages requiere GitHub Pro

---

## 📝 Alternativas a GitHub Pages

Si no quieres usar GitHub Pages, puedes usar:

### 1. Netlify (Gratis)
- Más fácil de configurar
- Drag & drop de la carpeta `docs/`
- URL: `https://laboraya.netlify.app`

### 2. Vercel (Gratis)
- Conecta tu repositorio de GitHub
- Despliegue automático
- URL: `https://laboraya.vercel.app`

### 3. Firebase Hosting (Gratis)
- Ya usas Firebase
- Comando: `firebase deploy --only hosting`
- URL: `https://laboraya-XXXXX.web.app`

---

## 📋 Checklist para Play Store

Antes de subir a Play Store, verifica:

- [ ] URLs públicas funcionando
- [ ] Términos y Condiciones completos
- [ ] Política de Privacidad completa
- [ ] Páginas responsive (se ven bien en móvil)
- [ ] Información de contacto correcta
- [ ] Fecha de actualización correcta
- [ ] Sin errores de ortografía

---

## 🎯 Ejemplo Completo

Si tu usuario de GitHub es `juanperez` y tu repo es `laboraya`:

```
Página principal:
https://juanperez.github.io/laboraya/

Términos:
https://juanperez.github.io/laboraya/terminos.html

Privacidad:
https://juanperez.github.io/laboraya/privacidad.html
```

Estas URLs las copias directamente en Play Store Console.

---

## 📞 Contacto en las Páginas

Las páginas ya incluyen tu información de contacto:

- **Email:** laboraya@gmail.com
- **Teléfono:** +51 982 257 569
- **Ubicación:** Lima, Perú

Si necesitas cambiarla, edita los archivos HTML en la carpeta `docs/`.

---

## ✨ Características de las Páginas

✅ Diseño profesional y moderno
✅ Responsive (se adapta a móvil)
✅ Colores de marca (azul para términos, verde para privacidad)
✅ Fácil navegación entre páginas
✅ Información completa y legal
✅ Optimizado para SEO
✅ Carga rápida

---

## 🚀 Próximos Pasos

1. Sube el código a GitHub
2. Activa GitHub Pages
3. Copia las URLs
4. Úsalas en Play Store Console
5. ¡Listo para publicar! 🎉

---

**Nota:** GitHub Pages es 100% gratis y no tiene límites de tráfico para sitios públicos.
