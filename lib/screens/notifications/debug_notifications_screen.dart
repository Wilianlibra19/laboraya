import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/user_service.dart';
import '../../utils/constants.dart';

class DebugNotificationsScreen extends StatelessWidget {
  const DebugNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserService>().currentUser;
    
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Debug Notificaciones')),
        body: const Center(child: Text('Debes iniciar sesión')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Notificaciones'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Usuario Actual',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('ID: ${currentUser.id}'),
                    Text('Nombre: ${currentUser.name}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Botón para crear notificación de prueba
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('notifications').add({
                    'userId': currentUser.id,
                    'title': 'Notificación de Prueba',
                    'body': 'Esta es una notificación de prueba creada manualmente',
                    'type': 'general',
                    'isRead': false,
                    'createdAt': Timestamp.now(),
                  });
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Notificación de prueba creada'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear Notificación de Prueba'),
            ),
            
            const SizedBox(height: 16),
            
            // Botón para limpiar todas las notificaciones
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final snapshot = await FirebaseFirestore.instance
                      .collection('notifications')
                      .where('userId', isEqualTo: currentUser.id)
                      .get();
                  
                  final batch = FirebaseFirestore.instance.batch();
                  for (var doc in snapshot.docs) {
                    batch.delete(doc.reference);
                  }
                  await batch.commit();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ ${snapshot.docs.length} notificaciones eliminadas'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Limpiar Todas las Notificaciones'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            const Text(
              'Todas las Notificaciones (Raw)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Stream de TODAS las notificaciones sin filtro
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No hay notificaciones en la base de datos');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: ${snapshot.data!.docs.length} notificaciones',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final userId = data['userId'] ?? 'N/A';
                      final isMine = userId == currentUser.id;
                      
                      return Card(
                        color: isMine ? Colors.green[50] : null,
                        child: ListTile(
                          title: Text(data['title'] ?? 'Sin título'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['body'] ?? 'Sin cuerpo'),
                              const SizedBox(height: 4),
                              Text(
                                'userId: $userId ${isMine ? "(TÚ)" : ""}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isMine ? Colors.green : Colors.grey,
                                  fontWeight: isMine ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              Text(
                                'isRead: ${data['isRead']}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                'type: ${data['type']}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await doc.reference.delete();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Notificación eliminada')),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
