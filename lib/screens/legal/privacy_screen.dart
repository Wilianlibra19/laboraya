import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Política de Privacidad',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              '1. Introducción',
              'En LaboraYa, nos comprometemos a proteger su privacidad. Esta Política de Privacidad explica cómo recopilamos, usamos, compartimos y protegemos su información personal.',
            ),
            
            _buildSection(
              '2. Información que Recopilamos',
              'Recopilamos la siguiente información:\n\n'
              '• Información de registro: nombre, email, teléfono, foto de perfil\n'
              '• Información de ubicación: para mostrar trabajos cercanos\n'
              '• Información de trabajos: publicaciones, mensajes, calificaciones\n'
              '• Información de pago: datos de transacciones (procesados por terceros)\n'
              '• Información del dispositivo: tipo de dispositivo, sistema operativo\n'
              '• Información de uso: cómo interactúa con la aplicación',
            ),
            
            _buildSection(
              '3. Cómo Usamos su Información',
              'Usamos su información para:\n\n'
              '• Proporcionar y mejorar nuestros servicios\n'
              '• Conectar trabajadores con empleadores\n'
              '• Procesar pagos y transacciones\n'
              '• Enviar notificaciones sobre trabajos y mensajes\n'
              '• Prevenir fraude y garantizar la seguridad\n'
              '• Cumplir con obligaciones legales\n'
              '• Analizar el uso de la aplicación\n'
              '• Comunicarnos con usted sobre actualizaciones',
            ),
            
            _buildSection(
              '4. Compartir Información',
              'Compartimos su información con:\n\n'
              '• Otros usuarios: nombre, foto, calificaciones, ubicación aproximada\n'
              '• Proveedores de servicios: procesamiento de pagos, almacenamiento en la nube\n'
              '• Autoridades legales: cuando sea requerido por ley\n'
              '• Compradores potenciales: en caso de venta o fusión de la empresa\n\n'
              'NO vendemos su información personal a terceros para marketing.',
            ),
            
            _buildSection(
              '5. Almacenamiento de Datos',
              'Sus datos se almacenan en:\n\n'
              '• Firebase (Google Cloud): base de datos y autenticación\n'
              '• Cloudinary: imágenes y documentos\n'
              '• Servidores ubicados en Estados Unidos\n\n'
              'Implementamos medidas de seguridad para proteger sus datos, incluyendo encriptación y controles de acceso.',
            ),
            
            _buildSection(
              '6. Retención de Datos',
              'Conservamos su información mientras:\n\n'
              '• Su cuenta esté activa\n'
              '• Sea necesario para proporcionar servicios\n'
              '• Sea requerido por ley\n\n'
              'Después de eliminar su cuenta, conservamos algunos datos por 90 días para cumplir con obligaciones legales.',
            ),
            
            _buildSection(
              '7. Sus Derechos',
              'Usted tiene derecho a:\n\n'
              '• Acceder a su información personal\n'
              '• Corregir información inexacta\n'
              '• Eliminar su cuenta y datos\n'
              '• Exportar sus datos\n'
              '• Oponerse al procesamiento de sus datos\n'
              '• Retirar su consentimiento\n'
              '• Presentar una queja ante la autoridad de protección de datos',
            ),
            
            _buildSection(
              '8. Seguridad',
              'Implementamos medidas de seguridad que incluyen:\n\n'
              '• Encriptación de datos en tránsito y en reposo\n'
              '• Autenticación segura con Firebase\n'
              '• Controles de acceso estrictos\n'
              '• Monitoreo de actividad sospechosa\n'
              '• Auditorías de seguridad regulares\n\n'
              'Sin embargo, ningún sistema es 100% seguro. Usted es responsable de mantener su contraseña segura.',
            ),
            
            _buildSection(
              '9. Cookies y Tecnologías Similares',
              'Usamos cookies y tecnologías similares para:\n\n'
              '• Mantener su sesión activa\n'
              '• Recordar sus preferencias\n'
              '• Analizar el uso de la aplicación\n'
              '• Mejorar la experiencia del usuario\n\n'
              'Puede desactivar las cookies en la configuración de su dispositivo.',
            ),
            
            _buildSection(
              '10. Privacidad de Menores',
              'LaboraYa no está dirigido a menores de 18 años. No recopilamos intencionalmente información de menores. Si descubrimos que hemos recopilado información de un menor, la eliminaremos inmediatamente.',
            ),
            
            _buildSection(
              '11. Transferencias Internacionales',
              'Sus datos pueden ser transferidos y procesados en países fuera de Perú, incluyendo Estados Unidos. Nos aseguramos de que estas transferencias cumplan con las leyes de protección de datos aplicables.',
            ),
            
            _buildSection(
              '12. Cambios a esta Política',
              'Podemos actualizar esta Política de Privacidad periódicamente. Le notificaremos sobre cambios significativos a través de la aplicación o por email. La fecha de "Última actualización" indica cuándo se realizó el cambio más reciente.',
            ),
            
            _buildSection(
              '13. Contacto',
              'Si tiene preguntas sobre esta política o desea ejercer sus derechos, contáctenos:\n\n'
              'Email: laboraya@gmail.com\n'
              'Teléfono: +51 982 257 569\n'
              'Dirección: Lima, Perú',
            ),
            
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Colors.green,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Su privacidad es importante para nosotros',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Implementamos las mejores prácticas de seguridad para proteger sus datos personales.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
