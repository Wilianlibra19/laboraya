@echo off
REM 🚀 Script de Instalación Rápida - Sistema de Pagos LaboraYa (Windows)
REM Este script configura Firebase Functions y el sistema de webhooks

echo 🚀 Configurando Sistema de Pagos LaboraYa...
echo.

REM Verificar Node.js
echo 📦 Verificando Node.js...
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Node.js no está instalado
    echo Instala Node.js desde: https://nodejs.org
    pause
    exit /b 1
)
node --version
echo ✅ Node.js instalado
echo.

REM Verificar Firebase CLI
echo 🔥 Verificando Firebase CLI...
where firebase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ⚠️  Firebase CLI no está instalado
    echo Instalando Firebase CLI...
    npm install -g firebase-tools
)
firebase --version
echo ✅ Firebase CLI instalado
echo.

REM Login a Firebase
echo 🔐 Iniciando sesión en Firebase...
firebase login
echo.

REM Instalar dependencias de Flutter
echo 📱 Instalando dependencias de Flutter...
flutter pub get
echo ✅ Dependencias de Flutter instaladas
echo.

REM Instalar dependencias de Functions
echo ⚡ Instalando dependencias de Firebase Functions...
cd functions
call npm install
cd ..
echo ✅ Dependencias de Functions instaladas
echo.

REM Configurar variables de entorno
echo 🔑 Configurando variables de entorno...
echo.
echo Necesitas tus API Keys de Culqi:
echo 1. Ve a: https://integ-panel.culqi.com
echo 2. Desarrollo → Llaves API
echo.

set /p CULQI_SECRET_KEY="Ingresa tu SECRET KEY de Culqi (sk_test_XXX): "
set /p CULQI_WEBHOOK_SECRET="Ingresa tu WEBHOOK SECRET de Culqi (opcional por ahora): "

if "%CULQI_WEBHOOK_SECRET%"=="" (
    set CULQI_WEBHOOK_SECRET=webhook_secret_placeholder
)

firebase functions:config:set culqi.secret_key="%CULQI_SECRET_KEY%"
firebase functions:config:set culqi.webhook_secret="%CULQI_WEBHOOK_SECRET%"

echo ✅ Variables configuradas
echo.

REM Desplegar Functions
echo 🚀 Desplegando Firebase Functions...
echo Esto puede tomar 2-5 minutos...
firebase deploy --only functions

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ ¡Firebase Functions desplegadas exitosamente!
    echo.
    echo 📋 PRÓXIMOS PASOS:
    echo.
    echo 1. Copia la URL del webhook que aparece arriba
    echo    Busca: Function URL (culqiWebhook^)
    echo.
    echo 2. Ve a Culqi: https://integ-panel.culqi.com
    echo    → Desarrollo → Webhooks → Crear Webhook
    echo.
    echo 3. Configura el webhook:
    echo    - URL: La URL que copiaste
    echo    - Eventos: charge.succeeded, charge.failed
    echo.
    echo 4. Copia el Webhook Secret de Culqi y actualiza:
    echo    firebase functions:config:set culqi.webhook_secret="TU_SECRET"
    echo    firebase deploy --only functions
    echo.
    echo 5. ¡Prueba el sistema!
    echo    - Abre la app
    echo    - Ve a Mis Créditos
    echo    - Compra un paquete con tarjeta de prueba
    echo.
    echo 📚 Lee CONFIGURAR_WEBHOOKS.md para más detalles
    echo.
) else (
    echo.
    echo ❌ Error desplegando Functions
    echo Revisa los errores arriba y vuelve a intentar
    pause
    exit /b 1
)

pause
