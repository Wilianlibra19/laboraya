import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/job_application_model.dart';
import '../../core/models/job_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/favorite_service.dart';
import '../../core/services/job_application_service.dart';
import '../../core/services/job_service.dart';
import '../../core/services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/job/job_action_buttons.dart';
import '../../widgets/job/job_progress_bar.dart';
import '../report/report_screen.dart';
import 'job_applications_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  JobModel? job;
  UserModel? creator;
  bool isLoading = true;
  bool isFavorite = false;
  int _currentImageIndex = 0;
  StreamSubscription<DocumentSnapshot>? _jobSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenToJobChanges();
    _checkFavorite();
  }

  @override
  void dispose() {
    _jobSubscription?.cancel();
    super.dispose();
  }

  void _listenToJobChanges() {
    _jobSubscription = FirebaseFirestore.instance
        .collection('jobs')
        .doc(widget.jobId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          job = JobModel.fromFirestore(snapshot);
        });
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    final jobService = context.read<JobService>();
    final userService = context.read<UserService>();

    job = await jobService.getJobById(widget.jobId);

    if (job != null) {
      if (job!.acceptedBy != null && job!.acceptedBy!.isNotEmpty) {
        creator = await userService.getUserById(job!.acceptedBy!);
      } else {
        creator = await userService.getUserById(job!.createdBy);
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _checkFavorite() async {
    final currentUser = context.read<UserService>().currentUser;
    if (currentUser == null) return;

    final favoriteService = FavoriteService();
    final result = await favoriteService.isFavorite(currentUser.id, widget.jobId);

    if (mounted) {
      setState(() => isFavorite = result);
    }
  }

  Future<void> _toggleFavorite() async {
    final currentUser = context.read<UserService>().currentUser;
    if (currentUser == null) return;

    final favoriteService = FavoriteService();

    if (isFavorite) {
      await favoriteService.removeFavorite(currentUser.id, widget.jobId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eliminado de favoritos')),
        );
      }
    } else {
      await favoriteService.addFavorite(currentUser.id, widget.jobId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Agregado a favoritos')),
        );
      }
    }

    if (mounted) {
      setState(() => isFavorite = !isFavorite);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.blue;
      case 'accepted':
        return Colors.amber.shade700;
      case 'on_the_way':
        return Colors.deepPurple;
      case 'in_progress':
        return Colors.orange;
      case 'finished_by_worker':
        return Colors.indigo;
      case 'confirmed_by_client':
        return Colors.teal;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'available':
        return 'Disponible';
      case 'accepted':
        return 'Aceptado';
      case 'on_the_way':
        return 'En camino';
      case 'in_progress':
        return 'En progreso';
      case 'finished_by_worker':
        return 'Esperando confirmación';
      case 'confirmed_by_client':
        return 'Confirmado';
      case 'completed':
        return 'Completado';
      default:
        return status;
    }
  }

  bool get _showWorkerCard {
    if (job == null) return false;
    return job!.jobStatus == 'completed' ||
        job!.jobStatus == 'in_progress' ||
        job!.jobStatus == 'on_the_way' ||
        job!.jobStatus == 'accepted' ||
        job!.jobStatus == 'finished_by_worker' ||
        job!.jobStatus == 'confirmed_by_client';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trabajo')),
        body: const Center(child: Text('Trabajo no encontrado')),
      );
    }

    final currentUser = context.watch<UserService>().currentUser;
    final isOwner = currentUser?.id == job!.createdBy;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeroSection(context, isDark, isOwner),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(isDark),
                  const SizedBox(height: 16),
                  _buildProgressCard(isDark),
                  const SizedBox(height: 16),
                  _buildDescriptionCard(isDark),
                  const SizedBox(height: 16),
                  _buildDetailsCard(isDark),
                  if (job!.documents.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDocumentsCard(isDark),
                  ],
                  if (creator != null) ...[
                    const SizedBox(height: 16),
                    _buildCreatorCard(isDark),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, currentUser, isOwner, isDark),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDark, bool isOwner) {
    final hasImages = job!.images.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: hasImages
            ? null
            : LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.88),
                  const Color(0xFF69C9FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: Stack(
        children: [
          SizedBox(
            height: 360,
            width: double.infinity,
            child: hasImages
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        itemCount: job!.images.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final imageUrl = job!.images[index];
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.all(12),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Material(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(999),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              color: Colors.white,
                                            ),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.10),
                              Colors.black.withOpacity(0.18),
                              Colors.black.withOpacity(0.55),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _GlassIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      if (isOwner && job!.jobStatus == 'available')
                        StreamBuilder<List<JobApplicationModel>>(
                          stream: JobApplicationService().getJobApplications(widget.jobId),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.length ?? 0;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _BadgeIconButton(
                                icon: Icons.people_alt_outlined,
                                badgeCount: count,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => JobApplicationsScreen(
                                        jobId: widget.jobId,
                                        jobTitle: job!.title,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      _GlassIconButton(
                        icon: isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        iconColor: isFavorite ? Colors.redAccent : Colors.white,
                        onTap: _toggleFavorite,
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                        color: isDark ? const Color(0xFF1E2227) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (value) {
                          if (value == 'report') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReportScreen(
                                  reportedId: widget.jobId,
                                  reportedType: 'job',
                                  reportedName: job!.title,
                                ),
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(Icons.flag_outlined, size: 20, color: Colors.red),
                                SizedBox(width: 12),
                                Text('Reportar', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(hasImages ? 0.14 : 0.18),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeroPill(
                        icon: CategoryIcons.icons[job!.category] ?? Icons.work_outline_rounded,
                        text: job!.category,
                      ),
                      _HeroPill(
                        icon: Icons.payments_outlined,
                        text: job!.paymentType,
                      ),
                      _HeroPill(
                        icon: Icons.schedule_rounded,
                        text: _statusText(job!.jobStatus),
                      ),
                      if (job!.isUrgent)
                        const _HeroPill(
                          icon: Icons.local_fire_department_rounded,
                          text: 'Urgente',
                          isUrgent: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    job!.title,
                    style: const TextStyle(
                      fontSize: 27,
                      height: 1.18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          job!.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (job!.images.length > 1) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        job!.images.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentImageIndex == index ? 18 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index
                                ? Colors.white
                                : Colors.white54,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return _CardShell(
      isDark: isDark,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  icon: Icons.attach_money_rounded,
                  label: 'Pago',
                  value: Helpers.formatCurrency(job!.payment),
                  subtitle: job!.paymentType,
                  accent: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricBlock(
                  icon: Icons.timelapse_rounded,
                  label: 'Duración',
                  value: job!.duration,
                  subtitle: job!.jobType == 'contract'
                      ? 'Contrato'
                      : 'Trabajo puntual',
                  accent: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _statusColor(job!.jobStatus).withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: _statusColor(job!.jobStatus),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Estado actual: ${_statusText(job!.jobStatus)}',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(job!.jobStatus),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  Helpers.getTimeAgo(job!.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF708090),
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

  Widget _buildProgressCard(bool isDark) {
    return _CardShell(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.insights_outlined,
            title: 'Progreso del trabajo',
            color: AppColors.primary,
          ),
          const SizedBox(height: 14),
          // JobProgressBar sin padding extra
          JobProgressBar(job: job!),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(bool isDark) {
    return _CardShell(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.description_outlined,
            title: 'Descripción',
            color: AppColors.primary,
          ),
          const SizedBox(height: 14),
          Text(
            job!.description,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.6,
              color: isDark ? Colors.white70 : const Color(0xFF4F5D6B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(bool isDark) {
    return _CardShell(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.info_outline_rounded,
            title: 'Detalles',
            color: AppColors.primary,
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.people_alt_outlined,
            label: 'Personas necesarias',
            value: '${job!.workersNeeded}',
          ),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Fecha programada',
            value: job!.scheduledDate != null
                ? Helpers.formatDate(job!.scheduledDate!)
                : 'Por coordinar',
          ),
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: 'Ubicación',
            value: job!.address,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsCard(bool isDark) {
    return _CardShell(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Documentos',
            color: Colors.deepOrange,
          ),
          const SizedBox(height: 14),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: job!.documents.length,
            itemBuilder: (context, index) {
              final docName = 'Documento ${index + 1}.pdf';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.deepOrange.withOpacity(0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        docName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.download_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Abriendo documento...'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorCard(bool isDark) {
    final title = _showWorkerCard ? 'Trabajador asignado' : 'Publicado por';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.88),
            const Color(0xFF5FC7FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 18),
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            backgroundImage:
                creator!.photo != null && creator!.photo!.isNotEmpty
                    ? NetworkImage(creator!.photo!)
                    : null,
            child: creator!.photo == null || creator!.photo!.isEmpty
                ? Text(
                    Helpers.getInitials(creator!.name),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 14),
          Text(
            creator!.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (creator!.isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 17, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Verificado',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _UserMiniStat(
                icon: Icons.star_rounded,
                value: creator!.rating.toStringAsFixed(1),
                label: 'Rating',
              ),
              _UserMiniStat(
                icon: Icons.work_history_outlined,
                value: '${creator!.completedJobs}',
                label: 'Trabajos',
              ),
              _UserMiniStat(
                icon: Icons.location_on_outlined,
                value: creator!.district,
                label: 'Zona',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar(
    BuildContext context,
    UserModel? currentUser,
    bool isOwner,
    bool isDark,
  ) {
    if (currentUser == null || job == null) return null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8EEF6),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: JobActionButtons(
            job: job!,
            currentUser: currentUser,
            onStatusChanged: _loadData,
          ),
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _CardShell({
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EEF6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF162033),
          ),
        ),
      ],
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color accent;

  const _MetricBlock({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : const Color(0xFF708090),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF162033),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.white70 : const Color(0xFF5D6A79),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isUrgent;

  const _HeroPill({
    required this.icon,
    required this.text,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isUrgent
            ? Colors.redAccent.withOpacity(0.22)
            : Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.14),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 42,
          width: 42,
          child: Icon(
            icon,
            color: iconColor ?? Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _BadgeIconButton extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;

  const _BadgeIconButton({
    required this.icon,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(
              height: 42,
              width: 42,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.4),
              ),
              child: Text(
                '$badgeCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UserMiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _UserMiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white60 : const Color(0xFF708090),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF162033),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}