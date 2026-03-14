@echo off
echo ========================================
echo Limpiando proyecto Flutter...
echo ========================================

REM Limpiar Flutter
echo.
echo [1/5] Limpiando cache de Flutter...
call flutter clean

REM Eliminar carpetas problemáticas
echo.
echo [2/5] Eliminando carpetas de build...
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool

REM Obtener dependencias
echo.
echo [3/5] Obteniendo dependencias...
call flutter pub get

REM Generar archivos Hive
echo.
echo [4/5] Generando archivos Hive...
call flutter pub run build_runner build --delete-conflicting-outputs

REM Intentar build
echo.
echo [5/5] Intentando build...
call flutter build apk --debug

echo.
echo ========================================
echo Proceso completado
echo ========================================
pause
