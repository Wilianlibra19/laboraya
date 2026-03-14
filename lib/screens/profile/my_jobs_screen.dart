import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/job_service.dart';
import '../../core/services/user_service.dart';
import '../../utils/constants.dart';
import '../../widgets/job/job_card.dart';
import '../job/job_detail_screen.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserService>().currentUser;
    final jobService = context.watch<JobService>();

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no encontrado')),
      );
    }

    final myJobs = jobService.jobs
        .where((job) => job.createdBy == user.id)
        .toList();
    final acceptedJobs = jobService.jobs
        .where((job) => 
            job.acceptedBy == user.id && 
            job.jobStatus != 'completed')
        .toList();
    final completedJobs = jobService.jobs
        .where((job) =>
            (job.createdBy == user.id || job.acceptedBy == user.id) &&
            job.jobStatus == 'completed')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Trabajos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Publicados'),
            Tab(text: 'Aceptados'),
            Tab(text: 'Completados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildJobList(myJobs, 'No has publicado trabajos', showStatus: true),
          _buildJobList(acceptedJobs, 'No has aceptado trabajos', showStatus: true),
          _buildJobList(completedJobs, 'No tienes trabajos completados'),
        ],
      ),
    );
  }

  Widget _buildJobList(List jobs, String emptyMessage, {bool showStatus = false}) {
    if (jobs.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return JobCard(
          job: job,
          showStatus: showStatus,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JobDetailScreen(jobId: job.id),
              ),
            );
          },
        );
      },
    );
  }
}
