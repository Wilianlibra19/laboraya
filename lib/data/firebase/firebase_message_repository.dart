import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/message_model.dart';
import '../../core/repositories/message_repository.dart';

class FirebaseMessageRepository implements MessageRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<MessageModel>> getMessages(String jobId) async {
    try {
      final snapshot = await _firestore
          .collection('messages')
          .where('jobId', isEqualTo: jobId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MessageModel(
          id: doc.id,
          jobId: data['jobId'] ?? '',
          senderId: data['senderId'] ?? '',
          text: data['text'] ?? '',
          image: data['image'],
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] ?? false,
          receiverId: data['receiverId'],
        );
      }).toList();
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  /// Stream de mensajes en tiempo real con caché
  Stream<List<MessageModel>> getMessagesStream(String jobId) {
    print('📡 Iniciando stream de mensajes para jobId: $jobId');
    
    return _firestore
        .collection('messages')
        .where('jobId', isEqualTo: jobId)
        .orderBy('createdAt', descending: false)
        .snapshots(includeMetadataChanges: false) // No incluir cambios de metadata para mejor performance
        .map((snapshot) {
      print('📨 Snapshot recibido: ${snapshot.docs.length} mensajes, desde caché: ${snapshot.metadata.isFromCache}');
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MessageModel(
          id: doc.id,
          jobId: data['jobId'] ?? '',
          senderId: data['senderId'] ?? '',
          text: data['text'] ?? '',
          image: data['image'],
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] ?? false,
          receiverId: data['receiverId'],
        );
      }).toList();
    });
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    try {
      print('📨 Enviando mensaje:');
      print('  - jobId: ${message.jobId}');
      print('  - senderId: ${message.senderId}');
      print('  - receiverId: ${message.receiverId}');
      print('  - text: ${message.text}');
      
      await _firestore.collection('messages').doc(message.id).set({
        'jobId': message.jobId,
        'senderId': message.senderId,
        'text': message.text,
        'image': message.image,
        'createdAt': Timestamp.fromDate(message.createdAt),
        'isRead': false,
        'receiverId': message.receiverId,
      });
      
      print('✅ Mensaje guardado exitosamente');
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  /// Obtener el número de mensajes no leídos para un usuario
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Marcar todos los mensajes de un chat como leídos
  Future<void> markMessagesAsRead(String jobId, String userId) async {
    try {
      print('📖 Marcando mensajes como leídos:');
      print('  - jobId: $jobId');
      print('  - userId (receptor): $userId');
      
      final snapshot = await _firestore
          .collection('messages')
          .where('jobId', isEqualTo: jobId)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      print('  - Mensajes no leídos encontrados: ${snapshot.docs.length}');

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
        print('    ✓ Marcando mensaje ${doc.id} como leído');
      }
      await batch.commit();
      
      print('✅ Todos los mensajes marcados como leídos');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  /// Stream de mensajes no leídos
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Future<Map<String, List<MessageModel>>> getAllConversations(String userId) async {
    try {
      print('🔍 Obteniendo conversaciones para usuario: $userId');
      
      // Obtener todos los mensajes donde el usuario es el remitente O el receptor
      final sentSnapshot = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .get();
      
      print('📤 Mensajes enviados: ${sentSnapshot.docs.length}');

      final receivedSnapshot = await _firestore
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .get();
      
      print('📥 Mensajes recibidos: ${receivedSnapshot.docs.length}');

      // Combinar todos los jobIds únicos de los mensajes
      final Set<String> jobIds = {};
      
      for (var doc in sentSnapshot.docs) {
        final jobId = doc.data()['jobId'] as String?;
        if (jobId != null) {
          jobIds.add(jobId);
          print('  ➡️ JobId de mensaje enviado: $jobId');
        }
      }
      
      for (var doc in receivedSnapshot.docs) {
        final jobId = doc.data()['jobId'] as String?;
        if (jobId != null) {
          jobIds.add(jobId);
          print('  ⬅️ JobId de mensaje recibido: $jobId');
        }
      }

      print('💬 Total de conversaciones únicas: ${jobIds.length}');

      // Obtener mensajes para cada trabajo
      final Map<String, List<MessageModel>> conversations = {};
      for (var jobId in jobIds) {
        final messages = await getMessages(jobId);
        if (messages.isNotEmpty) {
          conversations[jobId] = messages;
          print('  ✅ Conversación $jobId: ${messages.length} mensajes');
        }
      }

      print('📊 Total de conversaciones con mensajes: ${conversations.length}');
      return conversations;
    } catch (e) {
      print('❌ Error getting conversations: $e');
      return {};
    }
  }
}
