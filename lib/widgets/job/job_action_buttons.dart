import 'package:flutter/material.dart';
import '../../core/models/job_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/job_status_service.dart';
import '../../core/services/job_application_service.dart';
import '../../utils/constants.dart';
import '../../widgets/common/custom_button.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/job/rate_worker_screen.dart';

class JobActionButtons extends StatefulWidget {
  final JobModel job;
  final UserModel currentUser;
  final VoidCallback onStatusChanged;

  const JobActionButtons({
    super.key,
    required this.job,
    required this.currentUser,
    required this.onStatusChanged,
  });

  @override
  State<JobActionButtons> createState() => _JobActionButtonsState();
}

class _JobActionButtonsState extends State<JobActionButtons> {
  bool _isLoading = false;
  final _jobStatusService = JobStatusService();
  final _applicationService = JobApplicationService();

  bool get isOwner => widget.currentUser.id == widget.job.createdBy;
  bool get isWorker => widget.currentUser.id == widget.job.acceptedBy;

  Future<void> _applyToJob() async {
    // Verificar si ya aplicó
    final hasApplied = await _applicationService.hasUserApplied(
      widget.job.id,
      widget.currentUser.id,
    );

    if (hasApplied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya has solicitado este trabajo'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Mostrar diálogo mejorado para mensaje
    final messageController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ApplicationDialog(
        messageController: messageController,
        jobTitle: widget.job.title,
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _applicationService.applyToJob(
        jobId: widget.job.id,
        applicant: widget.currentUser,
        message: messageController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '✅ Solicitud enviada exitosamente',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Error enviando solicitud: $e');
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

  Future<void> _markOnTheWay() async {
    setState(() => _isLoading = true);

    try {
      await _jobStatusService.markOnTheWay(widget.job.id);
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Marcado como "En camino"'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onStatusChanged();
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

  Future<void> _startJob() async {
    setState(() => _isLoading = true);

    try {
      await _jobStatusService.startJob(widget.job.id);
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Trabajo iniciado'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onStatusChanged();
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

  Future<void> _finishJob() async {
    setState(() => _isLoading = true);

    try {
      await _jobStatusService.finishJob(widget.job.id);
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Trabajo marcado como terminado'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onStatusChanged();
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

  Future<void> _confirmJob() async {
    setState(() => _isLoading = true);

    try {
      await _jobStatusService.confirmJob(widget.job.id);
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Trabajo confirmado'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onStatusChanged();
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

  Future<void> _rateWorker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RateWorkerScreen(job: widget.job),
      ),
    );

    if (result == true) {
      widget.onStatusChanged();
    }
  }

  void _openChat() {
    final otherUserId = isOwner ? widget.job.acceptedBy! : widget.job.createdBy;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          jobId: widget.job.id,
          otherUserId: otherUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🎯 JobActionButtons - Estado: ${widget.job.jobStatus}');
    print('🎯 isOwner: $isOwner, isWorker: $isWorker');
    
    // Si el trabajo está disponible y no eres el dueño
    if (widget.job.jobStatus == 'available' && !isOwner) {
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Mensaje',
              onPressed: _openChat,
              icon: Icons.chat,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomButton(
              text: 'Solicitar',
              onPressed: _applyToJob,
              isLoading: _isLoading,
              icon: Icons.send,
            ),
          ),
        ],
      );
    }

    // Si eres el trabajador
    if (isWorker) {
      switch (widget.job.jobStatus) {
        case 'accepted':
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: CustomButton(
                  text: 'En camino',
                  onPressed: _markOnTheWay,
                  isLoading: _isLoading,
                  icon: Icons.directions_car,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: 'Chat',
                  onPressed: _openChat,
                  icon: Icons.chat,
                  color: Colors.grey,
                ),
              ),
            ],
          );

        case 'on_the_way':
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: CustomButton(
                  text: 'Iniciar',
                  onPressed: _startJob,
                  isLoading: _isLoading,
                  icon: Icons.play_arrow,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: 'Chat',
                  onPressed: _openChat,
                  icon: Icons.chat,
                  color: Colors.grey,
                ),
              ),
            ],
          );

        case 'in_progress':
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: CustomButton(
                  text: 'Terminado',
                  onPressed: _finishJob,
                  isLoading: _isLoading,
                  icon: Icons.check_circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: 'Chat',
                  onPressed: _openChat,
                  icon: Icons.chat,
                  color: Colors.grey,
                ),
              ),
            ],
          );

        case 'finished_by_worker':
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.pending, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Esperando confirmación',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CustomButton(
                text: 'Chat',
                onPressed: _openChat,
                icon: Icons.chat,
                color: Colors.grey,
              ),
            ],
          );

        case 'confirmed_by_client':
        case 'completed':
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '¡Completado!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.job.ratingWorker != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < widget.job.ratingWorker!.toInt()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 18,
                      );
                    }),
                  ],
                ),
                if (widget.job.commentWorker != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '"${widget.job.commentWorker}"',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ],
          );
      }
    }

    // Si eres el dueño
    if (isOwner) {
      switch (widget.job.jobStatus) {
        case 'available':
          return Row(
            children: [
              const Icon(Icons.hourglass_empty, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Esperando aceptación',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );

        case 'accepted':
        case 'on_the_way':
        case 'in_progress':
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    widget.job.jobStatus == 'accepted'
                        ? Icons.handshake
                        : widget.job.jobStatus == 'on_the_way'
                            ? Icons.directions_car
                            : Icons.construction,
                    color: Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.job.jobStatus == 'accepted'
                          ? 'Trabajo aceptado'
                          : widget.job.jobStatus == 'on_the_way'
                              ? 'En camino'
                              : 'En progreso',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CustomButton(
                text: 'Chat',
                onPressed: _openChat,
                icon: Icons.chat,
              ),
            ],
          );

        case 'finished_by_worker':
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.pending, color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Trabajador terminó',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomButton(
                      text: 'Confirmar',
                      onPressed: _confirmJob,
                      isLoading: _isLoading,
                      icon: Icons.verified,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Chat',
                      onPressed: _openChat,
                      icon: Icons.chat,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          );

        case 'confirmed_by_client':
          return CustomButton(
            text: 'Calificar',
            onPressed: _rateWorker,
            icon: Icons.star,
          );

        case 'completed':
          return Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '¡Completado!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          );
      }
    }

    return const SizedBox.shrink();
  }
}


// Diálogo animado para solicitar trabajo
class _ApplicationDialog extends StatefulWidget {
  final TextEditingController messageController;
  final String jobTitle;

  const _ApplicationDialog({
    required this.messageController,
    required this.jobTitle,
  });

  @override
  State<_ApplicationDialog> createState() => _ApplicationDialogState();
}

class _ApplicationDialogState extends State<_ApplicationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Icono animado
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.work_outline,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Título
                const Text(
                  'Solicitar Trabajo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtítulo con nombre del trabajo
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.jobTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 24),

                // Instrucción
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Escribe un mensaje para destacar:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Campo de texto mejorado
                Container(
                  constraints: const BoxConstraints(
                    minHeight: 120,
                    maxHeight: 200,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: widget.messageController,
                    maxLines: null,
                    minLines: 5,
                    maxLength: 300,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Ej: Tengo 5 años de experiencia en...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      counterStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Enviar Solicitud',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
      ),
    );
  }
}
