/// Configuración de créditos GRATIS
/// Los créditos solo se GANAN, no se compran (compatible con Google Play)
class CreditsConfig {
  // TODAS las publicaciones cuestan lo mismo
  static const int CREDITOS_POR_PUBLICACION = 10; // Cualquier tipo de trabajo
  
  // Créditos que se GANAN (no se compran)
  static const int CREDITOS_INICIALES = 500;               // Al registrarse (50 publicaciones)
  static const int CREDITOS_POR_REFERIDO = 40;             // Por cada amigo que se registre (4 publicaciones)
  static const int CREDITOS_POR_TRABAJO_COMPLETADO = 5;    // Por completar un trabajo
  
  /// Verificar si tiene créditos suficientes
  static bool tieneCreditosSuficientes(int creditosActuales) {
    return creditosActuales >= CREDITOS_POR_PUBLICACION;
  }
  
  /// Convertir créditos a soles (para mostrar al usuario)
  static double creditosASoles(int creditos) {
    return creditos * 0.10; // 1 crédito = S/ 0.10
  }
}

