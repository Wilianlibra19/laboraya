import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/user_service.dart';
import '../../utils/constants.dart';
import 'change_password_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_screen.dart';
import 'blocked_users_screen.dart';
import '../auth/welcome_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserService>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSection(
            title: 'Cuenta',
            children: [
              _buildTile(
                icon: Icons.lock_outline,
                title: 'Cambiar contraseña',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  );
                },
              ),
              _buildTile(
                icon: Icons.email_outlined,
                title: 'Correo electrónico',
                subtitle: currentUser?.email ?? '',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Correo electrónico'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tu correo actual es:'),
                          const SizedBox(height: 8),
                          Text(
                            currentUser?.email ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Para cambiar tu correo, contacta con soporte.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const Divider(height: 32),
          _buildSection(
            title: 'Notificaciones',
            children: [
              _buildTile(
                icon: Icons.notifications_outlined,
                title: 'Configurar notificaciones',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                  );
                },
              ),
            ],
          ),
          const Divider(height: 32),
          _buildSection(
            title: 'Privacidad y Seguridad',
            children: [
              _buildTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacidad',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  );
                },
              ),
              _buildTile(
                icon: Icons.block,
                title: 'Usuarios bloqueados',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
                  );
                },
              ),
            ],
          ),
          const Divider(height: 32),
          _buildSection(
            title: 'Soporte',
            children: [
              _buildTile(
                icon: Icons.help_outline,
                title: 'Centro de ayuda',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Centro de ayuda'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¿Necesitas ayuda?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildHelpItem(
                            icon: Icons.email,
                            title: 'Email',
                            subtitle: 'soporte@laboraya.com',
                          ),
                          const SizedBox(height: 12),
                          _buildHelpItem(
                            icon: Icons.phone,
                            title: 'WhatsApp',
                            subtitle: '+51 999 999 999',
                          ),
                          const SizedBox(height: 12),
                          _buildHelpItem(
                            icon: Icons.schedule,
                            title: 'Horario',
                            subtitle: 'Lun - Vie: 9am - 6pm',
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _buildTile(
                icon: Icons.info_outline,
                title: 'Acerca de',
                subtitle: 'Versión 1.0.0',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Acerca de LaboraYa'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.work,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'LaboraYa',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Versión 1.0.0',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Encuentra trabajo cerca de ti.\nConecta con trabajadores locales.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '© 2026 LaboraYa. Todos los derechos reservados.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const Divider(height: 32),
          _buildSection(
            title: 'Zona de peligro',
            children: [
              _buildTile(
                icon: Icons.delete_forever,
                title: 'Eliminar cuenta',
                titleColor: Colors.red,
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Eliminar cuenta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ Esta acción es permanente',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Al eliminar tu cuenta:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Se eliminarán todos tus datos'),
            const Text('• Perderás acceso a tus trabajos'),
            const Text('• No podrás recuperar tu cuenta'),
            const Text('• Se eliminarán tus calificaciones'),
            const SizedBox(height: 16),
            const Text(
              'Confirma tu contraseña:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Contraseña',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              passwordController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text.trim();
              
              if (password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresa tu contraseña'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              
              // Mostrar loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Eliminando cuenta...'),
                    ],
                  ),
                ),
              );
              
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null || user.email == null) {
                  throw Exception('Usuario no encontrado');
                }
                
                final userId = user.uid; // Guardar el ID antes de cualquier operación
                print('🔴 Iniciando eliminación de cuenta para usuario: $userId');
                
                // Re-autenticar usuario
                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: password,
                );
                
                print('🔐 Re-autenticando usuario...');
                await user.reauthenticateWithCredential(credential);
                print('✅ Usuario re-autenticado');
                
                final firestore = FirebaseFirestore.instance;
                
                // Eliminar todos los datos relacionados con el usuario
                print('🗑️ Eliminando todos los datos del usuario...');
                
                // 1. Eliminar trabajos creados por el usuario
                print('  - Eliminando trabajos...');
                final jobs = await firestore
                    .collection('jobs')
                    .where('createdBy', isEqualTo: userId)
                    .get();
                for (var doc in jobs.docs) {
                  await doc.reference.delete();
                }
                print('  ✅ ${jobs.docs.length} trabajos eliminados');
                
                // 2. Eliminar mensajes enviados o recibidos
                print('  - Eliminando mensajes enviados...');
                final sentMessages = await firestore
                    .collection('messages')
                    .where('senderId', isEqualTo: userId)
                    .get();
                for (var doc in sentMessages.docs) {
                  await doc.reference.delete();
                }
                print('  ✅ ${sentMessages.docs.length} mensajes enviados eliminados');
                
                print('  - Eliminando mensajes recibidos...');
                final receivedMessages = await firestore
                    .collection('messages')
                    .where('receiverId', isEqualTo: userId)
                    .get();
                for (var doc in receivedMessages.docs) {
                  await doc.reference.delete();
                }
                print('  ✅ ${receivedMessages.docs.length} mensajes recibidos eliminados');
                
                // 3. Eliminar notificaciones
                print('  - Eliminando notificaciones...');
                final notifications = await firestore
                    .collection('notifications')
                    .where('userId', isEqualTo: userId)
                    .get();
                for (var doc in notifications.docs) {
                  await doc.reference.delete();
                }
                print('  ✅ ${notifications.docs.length} notificaciones eliminadas');
                
                // 4. Eliminar solicitudes de trabajo
                print('  - Eliminando solicitudes de trabajo...');
                final applications = await firestore
                    .collection('job_applications')
                    .where('applicantId', isEqualTo: userId)
                    .get();
                for (var doc in applications.docs) {
                  await doc.reference.delete();
                }
                print('  ✅ ${applications.docs.length} solicitudes eliminadas');
                
                // 5. Eliminar favoritos
                print('  - Eliminando favoritos...');
                final favorites = await firestore
                    .collection('favorites')
                    .where('userId', isEqualTo: userId)
                    .get();
                for (var doc in favorites.docs) {
                  await doc.reference.delete();
                }
                print('  ✅ ${favorites.docs.length} favoritos eliminados');
                
                // 6. Eliminar reportes
                print('  - Eliminando reportes...');
                final reports = await firestore
                    .collection('reports')
                    .where('reporterId', isEqualTo: userId)
                    .get();
                for (var doc in reports.docs) {
                  await doc.reference.delete();
                }
                print('  ✅ ${reports.docs.length} reportes eliminados');
                
                // 7. Eliminar calificaciones
                print('  - Eliminando calificaciones...');
                final reviews = await firestore
                    .collection('reviews')
                    .where('reviewerId', isEqualTo: userId)
                    .get();
                for (var doc in reviews.docs) {
                  await doc.reference.delete();
                }
                print('  ✅ ${reviews.docs.length} calificaciones eliminadas');
                
                // 8. Eliminar usuarios bloqueados
                print('  - Eliminando bloqueos...');
                final blocks = await firestore
                    .collection('blocked_users')
                    .where('blockerId', isEqualTo: userId)
                    .get();
                for (var doc in blocks.docs) {
                  await doc.reference.delete();
                }
                print('  ✅ ${blocks.docs.length} bloqueos eliminados');
                
                // 9. Eliminar portafolio
                print('  - Eliminando portafolio...');
                final portfolio = await firestore
                    .collection('portfolio')
                    .where('userId', isEqualTo: userId)
                    .get();
                for (var doc in portfolio.docs) {
                  await doc.reference.delete();
                }
                print('  ✅ ${portfolio.docs.length} items de portafolio eliminados');
                
                // 10. Eliminar verificaciones
                print('  - Eliminando verificaciones...');
                final verifications = await firestore
                    .collection('verifications')
                    .where('userId', isEqualTo: userId)
                    .get();
                for (var doc in verifications.docs) {
                  await doc.reference.delete();
                }
                print('  ✅ ${verifications.docs.length} verificaciones eliminadas');
                
                // 11. Eliminar referidos
                print('  - Eliminando referidos...');
                final referrals = await firestore
                    .collection('referrals')
                    .where('referrerId', isEqualTo: userId)
                    .get();
                for (var doc in referrals.docs) {
                  await doc.reference.delete();
                }
                print('  ✅ ${referrals.docs.length} referidos eliminados');
                
                // 12. Finalmente, eliminar el documento del usuario
                print('  - Eliminando documento de usuario...');
                await firestore.collection('users').doc(userId).delete();
                print('  ✅ Documento de usuario eliminado');
                
                // Eliminar cuenta de Authentication
                print('🗑️ Eliminando cuenta de Authentication...');
                await user.delete();
                print('✅ Cuenta eliminada de Authentication');
                
                // Cerrar sesión DESPUÉS de eliminar todo
                print('🚪 Cerrando sesión...');
                await context.read<UserService>().logout();
                
                if (context.mounted) {
                  // Cerrar loading
                  Navigator.pop(context);
                  
                  // Ir a pantalla de bienvenida
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cuenta y todos los datos eliminados exitosamente'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                print('❌ Error de autenticación: ${e.code} - ${e.message}');
                
                if (context.mounted) {
                  Navigator.pop(context); // Cerrar loading
                  
                  String message = 'Error al eliminar cuenta';
                  if (e.code == 'wrong-password') {
                    message = 'Contraseña incorrecta';
                  } else if (e.code == 'too-many-requests') {
                    message = 'Demasiados intentos. Intenta más tarde';
                  } else if (e.code == 'requires-recent-login') {
                    message = 'Por seguridad, cierra sesión y vuelve a iniciar';
                  } else if (e.code == 'user-not-found') {
                    message = 'Usuario no encontrado';
                  } else {
                    message = 'Error: ${e.message}';
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                print('❌ Error general: $e');
                
                if (context.mounted) {
                  Navigator.pop(context); // Cerrar loading
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } finally {
                passwordController.dispose();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar cuenta'),
          ),
        ],
      ),
    );
  }
}
