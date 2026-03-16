import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_application_model.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class JobApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> applyToJob({
    required String jobId,
    required UserModel applicant,
    required String message,
  }) async {
    final applicationId = _firestore.collection('job_applications').doc().id;
    
    final application = JobApplicationModel(
      id: applicationId,
      jobId: jobId,
      applicantId: applicant.id,
      applicantName: applicant.name,
      applicantPhoto: applicant.photo ?? '',
      applicantRating: applicant.rating,
      applicantCompletedJobs: applicant.completedJobs,
      message: message,
      appliedAt: DateTime.now(),
      status: 'pending',
    );

    await _firestore
        .collection('job_applications')
        .doc(applicationId)
        .set(application.toJson());
    
    // Obtener información del trabajo para enviar notificación
    final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
    final jobData = jobDoc.data();
    final jobTitle = jobData?['title'] ?? 'un trabajo';
    final jobOwnerId = jobData?['createdBy'];
    
    // Enviar notificación al dueño del trabajo
    if (jobOwnerId != null) {
      await NotificationService.sendJobApplicationNotification(
        jobTitle: jobTitle,
        applicantName: applicant.name,
        jobOwnerId: jobOwnerId,
        jobId: jobId,
      );
      print('✅ Notificación de solicitud enviada al dueño: $jobOwnerId');
    }
  }

  Stream<List<JobApplicationModel>> getJobApplications(String jobId) {
    return _firestore
        .collection('job_applications')
        .where('jobId', isEqualTo: jobId)
        .where('status', isEqualTo: 'pending')
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobApplicationModel.fromFirestore(doc))
            .toList());
  }

  Future<void> acceptApplication(String applicationId, String jobId) async {
    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('job_applications').doc(applicationId),
      {'status': 'accepted'},
    );

    final appDoc = await _firestore
        .collection('job_applications')
        .doc(applicationId)
        .get();
    final applicantId = appDoc.data()!['applicantId'];

    batch.update(
      _firestore.collection('jobs').doc(jobId),
      {
        'acceptedBy': applicantId,
        'jobStatus': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      },
    );

    final otherApps = await _firestore
        .collection('job_applications')
        .where('jobId', isEqualTo: jobId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (var doc in otherApps.docs) {
      if (doc.id != applicationId) {
        batch.update(doc.reference, {'status': 'rejected'});
      }
    }

    await batch.commit();
  }

  Future<void> rejectApplication(String applicationId) async {
    await _firestore
        .collection('job_applications')
        .doc(applicationId)
        .update({'status': 'rejected'});
  }

  Future<bool> hasUserApplied(String jobId, String userId) async {
    final snapshot = await _firestore
        .collection('job_applications')
        .where('jobId', isEqualTo: jobId)
        .where('applicantId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.isNotEmpty;
  }
}
