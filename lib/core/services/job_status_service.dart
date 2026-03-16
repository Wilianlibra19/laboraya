import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class JobStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Trabajador acepta el trabajo
  Future<void> acceptJob(String jobId, String workerId) async {
    try {
      print('🔵 Iniciando aceptación de trabajo...');
      print('   Job ID: $jobId');
      print('   Worker ID: $workerId');
      
      // Obtener información del trabajo y trabajador
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final jobData = jobDoc.data();
      final jobTitle = jobData?['title'] ?? 'un trabajo';
      final jobOwnerId = jobData?['createdBy']; // ID del dueño del trabajo
      
      print('   Trabajo: $jobTitle');
      print('   Estado actual: ${jobData?['jobStatus']}');
      print('   Dueño del trabajo: $jobOwnerId');
      
      final workerDoc = await _firestore.collection('users').doc(workerId).get();
      final workerData = workerDoc.data();
      final workerName = workerData?['name'] ?? 'Un trabajador';
      
      print('   Trabajador: $workerName');
      print('🔵 Actualizando en Firebase...');
      
      await _firestore.collection('jobs').doc(jobId).update({
        'acceptedBy': workerId,
        'status': 'accepted',
        'jobStatus': 'accepted',
        'acceptedAt': Timestamp.now(),
      });
      
      print('✅ Trabajo aceptado en Firebase');
      print('   Nuevo estado: accepted');
      print('   Aceptado por: $workerId');
      
      // Enviar notificación SOLO al dueño del trabajo (no al que acepta)
      if (jobOwnerId != null && jobOwnerId != workerId) {
        await NotificationService.sendJobAcceptedNotification(
          jobTitle: jobTitle,
          workerName: workerName,
          jobOwnerId: jobOwnerId,
          jobId: jobId,
        );
        print('✅ Notificación enviada al dueño del trabajo: $jobOwnerId');
      } else {
        print('⚠️ No se envía notificación (mismo usuario o sin dueño)');
      }
    } catch (e) {
      print('❌ Error aceptando trabajo: $e');
      rethrow;
    }
  }

  /// Trabajador indica que va en camino
  Future<void> markOnTheWay(String jobId) async {
    try {
      // Obtener información del trabajo y trabajador
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final jobData = jobDoc.data();
      final jobTitle = jobData?['title'] ?? 'un trabajo';
      final workerId = jobData?['acceptedBy'];
      final jobOwnerId = jobData?['createdBy'];
      
      if (workerId != null && jobOwnerId != null) {
        final workerDoc = await _firestore.collection('users').doc(workerId).get();
        final workerData = workerDoc.data();
        final workerName = workerData?['name'] ?? 'El trabajador';
        
        await _firestore.collection('jobs').doc(jobId).update({
          'jobStatus': 'on_the_way',
        });
        
        print('✅ Trabajador va en camino');
        
        // Enviar notificación al dueño del trabajo
        await NotificationService.sendWorkerOnTheWayNotification(
          jobTitle: jobTitle,
          workerName: workerName,
          jobOwnerId: jobOwnerId,
          jobId: jobId,
        );
      }
    } catch (e) {
      print('❌ Error marcando en camino: $e');
      rethrow;
    }
  }

  /// Trabajador inicia el trabajo
  Future<void> startJob(String jobId) async {
    try {
      // Obtener información del trabajo y trabajador
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final jobData = jobDoc.data();
      final jobTitle = jobData?['title'] ?? 'un trabajo';
      final workerId = jobData?['acceptedBy'];
      final jobOwnerId = jobData?['createdBy'];
      final jobType = jobData?['jobType'] ?? 'daily';
      
      if (workerId != null && jobOwnerId != null) {
        final workerDoc = await _firestore.collection('users').doc(workerId).get();
        final workerData = workerDoc.data();
        final workerName = workerData?['name'] ?? 'El trabajador';
        
        final updateData = {
          'jobStatus': 'in_progress',
          'startedAt': Timestamp.now(),
        };
        
        // Si es un contrato, guardar la fecha de inicio del contrato
        if (jobType == 'contract') {
          updateData['contractStartDate'] = Timestamp.now();
          print('📅 Guardando fecha de inicio del contrato');
        }
        
        await _firestore.collection('jobs').doc(jobId).update(updateData);
        
        print('✅ Trabajo iniciado');
        
        // Enviar notificación al dueño del trabajo
        await NotificationService.sendJobStartedNotification(
          jobTitle: jobTitle,
          workerName: workerName,
          jobOwnerId: jobOwnerId,
          jobId: jobId,
        );
      }
    } catch (e) {
      print('❌ Error iniciando trabajo: $e');
      rethrow;
    }
  }

  /// Trabajador marca el trabajo como terminado
  Future<void> finishJob(String jobId) async {
    try {
      // Obtener información del trabajo y trabajador
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final jobData = jobDoc.data();
      final jobTitle = jobData?['title'] ?? 'un trabajo';
      final workerId = jobData?['acceptedBy'];
      final jobOwnerId = jobData?['createdBy'];
      
      if (workerId != null && jobOwnerId != null) {
        final workerDoc = await _firestore.collection('users').doc(workerId).get();
        final workerData = workerDoc.data();
        final workerName = workerData?['name'] ?? 'El trabajador';
        
        await _firestore.collection('jobs').doc(jobId).update({
          'jobStatus': 'finished_by_worker',
          'finishedAt': Timestamp.now(),
        });
        
        print('✅ Trabajo marcado como terminado por el trabajador');
        
        // Enviar notificación al dueño del trabajo
        await NotificationService.sendJobFinishedNotification(
          jobTitle: jobTitle,
          workerName: workerName,
          jobOwnerId: jobOwnerId,
          jobId: jobId,
        );
      }
    } catch (e) {
      print('❌ Error marcando trabajo como terminado: $e');
      rethrow;
    }
  }

  /// Cliente confirma que el trabajo está completo
  Future<void> confirmJob(String jobId) async {
    try {
      // Obtener información del trabajo y cliente
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final jobData = jobDoc.data();
      final jobTitle = jobData?['title'] ?? 'un trabajo';
      final clientId = jobData?['createdBy'];
      final workerId = jobData?['acceptedBy'];
      
      if (clientId != null && workerId != null) {
        final clientDoc = await _firestore.collection('users').doc(clientId).get();
        final clientData = clientDoc.data();
        final clientName = clientData?['name'] ?? 'El cliente';
        
        await _firestore.collection('jobs').doc(jobId).update({
          'jobStatus': 'confirmed_by_client',
          'confirmedAt': Timestamp.now(),
        });
        
        print('✅ Trabajo confirmado por el cliente');
        
        // Enviar notificación al trabajador
        await NotificationService.sendJobConfirmedNotification(
          jobTitle: jobTitle,
          clientName: clientName,
          workerId: workerId,
          jobId: jobId,
        );
      }
    } catch (e) {
      print('❌ Error confirmando trabajo: $e');
      rethrow;
    }
  }

  /// Cliente califica al trabajador y completa el trabajo
  Future<void> completeJobWithRating({
    required String jobId,
    required String workerId,
    required double ratingWorker,
    String? commentWorker,
  }) async {
    try {
      print('🔵 Completando trabajo y actualizando ganancias...');
      
      final batch = _firestore.batch();

      // Obtener el trabajo para saber el pago
      final jobRef = _firestore.collection('jobs').doc(jobId);
      final jobDoc = await jobRef.get();
      final jobData = jobDoc.data();
      final payment = (jobData?['payment'] ?? 0.0).toDouble();
      
      print('   Pago del trabajo: S/ $payment');

      // Actualizar el trabajo
      batch.update(jobRef, {
        'jobStatus': 'completed',
        'status': 'completed',
        'completedAt': Timestamp.now(),
        'ratingWorker': ratingWorker,
        'commentWorker': commentWorker,
      });

      // Obtener datos actuales del trabajador
      final workerRef = _firestore.collection('users').doc(workerId);
      final workerDoc = await workerRef.get();
      final workerData = workerDoc.data();
      
      final currentTotalEarnings = (workerData?['totalEarnings'] ?? 0.0).toDouble();
      final currentMonthlyEarnings = (workerData?['monthlyEarnings'] ?? 0.0).toDouble();
      final currentRating = (workerData?['rating'] ?? 0.0).toDouble();
      final completedJobs = (workerData?['completedJobs'] ?? 0);
      final totalReviews = (workerData?['totalReviews'] ?? 0);
      
      print('   Ganancias actuales: S/ $currentTotalEarnings');
      print('   Trabajos completados: $completedJobs');
      print('   Rating actual: $currentRating');
      
      // Calcular nueva calificación promedio
      final newRating = ((currentRating * totalReviews) + ratingWorker) / (totalReviews + 1);
      
      print('   Nuevo rating: $newRating');
      print('   Nuevas ganancias totales: S/ ${currentTotalEarnings + payment}');
      print('   Nuevas ganancias mensuales: S/ ${currentMonthlyEarnings + payment}');
      
      // Actualizar ganancias y calificación del trabajador
      batch.update(workerRef, {
        'totalEarnings': currentTotalEarnings + payment,
        'monthlyEarnings': currentMonthlyEarnings + payment,
        'rating': newRating,
        'completedJobs': completedJobs + 1,
        'totalReviews': totalReviews + 1,
      });

      await batch.commit();
      print('✅ Trabajo completado y trabajador actualizado');
      print('   Ganancia agregada: S/ $payment');
      print('   Total acumulado: S/ ${currentTotalEarnings + payment}');
    } catch (e) {
      print('❌ Error completando trabajo: $e');
      rethrow;
    }
  }

  /// Trabajador califica al cliente
  Future<void> rateClient({
    required String jobId,
    required double ratingClient,
    String? commentClient,
  }) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'ratingClient': ratingClient,
        'commentClient': commentClient,
      });
      print('✅ Cliente calificado');
    } catch (e) {
      print('❌ Error calificando cliente: $e');
      rethrow;
    }
  }
}
