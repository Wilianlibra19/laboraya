import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/user_service.dart';
import '../../core/services/job_service.dart';
import '../../core/services/job_application_service.dart';
import '../../core/models/job_model.dart';
import '../../data/mock/mock_data.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/job/job_card.dart';
import '../job/job_detail_screen.dart';
import '../job/create_job_screen.dart';
import '../notifications/notifications_screen.dart';
import '../job/my_job_applications_screen.dart';
import 'category_jobs_screen.dart';
import 'nearby_jobs_screen.dart';
import 'filter_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _appliedFilters;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar trabajos cuando se muestra la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobService>().loadJobs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<JobModel> _filterJobs(List<JobModel> jobs) {
    if (_searchQuery.isEmpty) return jobs;
    
    return jobs.where((JobModel job) {
      return job.title.toLowerCase().contains(_searchQuery) ||
             job.description.toLowerCase().contains(_searchQuery) ||
             job.category.toLowerCase().contains(_searchQuery) ||
             job.address.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _openFilters() async {
    final filters = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => FilterScreen(currentFilters: _appliedFilters),
      ),
    );
    if (filters != null) {
      setState(() => _appliedFilters = filters);
      // TODO: Apply filters to job list
    }
  }

  void _openNearbyJobs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NearbyJobsScreen()),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'on_the_way':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'finished_by_worker':
        return Colors.purple;
      case 'confirmed_by_client':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Aceptado';
      case 'on_the_way':
        return 'En camino';
      case 'in_progress':
        return 'En progreso';
      case 'finished_by_worker':
        return 'Terminado';
      case 'confirmed_by_client':
        return 'Confirmado';
      default:
        return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final jobService = context.watch<JobService>();
    final user = userService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LaboraYa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilters,
            tooltip: 'Filtros',
          ),
          // Icono de solicitudes con contador
          if (user != null)
            StreamBuilder<int>(
              stream: JobApplicationService().getPendingApplicationsCountStream(user.id),
              builder: (context, snapshot) {
                final applicationsCount = snapshot.data ?? 0;
                
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.people_outline),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyJobApplicationsScreen(),
                          ),
                        );
                      },
                      tooltip: 'Solicitudes',
                    ),
                    if (applicationsCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            applicationsCount > 9 ? '9+' : '$applicationsCount',
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
          // Icono de notificaciones con contador
          StreamBuilder<QuerySnapshot>(
            stream: user != null
                ? FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId', isEqualTo: user.id)
                    .where('isRead', isEqualTo: false)
                    .snapshots()
                : null,
            builder: (context, snapshot) {
              final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
              
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
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
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 8),
            child: GestureDetector(
              onTap: () {
                // Ir a perfil (cambiar a tab de perfil)
                DefaultTabController.of(context)?.animateTo(3);
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                backgroundImage: user?.photo != null && user!.photo!.isNotEmpty
                    ? NetworkImage(user.photo!)
                    : null,
                child: user?.photo == null || user!.photo!.isEmpty
                    ? Text(
                        Helpers.getInitials(user?.name ?? 'Usuario'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => jobService.loadJobs(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[850]
                      : AppColors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, ${user?.name.split(' ').first ?? 'Usuario'}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Encuentra trabajo o ayuda cerca de ti',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar trabajos...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.borderRadius),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nearby Jobs Button
                    InkWell(
                      onTap: _openNearbyJobs,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue[400]!,
                              Colors.blue[600]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Trabajos cerca de mí',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Encuentra trabajos en tu zona',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mis Trabajos en Progreso
              if (user != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('jobs')
                      .where('createdBy', isEqualTo: user.id)
                      .where('status', isEqualTo: 'accepted')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final jobs = snapshot.data!.docs;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingMedium,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.work_history,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Mis Trabajos en Progreso',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...jobs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final jobTitle = data['title'] ?? '';
                          final workerId = data['acceptedBy'] ?? '';
                          final jobStatus = data['jobStatus'] ?? 'accepted';
                          final payment = data['payment'] ?? 0.0;

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(workerId)
                                .get(),
                            builder: (context, workerSnapshot) {
                              final workerData = workerSnapshot.data?.data()
                                  as Map<String, dynamic>?;
                              final workerName =
                                  workerData?['name'] ?? 'Trabajador';
                              final workerPhoto = workerData?['photo'];

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.paddingMedium,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.primary,
                                    backgroundImage: workerPhoto != null &&
                                            workerPhoto.isNotEmpty
                                        ? NetworkImage(workerPhoto)
                                        : null,
                                    child: workerPhoto == null ||
                                            workerPhoto.isEmpty
                                        ? Text(
                                            Helpers.getInitials(workerName),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    jobTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'Trabajador: $workerName',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(jobStatus)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _getStatusText(jobStatus),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    _getStatusColor(jobStatus),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'S/ ${payment.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            JobDetailScreen(jobId: doc.id),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),

              // Categories
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMedium,
                ),
                child: const Text(
                  'Categorías',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingMedium,
                  ),
                  itemCount: MockData.getCategories().length,
                  itemBuilder: (context, index) {
                    final category = MockData.getCategories()[index];
                    return _CategoryCard(category: category);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Urgent Jobs
              if (jobService.urgentJobs
                  .where((job) => job.createdBy != user?.id)
                  .isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingMedium,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: AppColors.urgent),
                      const SizedBox(width: 8),
                      const Text(
                        'Trabajos Urgentes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ..._filterJobs(jobService.urgentJobs)
                    .where((job) => job.createdBy != user?.id)
                    .map((job) => JobCard(
                          job: job,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobDetailScreen(jobId: job.id),
                            ),
                          ),
                        )),
                const SizedBox(height: 24),
              ],

              // Available Jobs
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMedium,
                ),
                child: Text(
                  _searchQuery.isEmpty 
                      ? 'Trabajos Disponibles'
                      : 'Resultados de búsqueda',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (jobService.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.paddingLarge),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_filterJobs(jobService.availableJobs)
                  .where((job) => job.createdBy != user?.id)
                  .isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingLarge),
                    child: Column(
                      children: [
                        Icon(
                          _searchQuery.isEmpty ? Icons.work_off : Icons.search_off,
                          size: 64,
                          color: AppColors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No hay trabajos disponibles'
                              : 'No se encontraron trabajos',
                          style: const TextStyle(color: AppColors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._filterJobs(jobService.availableJobs)
                    .where((job) => job.createdBy != user?.id)
                    .map((job) => JobCard(
                          job: job,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobDetailScreen(jobId: job.id),
                            ),
                          ),
                          distance: 2.5,
                        )),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateJobScreen()),
          );
          // Si se creó un trabajo, recargar la lista
          if (result == true && mounted) {
            jobService.loadJobs();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Publicar Trabajo'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryJobsScreen(category: category),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CategoryIcons.icons[category] ?? Icons.work,
                size: 32,
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                category,
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
