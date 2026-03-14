@echo off
echo ========================================
echo  INSTALAR NOTIFICACIONES PUSH - LaboraYa
echo ========================================
echo.

echo [1/5] Verificando Node.js...
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js no esta instalado
    echo Descarga desde: https://nodejs.org/
    pause
    exit /b 1
)
echo OK - Node.js instalado
echo.

echo [2/5] Verificando Firebase CLI...
firebase --version >nul 2>&1
if errorlevel 1 (
    echo Instalando Firebase CLI...
    npm install -g firebase-tools
    if errorlevel 1 (
        echo ERROR: No se pudo instalar Firebase CLI
        pause
        exit /b 1
    )
)
echo OK - Firebase CLI instalado
echo.

echo [3/5] Iniciando sesion en Firebase...
firebase login
if errorlevel 1 (
    echo ERROR: No se pudo iniciar sesion
    pause
    exit /b 1
)
echo OK - Sesion iniciada
echo.

echo [4/5] Instalando dependencias...
cd functions
call npm install
if errorlevel 1 (
    echo ERROR: No se pudieron instalar las dependencias
    cd ..
    pause
    exit /b 1
)
cd ..
echo OK - Dependencias instaladas
echo.

echo [5/5] Desplegando Cloud Functions...
firebase deploy --only functions
if errorlevel 1 (
    echo ERROR: No se pudieron desplegar las functions
    pause
    exit /b 1
)
echo.

echo ========================================
echo  INSTALACION COMPLETADA
echo ========================================
echo.
echo Las notificaciones push ya estan activas!
echo.
echo Para verificar:
echo 1. Ve a Firebase Console
echo 2. Selecciona "Functions"
echo 3. Deberias ver: onJobAccepted y onNewMessage
echo.
pause
