import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/job_service.dart';
import '../../utils/constants.dart';
import '../../widgets/job/job_card.dart';
import '../job/job_detail_screen.dart';

class CategoryJobsScreen extends StatelessWidget {
  final String category;

  const CategoryJobsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final jobService = context.watch<JobService>();
    final categoryJobs = jobService.getJobsByCategory(category);

    return Scaffold(
      appBar: AppBar(
        title: Text(category),
      ),
      body: categoryJobs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CategoryIcons.icons[category] ?? Icons.work,
                    size: 80,
                    color: AppColors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay trabajos en $category',
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.paddingSmall,
              ),
              itemCount: categoryJobs.length,
              itemBuilder: (context, index) {
                final job = categoryJobs[index];
                return JobCard(
                  job: job,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobDetailScreen(jobId: job.id),
                      ),
                    );
                  },
                  distance: 2.5,
                );
              },
            ),
    );
  }
}
