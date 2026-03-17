import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../core/models/job_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/job_status_service.dart';
import '../../core/services/job_application_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
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

    // Navegar a pantalla completa para solicitar trabajo
    final messageController = TextEditingController();
    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _ApplicationDialog(
          messageController: messageController,
          jobTitle: widget.job.title,
        ),
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
            content: Text('✅ Trabajo marcado como terminado. Esperando confirmación del cliente.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
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
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    const Expanded(
                      child: Text(
                        'Solicitar Trabajo',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance para centrar
                  ],
                ),
              ),

              // Contenido principal
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icono y título del trabajo
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.work_outline,
                                  size: 50,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  widget.jobTitle,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Consejos
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb,
                                    color: Colors.amber[700],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Consejos para destacar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTip('Menciona tu experiencia relevante'),
                              _buildTip('Explica por qué eres el indicado'),
                              _buildTip('Sé claro y profesional'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Label del campo
                        const Text(
                          'Tu mensaje',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Campo de texto
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[850]
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: TextField(
                            controller: widget.messageController,
                            maxLines: 8,
                            maxLength: 500,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Ejemplo:\n\nHola, tengo 5 años de experiencia en este tipo de trabajos. He realizado proyectos similares con excelentes resultados. Estoy disponible de inmediato y puedo garantizar un trabajo de calidad.',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                                height: 1.5,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(20),
                              counterStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Botón de enviar
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'Enviar Solicitud',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 18,
            color: Colors.green,
          ),
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

// Diálogo de éxito para el trabajador con confeti
class _WorkerSuccessDialog extends StatefulWidget {
  final double payment;

  const _WorkerSuccessDialog({
    required this.payment,
  });

  @override
  State<_WorkerSuccessDialog> createState() => _WorkerSuccessDialogState();
}

class _WorkerSuccessDialogState extends State<_WorkerSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
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

                            // Tarjeta de pago
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(32),
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
                                  const Text(
                                    'Ganaste',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.shade400,
                                          Colors.green.shade600,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.account_balance_wallet,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          Helpers.formatCurrency(widget.payment),
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Esperando confirmación del cliente',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
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
}
