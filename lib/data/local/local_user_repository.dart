import '../../core/models/user_model.dart';
import '../../core/repositories/user_repository.dart';
import 'hive_service.dart';

class LocalUserRepository implements UserRepository {
  @override
  Future<UserModel?> getCurrentUser() async {
    final box = HiveService.getCurrentUserBox();
    final userId = box.get('currentUserId');
    if (userId == null) return null;
    return getUserById(userId);
  }

  @override
  Future<void> setCurrentUser(String userId) async {
    final box = HiveService.getCurrentUserBox();
    await box.put('currentUserId', userId);
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    final box = HiveService.getUsersBox();
    return box.get(id);
  }

  @override
  Future<void> createUser(UserModel user) async {
    final box = HiveService.getUsersBox();
    await box.put(user.id, user);
  }

  @override
  Future<void> updateUser(UserModel user) async {
    final box = HiveService.getUsersBox();
    await box.put(user.id, user);
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    final box = HiveService.getUsersBox();
    return box.values.toList();
  }
}
