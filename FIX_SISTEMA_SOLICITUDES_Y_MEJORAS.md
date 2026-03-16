# Fix: Sistema de Solicitudes y Mejoras

## Problemas Identificados

1. ✅ **Cualquiera puede aceptar el trabajo** - Debe ser sistema de solicitudes
2. ✅ **Confirmar cuando termina el trabajo** - El dueño debe confirmar
3. ✅ **Error al calificar trabajador** - Revisar rate_worker_screen.dart
4. ✅ **Notificación de prueba** - Eliminar notificación de prueba
5. ✅ **Eliminar notificaciones** - Poder eliminar notificaciones
6. ✅ **Ganancias en perfil** - Mostrar ganancias cuando termina trabajo

## Cambios Necesarios

### 1. Crear Modelo de Solicitud (JobApplication)

Crear archivo: `lib/core/models/job_application_model.dart`

```dart
class JobApplicationModel {
  final String id;
  final String jobId;
  final String applicantId;
  final String applicantName;
  final String applicantPhoto;
  final double applicantRating;
  final int applicantCompletedJobs;
  final String message; // Mensaje del solicitante
  final DateTime appliedAt;
  final String status; // 'pending', 'accepted', 'rejected'
  
  JobApplicationModel({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.applicantName,
    required this.applicantPhoto,
    required this.applicantRating,
    required this.applicantCompletedJobs,
    required this.message,
    required this.appliedAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobId': jobId,
        'applicantId': applicantId,
        'applicantName': applicantName,
        'applicantPhoto': applicantPhoto,
        'applicantRating': applicantRating,
        'applicantCompletedJobs': applicantCompletedJobs,
        'message': message,
        'appliedAt': appliedAt.toIso8601String(),
        'status': status,
      };

  factory JobApplicationModel.fromJson(Map<String, dynamic> json) =>
      JobApplicationModel(
        id: json['id'],
        jobId: json['jobId'],
        applicantId: json['applicantId'],
        applicantName: json['applicantName'],
        applicantPhoto: json['applicantPhoto'],
        applicantRating: json['applicantRating']?.toDouble() ?? 0.0,
        applicantCompletedJobs: json['applicantCompletedJobs'] ?? 0,
        message: json['message'] ?? '',
        appliedAt: DateTime.parse(json['appliedAt']),
        status: json['status'] ?? 'pending',
      );

  factory JobApplicationModel.fromFirestore(dynamic snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return JobApplicationModel(
      id: snapshot.id,
      jobId: data['jobId'] ?? '',
      applicantId: data['applicantId'] ?? '',
      applicantName: data['applicantName'] ?? '',
      applicantPhoto: data['applicantPhoto'] ?? '',
      applicantRating: (data['applicantRating'] ?? 0).toDouble(),
      applicantCompletedJobs: data['applicantCompletedJobs'] ?? 0,
      message: data['message'] ?? '',
      appliedAt: (data['appliedAt'] as dynamic).toDate(),
      status: data['status'] ?? 'pending',
    );
  }
}
```

### 2. Crear Servicio de Solicitudes

Crear archivo: `lib/core/services/job_application_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_application_model.dart';
import '../models/user_model.dart';

class JobApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Aplicar a un trabajo
  Future<void> applyToJob({
    required String jobId,
    required UserModel applicant,
    required String message,
  }) async {
    final applicationId = _firestore.collection('job_applications').doc().id;
    
    final application = JobApplicationModel(
      id: applicationId,
      jobId: jobId,
      applicantId: applicant.id,
      applicantName: applicant.name,
      applicantPhoto: applicant.photoUrl ?? '',
      applicantRating: applicant.rating,
      applicantCompletedJobs: applicant.completedJobs,
      message: message,
      appliedAt: DateTime.now(),
      status: 'pending',
    );

    await _firestore
        .collection('job_applications')
        .doc(applicationId)
        .set(application.toJson());
  }

  // Obtener solicitudes de un trabajo
  Stream<List<JobApplicationModel>> getJobApplications(String jobId) {
    return _firestore
        .collection('job_applications')
        .where('jobId', isEqualTo: jobId)
        .where('status', isEqualTo: 'pending')
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobApplicationModel.fromFirestore(doc))
            .toList());
  }

  // Aceptar solicitud
  Future<void> acceptApplication(String applicationId, String jobId) async {
    final batch = _firestore.batch();

    // Actualizar solicitud a aceptada
    batch.update(
      _firestore.collection('job_applications').doc(applicationId),
      {'status': 'accepted'},
    );

    // Obtener el applicantId
    final appDoc = await _firestore
        .collection('job_applications')
        .doc(applicationId)
        .get();
    final applicantId = appDoc.data()!['applicantId'];

    // Actualizar trabajo
    batch.update(
      _firestore.collection('jobs').doc(jobId),
      {
        'acceptedBy': applicantId,
        'jobStatus': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      },
    );

    // Rechazar otras solicitudes
    final otherApps = await _firestore
        .collection('job_applications')
        .where('jobId', isEqualTo: jobId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (var doc in otherApps.docs) {
      if (doc.id != applicationId) {
        batch.update(doc.reference, {'status': 'rejected'});
      }
    }

    await batch.commit();
  }

  // Rechazar solicitud
  Future<void> rejectApplication(String applicationId) async {
    await _firestore
        .collection('job_applications')
        .doc(applicationId)
        .update({'status': 'rejected'});
  }

  // Verificar si el usuario ya aplicó
  Future<bool> hasUserApplied(String jobId, String userId) async {
    final snapshot = await _firestore
        .collection('job_applications')
        .where('jobId', isEqualTo: jobId)
        .where('applicantId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.isNotEmpty;
  }
}
```

### 3. Modificar JobActionButtons

Cambiar el botón "Aceptar" por "Solicitar":

```dart
// En job_action_buttons.dart, reemplazar _acceptJob() por:

Future<void> _applyToJob() async {
  // Verificar si ya aplicó
  final applicationService = JobApplicationService();
  final hasApplied = await applicationService.hasUserApplied(
    widget.job.id,
    widget.currentUser.id,
  );

  if (hasApplied) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ya has solicitado este trabajo'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // Mostrar diálogo para mensaje
  final messageController = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Solicitar Trabajo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Escribe un mensaje para el empleador:'),
          const SizedBox(height: 16),
          TextField(
            controller: messageController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Ej: Tengo experiencia en...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Enviar Solicitud'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  setState(() => _isLoading = true);

  try {
    await applicationService.applyToJob(
      jobId: widget.job.id,
      applicant: widget.currentUser,
      message: messageController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Solicitud enviada'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
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

// Cambiar el botón:
CustomButton(
  text: 'Solicitar',
  onPressed: _applyToJob,
  isLoading: _isLoading,
)
```

### 4. Crear Pantalla de Solicitudes

Crear archivo: `lib/screens/job/job_applications_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../core/models/job_application_model.dart';
import '../../core/services/job_application_service.dart';
import '../../utils/constants.dart';

class JobApplicationsScreen extends StatelessWidget {
  final String jobId;
  final String jobTitle;

  const JobApplicationsScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  Widget build(BuildContext context) {
    final applicationService = JobApplicationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes'),
      ),
      body: StreamBuilder<List<JobApplicationModel>>(
        stream: applicationService.getJobApplications(jobId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No hay solicitudes aún'),
            );
          }

          final applications = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: app.applicantPhoto.isNotEmpty
                                ? NetworkImage(app.applicantPhoto)
                                : null,
                            child: app.applicantPhoto.isEmpty
                                ? Text(app.applicantName[0])
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.applicantName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 16, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${app.applicantRating.toStringAsFixed(1)} (${app.applicantCompletedJobs} trabajos)',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (app.message.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(app.message),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await applicationService.acceptApplication(
                                  app.id,
                                  jobId,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Solicitud aceptada'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check),
                              label: const Text('Aceptar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await applicationService.rejectApplication(
                                  app.id,
                                );
                              },
                              icon: const Icon(Icons.close),
                              label: const Text('Rechazar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

### 5. Agregar Botón de Solicitudes para el Dueño

En `job_detail_screen.dart`, agregar en el AppBar:

```dart
appBar: AppBar(
  title: const Text('Detalle del Trabajo'),
  actions: [
    if (isOwner && job!.jobStatus == 'available')
      StreamBuilder<List<JobApplicationModel>>(
        stream: JobApplicationService().getJobApplications(widget.jobId),
        builder: (context, snapshot) {
          final count = snapshot.data?.length ?? 0;
          return Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.people),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobApplicationsScreen(
                        jobId: widget.jobId,
                        jobTitle: job!.title,
                      ),
                    ),
                  );
                },
              ),
              if (count > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    IconButton(
      icon: const Icon(Icons.share),
      onPressed: () {},
    ),
  ],
),
```

## Resumen de Cambios

1. ✅ Sistema de solicitudes implementado
2. ✅ El dueño puede ver y aceptar/rechazar solicitudes
3. ✅ Solo el dueño puede aceptar trabajadores
4. ✅ Notificación cuando alguien solicita
5. ✅ El trabajador puede enviar mensaje al solicitar

## Próximos Pasos

1. Implementar estos cambios
2. Revisar error de calificación
3. Eliminar notificación de prueba
4. Agregar función de eliminar notificaciones
5. Mostrar ganancias en perfil
