import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/job_model.dart';
import '../../core/models/user_model.dart';
import '../../core/models/review_model.dart';
import '../../core/services/job_service.dart';
import '../../core/services/user_service.dart';
import '../../data/firebase/firebase_user_repository.dart';
import '../../data/firebase/firebase_review_repository.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/custom_button.dart';

class CompleteJobScreen extends StatefulWidget {
  final JobModel job;
  final UserModel worker;

  const CompleteJobScreen({
    super.key,
    required this.job,
    required this.worker,
  });

  @override
  State<CompleteJobScreen> createState() => _CompleteJobScreenState();
}

class _CompleteJobScreenState extends State<CompleteJobScreen> {
  double _rating = 5.0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _completeAndRate() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUser = context.read<UserService>().currentUser;
      if (currentUser == null) return;

      // 1. Completar el trabajo
      await context.read<JobService>().completeJob(
            widget.job.id,
            widget.worker.id,
            widget.job.payment,
          );

      // 2. Actualizar ganancias del trabajador
      final userRepo = FirebaseUserRepository();
      await userRepo.updateEarnings(widget.worker.id, widget.job.payment);

      // 3. Crear calificación
      final review = ReviewModel(
        id: const Uuid().v4(),
        jobId: widget.job.id,
        reviewerId: currentUser.id,
        reviewedUserId: widget.worker.id,
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      final reviewRepo = FirebaseReviewRepository();
      await reviewRepo.createReview(review);

      // 4. Actualizar calificación del trabajador
      await userRepo.updateRating(widget.worker.id, _rating);

      // 5. Recargar datos del usuario si es el trabajador
      if (currentUser.id == widget.worker.id) {
        print('🔄 Recargando datos del trabajador...');
        await context.read<UserService>().refreshCurrentUser();
        print('✅ Datos del trabajador recargados');
      }

      if (mounted) {
        Navigator.pop(context); // Cerrar pantalla de completar
        Navigator.pop(context); // Cerrar detalle del trabajo

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('¡Trabajo completado y calificado exitosamente!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Trabajo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del trabajo
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.job.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Helpers.formatCurrency(widget.job.payment),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Información del trabajador
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      Helpers.getInitials(widget.worker.name),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trabajador',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey,
                          ),
                        ),
                        Text(
                          widget.worker.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Calificación
            const Text(
              '¿Cómo fue el trabajo?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          size: 40,
                          color: AppColors.urgent,
                        ),
                        onPressed: () {
                          setState(() => _rating = index + 1.0);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRatingText(_rating),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Comentario
            const Text(
              'Comentario (opcional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Cuéntanos sobre tu experiencia...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[850]
                    : AppColors.background,
              ),
            ),
            const SizedBox(height: 32),

            // Resumen
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Al completar este trabajo:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    icon: Icons.check_circle_outline,
                    text: 'El trabajo se marcará como completado',
                  ),
                  _SummaryRow(
                    icon: Icons.attach_money,
                    text:
                        '${widget.worker.name} recibirá ${Helpers.formatCurrency(widget.job.payment)}',
                  ),
                  _SummaryRow(
                    icon: Icons.star_outline,
                    text: 'Tu calificación será visible en su perfil',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botón
            CustomButton(
              text: _isSubmitting ? 'Procesando...' : 'Completar y Calificar',
              onPressed: _isSubmitting ? () {} : () => _completeAndRate(),
              icon: Icons.check_circle,
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 5) return 'Excelente';
    if (rating >= 4) return 'Muy bueno';
    if (rating >= 3) return 'Bueno';
    if (rating >= 2) return 'Regular';
    return 'Malo';
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SummaryRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
