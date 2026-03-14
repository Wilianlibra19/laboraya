import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import '../../core/models/job_model.dart';
import '../../core/services/job_service.dart';
import '../../core/services/user_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/cloudinary_service.dart';
import '../../data/mock/mock_data.dart';
import '../../utils/constants.dart';
import '../../widgets/common/custom_button.dart';

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
  final _durationController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedCategory = 'Limpieza';
  String _paymentType = 'Por trabajo completo';
  String _selectedDuration = '1-2 horas';
  
  // TODO: Implementar "Marcar como urgente" como función de pago premium
  bool _isUrgent = false; // Siempre false por ahora
  
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  List<String> _selectedImages = [];
  double? _currentLatitude;
  double? _currentLongitude;

  @override
  void initState() {
    super.initState();
    _durationController.text = _selectedDuration;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _paymentController.dispose();
    _durationController.dispose();
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

        // Obtener la dirección desde las coordenadas (geocodificación inversa)
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            
            // Construir la dirección
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
            
            if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
              if (address.isNotEmpty) address += ', ';
              address += place.subAdministrativeArea!;
            }
            
            if (place.country != null && place.country!.isNotEmpty) {
              if (address.isNotEmpty) address += ', ';
              address += place.country!;
            }
            
            // Si no se pudo construir una dirección, usar coordenadas
            if (address.isEmpty) {
              address = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
            }
            
            // Actualizar el campo de dirección
            setState(() {
              _addressController.text = address;
            });
            
            print('📍 Dirección obtenida: $address');
          }
        } catch (e) {
          print('⚠️ Error obteniendo dirección: $e');
          // Si falla la geocodificación, usar coordenadas
          setState(() {
            _addressController.text = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Ubicación y dirección obtenidas'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo obtener la ubicación. Verifica los permisos.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener ubicación: $e'),
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

      // Subir imágenes a Cloudinary en paralelo (más rápido)
      List<String> uploadedImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        print('📤 Subiendo ${_selectedImages.length} imágenes...');
        
        uploadedImageUrls = await CloudinaryService.uploadMultipleImages(
          imagePaths: _selectedImages,
          folder: 'laboraya/jobs',
        );
        
        print('✅ Imágenes subidas');
      }

      final job = JobModel(
        id: const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        payment: double.parse(_paymentController.text),
        paymentType: _paymentType,
        workersNeeded: 1, // Siempre 1 persona
        duration: _durationController.text,
        latitude: _currentLatitude ?? -12.0464,
        longitude: _currentLongitude ?? -77.0428,
        address: _addressController.text,
        createdBy: currentUser.id,
        status: 'available',
        isUrgent: _isUrgent,
        images: uploadedImageUrls,
        createdAt: DateTime.now(),
        documents: [],
      );

      print('💾 Guardando trabajo...');
      await context.read<JobService>().createJob(job);
      print('✅ Trabajo guardado');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Trabajo publicado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
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
    final cardColor = isDark ? Colors.grey[850] : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Publicar Trabajo'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Información Básica
            _buildCard(
              cardColor: cardColor!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    icon: Icons.info_outline,
                    title: 'Información Básica',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _titleController,
                    label: 'Título del trabajo',
                    icon: Icons.work,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20), // Aumentado de 16 a 20
                  // Categoría con autocompletado
                  Autocomplete<String>(
                    initialValue: TextEditingValue(text: _selectedCategory),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      // NO mostrar opciones si el campo está vacío
                      if (textEditingValue.text.trim().isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      // Filtrar categorías que coincidan
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
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Categoría *',
                          hintText: 'Escribe para buscar (ej: Plomero, Pintor, Ayudante)...',
                          helperText: 'Empieza a escribir para ver opciones',
                          helperStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          prefixIcon: const Icon(Icons.category),
                          suffixIcon: controller.text.isEmpty 
                              ? const Icon(Icons.search)
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    controller.clear();
                                    setState(() {
                                      _selectedCategory = '';
                                    });
                                  },
                                ),
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                        onEditingComplete: onEditingComplete,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Selecciona una categoría';
                          }
                          // Validar que la categoría esté en la lista
                          if (!MockData.getCategories().contains(value.trim())) {
                            return 'Selecciona una categoría válida de la lista';
                          }
                          return null;
                        },
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
                            width: MediaQuery.of(context).size.width - 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isDark ? Colors.grey[850] : Colors.white,
                            ),
                            child: options.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No se encontraron categorías',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
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
            ),
            const SizedBox(height: 20), // Aumentado de 16 a 20

            // Descripción
            _buildCard(
              cardColor: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    icon: Icons.description_outlined,
                    title: 'Descripción',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Descripción',
                    hint: 'Describe el trabajo en detalle...',
                    icon: Icons.edit,
                    isDark: isDark,
                    maxLines: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Aumentado de 16 a 20

            // Pago y Duración
            _buildCard(
              cardColor: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    icon: Icons.payments_outlined,
                    title: 'Pago y Duración',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _paymentController,
                    label: 'Pago (S/)',
                    icon: Icons.attach_money,
                    isDark: isDark,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20), // Aumentado de 16 a 20
                  _buildDropdown(
                    value: _paymentType,
                    label: 'Tipo de pago',
                    icon: Icons.payment,
                    isDark: isDark,
                    items: ['Por trabajo completo', 'Por día', 'Por hora'],
                    onChanged: (value) =>
                        setState(() => _paymentType = value ?? ''),
                  ),
                  const SizedBox(height: 20), // Aumentado de 16 a 20
                  _buildDropdown(
                    value: _selectedDuration,
                    label: 'Duración estimada',
                    icon: Icons.access_time,
                    isDark: isDark,
                    items: [
                      '1-2 horas',
                      '3-4 horas',
                      'Medio día (4-6 horas)',
                      'Día completo (8 horas)',
                      '2-3 días',
                      '1 semana',
                      '2 semanas',
                      '1 mes',
                      'Más de 1 mes',
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDuration = value ?? '1-2 horas';
                        _durationController.text = _selectedDuration;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Aumentado de 16 a 20

            // Ubicación
            _buildCard(
              cardColor: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    icon: Icons.location_on_outlined,
                    title: 'Ubicación',
                    color: Colors.red,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Dirección',
                    icon: Icons.location_on,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20), // Aumentado de 16 a 20
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                      icon: _isLoadingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        _currentLatitude != null
                            ? 'Ubicación obtenida ✓'
                            : 'Usar mi ubicación actual',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentLatitude != null
                            ? Colors.green
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (_currentLatitude != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Coordenadas: ${_currentLatitude!.toStringAsFixed(4)}, ${_currentLongitude!.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20), // Aumentado de 16 a 20

            // Fotos del Trabajo
            _buildCard(
              cardColor: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    icon: Icons.photo_camera_outlined,
                    title: 'Fotos del Trabajo',
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Máximo 5 fotos',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedImages.length >= 5
                                    ? Colors.red.withOpacity(0.1)
                                    : AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_selectedImages.length}/5',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedImages.length >= 5
                                      ? Colors.red
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_selectedImages.isEmpty)
                          Column(
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 56,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No hay fotos seleccionadas',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        else
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          File(_selectedImages[index]),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
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
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _selectedImages.length >= 5 ? null : _pickImages,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: Text(
                              _selectedImages.isEmpty
                                  ? 'Agregar Fotos'
                                  : 'Agregar Más Fotos',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Aumentado de 16 a 20

            // Botón publicar
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CustomButton(
                text: 'Publicar Trabajo',
                onPressed: _createJob,
                isLoading: _isLoading,
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required Color cardColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24), // Aumentado de 20 a 24
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 17, height: 1.4), // Aumentado y agregado height
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        hintText: hint,
        hintStyle: TextStyle(fontSize: 15, color: Colors.grey[400]),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(16), // Aumentado de 14 a 16
          child: Icon(icon, size: 26), // Aumentado de 24 a 26
        ),
        alignLabelWithHint: maxLines > 1,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 24, // Aumentado de 20 a 24
          vertical: maxLines > 1 ? 24 : 20, // Aumentado de 20/18 a 24/20
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), // Aumentado de 12 a 14
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2.5,
          ),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: maxLines > 1 ? 3 : 1,
      validator: (value) =>
          value?.isEmpty ?? true ? 'Campo requerido' : null,
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String label,
    required IconData icon,
    required bool isDark,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      style: TextStyle(
        fontSize: 17, // Aumentado de 16 a 17
        height: 1.4,
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(16), // Aumentado de 14 a 16
          child: Icon(icon, size: 26), // Aumentado de 24 a 26
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24, // Aumentado de 20 a 24
          vertical: 20, // Aumentado de 18 a 20
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), // Aumentado de 12 a 14
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2.5,
          ),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
      ),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString()),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
