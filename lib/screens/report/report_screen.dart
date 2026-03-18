import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/user_service.dart';
import '../../core/services/report_service.dart';
import '../../utils/constants.dart';
import '../../widgets/common/custom_button.dart';

class ReportScreen extends StatefulWidget {
  final String reportedId;
  final String reportedType; // 'user' o 'job'
  final String reportedName;

  const ReportScreen({
    super.key,
    required this.reportedId,
    required this.reportedType,
    required this.reportedName,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String _selectedReason = 'Contenido inapropiado';
  bool _isLoading = false;

  final List<String> _reasons = const [
    'Contenido inapropiado',
    'Fraude o estafa',
    'Spam',
    'Información falsa',
    'Acoso o intimidación',
    'Violencia',
    'Otro',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = context.read<UserService>().currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      final reportService = ReportService();

      if (widget.reportedType == 'user') {
        await reportService.reportUser(
          reporterId: currentUser.id,
          reportedUserId: widget.reportedId,
          reason: _selectedReason,
          description: _descriptionController.text.trim(),
        );
      } else {
        await reportService.reportJob(
          reporterId: currentUser.id,
          jobId: widget.reportedId,
          reason: _selectedReason,
          description: _descriptionController.text.trim(),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text('Reporte enviado. Nuestro equipo lo revisará pronto.'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar reporte: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String get _reportedLabel {
    return widget.reportedType == 'user' ? 'usuario' : 'publicación';
  }

  String get _reportedTitle {
    return widget.reportedType == 'user'
        ? 'Reportar usuario'
        : 'Reportar publicación';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDark ? const Color(0xFF0F141B) : const Color(0xFFF6F8FC);

    final cardColor = isDark ? const Color(0xFF171C23) : Colors.white;

    final inputFill = isDark ? const Color(0xFF202631) : const Color(0xFFF8FAFD);

    final borderColor =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE6EBF2);

    final textPrimary = isDark ? Colors.white : const Color(0xFF182230);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF667085);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _PremiumHeader(
              title: _reportedTitle,
              subtitle: 'Ayúdanos a mantener LaboraYa seguro y confiable',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  children: [
                    _HeroWarningCard(
                      isDark: isDark,
                      reportedLabel: _reportedLabel,
                      reportedName: widget.reportedName,
                    ),
                    const SizedBox(height: 18),
                    _PremiumSectionCard(
                      color: cardColor,
                      borderColor: borderColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(
                            icon: Icons.flag_outlined,
                            iconColor: Colors.red,
                            title: 'Motivo del reporte',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Selecciona la razón principal por la que deseas reportar este $_reportedLabel.',
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildReasonSelector(
                            isDark: isDark,
                            fillColor: inputFill,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PremiumSectionCard(
                      color: cardColor,
                      borderColor: borderColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(
                            icon: Icons.description_outlined,
                            iconColor: AppColors.primary,
                            title: 'Descripción adicional',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Puedes agregar detalles útiles para ayudarnos a entender mejor el problema.',
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 6,
                            maxLength: 500,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Ejemplo: esta publicación contiene información engañosa o el usuario tuvo una conducta inapropiada...',
                              hintStyle: TextStyle(
                                color: textSecondary.withOpacity(0.75),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: inputFill,
                              counterStyle: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: borderColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: borderColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.8,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().length > 500) {
                                return 'Máximo 500 caracteres';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PremiumSectionCard(
                      color: cardColor,
                      borderColor: borderColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(
                            icon: Icons.privacy_tip_outlined,
                            iconColor: Colors.orange,
                            title: 'Antes de enviar',
                          ),
                          const SizedBox(height: 16),
                          _InfoRow(
                            icon: Icons.verified_user_outlined,
                            text: 'Nuestro equipo revisará el reporte manualmente.',
                            textColor: textPrimary,
                            subColor: textSecondary,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.visibility_outlined,
                            text: 'No mostraremos tu identidad al usuario reportado.',
                            textColor: textPrimary,
                            subColor: textSecondary,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.gavel_outlined,
                            text: 'Tomaremos medidas si detectamos una infracción.',
                            textColor: textPrimary,
                            subColor: textSecondary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.20),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: CustomButton(
                        text: 'Enviar reporte',
                        onPressed: _submitReport,
                        isLoading: _isLoading,
                        icon: Icons.send_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Usa esta opción solo cuando exista un motivo real. Los reportes falsos o abusivos también pueden ser revisados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonSelector({
    required bool isDark,
    required Color fillColor,
    required Color borderColor,
    required Color textPrimary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedReason,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        style: TextStyle(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(Icons.shield_outlined, color: Colors.red),
        ),
        dropdownColor: isDark ? const Color(0xFF202631) : Colors.white,
        items: _reasons.map((reason) {
          return DropdownMenuItem<String>(
            value: reason,
            child: Text(
              reason,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedReason = value);
          }
        },
      ),
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _PremiumHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFF44336)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroWarningCard extends StatelessWidget {
  final bool isDark;
  final String reportedLabel;
  final String reportedName;

  const _HeroWarningCard({
    required this.isDark,
    required this.reportedLabel,
    required this.reportedName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(isDark ? 0.18 : 0.12),
            Colors.orange.withOpacity(isDark ? 0.12 : 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.red.withOpacity(0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.report_gmailerrorred_rounded,
              color: Colors.red,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estás enviando un reporte',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Objeto reportado: $reportedLabel',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? Colors.white70 : const Color(0xFF5B6574),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reportedName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF202939),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumSectionCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;

  const _PremiumSectionCard({
    required this.child,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color textColor;
  final Color subColor;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: subColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}