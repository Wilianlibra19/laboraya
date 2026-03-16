import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/user_service.dart';
import '../../core/services/report_service.dart';
import '../../utils/constants.dart';
import '../../widgets/common/custom_button.dart';

class ReportScreen extends StatefulWidget {
  final String reportedId;
  final String reportedType; // 'user' o 'job'
  final String reportedName;

  const ReportScreen({
    super.key,
    required this.reportedId,
    required this.reportedType,
    required this.reportedName,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedReason = 'Contenido inapropiado';
  bool _isLoading = false;

  final List<String> _reasons = [
    'Contenido inapropiado',
    'Fraude o estafa',
    'Spam',
    'Información falsa',
    'Acoso o intimidación',
    'Violencia',
    'Otro',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = context.read<UserService>().currentUser;
      if (currentUser == null) throw Exception('Usuario no autenticado');

      final reportService = ReportService();

      if (widget.reportedType == 'user') {
        await reportService.reportUser(
          reporterId: currentUser.id,
          reportedUserId: widget.reportedId,
          reason: _selectedReason,
          description: _descriptionController.text,
        );
      } else {
        await reportService.reportJob(
          reporterId: currentUser.id,
          jobId: widget.reportedId,
          reason: _selectedReason,
          description: _descriptionController.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reporte enviado. Lo revisaremos pronto.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reportar contenido',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Estás reportando: ${widget.reportedName}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Motivo del reporte',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  isExpanded: true,
                  items: _reasons.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(reason),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedReason = value!);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Descripción (opcional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 500,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Proporciona más detalles sobre el problema...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Enviar Reporte',
              onPressed: _submitReport,
              isLoading: _isLoading,
              icon: Icons.send,
            ),
            const SizedBox(height: 16),
            Text(
              'Tu reporte será revisado por nuestro equipo. Tomaremos las medidas apropiadas si encontramos una violación de nuestras políticas.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
