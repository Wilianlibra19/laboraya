import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/review_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/user_service.dart';
import '../../data/local/hive_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/custom_button.dart';

class RateJobScreen extends StatefulWidget {
  final String jobId;
  final String workerUserId;

  const RateJobScreen({
    super.key,
    required this.jobId,
    required this.workerUserId,
  });

  @override
  State<RateJobScreen> createState() => _RateJobScreenState();
}

class _RateJobScreenState extends State<RateJobScreen> {
  double _rating = 5.0;
  final _commentController = TextEditingController();
  bool _isLoading = false;
  UserModel? _worker;

  @override
  void initState() {
    super.initState();
    _loadWorker();
  }

  Future<void> _loadWorker() async {
    final userService = context.read<UserService>();
    _worker = await userService.getUserById(widget.workerUserId);
    setState(() {});
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    setState(() => _isLoading = true);

    final currentUser = context.read<UserService>().currentUser!;
    
    // Crear reseña
    final review = ReviewModel(
      id: const Uuid().v4(),
      jobId: widget.jobId,
      reviewerId: currentUser.id,
      reviewedUserId: widget.workerUserId,
      rating: _rating,
      comment: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    // Guardar reseña
    final reviewsBox = HiveService.getReviewsBox();
    await reviewsBox.put(review.id, review);

    // Actualizar calificación del trabajador
    if (_worker != null) {
      final totalReviews = _worker!.totalReviews + 1;
      final newRating = ((_worker!.rating * _worker!.totalReviews) + _rating) / totalReviews;
      
      _worker!.rating = newRating;
      _worker!.totalReviews = totalReviews;
      
      await context.read<UserService>().updateProfile(_worker!);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calificación enviada exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calificar Trabajo'),
      ),
      body: _worker == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: Column(
                children: [
                  // Perfil del trabajador
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingLarge),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary,
                          backgroundImage: _worker!.photo != null
                              ? NetworkImage(_worker!.photo!)
                              : null,
                          child: _worker!.photo == null
                              ? Text(
                                  Helpers.getInitials(_worker!.name),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _worker!.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star,
                              color: AppColors.urgent,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _worker!.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${_worker!.totalReviews} reseñas)',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Calificación
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingLarge),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¿Cómo fue tu experiencia?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                _rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() => _rating = index + 1.0);
                                    },
                                    child: Icon(
                                      index < _rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 48,
                                      color: AppColors.urgent,
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _rating == 5
                                    ? 'Excelente'
                                    : _rating >= 4
                                        ? 'Muy bueno'
                                        : _rating >= 3
                                            ? 'Bueno'
                                            : _rating >= 2
                                                ? 'Regular'
                                                : 'Malo',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Comentario
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingLarge),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Comentario (opcional)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Cuéntanos sobre tu experiencia...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                          ),
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón enviar
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingLarge),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    ),
                    child: CustomButton(
                      text: 'Enviar Calificación',
                      onPressed: _submitRating,
                      isLoading: _isLoading,
                      icon: Icons.send,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
