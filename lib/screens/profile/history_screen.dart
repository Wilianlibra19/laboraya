import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/job_service.dart';
import '../../core/services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../job/job_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserService>().currentUser;
    final jobService = context.watch<JobService>();

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no encontrado')),
      );
    }

    final allUserJobs = jobService.jobs
        .where((job) => job.createdBy == user.id || job.acceptedBy == user.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
      ),
      body: allUserJobs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: AppColors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No tienes historial',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              itemCount: allUserJobs.length,
              itemBuilder: (context, index) {
                final job = allUserJobs[index];
                final isCreator = job.createdBy == user.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: job.status == 'completed'
                          ? AppColors.success
                          : job.status == 'accepted'
                              ? AppColors.warning
                              : AppColors.primary,
                      child: Icon(
                        job.status == 'completed'
                            ? Icons.check
                            : job.status == 'accepted'
                                ? Icons.pending
                                : Icons.work,
                        color: AppColors.white,
                      ),
                    ),
                    title: Text(
                      job.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          isCreator ? 'Publicado por ti' : 'Aceptado por ti',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          Helpers.getTimeAgo(job.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Helpers.formatCurrency(job.payment),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: job.status == 'completed'
                                ? AppColors.success.withOpacity(0.1)
                                : job.status == 'accepted'
                                    ? AppColors.warning.withOpacity(0.1)
                                    : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            job.status == 'completed'
                                ? 'Completado'
                                : job.status == 'accepted'
                                    ? 'En proceso'
                                    : 'Disponible',
                            style: TextStyle(
                              fontSize: 10,
                              color: job.status == 'completed'
                                  ? AppColors.success
                                  : job.status == 'accepted'
                                      ? AppColors.warning
                                      : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailScreen(jobId: job.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
