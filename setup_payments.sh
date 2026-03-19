#!/bin/bash

# 🚀 Script de Instalación Rápida - Sistema de Pagos LaboraYa
# Este script configura Firebase Functions y el sistema de webhooks

echo "🚀 Configurando Sistema de Pagos LaboraYa..."
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar Node.js
echo "📦 Verificando Node.js..."
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js no está instalado${NC}"
    echo "Instala Node.js desde: https://nodejs.org"
    exit 1
fi
echo -e "${GREEN}✅ Node.js instalado: $(node --version)${NC}"
echo ""

# Verificar Firebase CLI
echo "🔥 Verificando Firebase CLI..."
if ! command -v firebase &> /dev/null; then
    echo -e "${YELLOW}⚠️  Firebase CLI no está instalado${NC}"
    echo "Instalando Firebase CLI..."
    npm install -g firebase-tools
fi
echo -e "${GREEN}✅ Firebase CLI instalado: $(firebase --version)${NC}"
echo ""

# Login a Firebase
echo "🔐 Iniciando sesión en Firebase..."
firebase login
echo ""

# Instalar dependencias de Flutter
echo "📱 Instalando dependencias de Flutter..."
flutter pub get
echo -e "${GREEN}✅ Dependencias de Flutter instaladas${NC}"
echo ""

# Instalar dependencias de Functions
echo "⚡ Instalando dependencias de Firebase Functions..."
cd functions
npm install
cd ..
echo -e "${GREEN}✅ Dependencias de Functions instaladas${NC}"
echo ""

# Configurar variables de entorno
echo "🔑 Configurando variables de entorno..."
echo ""
echo -e "${YELLOW}Necesitas tus API Keys de Culqi:${NC}"
echo "1. Ve a: https://integ-panel.culqi.com"
echo "2. Desarrollo → Llaves API"
echo ""

read -p "Ingresa tu SECRET KEY de Culqi (sk_test_XXX): " CULQI_SECRET_KEY
read -p "Ingresa tu WEBHOOK SECRET de Culqi (opcional por ahora): " CULQI_WEBHOOK_SECRET

if [ -z "$CULQI_WEBHOOK_SECRET" ]; then
    CULQI_WEBHOOK_SECRET="webhook_secret_placeholder"
fi

firebase functions:config:set culqi.secret_key="$CULQI_SECRET_KEY"
firebase functions:config:set culqi.webhook_secret="$CULQI_WEBHOOK_SECRET"

echo -e "${GREEN}✅ Variables configuradas${NC}"
echo ""

# Desplegar Functions
echo "🚀 Desplegando Firebase Functions..."
echo "Esto puede tomar 2-5 minutos..."
firebase deploy --only functions

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ ¡Firebase Functions desplegadas exitosamente!${NC}"
    echo ""
    echo "📋 PRÓXIMOS PASOS:"
    echo ""
    echo "1. Copia la URL del webhook que aparece arriba"
    echo "   Busca: Function URL (culqiWebhook)"
    echo ""
    echo "2. Ve a Culqi: https://integ-panel.culqi.com"
    echo "   → Desarrollo → Webhooks → Crear Webhook"
    echo ""
    echo "3. Configura el webhook:"
    echo "   - URL: La URL que copiaste"
    echo "   - Eventos: charge.succeeded, charge.failed"
    echo ""
    echo "4. Copia el Webhook Secret de Culqi y actualiza:"
    echo "   firebase functions:config:set culqi.webhook_secret=\"TU_SECRET\""
    echo "   firebase deploy --only functions"
    echo ""
    echo "5. ¡Prueba el sistema!"
    echo "   - Abre la app"
    echo "   - Ve a Mis Créditos"
    echo "   - Compra un paquete con tarjeta de prueba"
    echo ""
    echo -e "${GREEN}📚 Lee CONFIGURAR_WEBHOOKS.md para más detalles${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Error desplegando Functions${NC}"
    echo "Revisa los errores arriba y vuelve a intentar"
    exit 1
fi
