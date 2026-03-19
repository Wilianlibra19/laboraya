import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // IMPORTANTE: Estas son keys de PRUEBA
  // Cuando tengas tu cuenta Culqi, reemplázalas con tus keys reales
  static const String _publicKey = 'pk_test_XXXXXXXXXXXXXXXX'; // Tu PUBLIC KEY de Culqi
  
  // ⚠️ NUNCA pongas la SECRET KEY aquí - está en Firebase Functions
  
  // URLs de Culqi
  static const String _tokenUrl = 'https://api.culqi.com/v2/tokens';
  static const String _chargeUrl = 'https://api.culqi.com/v2/charges';

  /// Crear token de tarjeta
  Future<Map<String, dynamic>> createCardToken({
    required String cardNumber,
    required String cvv,
    required String expiryMonth,
    required String expiryYear,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Authorization': 'Bearer $_publicKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'card_number': cardNumber.replaceAll(' ', ''),
          'cvv': cvv,
          'expiration_month': expiryMonth,
          'expiration_year': expiryYear,
          'email': email,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Error al crear token: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  /// Procesar cargo con tarjeta
  /// NOTA: El cargo se procesa en el backend (Firebase Functions)
  /// para mantener la SECRET KEY segura
  Future<Map<String, dynamic>> processCardCharge({
    required String tokenId,
    required int amountInCents,
    required String currency,
    required String email,
    required String description,
    required int credits,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      // Crear cargo directamente con Culqi
      // El webhook de Firebase Functions detectará el pago y agregará los créditos
      final response = await http.post(
        Uri.parse(_chargeUrl),
        headers: {
          'Authorization': 'Bearer $_publicKey', // Usar public key temporalmente
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amountInCents,
          'currency_code': currency,
          'email': email,
          'source_id': tokenId,
          'description': description,
          'metadata': {
            'userId': user.uid,
            'credits': credits.toString(),
          },
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // El webhook agregará los créditos automáticamente
        // Aquí solo retornamos el resultado
        return {
          'success': true,
          'data': data,
          'chargeId': data['id'],
          'message': 'Pago procesado. Los créditos se agregarán en unos segundos.',
        };
      } else {
        return {
          'success': false,
          'error': 'Error al procesar pago: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  /// Agregar créditos al usuario en Firestore
  Future<bool> addCreditsToUser({
    required String userId,
    required int credits,
    required String paymentMethod,
    required double amount,
    String? transactionId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Actualizar créditos del usuario
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'credits': FieldValue.increment(credits),
      });

      // Crear registro de transacción
      final transactionRef = _firestore.collection('credit_transactions').doc();
      batch.set(transactionRef, {
        'userId': userId,
        'credits': credits,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'status': 'completed',
        'createdAt': Timestamp.now(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error agregando créditos: $e');
      return false;
    }
  }

  /// Simular pago con Yape (en producción, integrarías con API de Yape)
  Future<Map<String, dynamic>> processYapePayment({
    required String phoneNumber,
    required int amountInCents,
    required String userId,
  }) async {
    // SIMULACIÓN - En producción, aquí integrarías con la API real de Yape/Culqi
    await Future.delayed(const Duration(seconds: 2));

    // Simular éxito
    return {
      'success': true,
      'transactionId': 'YAPE_${DateTime.now().millisecondsSinceEpoch}',
      'message': 'Pago con Yape procesado exitosamente',
    };
  }

  /// Simular pago con Plin (en producción, integrarías con API de Plin)
  Future<Map<String, dynamic>> processPlinPayment({
    required String phoneNumber,
    required String bank,
    required int amountInCents,
    required String userId,
  }) async {
    // SIMULACIÓN - En producción, aquí integrarías con la API real de Plin/Culqi
    await Future.delayed(const Duration(seconds: 2));

    // Simular éxito
    return {
      'success': true,
      'transactionId': 'PLIN_${DateTime.now().millisecondsSinceEpoch}',
      'message': 'Pago con Plin procesado exitosamente',
    };
  }

  /// Verificar estado de transacción usando Firebase Functions
  Future<Map<String, dynamic>> verifyTransaction(String chargeId) async {
    try {
      final callable = _functions.httpsCallable('verifyPaymentStatus');
      final result = await callable.call({'chargeId': chargeId});

      return {
        'success': true,
        'data': result.data,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error verificando transacción: $e',
      };
    }
  }

  /// Obtener historial de transacciones usando Firebase Functions
  Future<List<Map<String, dynamic>>> getUserTransactions({int limit = 20}) async {
    try {
      final callable = _functions.httpsCallable('getPaymentHistory');
      final result = await callable.call({'limit': limit});

      final transactions = result.data['transactions'] as List;
      return transactions.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error obteniendo transacciones: $e');
      return [];
    }
  }

  /// Escuchar cambios en tiempo real de los créditos del usuario
  Stream<int> watchUserCredits(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return 0;
      return snapshot.data()?['credits'] ?? 0;
    });
  }

  /// Escuchar nuevas transacciones en tiempo real
  Stream<List<Map<String, dynamic>>> watchUserTransactions(String userId) {
    return _firestore
        .collection('credit_transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Descontar créditos del usuario
  Future<Map<String, dynamic>> deductCredits({
    required String userId,
    required int credits,
    required String reason,
    String? jobId,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        return {
          'success': false,
          'error': 'Usuario no encontrado',
        };
      }

      final currentCredits = userDoc.data()?['credits'] ?? 0;

      if (currentCredits < credits) {
        return {
          'success': false,
          'error': 'Créditos insuficientes',
          'currentCredits': currentCredits,
          'required': credits,
        };
      }

      final batch = _firestore.batch();

      // Descontar créditos
      batch.update(userRef, {
        'credits': FieldValue.increment(-credits),
      });

      // Crear registro de transacción
      final transactionRef = _firestore.collection('credit_transactions').doc();
      batch.set(transactionRef, {
        'userId': userId,
        'credits': -credits,
        'amount': 0,
        'paymentMethod': 'deduction',
        'reason': reason,
        'jobId': jobId,
        'status': 'completed',
        'createdAt': Timestamp.now(),
      });

      await batch.commit();

      return {
        'success': true,
        'remainingCredits': currentCredits - credits,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al descontar créditos: $e',
      };
    }
  }

  /// Obtener créditos actuales del usuario
  Future<int> getUserCredits(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;
      return userDoc.data()?['credits'] ?? 0;
    } catch (e) {
      print('Error obteniendo créditos: $e');
      return 0;
    }
  }
}
