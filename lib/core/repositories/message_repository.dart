import '../models/message_model.dart';

abstract class MessageRepository {
  Future<List<MessageModel>> getMessages(String jobId);
  Future<void> sendMessage(MessageModel message);
  Future<Map<String, List<MessageModel>>> getAllConversations(String userId);
}
