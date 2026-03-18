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

  bool get _isContract => job.jobType == 'contract';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF162033);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8EEF6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopRow(titleColor),
                const SizedBox(height: 14),

                Text(
                  job.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.28,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),

                const SizedBox(height: 10),

                if ((job.description).trim().isNotEmpty)
                  Text(
                    job.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: subtitleColor,
                    ),
                  ),

                if (showStatus) ...[
                  const SizedBox(height: 12),
                  _buildStatusBadge(),
                ],

                const SizedBox(height: 14),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: CategoryIcons.icons[job.category] ?? Icons.work_outline_rounded,
                      text: job.category,
                      background: AppColors.primary.withOpacity(0.10),
                      color: AppColors.primary,
                    ),
                    _InfoChip(
                      icon: _isContract ? Icons.badge_outlined : Icons.access_time_rounded,
                      text: _isContract ? 'Contrato' : job.duration,
                      background: const Color(0xFFF3F6FB),
                      color: const Color(0xFF4B5563),
                    ),
                    _InfoChip(
                      icon: Icons.payments_outlined,
                      text: job.paymentType,
                      background: const Color(0xFFF3F6FB),
                      color: const Color(0xFF4B5563),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: subtitleColor,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        job.address.split(',').first.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (distance != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.near_me_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              Helpers.formatDistance(distance!),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                if (_isContract &&
                    job.jobStatus == 'in_progress' &&
                    job.contractStartDate != null &&
                    job.estimatedDays != null) ...[
                  const SizedBox(height: 14),
                  _buildMiniContractProgress(),
                ],

                const SizedBox(height: 14),

                Container(
                  height: 1,
                  color: borderColor,
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: subtitleColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      Helpers.getTimeAgo(job.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _isContract
                            ? const Color(0xFFEEF6FF)
                            : const Color(0xFFF4FBF4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _isContract ? 'Contrato' : 'Trabajo puntual',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _isContract
                              ? const Color(0xFF1D70D6)
                              : const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(Color titleColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF21C87A), Color(0xFF17A965)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF21C87A).withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.payments_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      Helpers.formatCurrency(job.payment),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              if (job.isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7B72), Color(0xFFFF5A4F)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B6B).withOpacity(0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Urgente',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String statusText;
    IconData icon;

    switch (job.jobStatus) {
      case 'available':
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        statusText = 'Disponible';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'accepted':
        backgroundColor = Colors.amber.shade50;
        textColor = Colors.amber.shade800;
        statusText = 'Aceptado';
        icon = Icons.handshake_outlined;
        break;
      case 'on_the_way':
        backgroundColor = Colors.deepPurple.shade50;
        textColor = Colors.deepPurple.shade700;
        statusText = 'En camino';
        icon = Icons.near_me_rounded;
        break;
      case 'in_progress':
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        statusText = 'En progreso';
        icon = Icons.construction_rounded;
        break;
      case 'finished_by_worker':
        backgroundColor = Colors.indigo.shade50;
        textColor = Colors.indigo.shade700;
        statusText = 'Esperando confirmación';
        icon = Icons.pending_actions_rounded;
        break;
      case 'confirmed_by_client':
        backgroundColor = Colors.teal.shade50;
        textColor = Colors.teal.shade700;
        statusText = 'Confirmado';
        icon = Icons.verified_rounded;
        break;
      case 'completed':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        statusText = 'Completado';
        icon = Icons.check_circle_rounded;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        statusText = job.jobStatus;
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: textColor),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: Colors.orange,
            ),
            const SizedBox(width: 6),
            Text(
              'Día $daysPassed de $estimatedDays',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.orange,
              ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? Colors.red : Colors.orange,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color background;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.background,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}