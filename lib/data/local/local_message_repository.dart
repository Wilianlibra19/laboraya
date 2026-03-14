import '../../core/models/message_model.dart';
import '../../core/repositories/message_repository.dart';
import 'hive_service.dart';

class LocalMessageRepository implements MessageRepository {
  @override
  Future<List<MessageModel>> getMessagesByJob(String jobId) async {
    final box = HiveService.getMessagesBox();
    return box.values.where((msg) => msg.jobId == jobId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    final box = HiveService.getMessagesBox();
    await box.put(message.id, message);
  }

  @override
  Future<void> deleteMessage(String id) async {
    final box = HiveService.getMessagesBox();
    await box.delete(id);
  }
}
