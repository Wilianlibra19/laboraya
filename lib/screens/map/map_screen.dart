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
        key: ValueKey('marker_${job.id}'),
        point: LatLng(job.latitude, job.longitude),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => setState(() => _selectedJob = job),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pin del mapa
              Icon(
                Icons.location_on,
                size: 80,
                color: job.isUrgent ? AppColors.urgent : AppColors.primary,
              ),
              // Icono de la categoría
              Positioned(
                top: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCategoryIcon(job.category),
                    size: 24,
                    color: job.isUrgent ? AppColors.urgent : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'limpieza':
        return Icons.cleaning_services;
      case 'construcción':
        return Icons.construction;
      case 'electricidad':
        return Icons.electrical_services;
      case 'plomería':
        return Icons.plumbing;
      case 'jardinería':
        return Icons.yard;
      case 'pintura':
        return Icons.format_paint;
      case 'carpintería':
        return Icons.carpenter;
      case 'mudanza':
        return Icons.local_shipping;
      case 'reparaciones':
        return Icons.build;
      case 'tecnología':
        return Icons.computer;
      case 'cocina':
        return Icons.restaurant;
      case 'cuidado':
        return Icons.favorite;
      case 'educación':
        return Icons.school;
      case 'transporte':
      case 'chofer':
        return Icons.local_taxi;
      case 'delivery':
        return Icons.delivery_dining;
      case 'seguridad':
        return Icons.security;
      case 'belleza':
        return Icons.face;
      case 'mascotas':
        return Icons.pets;
      case 'eventos':
        return Icons.celebration;
      case 'fotografía':
        return Icons.camera_alt;
      case 'diseño':
        return Icons.design_services;
      case 'marketing':
        return Icons.campaign;
      case 'contabilidad':
        return Icons.calculate;
      case 'legal':
        return Icons.gavel;
      case 'salud':
        return Icons.medical_services;
      case 'fitness':
        return Icons.fitness_center;
      case 'música':
        return Icons.music_note;
      case 'traducción':
        return Icons.translate;
      case 'escritura':
        return Icons.edit;
      default:
        return Icons.work;
    }
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
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
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
