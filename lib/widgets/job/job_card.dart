import 'package:flutter/material.dart';
import '../../core/models/job_model.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;
  final double? distance;
  final bool showStatus;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.distance,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
        vertical: AppSizes.paddingSmall,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: Padding(
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (job.isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.urgent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'URGENTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                ],
              ),
              // Mostrar estado del trabajo si showStatus es true
              if (showStatus) ...[
                const SizedBox(height: 8),
                _buildStatusBadge(),
              ],
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
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.grey,
                    ),
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
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.address.split(',').first,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (distance != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      Helpers.formatDistance(distance!),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Mini barra de progreso para contratos en progreso
              if (job.jobType == 'contract' && 
                  job.jobStatus == 'in_progress' && 
                  job.contractStartDate != null && 
                  job.estimatedDays != null)
                _buildMiniContractProgress(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Helpers.formatCurrency(job.payment),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    Helpers.getTimeAgo(job.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String statusText;
    IconData icon;

    switch (job.jobStatus) {
      case 'available':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        statusText = 'Disponible';
        icon = Icons.check_circle_outline;
        break;
      case 'accepted':
        backgroundColor = Colors.yellow.shade100;
        textColor = Colors.yellow.shade900;
        statusText = 'Aceptado';
        icon = Icons.handshake;
        break;
      case 'on_the_way':
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade900;
        statusText = 'En camino';
        icon = Icons.directions_car;
        break;
      case 'in_progress':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        statusText = 'En progreso';
        icon = Icons.construction;
        break;
      case 'finished_by_worker':
        backgroundColor = Colors.indigo.shade100;
        textColor = Colors.indigo.shade900;
        statusText = 'Esperando confirmación';
        icon = Icons.pending;
        break;
      case 'confirmed_by_client':
        backgroundColor = Colors.teal.shade100;
        textColor = Colors.teal.shade900;
        statusText = 'Confirmado';
        icon = Icons.verified;
        break;
      case 'completed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        statusText = 'Completado';
        icon = Icons.check_circle;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade900;
        statusText = job.jobStatus;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniContractProgress() {
    final startDate = job.contractStartDate!;
    final estimatedDays = job.estimatedDays!;
    final now = DateTime.now();
    final daysPassed = now.difference(startDate).inDays;
    final progress = (daysPassed / estimatedDays).clamp(0.0, 1.0);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: Colors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                'Día $daysPassed de $estimatedDays',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.red : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
