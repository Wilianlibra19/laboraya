import '../models/job_model.dart';

abstract class JobRepository {
  Future<List<JobModel>> getAllJobs();
  Future<JobModel?> getJobById(String id);
  Future<void> createJob(JobModel job);
  Future<void> updateJob(JobModel job);
  Future<void> deleteJob(String id);
  Future<List<JobModel>> getJobsByStatus(String status);
  Future<List<JobModel>> getJobsByCategory(String category);
  Future<List<JobModel>> getJobsByUser(String userId);
}
