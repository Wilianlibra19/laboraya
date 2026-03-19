import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              isDark: isDark,
              title: '1. Información que Recopilamos',
              content: 'En LaboraYa recopilamos la siguiente información:\n\n'
                  '• Información de perfil: nombre, foto, ubicación, habilidades\n'
                  '• Información de contacto: correo electrónico, número de teléfono\n'
                  '• Información de trabajos: publicaciones, aplicaciones, calificaciones\n'
                  '• Información de pagos: transacciones de créditos (procesadas por Culqi)\n'
                  '• Información de uso: interacciones con la app, mensajes',
            ),
            
            _buildSection(
              isDark: isDark,
              title: '2. Cómo Usamos tu Información',
              content: 'Utilizamos tu información para:\n\n'
                  '• Proporcionar y mejorar nuestros servicios\n'
                  '• Conectar trabajadores con empleadores\n'
                  '• Procesar pagos y transacciones\n'
                  '• Enviar notificaciones relevantes\n'
                  '• Prevenir fraudes y abusos\n'
                  '• Cumplir con obligaciones legales',
            ),
            
            _buildSection(
              isDark: isDark,
              title: '3. Compartir Información',
              content: 'Tu información puede ser compartida con:\n\n'
                  '• Otros usuarios: tu perfil público es visible para todos\n'
                  '• Proveedores de servicios: Firebase, Culqi (procesamiento de pagos)\n'
                  '• Autoridades: cuando sea requerido por ley\n\n'
                  'NO vendemos tu información personal a terceros.',
            ),
            
            _buildSection(
              isDark: isDark,
              title: '4. Seguridad de Datos',
              content: 'Implementamos medidas de seguridad para proteger tu información:\n\n'
                  '• Encriptación de datos en tránsito y reposo\n'
                  '• Autenticación segura con Firebase\n'
                  '• Pagos procesados por Culqi (certificado PCI DSS)\n'
                  '• Acceso restringido a datos personales\n'
                  '• Monitoreo continuo de seguridad',
            ),
            
            _buildSection(
              isDark: isDark,
              title: '5. Tus Derechos',
              content: 'Tienes derecho a:\n\n'
                  '• Acceder a tu información personal\n'
                  '• Corregir información incorrecta\n'
                  '• Eliminar tu cuenta y datos\n'
                  '• Exportar tus datos\n'
                  '• Oponerte al procesamiento de datos\n'
                  '• Retirar consentimientos otorgados',
            ),
            
            _buildSection(
              isDark: isDark,
              title: '6. Retención de Datos',
              content: 'Conservamos tu información mientras:\n\n'
                  '• Tu cuenta esté activa\n'
                  '• Sea necesario para proporcionar servicios\n'
                  '• Sea requerido por ley\n\n'
                  'Después de eliminar tu cuenta, conservamos algunos datos por 90 días para cumplir obligaciones legales.',
            ),
            
            _buildSection(
              isDark: isDark,
              title: '7. Cookies y Tecnologías Similares',
              content: 'Utilizamos:\n\n'
                  '• Cookies de sesión para mantener tu login\n'
                  '• Analytics para mejorar la app\n'
                  '• Tokens de notificaciones push\n\n'
                  'Puedes desactivar notificaciones en la configuración de tu dispositivo.',
            ),
            
            _buildSection(
              isDark: isDark,
              title: '8. Menores de Edad',
              content: 'LaboraYa está destinado a usuarios mayores de 18 años. '
                  'No recopilamos intencionalmente información de menores de edad. '
                  'Si descubrimos que un menor ha proporcionado información, la eliminaremos inmediatamente.',
            ),
            
            _buildSection(
              isDark: isDark,
              title: '9. Cambios a esta Política',
              content: 'Podemos actualizar esta política ocasionalmente. '
                  'Te notificaremos de cambios significativos mediante:\n\n'
                  '• Notificación en la app\n'
                  '• Correo electrónico\n'
                  '• Aviso en la pantalla de inicio\n\n'
                  'El uso continuado de la app después de cambios constituye aceptación.',
            ),
            
            _buildSection(
              isDark: isDark,
              title: '10. Contacto',
              content: 'Para preguntas sobre privacidad, contáctanos:\n\n'
                  '📧 Email: privacidad@laboraya.com\n'
                  '📱 WhatsApp: +51 999 999 999\n'
                  '📍 Dirección: Lima, Perú\n\n'
                  'Responderemos en un plazo de 48 horas hábiles.',
            ),
            
            const SizedBox(height: 40),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: AppColors.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Tu privacidad es importante para nosotros. Cumplimos con las leyes de protección de datos de Perú.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required bool isDark,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF162033),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
