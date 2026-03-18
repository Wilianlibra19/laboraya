import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();
    final formattedDate =
        '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
      body: Column(
        children: [
          _buildHeader(context, formattedDate),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroCard(isDark, formattedDate),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '1. Introducción',
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.primary,
                    content:
                        'En LaboraYa, nos comprometemos a proteger su privacidad. Esta Política de Privacidad explica cómo recopilamos, usamos, compartimos y protegemos su información personal.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '2. Información que recopilamos',
                    icon: Icons.folder_outlined,
                    iconColor: Colors.indigo,
                    content:
                        'Recopilamos la siguiente información:\n\n'
                        '• Información de registro: nombre, email, teléfono, foto de perfil\n'
                        '• Información de ubicación: para mostrar trabajos cercanos\n'
                        '• Información de trabajos: publicaciones, mensajes, calificaciones\n'
                        '• Información de pago: datos de transacciones (procesados por terceros)\n'
                        '• Información del dispositivo: tipo de dispositivo, sistema operativo\n'
                        '• Información de uso: cómo interactúa con la aplicación',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '3. Cómo usamos su información',
                    icon: Icons.settings_suggest_outlined,
                    iconColor: Colors.green,
                    content:
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
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '4. Compartir información',
                    icon: Icons.share_outlined,
                    iconColor: Colors.orange,
                    content:
                        'Compartimos su información con:\n\n'
                        '• Otros usuarios: nombre, foto, calificaciones, ubicación aproximada\n'
                        '• Proveedores de servicios: procesamiento de pagos, almacenamiento en la nube\n'
                        '• Autoridades legales: cuando sea requerido por ley\n'
                        '• Compradores potenciales: en caso de venta o fusión de la empresa\n\n'
                        'NO vendemos su información personal a terceros para marketing.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '5. Almacenamiento de datos',
                    icon: Icons.cloud_outlined,
                    iconColor: Colors.lightBlue,
                    content:
                        'Sus datos se almacenan en:\n\n'
                        '• Firebase (Google Cloud): base de datos y autenticación\n'
                        '• Cloudinary: imágenes y documentos\n'
                        '• Servidores ubicados en Estados Unidos\n\n'
                        'Implementamos medidas de seguridad para proteger sus datos, incluyendo encriptación y controles de acceso.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '6. Retención de datos',
                    icon: Icons.history_toggle_off_rounded,
                    iconColor: Colors.teal,
                    content:
                        'Conservamos su información mientras:\n\n'
                        '• Su cuenta esté activa\n'
                        '• Sea necesario para proporcionar servicios\n'
                        '• Sea requerido por ley\n\n'
                        'Después de eliminar su cuenta, conservamos algunos datos por 90 días para cumplir con obligaciones legales.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '7. Sus derechos',
                    icon: Icons.gavel_outlined,
                    iconColor: Colors.purple,
                    content:
                        'Usted tiene derecho a:\n\n'
                        '• Acceder a su información personal\n'
                        '• Corregir información inexacta\n'
                        '• Eliminar su cuenta y datos\n'
                        '• Exportar sus datos\n'
                        '• Oponerse al procesamiento de sus datos\n'
                        '• Retirar su consentimiento\n'
                        '• Presentar una queja ante la autoridad de protección de datos',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '8. Seguridad',
                    icon: Icons.shield_outlined,
                    iconColor: Colors.green,
                    content:
                        'Implementamos medidas de seguridad que incluyen:\n\n'
                        '• Encriptación de datos en tránsito y en reposo\n'
                        '• Autenticación segura con Firebase\n'
                        '• Controles de acceso estrictos\n'
                        '• Monitoreo de actividad sospechosa\n'
                        '• Auditorías de seguridad regulares\n\n'
                        'Sin embargo, ningún sistema es 100% seguro. Usted es responsable de mantener su contraseña segura.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '9. Cookies y tecnologías similares',
                    icon: Icons.cookie_outlined,
                    iconColor: Colors.brown,
                    content:
                        'Usamos cookies y tecnologías similares para:\n\n'
                        '• Mantener su sesión activa\n'
                        '• Recordar sus preferencias\n'
                        '• Analizar el uso de la aplicación\n'
                        '• Mejorar la experiencia del usuario\n\n'
                        'Puede desactivar las cookies en la configuración de su dispositivo.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '10. Privacidad de menores',
                    icon: Icons.child_care_outlined,
                    iconColor: Colors.pink,
                    content:
                        'LaboraYa no está dirigido a menores de 18 años. No recopilamos intencionalmente información de menores. Si descubrimos que hemos recopilado información de un menor, la eliminaremos inmediatamente.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '11. Transferencias internacionales',
                    icon: Icons.public_outlined,
                    iconColor: Colors.blue,
                    content:
                        'Sus datos pueden ser transferidos y procesados en países fuera de Perú, incluyendo Estados Unidos. Nos aseguramos de que estas transferencias cumplan con las leyes de protección de datos aplicables.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '12. Cambios a esta política',
                    icon: Icons.update_outlined,
                    iconColor: Colors.deepOrange,
                    content:
                        'Podemos actualizar esta Política de Privacidad periódicamente. Le notificaremos sobre cambios significativos a través de la aplicación o por email. La fecha de "Última actualización" indica cuándo se realizó el cambio más reciente.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '13. Contacto',
                    icon: Icons.mail_outline_rounded,
                    iconColor: AppColors.primary,
                    content:
                        'Si tiene preguntas sobre esta política o desea ejercer sus derechos, contáctenos:\n\n'
                        'Email: laboraya@gmail.com\n'
                        'Teléfono: +51 982 257 569\n'
                        'Dirección: Lima, Perú',
                  ),
                  const SizedBox(height: 18),
                  _buildSecurityNotice(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String formattedDate) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.88),
            const Color(0xFF67C4FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const _HeaderBackButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Política de Privacidad',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Última actualización: $formattedDate',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard(bool isDark, String formattedDate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EEF6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.privacy_tip_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu privacidad importa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF162033),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aquí encontrarás cómo recopilamos, usamos, protegemos y administramos tu información dentro de LaboraYa.',
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.55,
                    color: isDark ? Colors.white70 : const Color(0xFF5D6A79),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EEF6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MiniIconBubble(
                icon: icon,
                color: iconColor,
                backgroundColor: iconColor.withOpacity(0.10),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF162033),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.65,
              color: isDark ? Colors.white70 : const Color(0xFF536171),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNotice(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.14),
            Colors.teal.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.green.withOpacity(0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.green,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu privacidad es importante para nosotros',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF162033),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Implementamos buenas prácticas de seguridad para proteger tus datos personales dentro de la aplicación.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white70 : const Color(0xFF536171),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pop(context),
        child: const SizedBox(
          height: 42,
          width: 42,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _MiniIconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _MiniIconBubble({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}