import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube un documento a Firebase Storage
  /// Retorna la URL de descarga pública
  static Future<String?> uploadDocument({
    required String filePath,
    required String userId,
    required String documentType,
  }) async {
    try {
      print('📤 Subiendo documento a Firebase Storage...');
      
      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ Archivo no existe: $filePath');
        return null;
      }

      // Obtener extensión del archivo
      final extension = path.extension(filePath).toLowerCase();
      
      // Crear nombre único para el archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${documentType.toLowerCase()}_$timestamp$extension';
      
      // Ruta en Firebase Storage
      final storagePath = 'documents/$userId/$fileName';
      
      print('📁 Ruta: $storagePath');
      
      // Referencia al archivo
      final ref = _storage.ref().child(storagePath);
      
      // Determinar content type
      String contentType = 'application/octet-stream';
      if (extension == '.pdf') {
        contentType = 'application/pdf';
      } else if (['.jpg', '.jpeg'].contains(extension)) {
        contentType = 'image/jpeg';
      } else if (extension == '.png') {
        contentType = 'image/png';
      }
      
      // Subir archivo con metadata
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'userId': userId,
            'documentType': documentType,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      // Esperar a que termine la subida
      final snapshot = await uploadTask;
      
      // Obtener URL de descarga
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Documento subido exitosamente');
      print('URL: $downloadUrl');
      
      return downloadUrl;
    } catch (e, stackTrace) {
      print('❌ Error al subir documento: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Sube múltiples documentos
  static Future<List<String>> uploadMultipleDocuments({
    required List<Map<String, String>> documents,
    required String userId,
  }) async {
    final List<String> uploadedUrls = [];
    
    for (int i = 0; i < documents.length; i++) {
      final doc = documents[i];
      final filePath = doc['path'] ?? '';
      final docType = doc['type'] ?? 'documento';
      
      if (filePath.isEmpty) continue;
      
      print('📤 Subiendo documento ${i + 1}/${documents.length}: $docType');
      
      final url = await uploadDocument(
        filePath: filePath,
        userId: userId,
        documentType: docType,
      );
      
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    
    print('✅ ${uploadedUrls.length}/${documents.length} documentos subidos');
    return uploadedUrls;
  }

  /// Elimina un documento de Firebase Storage
  static Future<bool> deleteDocument(String downloadUrl) async {
    try {
      print('🗑️ Eliminando documento...');
      
      // Obtener referencia desde la URL
      final ref = _storage.refFromURL(downloadUrl);
      
      // Eliminar archivo
      await ref.delete();
      
      print('✅ Documento eliminado');
      return true;
    } catch (e) {
      print('❌ Error al eliminar documento: $e');
      return false;
    }
  }

  /// Elimina múltiples documentos
  static Future<void> deleteMultipleDocuments(List<String> downloadUrls) async {
    for (final url in downloadUrls) {
      await deleteDocument(url);
    }
  }
}
