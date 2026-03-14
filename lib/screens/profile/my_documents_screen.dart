import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';
import '../../core/services/user_service.dart';
import '../../core/services/storage_service.dart';
import '../../widgets/common/custom_button.dart';

class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({super.key});

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  List<Map<String, String>> _documents = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    
    try {
      final userService = context.read<UserService>();
      final user = userService.currentUser;
      
      if (user != null && user.documents.isNotEmpty) {
        // Procesar documentos de forma más eficiente
        final docs = <Map<String, String>>[];
        
        for (final url in user.documents) {
          // Extraer el tipo del nombre del archivo
          final fileName = url.split('/').last;
          String type = 'Documento';
          
          // Usar toLowerCase para comparación más rápida
          final lowerFileName = fileName.toLowerCase();
          
          if (lowerFileName.contains('cv')) {
            type = 'CV';
          } else if (lowerFileName.contains('dni')) {
            type = 'DNI';
          } else if (lowerFileName.contains('certificado')) {
            type = 'Certificado';
          } else if (lowerFileName.contains('licencia')) {
            type = 'Licencia';
          } else if (lowerFileName.contains('foto')) {
            type = 'Foto de trabajo';
          }
          
          docs.add({
            'type': type,
            'name': fileName,
            'url': url,
          });
        }
        
        setState(() {
          _documents = docs;
        });
      }
    } catch (e) {
      print('⚠️ Error cargando documentos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar documentos: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDocument(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _documents.add({
          'type': type,
          'name': result.files.single.name,
          'path': result.files.single.path ?? '',
          'url': '', // Se llenará al guardar
        });
        _hasChanges = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$type agregado. Presiona "Guardar" para subir.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _saveDocuments() async {
    if (!_hasChanges) return;
    
    setState(() => _isSaving = true);

    try {
      final userService = context.read<UserService>();
      final user = userService.currentUser;
      
      if (user == null) {
        throw Exception('Usuario no encontrado');
      }

      List<String> documentUrls = [];

      // Subir documentos nuevos a Firebase Storage
      for (var doc in _documents) {
        if (doc['url']!.isNotEmpty) {
          // Ya está subido
          documentUrls.add(doc['url']!);
        } else if (doc['path']!.isNotEmpty) {
          // Subir nuevo documento a Firebase Storage
          print('📤 Subiendo ${doc['type']} a Firebase Storage...');
          
          final url = await StorageService.uploadDocument(
            filePath: doc['path']!,
            userId: user.id,
            documentType: doc['type']!,
          );
          
          if (url != null && url.isNotEmpty) {
            documentUrls.add(url);
            print('✅ ${doc['type']} subido: $url');
          } else {
            throw Exception('Error al subir ${doc['type']}');
          }
        }
      }

      // Actualizar en Firebase
      await userService.updateUserDocuments(user.id, documentUrls);

      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Documentos guardados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recargar documentos
        _loadDocuments();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteDocument(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: const Text('¿Estás seguro de eliminar este documento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _documents.removeAt(index);
                _hasChanges = true;
              });
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Documento eliminado. Presiona "Guardar" para confirmar.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Documentos'),
        actions: [
          if (_hasChanges)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Sin guardar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  color: Theme.of(context).cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tipos de documentos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DocumentTypeCard(
                        icon: Icons.description,
                        title: 'Currículum Vitae',
                        onTap: () => _pickDocument('CV'),
                      ),
                      _DocumentTypeCard(
                        icon: Icons.badge,
                        title: 'DNI',
                        onTap: () => _pickDocument('DNI'),
                      ),
                      _DocumentTypeCard(
                        icon: Icons.card_membership,
                        title: 'Certificados',
                        onTap: () => _pickDocument('Certificado'),
                      ),
                      _DocumentTypeCard(
                        icon: Icons.credit_card,
                        title: 'Licencias',
                        onTap: () => _pickDocument('Licencia'),
                      ),
                      _DocumentTypeCard(
                        icon: Icons.photo_library,
                        title: 'Fotos de trabajos',
                        onTap: () => _pickDocument('Foto de trabajo'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_documents.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingMedium,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Documentos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_documents.length} archivo(s)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingMedium,
                      ),
                      itemCount: _documents.length,
                      itemBuilder: (context, index) {
                        final doc = _documents[index];
                        final isUploaded = doc['url']!.isNotEmpty;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isUploaded
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isUploaded
                                    ? Icons.cloud_done
                                    : Icons.cloud_upload,
                                color: isUploaded ? Colors.green : Colors.orange,
                              ),
                            ),
                            title: Text(
                              doc['name'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              isUploaded ? doc['type']! : '${doc['type']} - Pendiente',
                              style: TextStyle(
                                color: isUploaded ? AppColors.grey : Colors.orange,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isUploaded)
                                  IconButton(
                                    icon: const Icon(Icons.open_in_new, color: AppColors.primary),
                                    onPressed: () async {
                                      try {
                                        final uri = Uri.parse(doc['url']!);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(
                                            uri,
                                            mode: LaunchMode.externalApplication,
                                          );
                                        } else {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('No se pudo abrir el documento'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppColors.error),
                                  onPressed: () => _deleteDocument(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: AppColors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No has subido documentos',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Agrega documentos para verificar tu perfil',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Botón de guardar
                if (_hasChanges)
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: CustomButton(
                        text: 'Guardar Documentos',
                        onPressed: _saveDocuments,
                        isLoading: _isSaving,
                        icon: Icons.save,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _DocumentTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DocumentTypeCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.add_circle, color: AppColors.primary),
        onTap: onTap,
      ),
    );
  }
}
