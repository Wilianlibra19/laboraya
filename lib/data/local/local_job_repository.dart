import '../../core/models/job_model.dart';
import '../../core/repositories/job_repository.dart';
import 'hive_service.dart';

class LocalJobRepository implements JobRepository {
  @override
  Future<List<JobModel>> getAllJobs() async {
    final box = HiveService.getJobsBox();
    return box.values.toList();
  }

  @override
  Future<JobModel?> getJobById(String id) async {
    final box = HiveService.getJobsBox();
    return box.values.firstWhere(
      (job) => job.id == id,
      orElse: () => JobModel(
        id: '',
        title: '',
        description: '',
        category: '',
        payment: 0,
        paymentType: '',
        duration: '',
        latitude: 0,
        longitude: 0,
        address: '',
        createdBy: '',
        images: [],
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> createJob(JobModel job) async {
    final box = HiveService.getJobsBox();
    await box.put(job.id, job);
  }

  @override
  Future<void> updateJob(JobModel job) async {
    final box = HiveService.getJobsBox();
    await box.put(job.id, job);
  }

  @override
  Future<void> deleteJob(String id) async {
    final box = HiveService.getJobsBox();
    await box.delete(id);
  }

  @override
  Future<List<JobModel>> getJobsByStatus(String status) async {
    final box = HiveService.getJobsBox();
    return box.values.where((job) => job.status == status).toList();
  }

  @override
  Future<List<JobModel>> getJobsByCategory(String category) async {
    final box = HiveService.getJobsBox();
    return box.values.where((job) => job.category == category).toList();
  }

  @override
  Future<List<JobModel>> getJobsByUser(String userId) async {
    final box = HiveService.getJobsBox();
    return box.values
        .where((job) => job.createdBy == userId || job.acceptedBy == userId)
        .toList();
  }
}
