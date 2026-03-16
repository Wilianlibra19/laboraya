import 'package:flutter/material.dart';
import '../../core/models/job_model.dart';
import '../../utils/constants.dart';

class JobProgressBar extends StatelessWidget {
  final JobModel job;

  const JobProgressBar({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps();
    final currentStepIndex = _getCurrentStepIndex();

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
        vertical: AppSizes.paddingSmall,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.timeline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Progreso del Trabajo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Barra de progreso visual con SingleChildScrollView
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(steps.length * 2 - 1, (index) {
                  if (index.isEven) {
                    // Es un círculo (paso)
                    final stepIndex = index ~/ 2;
                    final step = steps[stepIndex];
                    final isCompleted = stepIndex < currentStepIndex;
                    final isCurrent = stepIndex == currentStepIndex;
                    
                    return _buildStep(
                      step: step,
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                    );
                  } else {
                    // Es una línea conectora
                    final stepIndex = index ~/ 2;
                    final isCompleted = stepIndex < currentStepIndex;
                    
                    return Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isCompleted 
                            ? AppColors.primary 
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }
                }),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Descripción del paso actual
            _buildCurrentStepDescription(steps[currentStepIndex]),
            
            // Si es un contrato en progreso, mostrar barra de progreso de días
            if (job.jobType == 'contract' && 
                job.jobStatus == 'in_progress' && 
                job.contractStartDate != null && 
                job.estimatedDays != null) ...[
              const SizedBox(height: 16),
              _buildContractProgress(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required ProgressStep step,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    Color color;
    Color bgColor;
    IconData icon;

    if (isCompleted) {
      color = AppColors.primary;
      bgColor = AppColors.primary;
      icon = Icons.check_circle;
    } else if (isCurrent) {
      color = Colors.orange;
      bgColor = Colors.orange;
      icon = step.icon;
    } else {
      color = Colors.grey.shade400;
      bgColor = Colors.grey.shade300;
      icon = step.icon;
    }

    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isCompleted || isCurrent 
                ? bgColor.withOpacity(0.15) 
                : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: isCurrent ? 3 : 2,
            ),
            boxShadow: isCurrent ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ] : [],
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 70,
          child: Text(
            step.label,
            style: TextStyle(
              fontSize: 11,
              color: isCurrent ? color : Colors.grey.shade700,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepDescription(ProgressStep step) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              step.icon,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractProgress() {
    final startDate = job.contractStartDate!;
    final estimatedDays = job.estimatedDays!;
    final now = DateTime.now();
    final daysPassed = now.difference(startDate).inDays;
    final progress = (daysPassed / estimatedDays).clamp(0.0, 1.0);
    final estimatedEndDate = startDate.add(Duration(days: estimatedDays));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade50,
            Colors.deepOrange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Progreso del Contrato',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.red : Colors.orange,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Información de días
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Día $daysPassed de $estimatedDays',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% completado',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: progress >= 1.0 
                      ? Colors.red.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: progress >= 1.0 
                        ? Colors.red.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  progress >= 1.0 ? 'Vencido' : 'En tiempo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: progress >= 1.0 ? Colors.red : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Fechas
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Inicio: ${_formatDate(startDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 16,
                      color: progress >= 1.0 ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fin estimado: ${_formatDate(estimatedEndDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
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

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  List<ProgressStep> _getSteps() {
    return [
      ProgressStep(
        label: 'Disponible',
        icon: Icons.work_outline,
        description: 'Trabajo publicado y esperando aceptación',
      ),
      ProgressStep(
        label: 'Aceptado',
        icon: Icons.handshake,
        description: 'Un trabajador aceptó el trabajo',
      ),
      ProgressStep(
        label: 'En camino',
        icon: Icons.directions_car,
        description: 'El trabajador va en camino',
      ),
      ProgressStep(
        label: 'En progreso',
        icon: Icons.construction,
        description: 'El trabajo está en progreso',
      ),
      ProgressStep(
        label: 'Terminado',
        icon: Icons.pending,
        description: 'Esperando confirmación del cliente',
      ),
      ProgressStep(
        label: 'Completado',
        icon: Icons.check_circle,
        description: 'Trabajo completado y calificado',
      ),
    ];
  }

  int _getCurrentStepIndex() {
    switch (job.jobStatus) {
      case 'available':
        return 0;
      case 'accepted':
        return 1;
      case 'on_the_way':
        return 2;
      case 'in_progress':
        return 3;
      case 'finished_by_worker':
        return 4;
      case 'confirmed_by_client':
      case 'completed':
        return 5;
      default:
        return 0;
    }
  }
}

class ProgressStep {
  final String label;
  final IconData icon;
  final String description;

  ProgressStep({
    required this.label,
    required this.icon,
    required this.description,
  });
}
