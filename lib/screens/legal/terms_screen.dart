import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Términos y Condiciones de Uso',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              '1. Aceptación de los Términos',
              'Al acceder y utilizar LaboraYa, usted acepta estar sujeto a estos Términos y Condiciones de Uso. Si no está de acuerdo con alguna parte de estos términos, no debe utilizar nuestra aplicación.',
            ),
            
            _buildSection(
              '2. Descripción del Servicio',
              'LaboraYa es una plataforma que conecta a personas que buscan realizar trabajos temporales con personas que necesitan servicios. Actuamos únicamente como intermediarios y no somos empleadores ni empleados de ninguna de las partes.',
            ),
            
            _buildSection(
              '3. Registro de Cuenta',
              'Para utilizar LaboraYa, debe:\n\n'
              '• Tener al menos 18 años de edad\n'
              '• Proporcionar información precisa y completa\n'
              '• Mantener la seguridad de su contraseña\n'
              '• Notificarnos inmediatamente sobre cualquier uso no autorizado de su cuenta\n'
              '• Ser responsable de todas las actividades que ocurran bajo su cuenta',
            ),
            
            _buildSection(
              '4. Uso Aceptable',
              'Usted se compromete a:\n\n'
              '• Usar la plataforma de manera legal y ética\n'
              '• No publicar contenido falso, engañoso o fraudulento\n'
              '• No acosar, amenazar o intimidar a otros usuarios\n'
              '• No utilizar la plataforma para actividades ilegales\n'
              '• Respetar los derechos de propiedad intelectual\n'
              '• No intentar acceder a cuentas de otros usuarios',
            ),
            
            _buildSection(
              '5. Publicación de Trabajos',
              'Al publicar un trabajo, usted:\n\n'
              '• Garantiza que la información es precisa y completa\n'
              '• Se compromete a pagar el monto acordado\n'
              '• Acepta que LaboraYa puede remover publicaciones inapropiadas\n'
              '• Entiende que es responsable de verificar las credenciales del trabajador',
            ),
            
            _buildSection(
              '6. Aceptación de Trabajos',
              'Al aceptar un trabajo, usted:\n\n'
              '• Se compromete a completar el trabajo según lo acordado\n'
              '• Acepta las condiciones de pago establecidas\n'
              '• Entiende que debe cumplir con los estándares de calidad\n'
              '• Acepta que las calificaciones negativas pueden afectar su perfil',
            ),
            
            _buildSection(
              '7. Pagos y Comisiones',
              'LaboraYa cobra una comisión del 10% sobre cada transacción completada. Los pagos se procesan a través de proveedores de pago externos. Usted es responsable de cualquier impuesto aplicable a sus ingresos.',
            ),
            
            _buildSection(
              '8. Calificaciones y Reseñas',
              'Las calificaciones y reseñas deben ser honestas y basadas en experiencias reales. LaboraYa se reserva el derecho de eliminar reseñas que violen nuestras políticas.',
            ),
            
            _buildSection(
              '9. Propiedad Intelectual',
              'Todo el contenido de LaboraYa, incluyendo textos, gráficos, logos, iconos y software, es propiedad de LaboraYa o sus licenciantes y está protegido por leyes de propiedad intelectual.',
            ),
            
            _buildSection(
              '10. Limitación de Responsabilidad',
              'LaboraYa no es responsable por:\n\n'
              '• La calidad o seguridad de los trabajos realizados\n'
              '• Disputas entre usuarios\n'
              '• Pérdidas o daños resultantes del uso de la plataforma\n'
              '• Contenido generado por usuarios\n'
              '• Interrupciones del servicio',
            ),
            
            _buildSection(
              '11. Suspensión y Terminación',
              'LaboraYa se reserva el derecho de suspender o terminar su cuenta si:\n\n'
              '• Viola estos términos\n'
              '• Participa en actividades fraudulentas\n'
              '• Recibe múltiples reportes negativos\n'
              '• No cumple con los pagos acordados',
            ),
            
            _buildSection(
              '12. Modificaciones',
              'LaboraYa puede modificar estos términos en cualquier momento. Le notificaremos sobre cambios significativos. El uso continuado de la aplicación después de las modificaciones constituye su aceptación de los nuevos términos.',
            ),
            
            _buildSection(
              '13. Ley Aplicable',
              'Estos términos se rigen por las leyes de Perú. Cualquier disputa será resuelta en los tribunales de Lima, Perú.',
            ),
            
            _buildSection(
              '14. Contacto',
              'Si tiene preguntas sobre estos términos, puede contactarnos en:\n\n'
              'Email: laboraya@gmail.com\n'
              'Teléfono: +51 982 257 569\n'
              'Dirección: Lima, Perú',
            ),
            
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Al usar LaboraYa, usted acepta estos términos y condiciones.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
