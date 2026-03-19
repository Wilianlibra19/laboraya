@echo off
echo Desplegando reglas de Firestore...
call firebase deploy --only firestore:rules
echo.
echo Reglas desplegadas exitosamente!
pause
