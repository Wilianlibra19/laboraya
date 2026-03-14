import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/review_model.dart';

class FirebaseReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createReview(ReviewModel review) async {
    try {
      await _firestore.collection('reviews').doc(review.id).set({
        'jobId': review.jobId,
        'reviewerId': review.reviewerId,
        'reviewedUserId': review.reviewedUserId,
        'rating': review.rating,
        'comment': review.comment,
        'createdAt': Timestamp.fromDate(review.createdAt),
      });
    } catch (e) {
      print('Error creating review: $e');
      rethrow;
    }
  }

  Future<List<ReviewModel>> getReviewsByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('reviewedUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ReviewModel(
          id: doc.id,
          jobId: data['jobId'] ?? '',
          reviewerId: data['reviewerId'] ?? '',
          reviewedUserId: data['reviewedUserId'] ?? '',
          rating: (data['rating'] ?? 0.0).toDouble(),
          comment: data['comment'] ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Error getting reviews: $e');
      return [];
    }
  }

  Future<ReviewModel?> getReviewByJob(String jobId, String reviewerId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('jobId', isEqualTo: jobId)
          .where('reviewerId', isEqualTo: reviewerId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data();
      return ReviewModel(
        id: doc.id,
        jobId: data['jobId'] ?? '',
        reviewerId: data['reviewerId'] ?? '',
        reviewedUserId: data['reviewedUserId'] ?? '',
        rating: (data['rating'] ?? 0.0).toDouble(),
        comment: data['comment'] ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      print('Error getting review by job: $e');
      return null;
    }
  }
}
