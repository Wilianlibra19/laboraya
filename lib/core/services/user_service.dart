import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import './cloudinary_service.dart';

class UserService extends ChangeNotifier {
  final UserRepository _repository;
  UserModel? _currentUser;
  bool _isLoading = false;

  UserService(this._repository);

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _repository.getCurrentUser();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String userId) async {
    try {
      await _repository.setCurrentUser(userId);
      await loadCurrentUser();
    } catch (e) {
      debugPrint('Error in login: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile(UserModel user) async {
    await _repository.updateUser(user);
    if (_currentUser?.id == user.id) {
      _currentUser = user;
      notifyListeners();
    }
  }

  Future<UserModel?> getUserById(String id) async {
    return _repository.getUserById(id);
  }

  Future<void> createUser(UserModel user) async {
    await _repository.createUser(user);
  }

  Future<String?> uploadProfilePhoto(String imagePath) async {
    try {
      // Usar la misma carpeta que los trabajos para evitar problemas
      final photoUrl = await CloudinaryService.uploadImage(
        imagePath: imagePath,
        folder: 'laboraya/jobs', // Usar la misma carpeta que funciona
      );
      return photoUrl;
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      rethrow;
    }
  }

  Future<void> updateUserDocuments(String userId, List<String> documentUrls) async {
    try {
      final user = await _repository.getUserById(userId);
      if (user != null) {
        final updatedUser = UserModel(
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          photo: user.photo,
          rating: user.rating,
          completedJobs: user.completedJobs,
          createdAt: user.createdAt,
          documents: documentUrls, // Actualizar documentos
          district: user.district,
          skills: user.skills,
          availability: user.availability,
          description: user.description,
          isDniVerified: user.isDniVerified,
          isPhoneVerified: user.isPhoneVerified,
          isDocumentVerified: user.isDocumentVerified,
          totalEarnings: user.totalEarnings,
          monthlyEarnings: user.monthlyEarnings,
          totalReviews: user.totalReviews,
        );
        await _repository.updateUser(updatedUser);
        
        // Si es el usuario actual, actualizar en memoria
        if (_currentUser?.id == userId) {
          _currentUser = updatedUser;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error updating user documents: $e');
      rethrow;
    }
  }
}
