import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Solicitar permisos
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permisos de notificaciones concedidos');
    } else {
      print('❌ Permisos de notificaciones denegados');
    }

    // Configurar notificaciones locales
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Obtener token FCM
    String? token = await _messaging.getToken();
    print('📱 FCM Token: $token');

    // Escuchar mensajes en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Escuchar cuando se toca una notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Verificar si la app se abrió desde una notificación
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('📬 Mensaje recibido en primer plano: ${message.notification?.title}');

    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'LaboraYa',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    print('👆 Notificación tocada: ${message.data}');
    // Aquí puedes navegar a una pantalla específica según el tipo de notificación
    // Por ejemplo: si es un mensaje, abrir el chat
    // if (message.data['type'] == 'message') { ... }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('👆 Notificación local tocada: ${response.payload}');
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'laboraya_channel',
      'LaboraYa Notifications',
      channelDescription: 'Notificaciones de trabajos y mensajes',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Método para enviar notificación local manualmente
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    await _showLocalNotification(title: title, body: body);
  }

  // Enviar notificación cuando aceptan un trabajo
  static Future<void> sendJobAcceptedNotification({
    required String jobTitle,
    required String workerName,
    required String jobOwnerId, // ID del dueño del trabajo
    String? jobId,
  }) async {
    try {
      // Obtener el usuario actual
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      // Crear notificación en Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': jobOwnerId,
        'title': '¡Trabajo Aceptado! 🎉',
        'body': '$workerName quiere trabajar en "$jobTitle"',
        'type': 'job_accepted',
        'jobId': jobId,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
      
      print('✅ Notificación guardada en Firestore para: $jobOwnerId');
      
      // Obtener el token FCM del dueño del trabajo
      final ownerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(jobOwnerId)
          .get();
      
      final ownerToken = ownerDoc.data()?['fcmToken'];
      
      if (ownerToken != null) {
        print('📤 Debería enviar notificación push a token: $ownerToken');
        print('   Título: ¡Trabajo Aceptado! 🎉');
        print('   Mensaje: $workerName quiere trabajar en "$jobTitle"');
      }
      
      // Mostrar notificación local SOLO si el usuario actual es el dueño del trabajo
      if (currentUserId == jobOwnerId) {
        await _showLocalNotification(
          title: '¡Trabajo Aceptado! 🎉',
          body: '$workerName quiere trabajar en "$jobTitle"',
        );
        print('✅ Notificación local mostrada al dueño');
      } else {
        print('⏭️ No se muestra notificación local (usuario actual no es el dueño)');
      }
    } catch (e) {
      print('❌ Error enviando notificación: $e');
    }
  }

  // Enviar notificación cuando el trabajador va en camino
  static Future<void> sendWorkerOnTheWayNotification({
    required String jobTitle,
    required String workerName,
    required String jobOwnerId,
    String? jobId,
  }) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      // Crear notificación en Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': jobOwnerId,
        'title': 'Trabajador en camino 🚗',
        'body': '$workerName va en camino para "$jobTitle"',
        'type': 'job_on_the_way',
        'jobId': jobId,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
      
      final ownerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(jobOwnerId)
          .get();
      
      final ownerToken = ownerDoc.data()?['fcmToken'];
      
      if (ownerToken != null) {
        print('📤 Debería enviar notificación push a token: $ownerToken');
        print('   Título: Trabajador en camino 🚗');
        print('   Mensaje: $workerName va en camino para "$jobTitle"');
      }
      
      if (currentUserId == jobOwnerId) {
        await _showLocalNotification(
          title: 'Trabajador en camino 🚗',
          body: '$workerName va en camino para "$jobTitle"',
        );
      }
    } catch (e) {
      print('❌ Error enviando notificación: $e');
    }
  }

  // Enviar notificación cuando inicia el trabajo
  static Future<void> sendJobStartedNotification({
    required String jobTitle,
    required String workerName,
    required String jobOwnerId,
    String? jobId,
  }) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      // Crear notificación en Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': jobOwnerId,
        'title': 'Trabajo iniciado 🔨',
        'body': '$workerName ha iniciado "$jobTitle"',
        'type': 'job_started',
        'jobId': jobId,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
      
      final ownerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(jobOwnerId)
          .get();
      
      final ownerToken = ownerDoc.data()?['fcmToken'];
      
      if (ownerToken != null) {
        print('📤 Debería enviar notificación push a token: $ownerToken');
        print('   Título: Trabajo iniciado 🔨');
        print('   Mensaje: $workerName ha iniciado "$jobTitle"');
      }
      
      if (currentUserId == jobOwnerId) {
        await _showLocalNotification(
          title: 'Trabajo iniciado 🔨',
          body: '$workerName ha iniciado "$jobTitle"',
        );
      }
    } catch (e) {
      print('❌ Error enviando notificación: $e');
    }
  }

  // Enviar notificación cuando termina el trabajo
  static Future<void> sendJobFinishedNotification({
    required String jobTitle,
    required String workerName,
    required String jobOwnerId,
    String? jobId,
  }) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      // Crear notificación en Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': jobOwnerId,
        'title': 'Trabajo terminado ✅',
        'body': '$workerName ha terminado "$jobTitle". ¡Confirma el trabajo!',
        'type': 'job_finished',
        'jobId': jobId,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
      
      final ownerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(jobOwnerId)
          .get();
      
      final ownerToken = ownerDoc.data()?['fcmToken'];
      
      if (ownerToken != null) {
        print('📤 Debería enviar notificación push a token: $ownerToken');
        print('   Título: Trabajo terminado ✅');
        print('   Mensaje: $workerName ha terminado "$jobTitle". ¡Confirma el trabajo!');
      }
      
      if (currentUserId == jobOwnerId) {
        await _showLocalNotification(
          title: 'Trabajo terminado ✅',
          body: '$workerName ha terminado "$jobTitle". ¡Confirma el trabajo!',
        );
      }
    } catch (e) {
      print('❌ Error enviando notificación: $e');
    }
  }

  // Enviar notificación cuando confirman el trabajo
  static Future<void> sendJobConfirmedNotification({
    required String jobTitle,
    required String clientName,
    required String workerId,
    String? jobId,
  }) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      // Crear notificación en Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': workerId,
        'title': 'Trabajo confirmado 🎉',
        'body': '$clientName ha confirmado "$jobTitle". ¡Ahora puedes calificar!',
        'type': 'job_confirmed',
        'jobId': jobId,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
      
      final workerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(workerId)
          .get();
      
      final workerToken = workerDoc.data()?['fcmToken'];
      
      if (workerToken != null) {
        print('📤 Debería enviar notificación push a token: $workerToken');
        print('   Título: Trabajo confirmado 🎉');
        print('   Mensaje: $clientName ha confirmado "$jobTitle". ¡Ahora puedes calificar!');
      }
      
      if (currentUserId == workerId) {
        await _showLocalNotification(
          title: 'Trabajo confirmado 🎉',
          body: '$clientName ha confirmado "$jobTitle". ¡Ahora puedes calificar!',
        );
      }
    } catch (e) {
      print('❌ Error enviando notificación: $e');
    }
  }

  // Obtener token FCM del dispositivo
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Guardar token FCM del usuario en Firestore
  static Future<void> saveUserToken(String userId) async {
    try {
      final token = await getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': token});
        print('✅ Token FCM guardado para usuario: $userId');
      }
    } catch (e) {
      print('❌ Error guardando token: $e');
    }
  }

  // Suscribirse a un tema
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    print('✅ Suscrito al tema: $topic');
  }

  // Desuscribirse de un tema
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    print('❌ Desuscrito del tema: $topic');
  }
}

// Handler para mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📬 Mensaje recibido en segundo plano: ${message.notification?.title}');
}
