import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../../core/models/job_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/job_status_service.dart';
import '../../core/services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/custom_button.dart';

class RateWorkerScreen extends StatefulWidget {
  final JobModel job;

  const RateWorkerScreen({super.key, required this.job});

  @override
  State<RateWorkerScreen> createState() => _RateWorkerScreenState();
}

class _RateWorkerScreenState extends State<RateWorkerScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isLoading = false;
  UserModel? _worker;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _loadWorker();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  Future<void> _loadWorker() async {
    if (widget.job.acceptedBy != null) {
      final worker = await context.read<UserService>().getUserById(widget.job.acceptedBy!);
      setState(() => _worker = worker);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una calificación'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final jobStatusService = JobStatusService();
      
      await jobStatusService.completeJobWithRating(
        jobId: widget.job.id,
        workerId: widget.job.acceptedBy!,
        ratingWorker: _rating.toDouble(),
        commentWorker: _commentController.text.trim().isEmpty 
            ? null 
            : _commentController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        
        // Iniciar confeti
        _confettiController.play();
        
        // Mostrar diálogo de éxito con animación
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _SuccessDialog(
            rating: _rating,
            comment: _commentController.text.trim(),
            payment: widget.job.payment,
            workerName: _worker?.name ?? 'Trabajador',
          ),
        );
        
        if (mounted) {
          // Cerrar la pantalla de calificación
          Navigator.of(context).pop(true);
          
          // Esperar un poco
          await Future.delayed(const Duration(milliseconds: 300));
          
          if (mounted) {
            // Cerrar también la pantalla de detalle del trabajo
            Navigator.of(context).pop();
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Calificar Trabajador'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Información del trabajo
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
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
                        Text(
                          Helpers.formatCurrency(widget.job.payment),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Información del trabajador
                if (_worker != null) ...[
                  const Text(
                    'Trabajador',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        backgroundImage: _worker!.photo != null
                            ? NetworkImage(_worker!.photo!)
                            : null,
                        child: _worker!.photo == null
                            ? Text(
                                _worker!.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: AppColors.white),
                              )
                            : null,
                      ),
                      title: Text(_worker!.name),
                      subtitle: Text(
                        '⭐ ${_worker!.rating.toStringAsFixed(1)} • ${_worker!.completedJobs} trabajos',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Calificación
                const Text(
                  '¿Cómo fue el trabajo?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        size: 40,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setState(() => _rating = index + 1);
                      },
                    );
                  }),
                ),
                if (_rating > 0)
                  Text(
                    _getRatingText(_rating),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.grey,
                    ),
                    textAlign: TextAlign.center,
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
                  decoration: InputDecoration(
                    hintText: 'Cuéntanos sobre tu experiencia...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    ),
                  ),
                  maxLines: 4,
                  maxLength: 200,
                ),
                const SizedBox(height: 24),

                // Resumen
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumen',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('• Pago al trabajador: ${Helpers.formatCurrency(widget.job.payment)}'),
                        Text('• Calificación: ${_rating > 0 ? "$_rating estrellas" : "Sin calificar"}'),
                        const Text('• El trabajo se marcará como completado'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón
                CustomButton(
                  text: 'Completar y Calificar',
                  onPressed: _submitRating,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
        // Confeti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
          ),
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }
}

class _SuccessDialog extends StatefulWidget {
  final int rating;
  final String comment;
  final double payment;
  final String workerName;

  const _SuccessDialog({
    required this.rating,
    required this.comment,
    required this.payment,
    required this.workerName,
  });

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    _controller.forward();
    _confettiController.play();

    // Auto cerrar después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            size: 28,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  // Contenido principal
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icono de éxito
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 100,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Título
                            const Text(
                              '¡Trabajo Terminado!',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Con éxito',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Tarjeta de información
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[850]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Nombre del trabajador
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        size: 24,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          widget.workerName,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Estrellas
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < widget.rating ? Icons.star : Icons.star_border,
                                        color: Colors.amber,
                                        size: 40,
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _getRatingText(widget.rating),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.grey,
                                    ),
                                  ),

                                  // Comentario
                                  if (widget.comment.isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.grey[800]
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        '"${widget.comment}"',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontStyle: FontStyle.italic,
                                          color: AppColors.grey,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 24),

                                  // Pago
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.shade400,
                                          Colors.green.shade600,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.account_balance_wallet,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          Helpers.formatCurrency(widget.payment),
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Botón cerrar
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Text(
                                  'Cerrar',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Confeti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
          ),
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }
}
