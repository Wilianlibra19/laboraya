import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/user_service.dart';
import '../../core/services/notification_cleanup_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../job/job_detail_screen.dart';
import 'debug_notifications_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserService>().currentUser;
    
    print('🔔 NotificationsScreen - Usuario actual: ${currentUser?.id}');
    print('🔔 NotificationsScreen - Nombre: ${currentUser?.name}');
    
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notificaciones')),
        body: const Center(child: Text('Debes iniciar sesión')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DebugNotificationsScreen(),
                ),
              );
            },
            tooltip: 'Debug',
          ),
          TextButton(
            onPressed: () async {
              // Marcar todas como leídas
              final batch = FirebaseFirestore.instance.batch();
              final snapshot = await FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: currentUser.id)
                  .where('isRead', isEqualTo: false)
                  .get();
              
              for (var doc in snapshot.docs) {
                batch.update(doc.reference, {'isRead': true});
              }
              await batch.commit();
            },
            child: const Text('Marcar todas como leídas'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUser.id)
            .snapshots(),
        builder: (context, snapshot) {
          print('🔔 NotificationsScreen - Estado: ${snapshot.connectionState}');
          print('🔔 Tiene datos: ${snapshot.hasData}');
          print('🔔 Cantidad de docs: ${snapshot.data?.docs.length ?? 0}');
          
          if (snapshot.hasError) {
            print('❌ Error en notificaciones: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(fontSize: 14, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Intentar recargar
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print('⚠️ No hay notificaciones para mostrar');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Usuario ID: ${currentUser.id}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await NotificationCleanupService.createTestNotification(currentUser.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Notificación de prueba creada'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Notificación de Prueba'),
                  ),
                ],
              ),
            );
          }

          // Ordenar manualmente por fecha (más reciente primero)
          final notifications = snapshot.data!.docs.toList();
          notifications.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime); // Descendente
          });

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final data = notif.data() as Map<String, dynamic>;
              
              final title = data['title'] ?? '';
              final body = data['body'] ?? '';
              final isRead = data['isRead'] ?? false;
              final type = data['type'] ?? 'general';
              final jobId = data['jobId'];
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

              return Dismissible(
                key: Key(notif.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(notif.id)
                      .delete();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notificación eliminada')),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isRead 
                        ? null 
                        : AppColors.primary.withOpacity(0.05),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[300]!,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getIconColor(type).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIcon(type),
                        color: _getIconColor(type),
                        size: 24,
                      ),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            Helpers.formatRelativeTime(createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: !isRead
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onTap: () async {
                      // Marcar como leída
                      if (!isRead) {
                        await FirebaseFirestore.instance
                            .collection('notifications')
                            .doc(notif.id)
                            .update({'isRead': true});
                      }

                      // Navegar según el tipo
                      if (jobId != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobDetailScreen(jobId: jobId),
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'job_accepted':
        return Icons.handshake;
      case 'job_on_the_way':
        return Icons.directions_car;
      case 'job_started':
        return Icons.construction;
      case 'job_finished':
        return Icons.check_circle;
      case 'job_confirmed':
        return Icons.verified;
      case 'message':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'job_accepted':
        return Colors.green;
      case 'job_on_the_way':
        return Colors.blue;
      case 'job_started':
        return Colors.orange;
      case 'job_finished':
        return Colors.purple;
      case 'job_confirmed':
        return Colors.teal;
      case 'message':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }
}
