import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidad'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Política de Privacidad',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '1. Información que recopilamos',
            content: 'Recopilamos información que nos proporcionas directamente, como tu nombre, correo electrónico, foto de perfil, ubicación y detalles de los trabajos que publicas o aceptas.',
          ),
          _buildSection(
            title: '2. Cómo usamos tu información',
            content: 'Usamos tu información para:\n• Proporcionar y mejorar nuestros servicios\n• Conectarte con otros usuarios\n• Enviar notificaciones sobre trabajos y mensajes\n• Procesar pagos\n• Prevenir fraudes',
          ),
          _buildSection(
            title: '3. Compartir información',
            content: 'Tu información de perfil (nombre, foto, calificación) es visible para otros usuarios. No compartimos tu información personal con terceros sin tu consentimiento.',
          ),
          _buildSection(
            title: '4. Seguridad',
            content: 'Implementamos medidas de seguridad para proteger tu información, incluyendo encriptación y autenticación segura.',
          ),
          _buildSection(
            title: '5. Tus derechos',
            content: 'Tienes derecho a:\n• Acceder a tu información\n• Corregir información incorrecta\n• Eliminar tu cuenta\n• Exportar tus datos',
          ),
          _buildSection(
            title: '6. Contacto',
            content: 'Si tienes preguntas sobre nuestra política de privacidad, contáctanos en: soporte@laboraya.com',
          ),
          const SizedBox(height: 16),
          Text(
            'Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
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
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}
