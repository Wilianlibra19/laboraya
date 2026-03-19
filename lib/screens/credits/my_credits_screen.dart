import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/services/user_service.dart';
import '../../core/services/payment_service.dart';
import '../../utils/constants.dart';
import 'payment_success_screen.dart';

class MyCreditsScreen extends StatefulWidget {
  const MyCreditsScreen({super.key});

  @override
  State<MyCreditsScreen> createState() => _MyCreditsScreenState();
}

class _MyCreditsScreenState extends State<MyCreditsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PaymentService _paymentService = PaymentService();

  bool _isLoading = true;
  int _totalCredits = 0;
  int _referralCredits = 0;
  List<Map<String, dynamic>> _transactions = [];
  
  // Para detectar pagos pendientes
  int? _pendingCredits;
  double? _pendingAmount;
  String? _pendingPaymentMethod;
  int? _previousCredits;

  @override
  void initState() {
    super.initState();
    _loadCredits();
    _listenToCreditsChanges();
  }

  void _listenToCreditsChanges() {
    final user = context.read<UserService>().currentUser;
    if (user == null) return;

    // Escuchar cambios en tiempo real
    _paymentService.watchUserCredits(user.id).listen((newCredits) {
      if (_previousCredits != null && newCredits > _previousCredits!) {
        // Se agregaron créditos!
        final addedCredits = newCredits - _previousCredits!;
        
        // Si hay un pago pendiente, mostrar pantalla de éxito
        if (_pendingCredits != null && addedCredits == _pendingCredits) {
          _showSuccessScreen(
            credits: _pendingCredits!,
            amount: _pendingAmount ?? 0,
            paymentMethod: _pendingPaymentMethod ?? 'Pago',
          );
          
          // Limpiar pendientes
          _pendingCredits = null;
          _pendingAmount = null;
          _pendingPaymentMethod = null;
        }
      }
      
      setState(() {
        _totalCredits = newCredits;
        _previousCredits = newCredits;
      });
    });
  }

  void _showSuccessScreen({
    required int credits,
    required double amount,
    required String paymentMethod,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          credits: credits,
          amount: amount,
          paymentMethod: paymentMethod,
        ),
      ),
    ).then((_) {
      // Recargar créditos cuando vuelva
      _loadCredits();
    });
  }

  void _setPendingPayment({
    required int credits,
    required double amount,
    required String paymentMethod,
  }) {
    setState(() {
      _pendingCredits = credits;
      _pendingAmount = amount;
      _pendingPaymentMethod = paymentMethod;
      _previousCredits = _totalCredits;
    });
  }

  Future<void> _loadCredits() async {
    final user = context.read<UserService>().currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userDoc = await _firestore.collection('users').doc(user.id).get();
      final userData = userDoc.data();

      final referralsSnapshot = await _firestore
          .collection('referrals')
          .where('referrerId', isEqualTo: user.id)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final transactions = referralsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'type': 'referral',
          'amount': data['bonusCredits'] ?? 100,
          'description': 'Referido exitoso',
          'date': (data['createdAt'] as Timestamp).toDate(),
        };
      }).toList();

      setState(() {
        _totalCredits = userData?['credits'] ?? 0;
        _referralCredits = userData?['referralCredits'] ?? 0;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando créditos: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadCredits,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
              sliver: SliverToBoxAdapter(
                child: _isLoading
                    ? const _LoadingView()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBalanceCard(isDark),
                          const SizedBox(height: 16),
                          _buildRechargeCard(isDark),
                          const SizedBox(height: 22),
                          _buildSectionTitle(
                            isDark: isDark,
                            icon: Icons.history_rounded,
                            title: 'Historial de créditos',
                            subtitle: 'Tus últimas transacciones',
                          ),
                          const SizedBox(height: 14),
                          if (_transactions.isEmpty)
                            _buildEmptyTransactions(isDark)
                          else
                            ..._transactions.map(
                              (transaction) => _TransactionCard(
                                transaction: transaction,
                                isDark: isDark,
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 24),
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
          Material(
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
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis Créditos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gestiona tus créditos y beneficios',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                // Scroll al historial de transacciones
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Desliza hacia abajo para ver tu historial'),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              child: const SizedBox(
                height: 42,
                width: 42,
                child: Icon(
                  Icons.history_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E88E5),
            const Color(0xFF42A5F5),
            const Color(0xFF7CC8FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 76,
            width: 76,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              size: 38,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Balance disponible',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_totalCredits',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'créditos',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _BalanceStatCard(
                  icon: Icons.people_outline_rounded,
                  value: '$_referralCredits',
                  label: 'Por referidos',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BalanceStatCard(
                  icon: Icons.card_giftcard_rounded,
                  value: '${_totalCredits - _referralCredits}',
                  label: 'Bonus inicial',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRechargeCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.add_card_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recargar créditos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Elige tu paquete preferido',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _RechargeOption(
                  isDark: isDark,
                  credits: 100,
                  price: 10,
                  isPopular: false,
                  onTap: () => _showPaymentDialog(100, 10),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RechargeOption(
                  isDark: isDark,
                  credits: 300,
                  price: 25,
                  isPopular: true,
                  onTap: () => _showPaymentDialog(300, 25),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RechargeOption(
                  isDark: isDark,
                  credits: 500,
                  price: 40,
                  isPopular: false,
                  onTap: () => _showPaymentDialog(500, 40),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pagos seguros con Yape, Plin o tarjeta',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(int credits, int price) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentBottomSheet(
        credits: credits,
        price: price,
        isDark: isDark,
        onPaymentInitiated: (String paymentMethod) {
          // Guardar información del pago pendiente
          _setPendingPayment(
            credits: credits,
            amount: price.toDouble(),
            paymentMethod: paymentMethod,
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF172033),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTransactions(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
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
      child: Column(
        children: [
          Container(
            height: 74,
            width: 74,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin transacciones',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invita amigos con tu código de referido para ganar más créditos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _BalanceStatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool isDark;

  const _TransactionCard({
    required this.transaction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final amount = transaction['amount'] as int;
    final description = transaction['description'] as String;
    final date = transaction['date'] as DateTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(22),
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
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.success,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF162033),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm', 'es').format(date),
                  style: TextStyle(
                    fontSize: 13.2,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '+$amount',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      alignment: Alignment.center,
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Cargando créditos...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}


class _RechargeOption extends StatelessWidget {
  final bool isDark;
  final int credits;
  final int price;
  final bool isPopular;
  final VoidCallback? onTap;

  const _RechargeOption({
    required this.isDark,
    required this.credits,
    required this.price,
    required this.isPopular,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            gradient: isPopular
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.12),
                      AppColors.primary.withOpacity(0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isPopular
                ? null
                : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF7F9FC)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPopular
                  ? AppColors.primary.withOpacity(0.30)
                  : (isDark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFE8EEF6)),
              width: isPopular ? 1.8 : 1,
            ),
          ),
          child: Column(
            children: [
              if (isPopular) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Popular',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Icon(
                Icons.stars_rounded,
                color: isPopular ? AppColors.primary : Colors.grey[600],
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                '$credits',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isPopular
                      ? AppColors.primary
                      : (isDark ? Colors.white : const Color(0xFF162033)),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'créditos',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isPopular
                      ? AppColors.primary.withOpacity(0.14)
                      : (isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'S/ $price',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isPopular
                        ? AppColors.primary
                        : (isDark ? Colors.white : const Color(0xFF162033)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _PaymentBottomSheet extends StatefulWidget {
  final int credits;
  final int price;
  final bool isDark;
  final Function(String paymentMethod) onPaymentInitiated;

  const _PaymentBottomSheet({
    required this.credits,
    required this.price,
    required this.isDark,
    required this.onPaymentInitiated,
  });

  @override
  State<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<_PaymentBottomSheet> {
  String _selectedMethod = 'yape';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.14),
                          AppColors.primary.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comprar créditos',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: widget.isDark
                                ? Colors.white
                                : const Color(0xFF162033),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.credits} créditos por S/ ${widget.price}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Método de pago',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: widget.isDark ? Colors.white : const Color(0xFF162033),
                ),
              ),
              const SizedBox(height: 14),
              _PaymentMethodOption(
                isDark: widget.isDark,
                icon: Icons.phone_android_rounded,
                title: 'Yape',
                subtitle: 'Pago instantáneo',
                value: 'yape',
                groupValue: _selectedMethod,
                color: const Color(0xFF6B2C91),
                onChanged: (value) {
                  setState(() => _selectedMethod = value!);
                },
              ),
              const SizedBox(height: 10),
              _PaymentMethodOption(
                isDark: widget.isDark,
                icon: Icons.account_balance_wallet_rounded,
                title: 'Plin',
                subtitle: 'Transferencia rápida',
                value: 'plin',
                groupValue: _selectedMethod,
                color: const Color(0xFF00D4AA),
                onChanged: (value) {
                  setState(() => _selectedMethod = value!);
                },
              ),
              const SizedBox(height: 10),
              _PaymentMethodOption(
                isDark: widget.isDark,
                icon: Icons.credit_card_rounded,
                title: 'Tarjeta',
                subtitle: 'Débito o crédito',
                value: 'card',
                groupValue: _selectedMethod,
                color: AppColors.primary,
                onChanged: (value) {
                  setState(() => _selectedMethod = value!);
                },
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFE8EEF6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Resumen de compra',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SummaryRow(
                      isDark: widget.isDark,
                      label: 'Créditos',
                      value: '${widget.credits}',
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      isDark: widget.isDark,
                      label: 'Subtotal',
                      value: 'S/ ${widget.price}',
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      isDark: widget.isDark,
                      label: 'Comisión',
                      value: 'S/ 0.00',
                    ),
                    const Divider(height: 20),
                    _SummaryRow(
                      isDark: widget.isDark,
                      label: 'Total a pagar',
                      value: 'S/ ${widget.price}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.24),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _isProcessing ? null : _processPayment,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: _isProcessing
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Pagar S/ ${widget.price}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pago 100% seguro y encriptado',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == 'card') {
      // Abrir formulario de tarjeta
      Navigator.pop(context);
      widget.onPaymentInitiated('Tarjeta');
      _showCardPaymentScreen();
      return;
    }

    if (_selectedMethod == 'yape') {
      // Abrir pantalla de Yape
      Navigator.pop(context);
      widget.onPaymentInitiated('Yape');
      _showYapePaymentScreen();
      return;
    }

    if (_selectedMethod == 'plin') {
      // Abrir pantalla de Plin
      Navigator.pop(context);
      widget.onPaymentInitiated('Plin');
      _showPlinPaymentScreen();
      return;
    }

    setState(() => _isProcessing = true);

    // Simular procesamiento de pago
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isProcessing = false);

    // Mostrar diálogo de éxito
    Navigator.pop(context);
    _showSuccessDialog();
  }

  void _showCardPaymentScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CardPaymentScreen(
          credits: widget.credits,
          price: widget.price,
          onSuccess: _showSuccessDialog,
        ),
      ),
    );
  }

  void _showYapePaymentScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _YapePaymentScreen(
          credits: widget.credits,
          price: widget.price,
          onSuccess: _showSuccessDialog,
        ),
      ),
    );
  }

  void _showPlinPaymentScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PlinPaymentScreen(
          credits: widget.credits,
          price: widget.price,
          onSuccess: _showSuccessDialog,
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '¡Compra exitosa!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF162033),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Se han agregado ${widget.credits} créditos a tu cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.pop(context);
                      // Recargar créditos
                      if (mounted) {
                        (context as Element)
                            .findAncestorStateOfType<_MyCreditsScreenState>()
                            ?._loadCredits();
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text(
                          'Entendido',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final Color color;
  final ValueChanged<String?> onChanged;

  const _PaymentMethodOption({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(isSelected ? 0.08 : 0.03)
                : (isSelected
                    ? color.withOpacity(0.08)
                    : const Color(0xFFF7F9FC)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? color
                  : (isDark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFE8EEF6)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF162033),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.isDark,
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isDark
                ? (isBold ? Colors.white : Colors.white70)
                : (isBold ? const Color(0xFF162033) : Colors.grey[700]),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: isBold
                ? AppColors.primary
                : (isDark ? Colors.white : const Color(0xFF162033)),
          ),
        ),
      ],
    );
  }
}


class _CardPaymentScreen extends StatefulWidget {
  final int credits;
  final int price;
  final VoidCallback onSuccess;

  const _CardPaymentScreen({
    required this.credits,
    required this.price,
    required this.onSuccess,
  });

  @override
  State<_CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<_CardPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isProcessing = false;
  String _cardType = 'visa';

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String _formatCardNumber(String value) {
    value = value.replaceAll(' ', '');
    String formatted = '';
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += value[i];
    }
    return formatted;
  }

  String _formatExpiry(String value) {
    value = value.replaceAll('/', '');
    if (value.length >= 2) {
      return '${value.substring(0, 2)}/${value.substring(2)}';
    }
    return value;
  }

  void _detectCardType(String number) {
    if (number.startsWith('4')) {
      setState(() => _cardType = 'visa');
    } else if (number.startsWith('5')) {
      setState(() => _cardType = 'mastercard');
    } else if (number.startsWith('3')) {
      setState(() => _cardType = 'amex');
    } else {
      setState(() => _cardType = 'visa');
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCreditCard(isDark),
                    const SizedBox(height: 28),
                    _buildCardNumberField(isDark),
                    const SizedBox(height: 16),
                    _buildCardHolderField(isDark),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildExpiryField(isDark),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildCVVField(isDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSecurityInfo(isDark),
                    const SizedBox(height: 24),
                    _buildPayButton(),
                  ],
                ),
              ),
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
          Material(
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
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pago con tarjeta',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: S/ ${widget.price}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard(bool isDark) {
    final cardNumber = _cardNumberController.text.isEmpty
        ? '•••• •••• •••• ••••'
        : _formatCardNumber(_cardNumberController.text.padRight(16, '•'));
    
    final cardHolder = _cardHolderController.text.isEmpty
        ? 'NOMBRE DEL TITULAR'
        : _cardHolderController.text.toUpperCase();
    
    final expiry = _expiryController.text.isEmpty
        ? 'MM/AA'
        : _expiryController.text;

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _cardType == 'visa'
              ? [const Color(0xFF1A237E), const Color(0xFF283593)]
              : _cardType == 'mastercard'
                  ? [const Color(0xFFEB001B), const Color(0xFFF79E1B)]
                  : [const Color(0xFF006FCF), const Color(0xFF0099CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Patrón de fondo
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 40,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    if (_cardType == 'visa')
                      const Text(
                        'VISA',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else if (_cardType == 'mastercard')
                      Row(
                        children: [
                          Container(
                            height: 30,
                            width: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEB001B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            height: 30,
                            width: 30,
                            margin: const EdgeInsets.only(left: -10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF79E1B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        'AMEX',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  cardNumber,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TITULAR',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cardHolder,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'VENCE',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expiry,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardNumberField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Número de tarjeta',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF162033),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          maxLength: 19,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF162033),
          ),
          decoration: InputDecoration(
            hintText: '1234 5678 9012 3456',
            counterText: '',
            prefixIcon: const Icon(Icons.credit_card_rounded),
            filled: true,
            fillColor: isDark ? const Color(0xFF1B1E22) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE8EEF6),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
          onChanged: (value) {
            final formatted = _formatCardNumber(value.replaceAll(' ', ''));
            if (formatted != value) {
              _cardNumberController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
            _detectCardType(value.replaceAll(' ', ''));
            setState(() {});
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa el número de tarjeta';
            }
            if (value.replaceAll(' ', '').length < 16) {
              return 'Número de tarjeta inválido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCardHolderField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nombre del titular',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF162033),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _cardHolderController,
          textCapitalization: TextCapitalization.characters,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF162033),
          ),
          decoration: InputDecoration(
            hintText: 'JUAN PEREZ',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            filled: true,
            fillColor: isDark ? const Color(0xFF1B1E22) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE8EEF6),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
          onChanged: (value) => setState(() {}),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa el nombre del titular';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildExpiryField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha de vencimiento',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF162033),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _expiryController,
          keyboardType: TextInputType.number,
          maxLength: 5,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF162033),
          ),
          decoration: InputDecoration(
            hintText: 'MM/AA',
            counterText: '',
            prefixIcon: const Icon(Icons.calendar_today_rounded),
            filled: true,
            fillColor: isDark ? const Color(0xFF1B1E22) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE8EEF6),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
          onChanged: (value) {
            final formatted = _formatExpiry(value.replaceAll('/', ''));
            if (formatted != value) {
              _expiryController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
            setState(() {});
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Requerido';
            }
            if (value.length < 5) {
              return 'Inválido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCVVField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CVV',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF162033),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _cvvController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF162033),
          ),
          decoration: InputDecoration(
            hintText: '123',
            counterText: '',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            filled: true,
            fillColor: isDark ? const Color(0xFF1B1E22) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE8EEF6),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Requerido';
            }
            if (value.length < 3) {
              return 'Inválido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSecurityInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE8EEF6),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pago 100% seguro',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF162033),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tus datos están protegidos con encriptación SSL',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.24),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _isProcessing ? null : _processCardPayment,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _isProcessing
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Pagar S/ ${widget.price}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processCardPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isProcessing = true);

    // Simular procesamiento de pago
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isProcessing = false);

    // TEMPORAL: Mostrar pantalla de éxito con confeti
    Navigator.pop(context);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          credits: widget.credits,
          amount: widget.price.toDouble(),
          paymentMethod: 'Tarjeta',
        ),
      ),
    );
  }
}


class _YapePaymentScreen extends StatefulWidget {
  final int credits;
  final int price;
  final VoidCallback onSuccess;

  const _YapePaymentScreen({
    required this.credits,
    required this.price,
    required this.onSuccess,
  });

  @override
  State<_YapePaymentScreen> createState() => _YapePaymentScreenState();
}

class _YapePaymentScreenState extends State<_YapePaymentScreen> {
  final _phoneController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF6B2C91),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildYapeLogo(),
                    const SizedBox(height: 32),
                    _buildAmountCard(isDark),
                    const SizedBox(height: 24),
                    _buildQRSection(isDark),
                    const SizedBox(height: 20),
                    _buildDivider(isDark),
                    const SizedBox(height: 20),
                    _buildPhoneSection(isDark),
                    const SizedBox(height: 24),
                    _buildInstructions(isDark),
                    const SizedBox(height: 32),
                    _buildPayButton(),
                    const SizedBox(height: 16),
                    _buildSecurityText(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 22),
      child: Row(
        children: [
          Material(
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
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pagar con Yape',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pago instantáneo y seguro',
                  style: TextStyle(
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

  Widget _buildYapeLogo() {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'YAPE',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF6B2C91),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B2C91), Color(0xFF8E44AD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B2C91).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Monto a pagar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'S/ ${widget.price}.00',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.credits} créditos',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6B2C91).withOpacity(0.3),
          width: 2,
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
          Text(
            'Escanea este código QR',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF162033),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6B2C91).withOpacity(0.2),
                width: 3,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 120,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'QR de Yape',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6B2C91).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF6B2C91),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Abre Yape y escanea para pagar S/ ${widget.price}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'o',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneSection(bool isDark) {
    // Número de Yape de LaboraYa (reemplaza con tu número real)
    const String yapeNumber = '987 654 321';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6B2C91).withOpacity(0.3),
          width: 2,
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
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B2C91).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.phone_android_rounded,
                  color: Color(0xFF6B2C91),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O yapea al número',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+51 $yapeNumber',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF162033),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B2C91), Color(0xFF8E44AD)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  // Copiar número al portapapeles
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Número copiado al portapapeles'),
                      backgroundColor: Color(0xFF6B2C91),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Copiar número',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Número de celular Yape',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF162033),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 9,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF162033),
          ),
          decoration: InputDecoration(
            hintText: '987654321',
            counterText: '',
            prefixIcon: const Icon(Icons.phone_android_rounded),
            prefixText: '+51 ',
            prefixStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF162033),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1B1E22) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE8EEF6),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF6B2C91),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE8EEF6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B2C91).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF6B2C91),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Cómo pagar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF162033),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInstructionStep('1', 'Abre tu app Yape'),
          const SizedBox(height: 10),
          _buildInstructionStep('2', 'Escanea el QR o yapea al número mostrado'),
          const SizedBox(height: 10),
          _buildInstructionStep('3', 'Confirma el pago de S/ ${widget.price}'),
          const SizedBox(height: 10),
          _buildInstructionStep('4', 'Tus créditos se agregarán automáticamente'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 24,
          width: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF6B2C91),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B2C91), Color(0xFF8E44AD)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B2C91).withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _isProcessing ? null : _processPayment,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _isProcessing
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone_android_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Continuar con Yape',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shield_outlined,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Text(
          'Pago 100% seguro con Yape',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _processPayment() async {
    // TEMPORAL: Mostrar pantalla de éxito directamente para ver cómo quedó
    Navigator.pop(context);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          credits: widget.credits,
          amount: widget.price.toDouble(),
          paymentMethod: 'Yape',
        ),
      ),
    );
    
    // TODO: Cuando esté listo, descomentar el código real:
    /*
    // Mostrar diálogo de instrucciones
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B2C91).withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_android_rounded,
                  color: Color(0xFF6B2C91),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '¡Importante!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF162033),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Para completar tu compra:\n\n1. Abre tu app Yape\n2. Escanea el QR o yapea al número mostrado\n3. Confirma el pago de S/ ${widget.price}\n4. Vuelve a esta app\n\nTus créditos se agregarán automáticamente en 10-60 segundos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6B2C91), Color(0xFF8E44AD)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.pop(context, true),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                'Entendido',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    // Cerrar la pantalla de Yape y volver a Mis Créditos
    if (!mounted) return;
    Navigator.pop(context);

    // Mostrar SnackBar de confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Esperando confirmación del pago. Tus créditos se agregarán automáticamente.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6B2C91),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    */
  }
}

class _PlinPaymentScreen extends StatefulWidget {
  final int credits;
  final int price;
  final VoidCallback onSuccess;

  const _PlinPaymentScreen({
    required this.credits,
    required this.price,
    required this.onSuccess,
  });

  @override
  State<_PlinPaymentScreen> createState() => _PlinPaymentScreenState();
}

class _PlinPaymentScreenState extends State<_PlinPaymentScreen> {
  String _selectedBank = 'bcp';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF00D4AA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildPlinLogo(),
                    const SizedBox(height: 32),
                    _buildAmountCard(isDark),
                    const SizedBox(height: 24),
                    _buildBankSelector(isDark),
                    const SizedBox(height: 20),
                    _buildQRSection(isDark),
                    const SizedBox(height: 20),
                    _buildDivider(isDark),
                    const SizedBox(height: 20),
                    _buildPhoneSection(isDark),
                    const SizedBox(height: 24),
                    _buildInstructions(isDark),
                    const SizedBox(height: 32),
                    _buildPayButton(),
                    const SizedBox(height: 16),
                    _buildSecurityText(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 22),
      child: Row(
        children: [
          Material(
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
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pagar con Plin',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Transferencia rápida y segura',
                  style: TextStyle(
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

  Widget _buildPlinLogo() {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'PLIN',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF00D4AA),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D4AA), Color(0xFF00E5BB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4AA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Monto a pagar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'S/ ${widget.price}.00',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.credits} créditos',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona tu banco',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF162033),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _BankOption(
                isDark: isDark,
                name: 'BCP',
                value: 'bcp',
                groupValue: _selectedBank,
                onChanged: (value) => setState(() => _selectedBank = value!),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BankOption(
                isDark: isDark,
                name: 'BBVA',
                value: 'bbva',
                groupValue: _selectedBank,
                onChanged: (value) => setState(() => _selectedBank = value!),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BankOption(
                isDark: isDark,
                name: 'Interbank',
                value: 'interbank',
                groupValue: _selectedBank,
                onChanged: (value) => setState(() => _selectedBank = value!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQRSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.3),
          width: 2,
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
          Text(
            'Escanea este código QR',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF162033),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00D4AA).withOpacity(0.2),
                width: 3,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 120,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'QR de Plin',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF00D4AA),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Abre tu app ${_selectedBank.toUpperCase()} y escanea para pagar S/ ${widget.price}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'o',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneSection(bool isDark) {
    // Número de Plin de LaboraYa (reemplaza con tu número real)
    const String plinNumber = '987 654 321';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.3),
          width: 2,
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
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFF00D4AA),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O plinea al número',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+51 $plinNumber',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF162033),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4AA), Color(0xFF00E5BB)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  // Copiar número al portapapeles
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Número copiado al portapapeles'),
                      backgroundColor: Color(0xFF00D4AA),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Copiar número',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE8EEF6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF00D4AA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Cómo pagar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF162033),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInstructionStep('1', 'Abre tu app ${_selectedBank.toUpperCase()}'),
          const SizedBox(height: 10),
          _buildInstructionStep('2', 'Escanea el QR o yapea al número mostrado'),
          const SizedBox(height: 10),
          _buildInstructionStep('3', 'Confirma el pago de S/ ${widget.price}'),
          const SizedBox(height: 10),
          _buildInstructionStep('4', 'Tus créditos se agregarán automáticamente'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 24,
          width: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF6B2C91),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D4AA), Color(0xFF00E5BB)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4AA).withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _isProcessing ? null : _processPayment,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _isProcessing
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Continuar con Plin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shield_outlined,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Text(
          'Pago 100% seguro con Plin',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _processPayment() async {
    // TEMPORAL: Mostrar pantalla de éxito directamente para ver cómo quedó
    Navigator.pop(context);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          credits: widget.credits,
          amount: widget.price.toDouble(),
          paymentMethod: 'Plin',
        ),
      ),
    );
  }
}

class _BankOption extends StatelessWidget {
  final bool isDark;
  final String name;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _BankOption({
    required this.isDark,
    required this.name,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00D4AA).withOpacity(0.14)
                : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF7F9FC)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00D4AA)
                  : (isDark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFE8EEF6)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? const Color(0xFF00D4AA)
                    : (isDark ? Colors.white : const Color(0xFF162033)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
