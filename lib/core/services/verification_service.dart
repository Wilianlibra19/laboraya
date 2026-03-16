import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitPhoneVerification({
    required String userId,
    required String phoneNumber,
    required String verificationCode,
  }) async {
    await _firestore.collection('verifications').add({
      'userId': userId,
      'type': 'phone',
      'phoneNumber': phoneNumber,
      'verificationCode': verificationCode,
      'status': 'pending',
      'submittedAt': Timestamp.now(),
    });
  }

  Future<void> submitIdentityVerification({
    required String userId,
    required String dniNumber,
    required String frontImageUrl,
    required String backImageUrl,
    required String selfieUrl,
  }) async {
    await _firestore.collection('verifications').add({
      'userId': userId,
      'type': 'identity',
      'dniNumber': dniNumber,
      'frontImageUrl': frontImageUrl,
      'backImageUrl': backImageUrl,
      'selfieUrl': selfieUrl,
      'status': 'pending',
      'submittedAt': Timestamp.now(),
    });
  }

  Future<void> markUserAsVerified(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isVerified': true,
      'verifiedAt': Timestamp.now(),
    });
  }

  Future<bool> isUserVerified(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['isVerified'] ?? false;
  }
}
