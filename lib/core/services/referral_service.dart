import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../config/credits_config.dart';

class ReferralService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String generateReferralCode(String userId) {
    // Generar código de 6 caracteres basado en userId
    final random = Random(userId.hashCode);
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> createReferralCode(String userId) async {
    final code = generateReferralCode(userId);
    
    await _firestore.collection('users').doc(userId).update({
      'referralCode': code,
      'referralCount': 0,
      'referralCredits': 0,
      'credits': CreditsConfig.CREDITOS_INICIALES, // Créditos iniciales
    });
  }

  Future<bool> applyReferralCode(String userId, String referralCode) async {
    try {
      // Buscar usuario con ese código
      final snapshot = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: referralCode.toUpperCase())
          .get();

      if (snapshot.docs.isEmpty) return false;

      final referrerId = snapshot.docs.first.id;
      if (referrerId == userId) return false; // No puede referirse a sí mismo

      // Verificar que el usuario no haya usado un código antes
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.data()?['usedReferralCode'] != null) return false;

      // Aplicar referido
      final batch = _firestore.batch();

      // Actualizar usuario que usó el código (NO recibe créditos extra, solo los iniciales)
      batch.update(_firestore.collection('users').doc(userId), {
        'usedReferralCode': referralCode.toUpperCase(),
        'referredBy': referrerId,
      });

      // Actualizar contador del referidor (dar 40 créditos)
      batch.update(_firestore.collection('users').doc(referrerId), {
        'referralCount': FieldValue.increment(1),
        'referralCredits': FieldValue.increment(CreditsConfig.CREDITOS_POR_REFERIDO),
        'credits': FieldValue.increment(CreditsConfig.CREDITOS_POR_REFERIDO), // Sumar a créditos totales
      });

      // Crear registro de referido
      batch.set(_firestore.collection('referrals').doc(), {
        'referrerId': referrerId,
        'referredUserId': userId,
        'code': referralCode.toUpperCase(),
        'bonusCredits': CreditsConfig.CREDITOS_POR_REFERIDO,
        'createdAt': Timestamp.now(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error aplicando código de referido: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getReferralStats(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();

    final referralsSnapshot = await _firestore
        .collection('referrals')
        .where('referrerId', isEqualTo: userId)
        .get();

    return {
      'code': userData?['referralCode'] ?? '',
      'count': userData?['referralCount'] ?? 0,
      'credits': userData?['referralCredits'] ?? 0,
      'totalCredits': userData?['credits'] ?? CreditsConfig.CREDITOS_INICIALES,
      'referrals': referralsSnapshot.docs.length,
    };
  }
}
