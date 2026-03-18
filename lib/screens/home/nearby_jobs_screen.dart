import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/models/job_model.dart';
import '../../core/services/job_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/user_service.dart';
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
  double _selectedRadius = 5.0;
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

    final filteredJobs = allJobs.where((job) {
      return job.createdBy != currentUserId;
    }).toList();

    _nearbyJobs = filteredJobs
        .map((job) {
          final distance = LocationService.calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            job.latitude,
            job.longitude,
          );
          return JobWithDistance(job: job, distance: distance);
        })
        .where((jobWithDistance) => jobWithDistance.distance <= _selectedRadius)
        .toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
      body: Column(
        children: [
          _buildHeader(),
          _buildRadiusPanel(isDark),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentPosition == null
                    ? _LocationErrorState(
                        isDark: isDark,
                        onRetry: _loadNearbyJobs,
                      )
                    : _nearbyJobs.isEmpty
                        ? _EmptyNearbyState(
                            isDark: isDark,
                            radius: _selectedRadius,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                            itemCount: _nearbyJobs.length,
                            itemBuilder: (context, index) {
                              final jobWithDistance = _nearbyJobs[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: JobCard(
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
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
                  'Trabajos cerca de mí',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Explora oportunidades cercanas a tu ubicación',
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

  Widget _buildRadiusPanel(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RadiusHeader(
            radius: _selectedRadius,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          Slider(
            value: _selectedRadius,
            min: 1,
            max: 20,
            divisions: 19,
            label: '${_selectedRadius.toStringAsFixed(0)} km',
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() => _selectedRadius = value);
            },
            onChangeEnd: (_) {
              _loadNearbyJobs();
            },
          ),
          const SizedBox(height: 8),
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
    );
  }
}

class JobWithDistance {
  final JobModel job;
  final double distance;

  JobWithDistance({
    required this.job,
    required this.distance,
  });
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

class _RadiusHeader extends StatelessWidget {
  final double radius;
  final bool isDark;

  const _RadiusHeader({
    required this.radius,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.radar_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Radio de búsqueda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF162033),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${radius.toStringAsFixed(0)} km',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.primary,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _LocationErrorState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRetry;

  const _LocationErrorState({
    required this.isDark,
    required this.onRetry,
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
          child: Column(
            children: [
              Container(
                height: 92,
                width: 92,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.error.withOpacity(0.14),
                      AppColors.error.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.location_off_outlined,
                  size: 42,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No se pudo obtener tu ubicación',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF162033),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Activa el GPS y asegúrate de conceder permisos de ubicación a la app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.55,
                  color: isDark ? Colors.white70 : const Color(0xFF5D6A79),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onRetry,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Reintentar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNearbyState extends StatelessWidget {
  final bool isDark;
  final double radius;

  const _EmptyNearbyState({
    required this.isDark,
    required this.radius,
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
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 42,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No hay trabajos en ${radius.toStringAsFixed(0)} km',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF162033),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Prueba aumentando el radio de búsqueda para encontrar más oportunidades cercanas.',
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