import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/services/job_service.dart';
import '../../core/services/user_service.dart';
import '../../core/models/job_model.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../job/job_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  JobModel? _selectedJob;
  String _filterMode = 'available'; // 'available', 'mine', 'all'

  static const LatLng _initialPosition = LatLng(-12.0464, -77.0428);

  @override
  void initState() {
    super.initState();
  }

  List<Marker> _buildMarkers() {
    final jobService = context.watch<JobService>();
    final currentUserId = context.watch<UserService>().currentUser?.id;
    
    List<JobModel> jobs;
    
    switch (_filterMode) {
      case 'mine':
        // Mostrar solo mis trabajos (creados por mí o aceptados por mí)
        jobs = jobService.jobs.where((job) => 
          job.createdBy == currentUserId || job.acceptedBy == currentUserId
        ).toList();
        break;
      case 'all':
        // Mostrar todos los trabajos
        jobs = jobService.jobs;
        break;
      case 'available':
      default:
        // Mostrar solo trabajos disponibles
        jobs = jobService.availableJobs;
        break;
    }
    
    return jobs.map((job) {
      return Marker(
        point: LatLng(job.latitude, job.longitude),
        width: 70,
        height: 70,
        child: GestureDetector(
          onTap: () => setState(() => _selectedJob = job),
          child: Image.asset(
            'assets/icons/pingmapa.png',
            width: 70,
            height: 70,
            // Color celeste para trabajos normales, rojo para urgentes
            color: job.isUrgent ? AppColors.urgent : const Color(0xFF00BCD4), // Celeste/Cyan
            colorBlendMode: BlendMode.modulate,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Trabajos'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filterMode = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'available',
                child: Row(
                  children: [
                    Icon(
                      Icons.work_outline,
                      color: _filterMode == 'available' ? AppColors.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Disponibles',
                      style: TextStyle(
                        fontWeight: _filterMode == 'available' ? FontWeight.bold : null,
                        color: _filterMode == 'available' ? AppColors.primary : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mine',
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: _filterMode == 'mine' ? AppColors.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mis trabajos',
                      style: TextStyle(
                        fontWeight: _filterMode == 'mine' ? FontWeight.bold : null,
                        color: _filterMode == 'mine' ? AppColors.primary : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(
                      Icons.map,
                      color: _filterMode == 'all' ? AppColors.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Todos',
                      style: TextStyle(
                        fontWeight: _filterMode == 'all' ? FontWeight.bold : null,
                        color: _filterMode == 'all' ? AppColors.primary : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _mapController.move(_initialPosition, 13);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 13,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.laboraya_app',
              ),
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),
          if (_selectedJob != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _JobMapCard(
                job: _selectedJob!,
                onClose: () => setState(() => _selectedJob = null),
                onViewDetails: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          JobDetailScreen(jobId: _selectedJob!.id),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _JobMapCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onClose;
  final VoidCallback onViewDetails;

  const _JobMapCard({
    required this.job,
    required this.onClose,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        job.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      CategoryIcons.icons[job.category] ?? Icons.work,
                      size: 16,
                      color: AppColors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      job.category,
                      style: const TextStyle(color: AppColors.grey),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      job.duration,
                      style: const TextStyle(color: AppColors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Helpers.formatCurrency(job.payment),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onViewDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Ver Detalle'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
