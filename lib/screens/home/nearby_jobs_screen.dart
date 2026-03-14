import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/job_service.dart';
import '../../core/services/user_service.dart';
import '../../core/services/location_service.dart';
import '../../core/models/job_model.dart';
import '../../utils/constants.dart';
import '../../widgets/job/job_card.dart';
import '../job/job_detail_screen.dart';

class NearbyJobsScreen extends StatefulWidget {
  const NearbyJobsScreen({super.key});

  @override
  State<NearbyJobsScreen> createState() => _NearbyJobsScreenState();
}

class _NearbyJobsScreenState extends State<NearbyJobsScreen> {
  Position? _currentPosition;
  bool _isLoading = true;
  double _selectedRadius = 5.0; // km
  List<JobWithDistance> _nearbyJobs = [];

  @override
  void initState() {
    super.initState();
    _loadNearbyJobs();
  }

  Future<void> _loadNearbyJobs() async {
    setState(() => _isLoading = true);

    _currentPosition = await LocationService.getCurrentLocation();

    if (_currentPosition == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener tu ubicación'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final currentUserId = context.read<UserService>().currentUser?.id;
    final allJobs = context.read<JobService>().availableJobs;
    
    print('🔍 Usuario actual: $currentUserId');
    print('🔍 Total de trabajos: ${allJobs.length}');
    
    // Filtrar trabajos propios
    final filteredJobs = allJobs.where((job) {
      final isOwn = job.createdBy == currentUserId;
      if (isOwn) {
        print('❌ Filtrando trabajo propio: ${job.title} (${job.id})');
      }
      return !isOwn; // Solo mostrar trabajos que NO son del usuario actual
    }).toList();
    
    print('✅ Trabajos después de filtrar: ${filteredJobs.length}');
    
    _nearbyJobs = filteredJobs.map((job) {
      final distance = LocationService.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        job.latitude,
        job.longitude,
      );
      return JobWithDistance(job: job, distance: distance);
    }).where((jobWithDistance) {
      return jobWithDistance.distance <= _selectedRadius;
    }).toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trabajos Cerca de Mí'),
      ),
      body: Column(
        children: [
          // Selector de radio
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Radio de búsqueda',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _selectedRadius,
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: '${_selectedRadius.toStringAsFixed(0)} km',
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() => _selectedRadius = value);
                        },
                        onChangeEnd: (value) {
                          _loadNearbyJobs();
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_selectedRadius.toStringAsFixed(0)} km',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RadioChip(
                      label: '1 km',
                      isSelected: _selectedRadius == 1,
                      onTap: () {
                        setState(() => _selectedRadius = 1);
                        _loadNearbyJobs();
                      },
                    ),
                    _RadioChip(
                      label: '3 km',
                      isSelected: _selectedRadius == 3,
                      onTap: () {
                        setState(() => _selectedRadius = 3);
                        _loadNearbyJobs();
                      },
                    ),
                    _RadioChip(
                      label: '5 km',
                      isSelected: _selectedRadius == 5,
                      onTap: () {
                        setState(() => _selectedRadius = 5);
                        _loadNearbyJobs();
                      },
                    ),
                    _RadioChip(
                      label: '10 km',
                      isSelected: _selectedRadius == 10,
                      onTap: () {
                        setState(() => _selectedRadius = 10);
                        _loadNearbyJobs();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de trabajos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentPosition == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_off,
                              size: 80,
                              color: AppColors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No se pudo obtener tu ubicación',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Activa el GPS y da permisos de ubicación',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadNearbyJobs,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _nearbyJobs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 80,
                                  color: AppColors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay trabajos en ${_selectedRadius.toStringAsFixed(0)} km',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: AppColors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Intenta aumentar el radio de búsqueda',
                                  style: TextStyle(
                                    fontSize: 14,
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
                            itemCount: _nearbyJobs.length,
                            itemBuilder: (context, index) {
                              final jobWithDistance = _nearbyJobs[index];
                              return JobCard(
                                job: jobWithDistance.job,
                                distance: jobWithDistance.distance,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => JobDetailScreen(
                                        jobId: jobWithDistance.job.id,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class JobWithDistance {
  final JobModel job;
  final double distance;

  JobWithDistance({required this.job, required this.distance});
}

class _RadioChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RadioChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.primary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
