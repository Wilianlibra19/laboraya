import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/job_model.dart';
import '../../core/repositories/job_repository.dart';

class FirebaseJobRepository implements JobRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<JobModel?> getJobById(String id) async {
    try {
      final doc = await _firestore.collection('jobs').doc(id).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return _jobFromFirestore(doc.id, data);
    } catch (e) {
      print('Error getting job: $e');
      return null;
    }
  }

  @override
  Future<List<JobModel>> getAllJobs() async {
    try {
      final snapshot = await _firestore
          .collection('jobs')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => _jobFromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting all jobs: $e');
      return [];
    }
  }

  @override
  Future<List<JobModel>> getJobsByStatus(String status) async {
    try {
      final snapshot = await _firestore
          .collection('jobs')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => _jobFromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting jobs by status: $e');
      return [];
    }
  }

  @override
  Future<List<JobModel>> getJobsByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('jobs')
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => _jobFromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting jobs by user: $e');
      return [];
    }
  }

  @override
  Future<List<JobModel>> getJobsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('jobs')
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: 'available')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => _jobFromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting jobs by category: $e');
      return [];
    }
  }

  @override
  Future<void> createJob(JobModel job) async {
    try {
      await _firestore.collection('jobs').doc(job.id).set(_jobToFirestore(job));
    } catch (e) {
      print('Error creating job: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateJob(JobModel job) async {
    try {
      await _firestore.collection('jobs').doc(job.id).update(_jobToFirestore(job));
    } catch (e) {
      print('Error updating job: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteJob(String id) async {
    try {
      await _firestore.collection('jobs').doc(id).delete();
    } catch (e) {
      print('Error deleting job: $e');
      rethrow;
    }
  }

  // Helper methods
  JobModel _jobFromFirestore(String id, Map<String, dynamic> data) {
    return JobModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      payment: (data['payment'] ?? 0.0).toDouble(),
      paymentType: data['paymentType'] ?? 'Por trabajo',
      workersNeeded: data['workersNeeded'] ?? 1,
      duration: data['duration'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      address: data['address'] ?? '',
      createdBy: data['createdBy'] ?? '',
      acceptedBy: data['acceptedBy'],
      status: data['status'] ?? 'available',
      isUrgent: data['isUrgent'] ?? false,
      images: List<String>.from(data['images'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate(),
      documents: List<String>.from(data['documents'] ?? []),
      // Campos de estado del trabajo
      jobStatus: data['jobStatus'] ?? 'available',
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      finishedAt: (data['finishedAt'] as Timestamp?)?.toDate(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      ratingWorker: data['ratingWorker']?.toDouble(),
      commentWorker: data['commentWorker'],
      ratingClient: data['ratingClient']?.toDouble(),
      commentClient: data['commentClient'],
      // Campos de contrato
      jobType: data['jobType'] ?? 'daily',
      estimatedDays: data['estimatedDays'],
      contractStartDate: (data['contractStartDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> _jobToFirestore(JobModel job) {
    return {
      'title': job.title,
      'description': job.description,
      'category': job.category,
      'payment': job.payment,
      'paymentType': job.paymentType,
      'workersNeeded': job.workersNeeded,
      'duration': job.duration,
      'latitude': job.latitude,
      'longitude': job.longitude,
      'address': job.address,
      'createdBy': job.createdBy,
      'acceptedBy': job.acceptedBy,
      'status': job.status,
      'isUrgent': job.isUrgent,
      'images': job.images,
      'createdAt': Timestamp.fromDate(job.createdAt),
      'scheduledDate': job.scheduledDate != null 
          ? Timestamp.fromDate(job.scheduledDate!)
          : null,
      'documents': job.documents,
      // Campos de estado del trabajo
      'jobStatus': job.jobStatus,
      'acceptedAt': job.acceptedAt != null 
          ? Timestamp.fromDate(job.acceptedAt!)
          : null,
      'startedAt': job.startedAt != null 
          ? Timestamp.fromDate(job.startedAt!)
          : null,
      'finishedAt': job.finishedAt != null 
          ? Timestamp.fromDate(job.finishedAt!)
          : null,
      'confirmedAt': job.confirmedAt != null 
          ? Timestamp.fromDate(job.confirmedAt!)
          : null,
      'completedAt': job.completedAt != null 
          ? Timestamp.fromDate(job.completedAt!)
          : null,
      'ratingWorker': job.ratingWorker,
      'commentWorker': job.commentWorker,
      'ratingClient': job.ratingClient,
      'commentClient': job.commentClient,
      // Campos de contrato
      'jobType': job.jobType,
      'estimatedDays': job.estimatedDays,
      'contractStartDate': job.contractStartDate != null 
          ? Timestamp.fromDate(job.contractStartDate!)
          : null,
    };
  }
}
