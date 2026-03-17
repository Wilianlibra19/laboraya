import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/job_model.dart';
import '../../core/models/user_model.dart';
import '../../core/models/job_application_model.dart';
import '../../core/services/job_service.dart';
import '../../core/services/user_service.dart';
import '../../core/services/job_application_service.dart';
import '../../core/services/favorite_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/job/job_progress_bar.dart';
import '../../widgets/job/job_action_buttons.dart';
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
    // Escuchar cambios en tiempo real del trabajo
    _jobSubscription = FirebaseFirestore.instance
        .collection('jobs')
        .doc(widget.jobId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          job = JobModel.fromFirestore(snapshot);
        });
        print('🔄 Trabajo actualizado en tiempo real: ${job?.jobStatus}');
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() => isLoading = true);
    
    final jobService = context.read<JobService>();
    final userService = context.read<UserService>();

    print('🔍 Cargando trabajo: ${widget.jobId}');
    
    // Obtener DIRECTAMENTE desde Firebase (sin caché)
    job = await jobService.getJobById(widget.jobId);
    
    if (job != null) {
      print('✅ Trabajo: ${job!.title}');
      print('📊 status: ${job!.status}');
      print('📊 jobStatus: ${job!.jobStatus}');
      print('👤 acceptedBy: ${job!.acceptedBy}');
      
      // Si el trabajo está completado o en progreso, mostrar el trabajador
      // Si está disponible, mostrar quien lo publicó
      if (job!.acceptedBy != null && job!.acceptedBy!.isNotEmpty) {
        creator = await userService.getUserById(job!.acceptedBy!);
        print('👷 Mostrando perfil del trabajador: ${creator?.name}');
      } else {
        creator = await userService.getUserById(job!.createdBy);
        print('👤 Mostrando perfil del publicador: ${creator?.name}');
      }
    } else {
      print('❌ Trabajo no encontrado');
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
    
    setState(() => isFavorite = !isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
      appBar: AppBar(
        title: const Text('Detalle del Trabajo'),
        actions: [
          if (isOwner && job!.jobStatus == 'available')
            StreamBuilder<List<JobApplicationModel>>(
              stream: JobApplicationService().getJobApplications(widget.jobId),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.people),
                      onPressed: () {
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
                    if (count > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            color: isFavorite ? Colors.red : null,
            onPressed: _toggleFavorite,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'share') {
                // TODO: Implementar compartir
              } else if (value == 'report') {
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
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 12),
                    Text('Compartir'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Reportar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Galería de Fotos
            if (job!.images.isNotEmpty)
              SizedBox(
                height: 250,
                child: PageView.builder(
                  itemCount: job!.images.length,
                  itemBuilder: (context, index) {
                    final imageUrl = job!.images[index];
                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: Stack(
                              children: [
                                Center(
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  top: 40,
                                  right: 20,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                          if (job!.images.length > 1)
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${index + 1}/${job!.images.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              color: Theme.of(context).cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job!.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (job!.isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.urgent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'URGENTE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        CategoryIcons.icons[job!.category] ?? Icons.work,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        job!.category,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Barra de progreso del trabajo (SIEMPRE mostrar)
            JobProgressBar(job: job!),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              color: Theme.of(context).cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pago',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Helpers.formatCurrency(job!.payment),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        job!.paymentType,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Duración',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job!.duration,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              color: Theme.of(context).cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    job!.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              color: Theme.of(context).cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detalles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.people,
                    label: 'Personas necesarias',
                    value: '${job!.workersNeeded}',
                  ),
                  _DetailRow(
                    icon: Icons.calendar_today,
                    label: 'Fecha programada',
                    value: job!.scheduledDate != null
                        ? Helpers.formatDate(job!.scheduledDate!)
                        : 'Por coordinar',
                  ),
                  _DetailRow(
                    icon: Icons.location_on,
                    label: 'Ubicación',
                    value: job!.address,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Documentos PDF
            if (job!.documents.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                color: Theme.of(context).cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Documentos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: job!.documents.length,
                      itemBuilder: (context, index) {
                        final docUrl = job!.documents[index];
                        final docName = 'Documento ${index + 1}.pdf';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.deepOrange.withOpacity(0.3),
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.deepOrange,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              docName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text('Documento PDF'),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.download,
                                color: AppColors.primary,
                              ),
                              onPressed: () async {
                                // Abrir el PDF en el navegador
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Abriendo documento...'),
                                  ),
                                );
                                // Aquí podrías usar url_launcher para abrir el PDF
                                // await launchUrl(Uri.parse(docUrl));
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            if (job!.documents.isNotEmpty) const SizedBox(height: 16),

            if (creator != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      job!.jobStatus == 'completed' || job!.jobStatus == 'in_progress'
                          ? 'Trabajador'
                          : 'Publicado por',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: creator!.photo != null && creator!.photo!.isNotEmpty
                          ? NetworkImage(creator!.photo!)
                          : null,
                      child: creator!.photo == null || creator!.photo!.isEmpty
                          ? Text(
                              Helpers.getInitials(creator!.name),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      creator!.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (creator!.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 18,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Verificado',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 24,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          creator!.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${creator!.completedJobs} trabajos',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 18,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          creator!.district,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, currentUser, isOwner),
    );
  }

  Widget? _buildBottomBar(BuildContext context, UserModel? currentUser, bool isOwner) {
    if (currentUser == null || job == null) return null;

    print('🔵 Construyendo barra inferior de botones');
    print('🔵 Estado del trabajo: ${job!.jobStatus}');

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: AppColors.primary,
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
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
}
