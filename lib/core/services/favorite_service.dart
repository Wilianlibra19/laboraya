import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/favorite_model.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addFavorite(String userId, String jobId) async {
    final favoriteId = _firestore.collection('favorites').doc().id;
    
    final favorite = FavoriteModel(
      id: favoriteId,
      userId: userId,
      jobId: jobId,
      savedAt: DateTime.now(),
    );

    await _firestore
        .collection('favorites')
        .doc(favoriteId)
        .set(favorite.toJson());
  }

  Future<void> removeFavorite(String userId, String jobId) async {
    final snapshot = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('jobId', isEqualTo: jobId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<bool> isFavorite(String userId, String jobId) async {
    final snapshot = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('jobId', isEqualTo: jobId)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Stream<List<String>> getFavoriteJobIds(String userId) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()['jobId'] as String).toList());
  }
}
