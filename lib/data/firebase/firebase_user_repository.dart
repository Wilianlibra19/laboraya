import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../core/models/user_model.dart';
import '../../core/repositories/user_repository.dart';

class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  @override
  Future<UserModel?> getCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    return getUserById(currentUser.uid);
  }

  @override
  Future<void> setCurrentUser(String userId) async {
    // Firebase Auth maneja esto automáticamente
    // No necesitamos guardar el ID manualmente
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    try {
      final doc = await _firestore.collection('users').doc(id).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return UserModel(
        id: doc.id,
        name: data['name'] ?? '',
        photo: data['photo'],
        phone: data['phone'] ?? '',
        email: data['email'] ?? '',
        district: data['district'] ?? '',
        rating: (data['rating'] ?? 0.0).toDouble(),
        completedJobs: data['completedJobs'] ?? 0,
        skills: List<String>.from(data['skills'] ?? []),
        availability: data['availability'] ?? '',
        description: data['description'] ?? '',
        documents: List<String>.from(data['documents'] ?? []),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isDniVerified: data['isDniVerified'] ?? false,
        isPhoneVerified: data['isPhoneVerified'] ?? false,
        isDocumentVerified: data['isDocumentVerified'] ?? false,
        totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
        monthlyEarnings: (data['monthlyEarnings'] ?? 0.0).toDouble(),
        totalReviews: data['totalReviews'] ?? 0,
        credits: data['credits'] ?? 0,
      );
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  @override
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set({
        'name': user.name,
        'photo': user.photo,
        'phone': user.phone,
        'email': user.email,
        'district': user.district,
        'rating': user.rating,
        'completedJobs': user.completedJobs,
        'skills': user.skills,
        'availability': user.availability,
        'description': user.description,
        'documents': user.documents,
        'createdAt': Timestamp.fromDate(user.createdAt),
        'isDniVerified': user.isDniVerified,
        'isPhoneVerified': user.isPhoneVerified,
        'isDocumentVerified': user.isDocumentVerified,
        'totalEarnings': user.totalEarnings,
        'monthlyEarnings': user.monthlyEarnings,
        'totalReviews': user.totalReviews,
        'credits': user.credits,
      });
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update({
        'name': user.name,
        'photo': user.photo,
        'phone': user.phone,
        'district': user.district,
        'rating': user.rating,
        'completedJobs': user.completedJobs,
        'skills': user.skills,
        'availability': user.availability,
        'description': user.description,
        'documents': user.documents,
        'isDniVerified': user.isDniVerified,
        'isPhoneVerified': user.isPhoneVerified,
        'isDocumentVerified': user.isDocumentVerified,
        'totalEarnings': user.totalEarnings,
        'monthlyEarnings': user.monthlyEarnings,
        'totalReviews': user.totalReviews,
        'credits': user.credits,
      });
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel(
          id: doc.id,
          name: data['name'] ?? '',
          photo: data['photo'],
          phone: data['phone'] ?? '',
          email: data['email'] ?? '',
          district: data['district'] ?? '',
          rating: (data['rating'] ?? 0.0).toDouble(),
          completedJobs: data['completedJobs'] ?? 0,
          skills: List<String>.from(data['skills'] ?? []),
          availability: data['availability'] ?? '',
          description: data['description'] ?? '',
          documents: List<String>.from(data['documents'] ?? []),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isDniVerified: data['isDniVerified'] ?? false,
          isPhoneVerified: data['isPhoneVerified'] ?? false,
          isDocumentVerified: data['isDocumentVerified'] ?? false,
          totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
          monthlyEarnings: (data['monthlyEarnings'] ?? 0.0).toDouble(),
          totalReviews: data['totalReviews'] ?? 0,
          credits: data['credits'] ?? 0,
        );
      }).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  /// Actualizar ganancias del usuario
  Future<void> updateEarnings(String userId, double amount) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final currentTotal = (data['totalEarnings'] ?? 0.0).toDouble();
      final currentMonthly = (data['monthlyEarnings'] ?? 0.0).toDouble();

      await _firestore.collection('users').doc(userId).update({
        'totalEarnings': currentTotal + amount,
        'monthlyEarnings': currentMonthly + amount,
      });

      print('💰 Ganancias actualizadas para $userId: +S/ $amount');
    } catch (e) {
      print('Error updating earnings: $e');
      rethrow;
    }
  }

  /// Actualizar calificación del usuario
  Future<void> updateRating(String userId, double newRating) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final currentRating = (data['rating'] ?? 0.0).toDouble();
      final totalReviews = (data['totalReviews'] ?? 0);
      final completedJobs = (data['completedJobs'] ?? 0);

      // Calcular nuevo promedio
      final totalRatingPoints = currentRating * totalReviews;
      final newTotalReviews = totalReviews + 1;
      final newAverageRating = (totalRatingPoints + newRating) / newTotalReviews;

      await _firestore.collection('users').doc(userId).update({
        'rating': newAverageRating,
        'totalReviews': newTotalReviews,
        'completedJobs': completedJobs + 1,
      });

      print('⭐ Calificación actualizada para $userId: ${newAverageRating.toStringAsFixed(1)}');
    } catch (e) {
      print('Error updating rating: $e');
      rethrow;
    }
  }
}
