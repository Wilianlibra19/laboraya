import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/storage_service.dart';
import '../../core/services/user_service.dart';
import '../../utils/constants.dart';
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
        final docs = <Map<String, String>>[];

        for (final url in user.documents) {
          final fileName = url.split('/').last;
          String type = 'Documento';

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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _documents.add({
          'type': type,
          'name': result.files.single.name,
          'path': result.files.single.path ?? '',
          'url': '',
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

      final documentUrls = <String>[];

      for (final doc in _documents) {
        if ((doc['url'] ?? '').isNotEmpty) {
          documentUrls.add(doc['url']!);
        } else if ((doc['path'] ?? '').isNotEmpty) {
          final url = await StorageService.uploadDocument(
            filePath: doc['path']!,
            userId: user.id,
            documentType: doc['type']!,
          );

          if (url != null && url.isNotEmpty) {
            documentUrls.add(url);
          } else {
            throw Exception('Error al subir ${doc['type']}');
          }
        }
      }

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
                  content: Text(
                    'Documento eliminado. Presiona "Guardar" para confirmar.',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'CV':
        return Icons.description_outlined;
      case 'DNI':
        return Icons.badge_outlined;
      case 'Certificado':
        return Icons.workspace_premium_outlined;
      case 'Licencia':
        return Icons.credit_card_outlined;
      case 'Foto de trabajo':
        return Icons.photo_library_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'CV':
        return Colors.blue;
      case 'DNI':
        return Colors.indigo;
      case 'Certificado':
        return Colors.green;
      case 'Licencia':
        return Colors.deepPurple;
      case 'Foto de trabajo':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    children: [
                      _buildDocumentTypesCard(isDark),
                      const SizedBox(height: 16),
                      if (_documents.isNotEmpty)
                        _buildDocumentsListCard(isDark)
                      else
                        _buildEmptyState(isDark),
                      if (_hasChanges) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B1E22) : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : const Color(0xFFE8EEF6),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            top: false,
                            child: CustomButton(
                              text: 'Guardar documentos',
                              onPressed: _saveDocuments,
                              isLoading: _isSaving,
                              icon: Icons.save_outlined,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.88),
            const Color(0xFF67C4FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const _HeaderBackButton(),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis Documentos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sube y organiza tus archivos importantes',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_hasChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Sin guardar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentTypesCard(bool isDark) {
    final items = [
      ('CV', 'Currículum Vitae'),
      ('DNI', 'DNI'),
      ('Certificado', 'Certificados'),
      ('Licencia', 'Licencias'),
      ('Foto de trabajo', 'Fotos de trabajos'),
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
          _SectionTitle(
            title: 'Tipos de documentos',
            icon: Icons.upload_file_outlined,
            color: AppColors.primary,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          ...items.map((item) {
            final type = item.$1;
            final title = item.$2;
            final color = _getTypeColor(type);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DocumentTypeTile(
                icon: _getTypeIcon(type),
                color: color,
                title: title,
                onTap: () => _pickDocument(type),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDocumentsListCard(bool isDark) {
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
          _SectionTitle(
            title: 'Documentos subidos',
            icon: Icons.folder_open_outlined,
            color: AppColors.primary,
            isDark: isDark,
            trailing: Text(
              '${_documents.length} archivo(s)',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white60 : const Color(0xFF708090),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(_documents.length, (index) {
            final doc = _documents[index];
            final isUploaded = (doc['url'] ?? '').isNotEmpty;
            final type = doc['type'] ?? 'Documento';
            final color = _getTypeColor(type);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isUploaded
                        ? Colors.green.withOpacity(0.18)
                        : Colors.orange.withOpacity(0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: (isUploaded ? Colors.green : color).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isUploaded ? Icons.cloud_done_rounded : _getTypeIcon(type),
                        color: isUploaded ? Colors.green : color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc['name'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF162033),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isUploaded ? type : '$type · Pendiente',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isUploaded ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isUploaded)
                      IconButton(
                        icon: const Icon(
                          Icons.open_in_new_rounded,
                          color: AppColors.primary,
                        ),
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
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                      ),
                      onPressed: () => _deleteDocument(index),
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1E22) : Colors.white,
          borderRadius: BorderRadius.circular(28),
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
          children: [
            Container(
              height: 92,
              width: 92,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.14),
                    AppColors.primary.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No has subido documentos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF162033),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Agrega documentos para fortalecer tu perfil y generar más confianza.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.55,
                color: isDark ? Colors.white70 : const Color(0xFF5D6A79),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.16),
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
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isDark;
  final Widget? trailing;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.color,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
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
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _DocumentTypeTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  const _DocumentTypeTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withOpacity(0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF162033),
                  ),
                ),
              ),
              Icon(
                Icons.add_circle_rounded,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}