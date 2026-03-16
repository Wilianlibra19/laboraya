import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/user_service.dart';
import '../../core/services/favorite_service.dart';
import '../../core/models/job_model.dart';
import '../../utils/constants.dart';
import '../../widgets/job/job_card.dart';
import '../job/job_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserService>().currentUser;
    final favoriteService = FavoriteService();

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favoritos')),
        body: const Center(child: Text('Debes iniciar sesión')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trabajos Guardados'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<String>>(
        stream: favoriteService.getFavoriteJobIds(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes trabajos guardados',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Guarda trabajos para verlos más tarde',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          final jobIds = snapshot.data!;

          return FutureBuilder<List<JobModel>>(
            future: _loadJobs(jobIds),
            builder: (context, jobSnapshot) {
              if (jobSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!jobSnapshot.hasData || jobSnapshot.data!.isEmpty) {
                return const Center(child: Text('No se pudieron cargar los trabajos'));
              }

              final jobs = jobSnapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  final job = jobs[index];
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
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<JobModel>> _loadJobs(List<String> jobIds) async {
    final jobs = <JobModel>[];
    
    for (var jobId in jobIds) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('jobs')
            .doc(jobId)
            .get();
        
        if (doc.exists) {
          jobs.add(JobModel.fromFirestore(doc));
        }
      } catch (e) {
        print('Error cargando trabajo $jobId: $e');
      }
    }
    
    return jobs;
  }
}
