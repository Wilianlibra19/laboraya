import 'package:flutter/foundation.dart';
import '../models/job_model.dart';
import '../repositories/job_repository.dart';
import './notification_service.dart';

class JobService extends ChangeNotifier {
  final JobRepository _repository;
  List<JobModel> _jobs = [];
  bool _isLoading = false;

  JobService(this._repository);

  List<JobModel> get jobs => _jobs;
  bool get isLoading => _isLoading;

  List<JobModel> get availableJobs =>
      _jobs.where((job) => job.status == 'available').toList();

  List<JobModel> get urgentJobs =>
      _jobs.where((job) => job.isUrgent && job.status == 'available').toList();

  Future<void> loadJobs() async {
    _isLoading = true;
    notifyListeners();

    _jobs = await _repository.getAllJobs();
    _jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createJob(JobModel job) async {
    await _repository.createJob(job);
    await loadJobs();
  }

  Future<void> acceptJob(String jobId, String userId, String workerName) async {
    final job = await _repository.getJobById(jobId);
    if (job != null) {
      job.acceptedBy = userId;
      job.status = 'accepted';
      job.jobStatus = 'accepted';
      job.acceptedAt = DateTime.now();
      await _repository.updateJob(job);
      
      // Crear notificación para el publicador
      await NotificationService.sendJobAcceptedNotification(
        jobTitle: job.title,
        workerName: workerName,
        jobOwnerId: job.createdBy,
        jobId: jobId,
      );
      
      await loadJobs();
    }
  }

  Future<void> completeJob(String jobId, String workerId, double payment) async {
    final job = await _repository.getJobById(jobId);
    if (job != null) {
      job.status = 'completed';
      await _repository.updateJob(job);
      await loadJobs();
      
      print('✅ Trabajo completado: $jobId');
      print('💰 Pago al trabajador: S/ $payment');
    }
  }

  List<JobModel> getJobsByCategory(String category) {
    return _jobs.where((job) => job.category == category).toList();
  }

  Future<JobModel?> getJobById(String id) async {
    return _repository.getJobById(id);
  }

  Future<List<JobModel>> getUserJobs(String userId) async {
    return _repository.getJobsByUser(userId);
  }
}
