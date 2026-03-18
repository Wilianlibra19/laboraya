import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();
    final formattedDate =
        '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
      body: Column(
        children: [
          _buildHeader(context, formattedDate),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroCard(isDark, formattedDate),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '1. Aceptación de los términos',
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: AppColors.primary,
                    content:
                        'Al acceder y utilizar LaboraYa, usted acepta estar sujeto a estos Términos y Condiciones de Uso. Si no está de acuerdo con alguna parte de estos términos, no debe utilizar nuestra aplicación.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '2. Descripción del servicio',
                    icon: Icons.business_center_outlined,
                    iconColor: Colors.indigo,
                    content:
                        'LaboraYa es una plataforma que conecta a personas que buscan realizar trabajos temporales con personas que necesitan servicios. Actuamos únicamente como intermediarios tecnológicos y no somos empleadores ni empleados de ninguna de las partes.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '3. Registro de cuenta',
                    icon: Icons.person_outline_rounded,
                    iconColor: Colors.green,
                    content:
                        'Para utilizar LaboraYa, debe:\n\n'
                        '• Tener al menos 18 años de edad\n'
                        '• Proporcionar información precisa y completa\n'
                        '• Mantener la seguridad de su contraseña\n'
                        '• Notificarnos inmediatamente sobre cualquier uso no autorizado de su cuenta\n'
                        '• Ser responsable de todas las actividades que ocurran bajo su cuenta',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '4. Uso aceptable',
                    icon: Icons.rule_folder_outlined,
                    iconColor: Colors.orange,
                    content:
                        'Usted se compromete a:\n\n'
                        '• Usar la plataforma de manera legal y ética\n'
                        '• No publicar contenido falso, engañoso o fraudulento\n'
                        '• No acosar, amenazar o intimidar a otros usuarios\n'
                        '• No utilizar la plataforma para actividades ilegales\n'
                        '• Respetar los derechos de propiedad intelectual\n'
                        '• No intentar acceder a cuentas de otros usuarios',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '5. Publicación de trabajos',
                    icon: Icons.work_outline_rounded,
                    iconColor: Colors.lightBlue,
                    content:
                        'Al publicar un trabajo, usted:\n\n'
                        '• Garantiza que la información es precisa y completa\n'
                        '• Se compromete a respetar las condiciones ofrecidas\n'
                        '• Acepta que LaboraYa puede remover publicaciones inapropiadas\n'
                        '• Entiende que es responsable de verificar el perfil y la idoneidad del trabajador',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '6. Aceptación de trabajos',
                    icon: Icons.handshake_outlined,
                    iconColor: Colors.teal,
                    content:
                        'Al aceptar un trabajo, usted:\n\n'
                        '• Se compromete a completar el trabajo según lo acordado\n'
                        '• Acepta las condiciones publicadas por el cliente\n'
                        '• Entiende que debe cumplir con estándares mínimos de calidad y respeto\n'
                        '• Acepta que las calificaciones negativas pueden afectar su perfil',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '7. Pagos y acuerdos económicos',
                    icon: Icons.payments_outlined,
                    iconColor: Colors.green,
                    content:
                        'Actualmente, LaboraYa facilita el contacto entre usuarios, pero no procesa pagos dentro de la aplicación. Los acuerdos económicos, formas de pago y condiciones finales son establecidos directamente entre las partes. LaboraYa no garantiza ni administra transacciones externas entre usuarios.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '8. Calificaciones y reseñas',
                    icon: Icons.star_outline_rounded,
                    iconColor: Colors.amber,
                    content:
                        'Las calificaciones y reseñas deben ser honestas y basadas en experiencias reales. LaboraYa se reserva el derecho de moderar o eliminar reseñas que violen nuestras políticas o que sean ofensivas, falsas o engañosas.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '9. Propiedad intelectual',
                    icon: Icons.copyright_outlined,
                    iconColor: Colors.purple,
                    content:
                        'Todo el contenido de LaboraYa, incluyendo textos, gráficos, logos, iconos y software, es propiedad de LaboraYa o sus licenciantes y está protegido por las leyes aplicables de propiedad intelectual.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '10. Limitación de responsabilidad',
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.redAccent,
                    content:
                        'LaboraYa no es responsable por:\n\n'
                        '• La calidad, seguridad o legalidad de los trabajos realizados\n'
                        '• Disputas entre usuarios\n'
                        '• Pérdidas o daños resultantes del uso de la plataforma\n'
                        '• Contenido generado por usuarios\n'
                        '• Interrupciones temporales o fallas del servicio',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '11. Suspensión y terminación',
                    icon: Icons.block_outlined,
                    iconColor: Colors.deepOrange,
                    content:
                        'LaboraYa se reserva el derecho de suspender o terminar su cuenta si:\n\n'
                        '• Viola estos términos\n'
                        '• Participa en actividades fraudulentas\n'
                        '• Recibe múltiples reportes negativos válidos\n'
                        '• Hace un uso abusivo o inseguro de la plataforma',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '12. Modificaciones',
                    icon: Icons.update_outlined,
                    iconColor: Colors.blue,
                    content:
                        'LaboraYa puede modificar estos términos en cualquier momento. Le notificaremos sobre cambios significativos cuando corresponda. El uso continuado de la aplicación después de las modificaciones constituye su aceptación de los nuevos términos.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '13. Ley aplicable',
                    icon: Icons.gavel_outlined,
                    iconColor: Colors.brown,
                    content:
                        'Estos términos se rigen por las leyes de Perú. Cualquier disputa será resuelta conforme a la legislación peruana y, de ser necesario, ante las autoridades competentes de Lima, Perú.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isDark: isDark,
                    title: '14. Contacto',
                    icon: Icons.mail_outline_rounded,
                    iconColor: AppColors.primary,
                    content:
                        'Si tiene preguntas sobre estos términos, puede contactarnos en:\n\n'
                        'Email: laboraya@gmail.com\n'
                        'Teléfono: +51 982 257 569\n'
                        'Dirección: Lima, Perú',
                  ),
                  const SizedBox(height: 18),
                  _buildFinalNotice(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String formattedDate) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Términos y Condiciones',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Última actualización: $formattedDate',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard(bool isDark, String formattedDate) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Condiciones de uso de LaboraYa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF162033),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estos términos explican las reglas, condiciones y responsabilidades aplicables al uso de la plataforma.',
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.55,
                    color: isDark ? Colors.white70 : const Color(0xFF5D6A79),
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
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
  }) {
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
          Row(
            children: [
              _MiniIconBubble(
                icon: icon,
                color: iconColor,
                backgroundColor: iconColor.withOpacity(0.10),
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
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.65,
              color: isDark ? Colors.white70 : const Color(0xFF536171),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalNotice(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.14),
            AppColors.primary.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Al utilizar LaboraYa, usted declara haber leído y aceptado estos términos y condiciones de uso.',
              style: TextStyle(
                fontSize: 14.2,
                height: 1.55,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF162033),
              ),
            ),
          ),
        ],
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

class _MiniIconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _MiniIconBubble({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}