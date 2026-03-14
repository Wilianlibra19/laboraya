import 'package:flutter/material.dart';
import '../../core/models/job_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/job_status_service.dart';
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

  bool get isOwner => widget.currentUser.id == widget.job.createdBy;
  bool get isWorker => widget.currentUser.id == widget.job.acceptedBy;

  Future<void> _acceptJob() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Aceptar este trabajo?'),
        content: const Text('Te comprometes a realizar este trabajo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      print('🔵 Aceptando trabajo: ${widget.job.id}');
      print('🔵 Usuario: ${widget.currentUser.id}');
      
      await _jobStatusService.acceptJob(widget.job.id, widget.currentUser.id);
      
      print('✅ Trabajo aceptado, esperando actualización...');
      
      // Esperar un momento para que Firebase se actualice
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        print('🔵 Llamando onStatusChanged...');
        widget.onStatusChanged();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Trabajo aceptado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Cerrar la pantalla actual y volver atrás
        // La pantalla se actualizará automáticamente con el listener
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Error aceptando: $e');
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
              text: 'Aceptar',
              onPressed: _acceptJob,
              isLoading: _isLoading,
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
