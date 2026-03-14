import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../repositories/message_repository.dart';
import './notification_service.dart';

class MessageService extends ChangeNotifier {
  final MessageRepository _repository;
  Map<String, List<MessageModel>> _messagesByJob = {};
  Map<String, List<MessageModel>> _conversations = {};

  MessageService(this._repository);

  // Exponer el repository para acceder a métodos específicos
  MessageRepository get repository => _repository;

  Map<String, List<MessageModel>> get conversations => _conversations;

  List<MessageModel> getMessages(String jobId) {
    return _messagesByJob[jobId] ?? [];
  }

  Future<void> loadMessages(String jobId) async {
    final messages = await _repository.getMessages(jobId);
    _messagesByJob[jobId] = messages;
    notifyListeners();
  }

  Future<void> loadAllConversations(String userId) async {
    _conversations = await _repository.getAllConversations(userId);
    notifyListeners();
  }

  Future<void> sendMessage(MessageModel message) async {
    await _repository.sendMessage(message);
    // El Stream actualizará automáticamente los mensajes
    // Solo notificamos para actualizar otras partes de la UI si es necesario
    notifyListeners();
  }

  Map<String, MessageModel> getLastMessages() {
    Map<String, MessageModel> lastMessages = {};
    _messagesByJob.forEach((jobId, messages) {
      if (messages.isNotEmpty) {
        lastMessages[jobId] = messages.last;
      }
    });
    return lastMessages;
  }
}
