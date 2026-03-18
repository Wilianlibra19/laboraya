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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
        body: const Center(child: Text('Usuario no encontrado')),
      );
    }

    final myJobs = jobService.jobs.where((job) => job.createdBy == user.id).toList();

    final acceptedJobs = jobService.jobs
        .where((job) => job.acceptedBy == user.id && job.jobStatus != 'completed')
        .toList();

    final completedJobs = jobService.jobs
        .where(
          (job) =>
              (job.createdBy == user.id || job.acceptedBy == user.id) &&
              job.jobStatus == 'completed',
        )
        .toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
      body: Column(
        children: [
          _buildHeader(isDark),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1E22) : const Color(0xFFEFF3F8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor:
                  isDark ? Colors.white70 : const Color(0xFF607080),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              dividerColor: Colors.transparent,
              splashBorderRadius: BorderRadius.circular(14),
              tabs: [
                Tab(text: 'Publicados (${myJobs.length})'),
                Tab(text: 'Aceptados (${acceptedJobs.length})'),
                Tab(text: 'Completados (${completedJobs.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildJobList(
                  jobs: myJobs,
                  emptyTitle: 'No has publicado trabajos',
                  emptySubtitle:
                      'Cuando publiques oportunidades, aparecerán aquí.',
                  emptyIcon: Icons.work_outline_rounded,
                  isDark: isDark,
                  showStatus: true,
                ),
                _buildJobList(
                  jobs: acceptedJobs,
                  emptyTitle: 'No has aceptado trabajos',
                  emptySubtitle:
                      'Los trabajos que aceptes se mostrarán en esta sección.',
                  emptyIcon: Icons.handshake_outlined,
                  isDark: isDark,
                  showStatus: true,
                ),
                _buildJobList(
                  jobs: completedJobs,
                  emptyTitle: 'No tienes trabajos completados',
                  emptySubtitle:
                      'Aquí verás tus trabajos finalizados y cerrados.',
                  emptyIcon: Icons.check_circle_outline_rounded,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.88),
            const Color(0xFF67C4FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          _HeaderBackButton(),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis Trabajos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gestiona tus publicaciones y avances',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobList({
    required List jobs,
    required String emptyTitle,
    required String emptySubtitle,
    required IconData emptyIcon,
    required bool isDark,
    bool showStatus = false,
  }) {
    if (jobs.isEmpty) {
      return _EmptyJobsState(
        isDark: isDark,
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: JobCard(
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
          ),
        );
      },
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pop(context),
        child: const SizedBox(
          height: 42,
          width: 42,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _EmptyJobsState extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyJobsState({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1E22) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFE8EEF6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 92,
                width: 92,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.14),
                      AppColors.primary.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  icon,
                  size: 42,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF162033),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.55,
                  color: isDark ? Colors.white70 : const Color(0xFF5D6A79),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}