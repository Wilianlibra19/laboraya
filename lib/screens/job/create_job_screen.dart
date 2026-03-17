import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import '../../core/models/job_model.dart';
import '../../core/services/job_service.dart';
import '../../core/services/user_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/cloudinary_service.dart';
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

  String _selectedCategory = '';
  String _paymentType = 'Por trabajo completo';
  String _selectedDuration = 'Corto plazo (1-7 días)';
  
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  List<String> _selectedImages = [];
  double? _currentLatitude;
  double? _currentLongitude;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _paymentController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
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
            if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
              address += ' ${place.subThoroughfare}';
            }
            if (place.locality != null && place.locality!.isNotEmpty) {
              if (address.isNotEmpty) address += ', ';
              address += place.locality!;
            }
            if (address.isEmpty) {
              address = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
            }
            
            setState(() {
              _addressController.text = address;
            });
          }
        } catch (e) {
          setState(() {
            _addressController.text = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
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
      setState(() => _isLoadingLocation = false);
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

      List<String> uploadedImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        uploadedImageUrls = await CloudinaryService.uploadMultipleImages(
          imagePaths: _selectedImages,
          folder: 'laboraya/jobs',
        );
      }

      final job = JobModel(
        id: const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        payment: double.parse(_paymentController.text),
        paymentType: _paymentType,
        workersNeeded: 1,
        duration: _selectedDuration,
        latitude: _currentLatitude ?? -12.0464,
        longitude: _currentLongitude ?? -77.0428,
        address: _addressController.text,
        createdBy: currentUser.id,
        status: 'available',
        isUrgent: false,
        images: uploadedImageUrls,
        createdAt: DateTime.now(),
        documents: [],
        jobType: 'daily',
      );

      await context.read<JobService>().createJob(job);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Trabajo publicado'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Header azul con gradiente
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.7),
                ],
              ),
            ),
          ),
          
          // Contenido
          SafeArea(
            child: Column(
              children: [
                // AppBar personalizado
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Publicar Trabajo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Contenido con scroll
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      children: [
                        // Tarjeta: Información Básica
                        _buildSectionCard(
                          isDark: isDark,
                          icon: Icons.info_outline,
                          iconColor: AppColors.primary,
                          title: 'Información Básica',
                          children: [
                            _buildCardTextField(
                              controller: _titleController,
                              label: 'Título del trabajo',
                              icon: Icons.work,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 16),
                            // Categoría con Autocomplete
                            Autocomplete<String>(
                              initialValue: TextEditingValue(text: _selectedCategory),
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.trim().isEmpty) {
                                  return const Iterable<String>.empty();
                                }
                                return MockData.getCategories().where((String option) {
                                  return option.toLowerCase().contains(
                                    textEditingValue.text.toLowerCase(),
                                  );
                                });
                              },
                              onSelected: (String selection) {
                                setState(() {
                                  _selectedCategory = selection;
                                });
                              },
                              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.grey[850] : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    style: const TextStyle(fontSize: 15),
                                    decoration: InputDecoration(
                                      labelText: 'Categoría',
                                      hintText: 'Buscar categoría...',
                                      prefixIcon: Icon(
                                        _selectedCategory.isEmpty 
                                            ? Icons.search
                                            : (CategoryIcons.icons[_selectedCategory] ?? Icons.work),
                                        color: _selectedCategory.isEmpty ? Colors.grey[600] : AppColors.primary,
                                        size: 22,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                    onEditingComplete: onEditingComplete,
                                    onChanged: (value) {
                                      // Actualizar el icono cuando cambia el texto
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
                                    elevation: 8,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      constraints: const BoxConstraints(maxHeight: 250),
                                      width: MediaQuery.of(context).size.width - 72,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: isDark ? Colors.grey[850] : Colors.white,
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
                                              CategoryIcons.icons[option] ?? Icons.work,
                                              size: 20,
                                              color: AppColors.primary,
                                            ),
                                            title: Text(
                                              option,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            onTap: () {
                                              onSelected(option);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Tarjeta: Descripción
                        _buildSectionCard(
                          isDark: isDark,
                          icon: Icons.description,
                          iconColor: AppColors.primary,
                          title: 'Descripción',
                          children: [
                            _buildCardTextField(
                              controller: _descriptionController,
                              label: 'Agrega una descripción del trabajo...',
                              icon: Icons.edit,
                              isDark: isDark,
                              maxLines: 4,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Sección: Pago (fuera de tarjeta)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'Pago',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[900] : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Monto',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.payments_outlined, color: AppColors.primary, size: 24),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _paymentController,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              hintText: 'S/ 0.00',
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[900] : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tipo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.payment_outlined, color: AppColors.primary, size: 24),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: _paymentType,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                            dropdownColor: isDark ? Colors.grey[850] : Colors.white,
                                            items: const [
                                              DropdownMenuItem(value: 'Por trabajo completo', child: Text('Por trabajo completo')),
                                              DropdownMenuItem(value: 'Por día', child: Text('Por día')),
                                              DropdownMenuItem(value: 'Por hora', child: Text('Por hora')),
                                            ],
                                            onChanged: (value) => setState(() => _paymentType = value!),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Sección: Duración (fuera de tarjeta)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'Duración',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        _buildDurationOptions(isDark),
                        const SizedBox(height: 24),

                        // Tarjeta: Ubicación
                        _buildSectionCard(
                          isDark: isDark,
                          icon: Icons.location_on,
                          iconColor: AppColors.primary,
                          title: 'Ubicación',
                          children: [
                            _buildCardTextField(
                              controller: _addressController,
                              label: 'Dirección',
                              icon: Icons.location_on_outlined,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildLocationButton(isDark),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Tarjeta: Fotos
                        _buildSectionCard(
                          isDark: isDark,
                          icon: Icons.photo_camera,
                          iconColor: AppColors.primary,
                          title: 'Fotos',
                          children: [
                            _buildPhotoSection(isDark),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Botón publicar
                        _buildPublishButton(isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 15),
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey[600], size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
      ),
    );
  }

  Widget _buildCardDropdown({
    required String value,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey[600], size: 22),
          suffixIcon: const Icon(Icons.arrow_forward_ios, size: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 15)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDurationOptions(bool isDark) {
    final durations = [
      {'value': 'Corto plazo (1-7 días)', 'label': 'Corto plazo', 'subtitle': '1-7 días', 'icon': Icons.flash_on},
      {'value': 'Mediano plazo (1-4 semanas)', 'label': 'Mediano plazo', 'subtitle': '1-4 semanas', 'icon': Icons.calendar_today},
      {'value': 'Largo plazo (1+ mes)', 'label': 'Largo plazo', 'subtitle': '1+ mes', 'icon': Icons.event_available},
    ];

    return Column(
      children: durations.map((duration) {
        final isSelected = _selectedDuration == duration['value'];
        return GestureDetector(
          onTap: () => setState(() => _selectedDuration = duration['value'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.primary 
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    duration['icon'] as IconData,
                    color: isSelected ? Colors.white : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        duration['label'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        duration['subtitle'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 26),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
        icon: _isLoadingLocation
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(_currentLatitude != null ? Icons.check_circle : Icons.my_location),
        label: Text(_currentLatitude != null ? 'Ubicación obtenida' : 'Usar mi ubicación'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _currentLatitude != null ? Colors.green : AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(bool isDark) {
    return Column(
      children: [
        if (_selectedImages.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('Sin fotos', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          )
        else
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedImages[index]),
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
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
            icon: const Icon(Icons.add_photo_alternate, size: 20),
            label: Text(
              _selectedImages.isEmpty ? 'Agregar fotos' : 'Agregar más (${_selectedImages.length}/5)',
              style: const TextStyle(fontSize: 14),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPublishButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createJob,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Publicar Trabajo',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
