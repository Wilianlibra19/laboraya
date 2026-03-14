const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Enviar notificación cuando se acepta un trabajo
exports.onJobAccepted = functions.firestore
  .document('jobs/{jobId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    
    // Si el trabajo cambió de 'available' a 'accepted'
    if (oldData.jobStatus === 'available' && newData.jobStatus === 'accepted') {
      try {
        const ownerId = newData.createdBy;
        const workerId = newData.acceptedBy;
        
        // Obtener datos del trabajador y dueño
        const workerDoc = await admin.firestore().collection('users').doc(workerId).get();
        const ownerDoc = await admin.firestore().collection('users').doc(ownerId).get();
        
        const workerName = workerDoc.data()?.name || 'Un trabajador';
        const ownerToken = ownerDoc.data()?.fcmToken;
        
        if (ownerToken) {
          await admin.messaging().send({
            token: ownerToken,
            notification: {
              title: '¡Trabajo Aceptado! 🎉',
              body: `${workerName} quiere trabajar en "${newData.title}"`,
            },
            data: {
              type: 'job_accepted',
              jobId: context.params.jobId,
              workerId: workerId,
            },
            android: {
              priority: 'high',
              notification: {
                sound: 'default',
                channelId: 'laboraya_channel',
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                },
              },
            },
          });
          
          console.log(`✅ Notificación enviada al dueño: ${ownerId}`);
        } else {
          console.log(`⚠️ Dueño ${ownerId} no tiene token FCM`);
        }
      } catch (error) {
        console.error('❌ Error enviando notificación:', error);
      }
    }
    
    // Si el trabajador va en camino
    if (oldData.jobStatus === 'accepted' && newData.jobStatus === 'on_the_way') {
      try {
        const ownerId = newData.createdBy;
        const workerId = newData.acceptedBy;
        
        const workerDoc = await admin.firestore().collection('users').doc(workerId).get();
        const ownerDoc = await admin.firestore().collection('users').doc(ownerId).get();
        
        const workerName = workerDoc.data()?.name || 'El trabajador';
        const ownerToken = ownerDoc.data()?.fcmToken;
        
        if (ownerToken) {
          await admin.messaging().send({
            token: ownerToken,
            notification: {
              title: 'Trabajador en camino 🚗',
              body: `${workerName} va en camino para "${newData.title}"`,
            },
            data: {
              type: 'worker_on_the_way',
              jobId: context.params.jobId,
              workerId: workerId,
            },
          });
          
          console.log(`✅ Notificación 'en camino' enviada`);
        }
      } catch (error) {
        console.error('❌ Error:', error);
      }
    }
    
    // Si el trabajo inició
    if (oldData.jobStatus === 'on_the_way' && newData.jobStatus === 'in_progress') {
      try {
        const ownerId = newData.createdBy;
        const workerId = newData.acceptedBy;
        
        const workerDoc = await admin.firestore().collection('users').doc(workerId).get();
        const ownerDoc = await admin.firestore().collection('users').doc(ownerId).get();
        
        const workerName = workerDoc.data()?.name || 'El trabajador';
        const ownerToken = ownerDoc.data()?.fcmToken;
        
        if (ownerToken) {
          await admin.messaging().send({
            token: ownerToken,
            notification: {
              title: 'Trabajo iniciado 🔨',
              body: `${workerName} ha iniciado "${newData.title}"`,
            },
            data: {
              type: 'job_started',
              jobId: context.params.jobId,
              workerId: workerId,
            },
          });
          
          console.log(`✅ Notificación 'iniciado' enviada`);
        }
      } catch (error) {
        console.error('❌ Error:', error);
      }
    }
    
    // Si el trabajo terminó
    if (oldData.jobStatus === 'in_progress' && newData.jobStatus === 'finished_by_worker') {
      try {
        const ownerId = newData.createdBy;
        const workerId = newData.acceptedBy;
        
        const workerDoc = await admin.firestore().collection('users').doc(workerId).get();
        const ownerDoc = await admin.firestore().collection('users').doc(ownerId).get();
        
        const workerName = workerDoc.data()?.name || 'El trabajador';
        const ownerToken = ownerDoc.data()?.fcmToken;
        
        if (ownerToken) {
          await admin.messaging().send({
            token: ownerToken,
            notification: {
              title: 'Trabajo terminado ✅',
              body: `${workerName} ha terminado "${newData.title}". ¡Confirma el trabajo!`,
            },
            data: {
              type: 'job_finished',
              jobId: context.params.jobId,
              workerId: workerId,
            },
          });
          
          console.log(`✅ Notificación 'terminado' enviada`);
        }
      } catch (error) {
        console.error('❌ Error:', error);
      }
    }
    
    // Si el cliente confirmó el trabajo
    if (oldData.jobStatus === 'finished_by_worker' && newData.jobStatus === 'confirmed_by_client') {
      try {
        const ownerId = newData.createdBy;
        const workerId = newData.acceptedBy;
        
        const ownerDoc = await admin.firestore().collection('users').doc(ownerId).get();
        const workerDoc = await admin.firestore().collection('users').doc(workerId).get();
        
        const clientName = ownerDoc.data()?.name || 'El cliente';
        const workerToken = workerDoc.data()?.fcmToken;
        
        if (workerToken) {
          await admin.messaging().send({
            token: workerToken,
            notification: {
              title: 'Trabajo confirmado 🎉',
              body: `${clientName} ha confirmado "${newData.title}". ¡Ahora puedes calificar!`,
            },
            data: {
              type: 'job_confirmed',
              jobId: context.params.jobId,
              clientId: ownerId,
            },
          });
          
          console.log(`✅ Notificación 'confirmado' enviada al trabajador`);
        }
      } catch (error) {
        console.error('❌ Error:', error);
      }
    }
  });

// Enviar notificación cuando llega un mensaje nuevo
exports.onNewMessage = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snap, context) => {
    try {
      const message = snap.data();
      const receiverId = message.receiverId;
      const senderId = message.senderId;
      
      // Obtener datos del remitente y receptor
      const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
      const receiverDoc = await admin.firestore().collection('users').doc(receiverId).get();
      
      const senderName = senderDoc.data()?.name || 'Alguien';
      const receiverToken = receiverDoc.data()?.fcmToken;
      
      if (receiverToken) {
        const notificationBody = message.imageUrl 
          ? '📷 Envió una foto'
          : message.text;
        
        await admin.messaging().send({
          token: receiverToken,
          notification: {
            title: `💬 ${senderName}`,
            body: notificationBody,
          },
          data: {
            type: 'new_message',
            messageId: context.params.messageId,
            senderId: senderId,
            jobId: message.jobId || '',
          },
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              channelId: 'laboraya_channel',
            },
          },
        });
        
        console.log(`✅ Notificación de mensaje enviada a: ${receiverId}`);
      } else {
        console.log(`⚠️ Receptor ${receiverId} no tiene token FCM`);
      }
    } catch (error) {
      console.error('❌ Error enviando notificación de mensaje:', error);
    }
  });
