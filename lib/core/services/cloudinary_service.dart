import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CloudinaryService {
  // Cloud name correcto
  static const String cloudName = 'dpytjlvrc';
  
  // Preset en modo Unsigned - USAR NOMBRE, NO PID
  static const String uploadPreset = 'laboraya_unsigned';
  
  /// Sube una imagen a Cloudinary con optimización automática
  static Future<String?> uploadImage({
    required String imagePath,
    String? folder, // Parámetro opcional pero no se usa (preset ya tiene carpeta)
    bool optimize = true,
  }) async {
    try {
      print('📤 Subiendo imagen a Cloudinary...');
      print('Cloud: $cloudName');
      print('Preset: $uploadPreset');
      
      String finalPath = imagePath;
      
      // Optimizar imagen antes de subir
      if (optimize) {
        print('🔧 Optimizando imagen...');
        finalPath = await _optimizeImage(imagePath);
        print('✅ Imagen optimizada');
      }
      
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      
      final request = http.MultipartRequest('POST', uri);
      
      // SOLO enviar upload_preset y file
      request.fields['upload_preset'] = uploadPreset;
      
      // Agregar archivo
      request.files.add(
        await http.MultipartFile.fromPath('file', finalPath),
      );
      
      print('Enviando request a Cloudinary...');
      print('Fields: ${request.fields}');
      
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      
      print('Status code: ${streamedResponse.statusCode}');
      
      if (streamedResponse.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        final imageUrl = jsonResponse['secure_url'] as String?;
        
        if (imageUrl == null || imageUrl.isEmpty) {
          print('❌ Cloudinary respondió 200 pero sin secure_url');
          return null;
        }
        
        print('✅ Imagen subida exitosamente');
        print('URL: $imageUrl');
        
        // Limpiar archivo temporal si se optimizó
        if (optimize && finalPath != imagePath) {
          try {
            await File(finalPath).delete();
          } catch (e) {
            print('⚠️ No se pudo eliminar archivo temporal: $e');
          }
        }
        
        return imageUrl;
      } else {
        print('❌ Error al subir imagen: ${streamedResponse.statusCode}');
        print('Response: $responseBody');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Excepción al subir imagen: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// Optimiza una imagen reduciendo su tamaño y calidad
  static Future<String> _optimizeImage(String imagePath) async {
    try {
      // Leer imagen
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        return imagePath;
      }
      
      // Redimensionar si es muy grande (máximo 1920px en el lado más largo)
      img.Image resized = image;
      if (image.width > 1920 || image.height > 1920) {
        if (image.width > image.height) {
          resized = img.copyResize(image, width: 1920);
        } else {
          resized = img.copyResize(image, height: 1920);
        }
        print('📐 Imagen redimensionada de ${image.width}x${image.height} a ${resized.width}x${resized.height}');
      }
      
      // Comprimir con calidad 85
      final compressedBytes = img.encodeJpg(resized, quality: 85);
      
      // Guardar en archivo temporal
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/optimized_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(compressedBytes);
      
      final originalSize = imageBytes.length / 1024; // KB
      final optimizedSize = compressedBytes.length / 1024; // KB
      final reduction = ((originalSize - optimizedSize) / originalSize * 100).toStringAsFixed(1);
      
      print('💾 Tamaño original: ${originalSize.toStringAsFixed(1)} KB');
      print('💾 Tamaño optimizado: ${optimizedSize.toStringAsFixed(1)} KB');
      print('📉 Reducción: $reduction%');
      
      return tempPath;
    } catch (e) {
      print('⚠️ Error al optimizar imagen: $e');
      return imagePath;
    }
  }
  
  /// Sube múltiples imágenes a Cloudinary
  static Future<List<String>> uploadMultipleImages({
    required List<String> imagePaths,
    String? folder, // Parámetro opcional pero no se usa (preset ya tiene carpeta)
    bool optimize = true,
  }) async {
    final List<String> uploadedUrls = [];
    
    for (int i = 0; i < imagePaths.length; i++) {
      print('📤 Subiendo imagen ${i + 1}/${imagePaths.length}');
      
      final url = await uploadImage(
        imagePath: imagePaths[i],
        optimize: optimize,
      );
      
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    
    print('✅ ${uploadedUrls.length}/${imagePaths.length} imágenes subidas');
    return uploadedUrls;
  }
  
  /// Obtiene la URL optimizada de una imagen
  static String getOptimizedUrl({
    required String imageUrl,
    int? width,
    int? height,
    int quality = 80,
  }) {
    if (!imageUrl.contains('cloudinary.com')) {
      return imageUrl;
    }
    
    final transformations = <String>[];
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_$quality');
    transformations.add('f_auto');
    
    final transformation = transformations.join(',');
    
    return imageUrl.replaceFirst(
      '/upload/',
      '/upload/$transformation/',
    );
  }
  
  /// Obtiene thumbnail de una imagen
  static String getThumbnail({
    required String imageUrl,
    int size = 200,
  }) {
    return getOptimizedUrl(
      imageUrl: imageUrl,
      width: size,
      height: size,
      quality: 70,
    );
  }
}
