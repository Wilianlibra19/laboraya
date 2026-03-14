import 'package:hive_flutter/hive_flutter.dart';
import '../../core/models/user_model.dart';
import '../../core/models/job_model.dart';
import '../../core/models/message_model.dart';
import '../../core/models/document_model.dart';

class HiveService {
  static const String usersBox = 'users';
  static const String jobsBox = 'jobs';
  static const String messagesBox = 'messages';
  static const String documentsBox = 'documents';
  static const String currentUserBox = 'currentUser';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(JobModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MessageModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(DocumentModelAdapter());
    }

    // Open boxes
    await Hive.openBox<UserModel>(usersBox);
    await Hive.openBox<JobModel>(jobsBox);
    await Hive.openBox<MessageModel>(messagesBox);
    await Hive.openBox<DocumentModel>(documentsBox);
    await Hive.openBox(currentUserBox);
  }

  static Box<UserModel> getUsersBox() => Hive.box<UserModel>(usersBox);
  static Box<JobModel> getJobsBox() => Hive.box<JobModel>(jobsBox);
  static Box<MessageModel> getMessagesBox() => Hive.box<MessageModel>(messagesBox);
  static Box<DocumentModel> getDocumentsBox() => Hive.box<DocumentModel>(documentsBox);
  static Box getCurrentUserBox() => Hive.box(currentUserBox);
}
