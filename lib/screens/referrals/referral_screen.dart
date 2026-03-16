import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/referral_service.dart';
import '../../core/services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _referralService = ReferralService();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = context.read<UserService>().currentUser;
    if (user == null) return;

    final stats = await _referralService.getReferralStats(user.id);
    setState(() => _stats = stats);
  }

  Future<void> _applyCode() async {
    final user = context.read<UserService>().currentUser;
    if (user == null) return;

    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showMessage('Ingresa un código de referido', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final success = await _referralService.applyReferralCode(user.id, code);

    setState(() => _isLoading = false);

    if (success) {
      _showMessage('¡Código aplicado! Has ganado S/ 10');
      _codeController.clear();
      _loadStats();
    } else {
      _showMessage('Código inválido o ya usado', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserService>().currentUser;
    if (user == null || _stats == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final myCode = _stats!['code'] as String;
    final referralCount = _stats!['count'] as int;
    final earnings = _stats!['earnings'] as double;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Referidos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header con ganancias
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.people,
                    size: 64,
                    color: AppColors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Invita y Gana',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gana S/ 10 por cada amigo que se registre',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCard(
                        icon: Icons.people_outline,
                        value: referralCount.toString(),
                        label: 'Referidos',
                      ),
                      _StatCard(
                        icon: Icons.attach_money,
                        value: Helpers.formatCurrency(earnings),
                        label: 'Ganado',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mi código
            const Text(
              'Tu Código de Referido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    myCode,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: myCode));
                            _showMessage('Código copiado');
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copiar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Share.share(
                              '¡Únete a LaboraYa con mi código $myCode y gana S/ 10! '
                              'Descarga la app y encuentra trabajo fácilmente.',
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Compartir'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Aplicar código
            const Text(
              '¿Tienes un Código?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'Ingresa el código',
                prefixIcon: const Icon(Icons.card_giftcard),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _applyCode,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Aplicar Código'),
              ),
            ),
            const SizedBox(height: 32),

            // Cómo funciona
            const Text(
              'Cómo Funciona',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _HowItWorksCard(
              number: '1',
              title: 'Comparte tu código',
              description: 'Envía tu código a amigos y familiares',
            ),
            const SizedBox(height: 8),
            _HowItWorksCard(
              number: '2',
              title: 'Ellos se registran',
              description: 'Usan tu código al crear su cuenta',
            ),
            const SizedBox(height: 8),
            _HowItWorksCard(
              number: '3',
              title: '¡Ambos ganan!',
              description: 'Tú ganas S/ 10 y ellos también',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _HowItWorksCard({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
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
