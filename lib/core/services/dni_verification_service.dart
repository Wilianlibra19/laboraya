import 'package:http/http.dart' as http;
import 'dart:convert';

class DniVerificationService {
  // Tu token de apisperu.com
  static const String _apiToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6ImxhZmFybWVkMjAxNkBnbWFpbC5jb20ifQ.uf0nHh5iNP-G03GBkKRqEX_nqPWJWC1YO8xqXDB-kjc';
  static const String _baseUrl = 'https://dniruc.apisperu.com/api/v1/dni/';

  /// Verifica un DNI con la API de RENIEC
  /// Retorna los datos si es válido, null si no existe
  Future<Map<String, dynamic>?> verificarDNI(String dni) async {
    try {
      // Validar formato
      if (dni.length != 8 || !RegExp(r'^\d{8}$').hasMatch(dni)) {
        throw Exception('DNI debe tener 8 dígitos');
      }

      final url = Uri.parse('$_baseUrl$dni?token=$_apiToken');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Verificar que tenga datos válidos
        if (data['nombres'] != null && data['apellidoPaterno'] != null) {
          return {
            'dni': dni,
            'nombres': data['nombres'],
            'apellidoPaterno': data['apellidoPaterno'],
            'apellidoMaterno': data['apellidoMaterno'],
            'nombreCompleto': '${data['nombres']} ${data['apellidoPaterno']} ${data['apellidoMaterno']}',
            'valido': true,
          };
        }
      } else if (response.statusCode == 404) {
        // DNI no encontrado
        return null;
      }

      throw Exception('Error al consultar API: ${response.statusCode}');
    } catch (e) {
      print('Error verificando DNI: $e');
      rethrow;
    }
  }

  /// Verifica que el nombre del usuario coincida con el DNI
  bool verificarNombreCoincide(String nombreUsuario, String nombreDNI) {
    // Normalizar nombres (quitar acentos, mayúsculas, espacios extra)
    String normalizar(String texto) {
      return texto
          .toUpperCase()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .replaceAll('Á', 'A')
          .replaceAll('É', 'E')
          .replaceAll('Í', 'I')
          .replaceAll('Ó', 'O')
          .replaceAll('Ú', 'U')
          .replaceAll('Ñ', 'N');
    }

    final nombreUser = normalizar(nombreUsuario);
    final nombreDni = normalizar(nombreDNI);

    // Verificar si el nombre del usuario está contenido en el nombre del DNI
    // o viceversa (para casos como "Juan Perez" vs "Juan Carlos Perez Gomez")
    return nombreDni.contains(nombreUser) || nombreUser.contains(nombreDni);
  }
}
