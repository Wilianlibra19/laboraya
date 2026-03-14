import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationCleanupService {
  static Future<void> cleanupOrphanedNotifications() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      print('🧹 Limpiando notificaciones huérfanas...');
      
      // Intentar obtener todas las notificaciones del usuario
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .get();

      print('📊 Notificaciones encontradas: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        print('✅ No hay notificaciones para limpiar');
        return;
      }

      // Eliminar todas
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
        print('  🗑️ Eliminando: ${doc.id}');
      }
      
      await batch.commit();
      print('✅ ${snapshot.docs.length} notificaciones eliminadas');
    } catch (e) {
      print('❌ Error limpiando notificaciones: $e');
    }
  }

  static Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error obteniendo contador: $e');
      return 0;
    }
  }

  static Future<void> createTestNotification(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': '🧪 Notificación de Prueba',
        'body': 'Si ves esto, las notificaciones funcionan correctamente',
        'type': 'general',
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
      
      print('✅ Notificación de prueba creada');
    } catch (e) {
      print('❌ Error creando notificación de prueba: $e');
      rethrow;
    }
  }
}
