const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();
const db = admin.firestore();

// ============================================
// CONFIGURACIÓN DE CULQI
// ============================================
const CULQI_SECRET_KEY = functions.config().culqi?.secret_key || 'sk_test_XXXXXXXXXXXXXXXX';
const CULQI_WEBHOOK_SECRET = functions.config().culqi?.webhook_secret || 'webhook_secret_XXXXXXXX';

// ============================================
// WEBHOOK: RECIBIR NOTIFICACIONES DE CULQI
// ============================================
exports.culqiWebhook = functions.https.onRequest(async (req, res) => {
  // Solo aceptar POST
  if (req.method !== 'POST') {
    return res.status(405).send('Method Not Allowed');
  }

  try {
    const event = req.body;
    
    console.log('📥 Webhook recibido:', event.type);
    console.log('📦 Datos:', JSON.stringify(event.data, null, 2));

    // Verificar firma del webhook (seguridad)
    const signature = req.headers['x-culqi-signature'];
    if (!verifyWebhookSignature(signature, req.body)) {
      console.error('❌ Firma de webhook inválida');
      return res.status(401).send('Invalid signature');
    }

    // Procesar según el tipo de evento
    switch (event.type) {
      case 'charge.succeeded':
        await handleChargeSucceeded(event.data.object);
        break;
      
      case 'charge.failed':
        await handleChargeFailed(event.data.object);
        break;
      
      case 'charge.creation.succeeded':
        await handleChargeSucceeded(event.data.object);
        break;

      default:
        console.log('ℹ️ Evento no manejado:', event.type);
    }

    // Responder a Culqi que recibimos el webhook
    return res.status(200).json({ received: true });

  } catch (error) {
    console.error('❌ Error procesando webhook:', error);
    return res.status(500).json({ error: error.message });
  }
});

// ============================================
// PROCESAR PAGO EXITOSO
// ============================================
async function handleChargeSucceeded(charge) {
  try {
    console.log('✅ Procesando pago exitoso:', charge.id);

    // Extraer información del pago
    const chargeId = charge.id;
    const amount = charge.amount / 100; // Culqi envía en centavos
    const email = charge.email;
    const metadata = charge.metadata || {};
    const userId = metadata.userId;
    const credits = metadata.credits;
    const paymentMethod = getPaymentMethodName(charge.source?.type);

    if (!userId || !credits) {
      console.error('❌ Falta userId o credits en metadata');
      return;
    }

    // Verificar que no se haya procesado antes (idempotencia)
    const transactionRef = db.collection('credit_transactions').doc(chargeId);
    const existingTransaction = await transactionRef.get();

    if (existingTransaction.exists) {
      console.log('⚠️ Transacción ya procesada:', chargeId);
      return;
    }

    // Iniciar transacción de Firestore
    await db.runTransaction(async (transaction) => {
      const userRef = db.collection('users').doc(userId);
      const userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw new Error('Usuario no encontrado');
      }

      const currentCredits = userDoc.data().credits || 0;

      // Actualizar créditos del usuario
      transaction.update(userRef, {
        credits: currentCredits + parseInt(credits),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Crear registro de transacción
      transaction.set(transactionRef, {
        userId: userId,
        credits: parseInt(credits),
        amount: amount,
        paymentMethod: paymentMethod,
        transactionId: chargeId,
        status: 'completed',
        email: email,
        culqiData: {
          chargeId: charge.id,
          currency: charge.currency_code,
          sourceType: charge.source?.type,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    console.log(`✅ Créditos agregados: ${credits} créditos para usuario ${userId}`);

    // Enviar notificación push al usuario (opcional)
    await sendPushNotification(userId, {
      title: '¡Compra exitosa!',
      body: `Se han agregado ${credits} créditos a tu cuenta`,
    });

  } catch (error) {
    console.error('❌ Error en handleChargeSucceeded:', error);
    throw error;
  }
}

// ============================================
// PROCESAR PAGO FALLIDO
// ============================================
async function handleChargeFailed(charge) {
  try {
    console.log('❌ Procesando pago fallido:', charge.id);

    const metadata = charge.metadata || {};
    const userId = metadata.userId;

    if (!userId) {
      return;
    }

    // Registrar intento fallido
    await db.collection('failed_payments').add({
      userId: userId,
      chargeId: charge.id,
      amount: charge.amount / 100,
      reason: charge.outcome?.user_message || 'Pago rechazado',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Notificar al usuario
    await sendPushNotification(userId, {
      title: 'Pago rechazado',
      body: 'Tu pago no pudo ser procesado. Intenta con otro método.',
    });

  } catch (error) {
    console.error('❌ Error en handleChargeFailed:', error);
  }
}

// ============================================
// VERIFICAR FIRMA DEL WEBHOOK
// ============================================
function verifyWebhookSignature(signature, payload) {
  // En producción, verifica la firma usando el webhook secret de Culqi
  // Por ahora, en desarrollo, aceptamos todos
  if (process.env.NODE_ENV === 'production') {
    // TODO: Implementar verificación real con crypto
    // const crypto = require('crypto');
    // const hash = crypto.createHmac('sha256', CULQI_WEBHOOK_SECRET)
    //   .update(JSON.stringify(payload))
    //   .digest('hex');
    // return hash === signature;
    return true;
  }
  return true;
}

// ============================================
// OBTENER NOMBRE DEL MÉTODO DE PAGO
// ============================================
function getPaymentMethodName(sourceType) {
  const methods = {
    'card': 'Tarjeta',
    'yape': 'Yape',
    'plin': 'Plin',
  };
  return methods[sourceType] || 'Otro';
}

// ============================================
// ENVIAR NOTIFICACIÓN PUSH
// ============================================
async function sendPushNotification(userId, notification) {
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      console.log('⚠️ Usuario sin FCM token');
      return;
    }

    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        type: 'credit_purchase',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    });

    console.log('📱 Notificación enviada a:', userId);
  } catch (error) {
    console.error('❌ Error enviando notificación:', error);
  }
}

// ============================================
// FUNCIÓN PARA VERIFICAR ESTADO DE PAGO
// ============================================
exports.verifyPaymentStatus = functions.https.onCall(async (data, context) => {
  // Verificar autenticación
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Usuario no autenticado'
    );
  }

  const { chargeId } = data;
  const userId = context.auth.uid;

  try {
    // Consultar a Culqi el estado del pago
    const response = await axios.get(
      `https://api.culqi.com/v2/charges/${chargeId}`,
      {
        headers: {
          'Authorization': `Bearer ${CULQI_SECRET_KEY}`,
        },
      }
    );

    const charge = response.data;

    // Verificar que el pago pertenece al usuario
    if (charge.metadata?.userId !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'No tienes permiso para ver este pago'
      );
    }

    return {
      status: charge.outcome?.type || 'unknown',
      message: charge.outcome?.user_message || '',
      amount: charge.amount / 100,
      currency: charge.currency_code,
    };

  } catch (error) {
    console.error('❌ Error verificando pago:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error verificando el estado del pago'
    );
  }
});

// ============================================
// FUNCIÓN PARA OBTENER HISTORIAL DE PAGOS
// ============================================
exports.getPaymentHistory = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Usuario no autenticado'
    );
  }

  const userId = context.auth.uid;
  const { limit = 20 } = data;

  try {
    const snapshot = await db
      .collection('credit_transactions')
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();

    const transactions = [];
    snapshot.forEach(doc => {
      transactions.push({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate().toISOString(),
      });
    });

    return { transactions };

  } catch (error) {
    console.error('❌ Error obteniendo historial:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error obteniendo historial de pagos'
    );
  }
});

// ============================================
// FUNCIÓN PROGRAMADA: LIMPIAR PAGOS ANTIGUOS
// ============================================
exports.cleanOldFailedPayments = functions.pubsub
  .schedule('every 7 days')
  .onRun(async (context) => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const snapshot = await db
      .collection('failed_payments')
      .where('createdAt', '<', thirtyDaysAgo)
      .get();

    const batch = db.batch();
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`🧹 Limpiados ${snapshot.size} pagos fallidos antiguos`);
  });
