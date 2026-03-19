import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/services/user_service.dart';
import '../../core/services/verification_service.dart';
import '../../core/services/dni_verification_service.dart';
import '../../core/services/cloudinary_service.dart';
import '../../utils/constants.dart';
import '../../widgets/common/custom_button.dart';

class VerifyIdentityScreen extends StatefulWidget {
  const VerifyIdentityScreen({super.key});

  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  bool _isLoading = false;
  
  String? _frontImagePath;
  String? _backImagePath;
  String? _selfiePath;

  @override
  void dispose() {
    _dniController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        switch (type) {
          case 'front':
            _frontImagePath = image.path;
            break;
          case 'back':
            _backImagePath = image.path;
            break;
          case 'selfie':
            _selfiePath = image.path;
            break;
        }
      });
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_frontImagePath == null || _backImagePath == null || _selfiePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes tomar todas las fotos requeridas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = context.read<UserService>().currentUser;
      if (currentUser == null) throw Exception('Usuario no autenticado');

      final dni = _dniController.text.trim();

      // 1. VERIFICAR DNI CON API DE RENIEC
      print('🔍 Verificando DNI con RENIEC...');
      final dniService = DniVerificationService();
      final dniData = await dniService.verificarDNI(dni);

      if (dniData == null) {
        throw Exception('DNI no encontrado en RENIEC. Verifica que sea correcto.');
      }

      print('✅ DNI válido: ${dniData['nombreCompleto']}');

      // 2. VERIFICAR QUE EL NOMBRE COINCIDA
      final nombreCoincide = dniService.verificarNombreCoincide(
        currentUser.name,
        dniData['nombreCompleto'],
      );

      if (!nombreCoincide) {
        throw Exception(
          'El nombre de tu perfil (${currentUser.name}) no coincide con el DNI (${dniData['nombreCompleto']}). '
          'Actualiza tu nombre en el perfil primero.',
        );
      }

      print('✅ Nombre coincide');

      // 3. SUBIR IMÁGENES A CLOUDINARY
      print('📤 Subiendo imágenes...');
      final frontUrl = await CloudinaryService.uploadImage(
        imagePath: _frontImagePath!,
        folder: 'laboraya/verifications',
      );
      final backUrl = await CloudinaryService.uploadImage(
        imagePath: _backImagePath!,
        folder: 'laboraya/verifications',
      );
      final selfieUrl = await CloudinaryService.uploadImage(
        imagePath: _selfiePath!,
        folder: 'laboraya/verifications',
      );

      print('✅ Imágenes subidas');

      if (frontUrl == null || backUrl == null || selfieUrl == null) {
        throw Exception('Error al subir imágenes');
      }

      // 4. GUARDAR VERIFICACIÓN EN FIREBASE
      final verificationService = VerificationService();
      await verificationService.submitIdentityVerification(
        userId: currentUser.id,
        dniNumber: dni,
        frontImageUrl: frontUrl,
        backImageUrl: backUrl,
        selfieUrl: selfieUrl,
      );

      // 5. MARCAR USUARIO COMO VERIFICADO AUTOMÁTICAMENTE
      await verificationService.markUserAsVerified(currentUser.id);
      
      // Actualizar usuario en memoria
      await context.read<UserService>().refreshCurrentUser();

      print('✅ Usuario verificado automáticamente');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ¡Verificado! Tu DNI es válido.\n'
              'Nombre: ${dniData['nombreCompleto']}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
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
            duration: const Duration(seconds: 5),
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
        title: const Text('Verificar Identidad'),
        backgroundColor: AppColors.primary,
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
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verificación Automática',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tu DNI se verificará automáticamente con RENIEC en segundos',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _dniController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Número de DNI',
                hintText: '12345678',
                prefixIcon: const Icon(Icons.badge),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Ingresa tu DNI';
                if (value.length != 8) return 'DNI debe tener 8 dígitos';
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Fotos Requeridas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPhotoCard(
              title: 'Foto frontal del DNI',
              description: 'Toma una foto clara del frente de tu DNI',
              icon: Icons.credit_card,
              imagePath: _frontImagePath,
              onTap: () => _pickImage('front'),
            ),
            const SizedBox(height: 12),
            _buildPhotoCard(
              title: 'Foto posterior del DNI',
              description: 'Toma una foto clara del reverso de tu DNI',
              icon: Icons.credit_card,
              imagePath: _backImagePath,
              onTap: () => _pickImage('back'),
            ),
            const SizedBox(height: 12),
            _buildPhotoCard(
              title: 'Selfie con DNI',
              description: 'Toma una selfie sosteniendo tu DNI junto a tu rostro',
              icon: Icons.face,
              imagePath: _selfiePath,
              onTap: () => _pickImage('selfie'),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Enviar Verificación',
              onPressed: _submitVerification,
              isLoading: _isLoading,
              icon: Icons.send,
            ),
            const SizedBox(height: 16),
            Text(
              'Tu DNI se verificará automáticamente con la base de datos de RENIEC. '
              'Asegúrate de que tu nombre en el perfil coincida con tu DNI.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard({
    required String title,
    required String description,
    required IconData icon,
    required String? imagePath,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: imagePath != null ? Colors.green : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: imagePath != null 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(icon, size: 30, color: Colors.grey[600]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (imagePath != null)
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.camera_alt,
              color: imagePath != null ? Colors.green : AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
