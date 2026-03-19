import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../config/credits_config.dart';
import '../../core/models/job_model.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/services/job_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/payment_service.dart';
import '../../core/services/user_service.dart';
import '../../data/mock/mock_data.dart';
import '../../utils/constants.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _paymentController = TextEditingController();
  final _addressController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _benefitsController = TextEditingController();
  final _requirementsController = TextEditingController();

  String _publicationType = 'Trabajo puntual';
  String _selectedCategory = '';
  String _paymentType = 'Por trabajo completo';
  String _selectedDuration = 'Corto plazo (1-7 días)';
  
  // Tipo de publicación (Normal, Destacado, Premium)
  String _jobTier = 'Normal';

  String _paymentFrequency = 'Pago único al finalizar';
  String _contractDuration = '1 mes';
  String _contractType = 'Temporal';
  String _workModality = 'Presencial';

  DateTime? _startDate;
  DateTime? _endDate;
  bool _indefiniteContract = false;

  bool _isLoading = false;
  bool _isLoadingLocation = false;

  List<String> _selectedImages = [];

  double? _currentLatitude;
  double? _currentLongitude;

  bool get _isContract => _publicationType == 'Contrato';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _paymentController.dispose();
    _addressController.dispose();
    _scheduleController.dispose();
    _benefitsController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((img) => img.path));
        if (_selectedImages.length > 5) {
          _selectedImages = _selectedImages.sublist(0, 5);
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final position = await LocationService.getCurrentLocation();

      if (position != null) {
        setState(() {
          _currentLatitude = position.latitude;
          _currentLongitude = position.longitude;
        });

        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            String address = '';

            if (place.street != null && place.street!.isNotEmpty) {
              address += place.street!;
            }
            if (place.subThoroughfare != null &&
                place.subThoroughfare!.isNotEmpty) {
              address += ' ${place.subThoroughfare}';
            }
            if (place.locality != null && place.locality!.isNotEmpty) {
              if (address.isNotEmpty) address += ', ';
              address += place.locality!;
            }

            if (address.isEmpty) {
              address =
                  '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
            }

            setState(() {
              _addressController.text = address;
            });
          }
        } catch (_) {
          setState(() {
            _addressController.text =
                '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Ubicación obtenida'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
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
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _createJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = context.read<UserService>().currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Todas las publicaciones cuestan 10 créditos
      const int creditCost = CreditsConfig.CREDITOS_POR_PUBLICACION;

      // Verificar y descontar créditos
      final paymentService = PaymentService();
      final currentCredits = await paymentService.getUserCredits(currentUser.id);

      if (currentCredits < creditCost) {
        throw Exception(
          'Créditos insuficientes. Tienes $currentCredits créditos, necesitas $creditCost.',
        );
      }

      // Descontar créditos
      final deductResult = await paymentService.deductCredits(
        userId: currentUser.id,
        credits: creditCost,
        reason: 'Publicación de trabajo',
      );

      if (deductResult['success'] != true) {
        throw Exception(deductResult['error'] ?? 'Error al descontar créditos');
      }

      final payment = double.tryParse(_paymentController.text.trim());
      if (payment == null || payment <= 0) {
        throw Exception('Ingresa un monto válido');
      }

      List<String> uploadedImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        uploadedImageUrls = await CloudinaryService.uploadMultipleImages(
          imagePaths: _selectedImages,
          folder: 'laboraya/jobs',
        );
      }

      final finalDescription = _isContract
          ? '''
${_descriptionController.text.trim()}

Tipo de contrato: $_contractType
Frecuencia de pago: $_paymentFrequency
Duración del contrato: $_contractDuration
Modalidad: $_workModality
Horario: ${_scheduleController.text.trim().isEmpty ? 'No especificado' : _scheduleController.text.trim()}
Beneficios: ${_benefitsController.text.trim().isEmpty ? 'No especificado' : _benefitsController.text.trim()}
Requisitos: ${_requirementsController.text.trim().isEmpty ? 'No especificado' : _requirementsController.text.trim()}
'''.trim()
          : _descriptionController.text.trim();

      final job = JobModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: finalDescription,
        category: _selectedCategory.trim(),
        payment: payment,
        paymentType: _isContract ? _paymentFrequency : _paymentType,
        workersNeeded: 1,
        duration: _isContract ? _contractDuration : _selectedDuration,
        latitude: _currentLatitude ?? -12.0464,
        longitude: _currentLongitude ?? -77.0428,
        address: _addressController.text.trim(),
        createdBy: currentUser.id,
        status: 'available',
        isUrgent: _jobTier == 'Premium',
        images: uploadedImageUrls,
        createdAt: DateTime.now(),
        documents: [],
        jobType: _isContract ? 'contract' : 'daily',
      );

      await context.read<JobService>().createJob(job);

      if (mounted) {
        // Mensaje de éxito
        final successMessage = _isContract 
          ? '✅ Contrato publicado\n💳 Se descontaron $creditCost créditos' 
          : '✅ Trabajo publicado\n💳 Se descontaron $creditCost créditos';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Mostrar diálogo informativo con créditos restantes
        final remainingCredits = await PaymentService().getUserCredits(currentUser.id);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '¡Publicado!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isContract 
                    ? 'Tu contrato ha sido publicado exitosamente.'
                    : 'Tu trabajo ha sido publicado exitosamente.',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Créditos descontados',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '-$creditCost créditos',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Créditos restantes: $remainingCredits',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar diálogo
                  Navigator.pop(context, true); // Volver a la pantalla anterior
                },
                child: const Text(
                  'Entendido',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildPremiumHeader(isDark),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    _buildModernToggle(isDark),
                    const SizedBox(height: 20),
                    _buildIntroBanner(isDark),
                    const SizedBox(height: 20),
                    _buildJobTierSelector(isDark),
                    const SizedBox(height: 20),
                    if (_isContract) ..._buildContractContent(isDark) else ..._buildQuickJobContent(isDark),
                    const SizedBox(height: 24),
                    _buildModernPublishButton(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.90),
            const Color(0xFF67C4FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    height: 42,
                    width: 42,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Publicar trabajo',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Crea una publicación atractiva y clara',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntroBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EEF6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _isContract ? Icons.description_outlined : Icons.flash_on_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isContract
                  ? 'Publica una oportunidad más formal con condiciones claras.'
                  : 'Publica un trabajo rápido y encuentra ayuda lo antes posible.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: isDark ? Colors.white70 : const Color(0xFF5F6B7A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobTierSelector(bool isDark) {
    final tiers = [
      {
        'name': 'Normal',
        'icon': Icons.work_outline_rounded,
        'color': Colors.blue,
        'features': ['Publicación estándar', 'Visible en búsquedas'],
      },
      {
        'name': 'Destacado',
        'icon': Icons.star_rounded,
        'color': Colors.orange,
        'features': ['Aparece arriba', 'Badge "Destacado"', 'Más visibilidad'],
      },
      {
        'name': 'Premium',
        'icon': Icons.workspace_premium_rounded,
        'color': Colors.purple,
        'features': ['Máxima prioridad', 'Badge "Premium"', 'Urgente', 'Destacado 7 días'],
      },
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EEF6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipo de publicación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF162033),
                      ),
                    ),
                    Text(
                      'Todas cuestan ${CreditsConfig.CREDITOS_POR_PUBLICACION} créditos',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tiers.map((tier) {
            final isSelected = _jobTier == tier['name'];
            final color = tier['color'] as Color;
            final features = tier['features'] as List<String>;

            return GestureDetector(
              onTap: () => setState(() => _jobTier = tier['name'] as String),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.08)
                      : (isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC)),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: isSelected ? color : Colors.grey[400],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        tier['icon'] as IconData,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tier['name'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? color
                                  : (isDark ? Colors.white : const Color(0xFF162033)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...features.map((feature) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: isSelected ? color : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      feature,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: color,
                        size: 28,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EEF6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF162033),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCardTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool requiredField = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : const Color(0xFF162033),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey[600], size: 21),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
        validator: requiredField
            ? (value) => value == null || value.trim().isEmpty
                ? 'Campo requerido'
                : null
            : null,
      ),
    );
  }

  Widget _buildModernToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2328) : const Color(0xFFEEF2F7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleItem(
              icon: Icons.flash_on_rounded,
              label: 'Trabajo puntual',
              active: _publicationType == 'Trabajo puntual',
              onTap: () => setState(() => _publicationType = 'Trabajo puntual'),
            ),
          ),
          Expanded(
            child: _buildToggleItem(
              icon: Icons.description_rounded,
              label: 'Contrato',
              active: _publicationType == 'Contrato',
              onTap: () => setState(() => _publicationType = 'Contrato'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                  )
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? Colors.white : Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildQuickJobContent(bool isDark) {
    return [
      _buildSectionCard(
        isDark: isDark,
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.primary,
        title: 'Información básica',
        children: [
          _buildCardTextField(
            controller: _titleController,
            label: 'Título del trabajo',
            hint: 'Ej: Ayuda para mudanza hoy',
            icon: Icons.work_outline_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildCategoryAutocomplete(isDark),
        ],
      ),
      const SizedBox(height: 16),
      _buildSectionCard(
        isDark: isDark,
        icon: Icons.description_outlined,
        iconColor: AppColors.primary,
        title: 'Descripción',
        children: [
          _buildCardTextField(
            controller: _descriptionController,
            label: 'Describe el trabajo',
            hint: 'Explica lo que necesitas, horarios o detalles importantes',
            icon: Icons.edit_note_rounded,
            isDark: isDark,
            maxLines: 4,
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildSectionCard(
        isDark: isDark,
        icon: Icons.payments_outlined,
        iconColor: Colors.green,
        title: 'Pago y duración',
        children: [
          _buildQuickPaymentSection(isDark),
        ],
      ),
      const SizedBox(height: 16),
      _buildSectionCard(
        isDark: isDark,
        icon: Icons.location_on_outlined,
        iconColor: AppColors.primary,
        title: 'Ubicación',
        children: [
          _buildCardTextField(
            controller: _addressController,
            label: 'Dirección',
            hint: 'Ingresa la dirección del trabajo',
            icon: Icons.location_on_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildLocationButton(isDark),
        ],
      ),
      const SizedBox(height: 16),
      _buildSectionCard(
        isDark: isDark,
        icon: Icons.photo_camera_outlined,
        iconColor: AppColors.primary,
        title: 'Fotos',
        children: [
          _buildPhotoSection(isDark),
        ],
      ),
    ];
  }

  List<Widget> _buildContractContent(bool isDark) {
    return [
      _buildSectionCard(
        isDark: isDark,
        icon: Icons.business_center_outlined,
        iconColor: const Color(0xFF1565C0),
        title: 'Información del puesto',
        children: [
          _buildCardTextField(
            controller: _titleController,
            label: 'Título del puesto',
            hint: 'Ej: Asistente administrativo',
            icon: Icons.badge_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildCategoryAutocomplete(isDark),
          const SizedBox(height: 14),
          _buildCardTextField(
            controller: _descriptionController,
            label: 'Descripción del puesto',
            hint: 'Responsabilidades, funciones y detalles del cargo',
            icon: Icons.description_outlined,
            isDark: isDark,
            maxLines: 5,
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildSectionCard(
        isDark: isDark,
        icon: Icons.account_balance_wallet_outlined,
        iconColor: Colors.green,
        title: 'Condiciones económicas',
        children: [
          _buildContractPaymentSection(isDark),
        ],
      ),
      const SizedBox(height: 16),
      _buildSectionCard(
        isDark: isDark,
        icon: Icons.calendar_month_outlined,
        iconColor: const Color(0xFF1565C0),
        title: 'Duración y modalidad',
        children: [
          _buildContractDurationSection(isDark),
        ],
      ),
      const SizedBox(height: 16),
      _buildSectionCard(
        isDark: isDark,
        icon: Icons.checklist_rounded,
        iconColor: const Color(0xFF1565C0),
        title: 'Requisitos',
        children: [
          _buildCardTextField(
            controller: _requirementsController,
            label: 'Requisitos',
            hint: 'Experiencia, estudios, habilidades y otros requisitos',
            icon: Icons.school_outlined,
            isDark: isDark,
            maxLines: 4,
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildSectionCard(
        isDark: isDark,
        icon: Icons.location_on_outlined,
        iconColor: const Color(0xFF1565C0),
        title: 'Ubicación',
        children: [
          _buildCardTextField(
            controller: _addressController,
            label: 'Dirección',
            hint: 'Dirección del centro de trabajo',
            icon: Icons.location_on_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildLocationButton(isDark),
        ],
      ),
      const SizedBox(height: 16),
      _buildSectionCard(
        isDark: isDark,
        icon: Icons.attach_file_rounded,
        iconColor: const Color(0xFF1565C0),
        title: 'Archivos adjuntos',
        children: [
          _buildPhotoSection(isDark),
        ],
      ),
    ];
  }

  Widget _buildCategoryAutocomplete(bool isDark) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _selectedCategory),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.trim().isEmpty) {
          return const Iterable<String>.empty();
        }
        return MockData.getCategories().where((option) {
          return option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
        });
      },
      onSelected: (selection) {
        setState(() {
          _selectedCategory = selection;
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : const Color(0xFF162033),
            ),
            decoration: InputDecoration(
              labelText: 'Categoría',
              hintText: 'Buscar categoría...',
              prefixIcon: Icon(
                _selectedCategory.isEmpty
                    ? Icons.search_rounded
                    : (CategoryIcons.icons[_selectedCategory] ?? Icons.work_outline_rounded),
                color: _selectedCategory.isEmpty ? Colors.grey[600] : AppColors.primary,
                size: 21,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
            onEditingComplete: onEditingComplete,
            onChanged: (value) {
              if (MockData.getCategories().contains(value)) {
                setState(() {
                  _selectedCategory = value;
                });
              } else if (value.isEmpty) {
                setState(() {
                  _selectedCategory = '';
                });
              }
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Selecciona una categoría';
              }
              if (!MockData.getCategories().contains(value.trim())) {
                return 'Selecciona una categoría válida';
              }
              return null;
            },
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 260),
              width: MediaQuery.of(context).size.width - 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDark ? const Color(0xFF1F2328) : Colors.white,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      CategoryIcons.icons[option] ?? Icons.work_outline_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      option,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF162033),
                      ),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickPaymentSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.10),
                Colors.green.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.green.withOpacity(0.20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Monto a pagar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF162033),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF24282D) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextFormField(
                  controller: _paymentController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.green,
                  ),
                  decoration: InputDecoration(
                    hintText: 'S/ 0.00',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                    prefixIcon: const Icon(
                      Icons.attach_money_rounded,
                      color: Colors.green,
                      size: 28,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF24282D) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el monto';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Monto inválido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _buildLabel('Tipo de pago', isDark),
        const SizedBox(height: 10),
        _buildPaymentTypeOptions(isDark),
        const SizedBox(height: 18),
        Divider(color: Colors.grey[300], thickness: 1),
        const SizedBox(height: 18),
        _buildLabel('Duración estimada', isDark),
        const SizedBox(height: 10),
        _buildDurationOptions(isDark),
      ],
    );
  }

  Widget _buildContractPaymentSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Salario o monto', isDark),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.20)),
          ),
          child: TextFormField(
            controller: _paymentController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Colors.green,
            ),
            decoration: InputDecoration(
              hintText: 'S/ 0.00',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 20,
              ),
              prefixIcon: const Icon(
                Icons.attach_money_rounded,
                color: Colors.green,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa el salario';
              }
              if (double.tryParse(value.trim()) == null) {
                return 'Monto inválido';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 18),
        _buildLabel('Frecuencia de pago', isDark),
        const SizedBox(height: 10),
        _buildPaymentFrequencyOptions(isDark),
        const SizedBox(height: 18),
        _buildCardTextField(
          controller: _benefitsController,
          label: 'Beneficios adicionales',
          hint: 'Ej: bonos, seguro, movilidad, alimentación...',
          icon: Icons.card_giftcard_outlined,
          isDark: isDark,
          maxLines: 3,
          requiredField: false,
        ),
      ],
    );
  }

  Widget _buildContractDurationSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Tipo de vínculo', isDark),
        const SizedBox(height: 10),
        _buildContractTypeOptions(isDark),
        const SizedBox(height: 18),
        _buildLabel('Duración del contrato', isDark),
        const SizedBox(height: 10),
        _buildContractDurationOptions(isDark),
        const SizedBox(height: 18),
        Divider(color: Colors.grey[300], thickness: 1),
        const SizedBox(height: 18),
        _buildLabel('Modalidad de trabajo', isDark),
        const SizedBox(height: 10),
        _buildWorkModalityOptions(isDark),
        const SizedBox(height: 18),
        _buildCardTextField(
          controller: _scheduleController,
          label: 'Horario esperado',
          hint: 'Ej: Lunes a Viernes, 8:00 AM - 5:00 PM',
          icon: Icons.schedule_rounded,
          isDark: isDark,
          maxLines: 2,
          requiredField: false,
        ),
      ],
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white70 : const Color(0xFF4D5A6B),
      ),
    );
  }

  Widget _buildPaymentTypeOptions(bool isDark) {
    final paymentTypes = [
      {
        'value': 'Por trabajo completo',
        'icon': Icons.work_outline_rounded,
        'desc': 'Pago único al finalizar',
      },
      {
        'value': 'Por día',
        'icon': Icons.calendar_today_rounded,
        'desc': 'Pago diario',
      },
      {
        'value': 'Por hora',
        'icon': Icons.access_time_rounded,
        'desc': 'Pago por hora trabajada',
      },
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: paymentTypes.map((type) {
        final isSelected = _paymentType == type['value'];
        return GestureDetector(
          onTap: () => setState(() => _paymentType = type['value'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.12)
                  : (isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 1.6,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type['icon'] as IconData,
                  color: isSelected ? AppColors.primary : Colors.grey[600],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      type['value'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? Colors.white : const Color(0xFF162033)),
                      ),
                    ),
                    Text(
                      type['desc'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDurationOptions(bool isDark) {
    final durations = [
      {
        'value': 'Corto plazo (1-7 días)',
        'label': 'Corto plazo',
        'subtitle': '1-7 días',
        'icon': Icons.flash_on_rounded,
      },
      {
        'value': 'Mediano plazo (1-4 semanas)',
        'label': 'Mediano plazo',
        'subtitle': '1-4 semanas',
        'icon': Icons.calendar_today_rounded,
      },
      {
        'value': 'Largo plazo (1+ mes)',
        'label': 'Largo plazo',
        'subtitle': '1+ mes',
        'icon': Icons.event_available_rounded,
      },
    ];

    return Column(
      children: durations.map((duration) {
        final isSelected = _selectedDuration == duration['value'];
        return GestureDetector(
          onTap: () => setState(() => _selectedDuration = duration['value'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.10)
                  : (isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 1.6,
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    duration['icon'] as IconData,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        duration['label'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white : const Color(0xFF162033)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        duration['subtitle'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentFrequencyOptions(bool isDark) {
    final frequencies = [
      {'value': 'Semanal', 'icon': Icons.calendar_view_week_rounded},
      {'value': 'Quincenal', 'icon': Icons.calendar_view_month_rounded},
      {'value': 'Mensual', 'icon': Icons.calendar_month_rounded},
      {'value': 'Pago único al finalizar', 'icon': Icons.check_circle_rounded},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: frequencies.map((freq) {
        final isSelected = _paymentFrequency == freq['value'];
        return GestureDetector(
          onTap: () => setState(() => _paymentFrequency = freq['value'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.green.withOpacity(0.12)
                  : (isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? Colors.green : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  freq['icon'] as IconData,
                  color: isSelected ? Colors.green : Colors.grey[600],
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  freq['value'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.green
                        : (isDark ? Colors.white : const Color(0xFF162033)),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContractTypeOptions(bool isDark) {
    final types = [
      {
        'value': 'Temporal',
        'icon': Icons.access_time_rounded,
        'desc': 'Plazo definido',
      },
      {
        'value': 'Contrato fijo',
        'icon': Icons.event_available_rounded,
        'desc': 'Duración específica',
      },
      {
        'value': 'Proyecto',
        'icon': Icons.work_outline_rounded,
        'desc': 'Por campaña',
      },
      {
        'value': 'Permanente',
        'icon': Icons.verified_rounded,
        'desc': 'Indefinido',
      },
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = _contractType == type['value'];
        return GestureDetector(
          onTap: () => setState(() => _contractType = type['value'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1565C0).withOpacity(0.12)
                  : (isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFF1565C0) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type['icon'] as IconData,
                      color: isSelected ? const Color(0xFF1565C0) : Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type['value'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? const Color(0xFF1565C0)
                            : (isDark ? Colors.white : const Color(0xFF162033)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  type['desc'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContractDurationOptions(bool isDark) {
    final durations = [
      {'value': '1 mes', 'label': '1 mes'},
      {'value': '3 meses', 'label': '3 meses'},
      {'value': '6 meses', 'label': '6 meses'},
      {'value': 'Indefinido', 'label': 'Indefinido'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: durations.map((duration) {
        final isSelected = _contractDuration == duration['value'];
        return GestureDetector(
          onTap: () => setState(() => _contractDuration = duration['value'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1565C0).withOpacity(0.12)
                  : (isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFF1565C0) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              duration['label'] as String,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? const Color(0xFF1565C0)
                    : (isDark ? Colors.white : const Color(0xFF162033)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkModalityOptions(bool isDark) {
    final modalities = [
      {
        'value': 'Presencial',
        'icon': Icons.business_rounded,
        'desc': 'En oficina o local',
      },
      {
        'value': 'Remoto',
        'icon': Icons.home_rounded,
        'desc': 'Desde casa',
      },
      {
        'value': 'Híbrido',
        'icon': Icons.sync_alt_rounded,
        'desc': 'Combinado',
      },
    ];

    return Column(
      children: modalities.map((modality) {
        final isSelected = _workModality == modality['value'];
        return GestureDetector(
          onTap: () => setState(() => _workModality = modality['value'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1565C0).withOpacity(0.10)
                  : (isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF1565C0) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1565C0) : Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    modality['icon'] as IconData,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modality['value'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? const Color(0xFF1565C0)
                              : (isDark ? Colors.white : const Color(0xFF162033)),
                        ),
                      ),
                      Text(
                        modality['desc'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF1565C0),
                    size: 22,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationButton(bool isDark) {
    final success = _currentLatitude != null;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
        icon: _isLoadingLocation
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(success ? Icons.check_circle_rounded : Icons.my_location_rounded),
        label: Text(success ? 'Ubicación obtenida' : 'Usar mi ubicación'),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: success ? Colors.green : AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(bool isDark) {
    return Column(
      children: [
        if (_selectedImages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFE8EEF6),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 40,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Sin fotos seleccionadas',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 94,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 94,
                  margin: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_selectedImages[index]),
                          width: 94,
                          height: 94,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _selectedImages.length >= 5 ? null : _pickImages,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
            label: Text(
              _selectedImages.isEmpty
                  ? 'Agregar fotos'
                  : 'Agregar más (${_selectedImages.length}/5)',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(
                color: AppColors.primary.withOpacity(0.40),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernPublishButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _createJob,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isContract
                            ? Icons.description_rounded
                            : Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isContract ? 'PUBLICAR CONTRATO' : 'PUBLICAR TRABAJO',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}