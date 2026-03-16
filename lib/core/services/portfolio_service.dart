import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/portfolio_item_model.dart';

class PortfolioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addPortfolioItem(PortfolioItemModel item) async {
    await _firestore
        .collection('portfolio')
        .doc(item.id)
        .set(item.toJson());
  }

  Future<void> deletePortfolioItem(String itemId) async {
    await _firestore.collection('portfolio').doc(itemId).delete();
  }

  Stream<List<PortfolioItemModel>> getUserPortfolio(String userId) {
    return _firestore
        .collection('portfolio')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PortfolioItemModel.fromJson(doc.data()))
            .toList());
  }

  Future<List<PortfolioItemModel>> getUserPortfolioFuture(String userId) async {
    final snapshot = await _firestore
        .collection('portfolio')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PortfolioItemModel.fromJson(doc.data()))
        .toList();
  }
}
