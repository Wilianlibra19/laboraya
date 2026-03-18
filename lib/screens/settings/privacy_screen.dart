import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                _buildIntroCard(isDark),
                const SizedBox(height: 16),
                _buildSectionCard(
                  isDark: isDark,
                  index: '1',
                  title: 'Información que recopilamos',
                  icon: Icons.inventory_2_outlined,
                  iconColor: AppColors.primary,
                  content:
                      'Recopilamos información que nos proporcionas directamente, como tu nombre, correo electrónico, foto de perfil, ubicación y detalles de los trabajos que publicas o aceptas.',
                ),
                const SizedBox(height: 14),
                _buildSectionCard(
                  isDark: isDark,
                  index: '2',
                  title: 'Cómo usamos tu información',
                  icon: Icons.settings_suggest_outlined,
                  iconColor: Colors.green,
                  content:
                      'Usamos tu información para:\n\n'
                      '• Proporcionar y mejorar nuestros servicios\n'
                      '• Conectarte con otros usuarios\n'
                      '• Enviar notificaciones sobre trabajos y mensajes\n'
                      '• Procesar pagos\n'
                      '• Prevenir fraudes',
                ),
                const SizedBox(height: 14),
                _buildSectionCard(
                  isDark: isDark,
                  index: '3',
                  title: 'Compartir información',
                  icon: Icons.people_outline_rounded,
                  iconColor: Colors.orange,
                  content:
                      'Tu información de perfil (nombre, foto, calificación) es visible para otros usuarios. No compartimos tu información personal con terceros sin tu consentimiento.',
                ),
                const SizedBox(height: 14),
                _buildSectionCard(
                  isDark: isDark,
                  index: '4',
                  title: 'Seguridad',
                  icon: Icons.shield_outlined,
                  iconColor: Colors.purple,
                  content:
                      'Implementamos medidas de seguridad para proteger tu información, incluyendo encriptación y autenticación segura.',
                ),
                const SizedBox(height: 14),
                _buildSectionCard(
                  isDark: isDark,
                  index: '5',
                  title: 'Tus derechos',
                  icon: Icons.verified_user_outlined,
                  iconColor: Colors.teal,
                  content:
                      'Tienes derecho a:\n\n'
                      '• Acceder a tu información\n'
                      '• Corregir información incorrecta\n'
                      '• Eliminar tu cuenta\n'
                      '• Exportar tus datos',
                ),
                const SizedBox(height: 14),
                _buildSectionCard(
                  isDark: isDark,
                  index: '6',
                  title: 'Contacto',
                  icon: Icons.support_agent_rounded,
                  iconColor: Colors.redAccent,
                  content:
                      'Si tienes preguntas sobre nuestra política de privacidad, contáctanos en:\n\n'
                      'soporte@laboraya.com',
                ),
                const SizedBox(height: 18),
                _buildFooterCard(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 24),
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
            color: AppColors.primary.withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _HeaderBackButton(
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacidad',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cómo protegemos tu información en LaboraYa',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.privacy_tip_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : const Color(0xFFE8EEF6),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shield_moon_outlined,
              color: Colors.green,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu privacidad es importante',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Esta política explica qué datos usamos, cómo los protegemos y qué control tienes sobre tu información.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AppColors.grey,
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
    required String index,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : const Color(0xFFE8EEF6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    index,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF162033),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 14.3,
              height: 1.65,
              color: isDark ? Colors.white70 : const Color(0xFF4D5B72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterCard(bool isDark) {
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.14),
            Colors.green.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.green.withOpacity(0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: Colors.green,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Compromiso de seguridad',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Aplicamos buenas prácticas de seguridad para cuidar tu cuenta y tu información personal dentro de la app.',
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Última actualización: ${now.day}/${now.month}/${now.year}',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.white60 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HeaderBackButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
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