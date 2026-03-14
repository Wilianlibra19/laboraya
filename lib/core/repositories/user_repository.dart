import '../models/user_model.dart';

abstract class UserRepository {
  Future<UserModel?> getCurrentUser();
  Future<void> setCurrentUser(String userId);
  Future<UserModel?> getUserById(String id);
  Future<void> createUser(UserModel user);
  Future<void> updateUser(UserModel user);
  Future<List<UserModel>> getAllUsers();
}
