# 🎁 Sistema de Referidos - Cómo Funciona

## 📋 Resumen

- **Referir amigo**: +40 créditos (4 publicaciones)
- **Solo se dan créditos cuando el amigo SE REGISTRA**
- **Cada usuario tiene un código único**

## 🔄 Flujo Completo

### 1. Usuario A (Referidor)
```
1. Va a "Referir Amigos" en el menú
2. Ve su código único (ejemplo: ABC123)
3. Comparte el código con amigos
4. Espera a que se registren
```

### 2. Usuario B (Nuevo Usuario)
```
1. Descarga la app
2. Se registra (nombre, email, contraseña)
3. Recibe 500 créditos gratis
4. OPCIONAL: Puede ingresar código de referido
5. Si ingresa ABC123 → Usuario A recibe 40 créditos
```

### 3. Sistema Automático
```
1. Usuario B ingresa código ABC123
2. Sistema busca en Firebase quién tiene ese código
3. Encuentra a Usuario A
4. Verifica que:
   - El código existe
   - Usuario B no usó otro código antes
   - Usuario B no es el mismo que Usuario A
5. Si todo OK:
   - Usuario A recibe +40 créditos
   - Se guarda registro en Firebase
   - Usuario B queda marcado como "referido por A"
```

## 🎯 Cómo Saber si se Registró

El sistema sabe automáticamente porque:

1. **Código Único**: Cada usuario tiene un código único generado al registrarse
2. **Firebase Guarda Todo**: 
   - Quién refirió a quién
   - Cuándo se registró
   - Cuántos créditos se dieron
3. **Solo Una Vez**: Cada usuario solo puede usar UN código de referido
4. **Registro en Tiempo Real**: Los créditos se agregan automáticamente

## 📊 Ejemplo Real

```
Usuario: Juan
Código: JUAN99

Juan comparte JUAN99 con 3 amigos:

Amigo 1 (María):
- Se registra
- Ingresa código JUAN99
- Juan recibe +40 créditos ✅

Amigo 2 (Pedro):
- Se registra
- NO ingresa código
- Juan NO recibe créditos ❌

Amigo 3 (Ana):
- Se registra
- Ingresa código JUAN99
- Juan recibe +40 créditos ✅

Total: Juan ganó 80 créditos (2 referidos exitosos)
```

## 🔍 Dónde Ver los Referidos

En la pantalla "Referir Amigos":
- **Mi código**: ABC123
- **Amigos referidos**: 5 personas
- **Créditos ganados**: 200 créditos (5 × 40)
- **Créditos totales**: 700 créditos

## 💡 Importante

### ✅ Se Dan Créditos Cuando:
- El amigo completa el registro
- El amigo ingresa tu código
- El código es válido
- El amigo no usó otro código antes

### ❌ NO Se Dan Créditos Cuando:
- El amigo solo descarga la app (no se registra)
- El amigo se registra pero no ingresa código
- El código es inválido
- El amigo ya usó otro código antes
- Intentas usar tu propio código

## 🎮 Para Probar

1. Crea Usuario A
2. Ve a "Referir Amigos"
3. Copia el código (ejemplo: ABC123)
4. Cierra sesión
5. Crea Usuario B (nuevo)
6. En el registro, ingresa código ABC123
7. Completa el registro
8. Inicia sesión con Usuario A
9. Ve a "Referir Amigos"
10. Verás: +40 créditos, 1 referido

## 📱 Compartir Código

Los usuarios pueden compartir su código por:
- WhatsApp
- Facebook
- Instagram
- SMS
- Copiar y pegar

El mensaje dice:
```
¡Únete a LaboraYa con mi código ABC123 y recibe 500 créditos gratis!
```

## 🔒 Seguridad

- ✅ Cada código es único
- ✅ No se puede usar el mismo código dos veces
- ✅ No puedes referirte a ti mismo
- ✅ Todo se guarda en Firebase
- ✅ Imposible hacer trampa

¡El sistema está listo y funciona automáticamente! 🚀
