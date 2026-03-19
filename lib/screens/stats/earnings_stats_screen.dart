import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class EarningsStatsScreen extends StatefulWidget {
  const EarningsStatsScreen({super.key});

  @override
  State<EarningsStatsScreen> createState() => _EarningsStatsScreenState();
}

class _EarningsStatsScreenState extends State<EarningsStatsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _monthlyData = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = context.read<UserService>().currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));

      final snapshot = await _firestore
          .collection('jobs')
          .where('completedAt', isGreaterThan: Timestamp.fromDate(sixMonthsAgo))
          .get();

      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data();

        final workerId = data['workerId'];
        final acceptedBy = data['acceptedBy'];
        final status = (data['status'] ?? '').toString().toLowerCase();
        final jobStatus = (data['jobStatus'] ?? '').toString().toLowerCase();

        final isThisUser =
            workerId == user.id || acceptedBy == user.id;

        final isCompleted =
            status == 'completed' ||
            jobStatus == 'completed' ||
            jobStatus == 'confirmed_by_client';

        return isThisUser && isCompleted;
      }).toList();

      final Map<String, double> monthlyEarnings = {};
      final Map<String, int> monthlyJobs = {};

      for (final doc in filteredDocs) {
        final data = doc.data();

        final completedAtRaw = data['completedAt'];
        if (completedAtRaw == null || completedAtRaw is! Timestamp) continue;

        final completedAt = completedAtRaw.toDate();
        final monthKey = DateFormat('yyyy-MM').format(completedAt);

        final amountRaw = data['payment'] ?? data['price'] ?? 0;
        final amount = (amountRaw as num).toDouble();

        monthlyEarnings[monthKey] = (monthlyEarnings[monthKey] ?? 0) + amount;
        monthlyJobs[monthKey] = (monthlyJobs[monthKey] ?? 0) + 1;
      }

      final sortedMonths = monthlyEarnings.keys.toList()..sort();

      final monthlyData = sortedMonths.map((month) {
        return {
          'month': month,
          'earnings': monthlyEarnings[month] ?? 0.0,
          'jobs': monthlyJobs[month] ?? 0,
        };
      }).toList();

      final totalEarnings =
          monthlyEarnings.values.fold(0.0, (a, b) => a + b);
      final totalJobs = monthlyJobs.values.fold(0, (a, b) => a + b);
      final avgPerJob = totalJobs > 0 ? totalEarnings / totalJobs : 0.0;

      MapEntry<String, double>? bestMonth;
      if (monthlyEarnings.isNotEmpty) {
        bestMonth = monthlyEarnings.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );
      }

      double currentMonthEarnings = 0;
      final currentMonthKey = DateFormat('yyyy-MM').format(DateTime.now());
      currentMonthEarnings = monthlyEarnings[currentMonthKey] ?? 0.0;

      setState(() {
        _monthlyData = monthlyData;
        _stats = {
          'total': totalEarnings,
          'totalJobs': totalJobs,
          'avgPerJob': avgPerJob,
          'bestMonth': bestMonth?.key,
          'bestMonthEarnings': bestMonth?.value ?? 0.0,
          'currentMonth': currentMonthEarnings,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reload() async {
    await _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1115) : const Color(0xFFF5F8FC),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _reload,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _StatsHeader(
                onBack: () => Navigator.pop(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
              sliver: SliverToBoxAdapter(
                child: _isLoading
                    ? const _LoadingView()
                    : _monthlyData.isEmpty
                        ? const _EmptyStatsView()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TopSummary(
                                total: (_stats['total'] ?? 0.0) as double,
                                currentMonth:
                                    (_stats['currentMonth'] ?? 0.0) as double,
                                totalJobs: (_stats['totalJobs'] ?? 0) as int,
                                avgPerJob:
                                    (_stats['avgPerJob'] ?? 0.0) as double,
                                bestMonth: _stats['bestMonth'] as String?,
                              ),
                              const SizedBox(height: 18),
                              _InsightBanner(
                                total: (_stats['total'] ?? 0.0) as double,
                                bestMonth: _stats['bestMonth'] as String?,
                                bestMonthEarnings:
                                    (_stats['bestMonthEarnings'] ?? 0.0)
                                        as double,
                              ),
                              const SizedBox(height: 22),
                              const _SectionTitle(
                                title: 'Ganancias mensuales',
                                subtitle: 'Resumen visual de los últimos meses',
                                icon: Icons.bar_chart_rounded,
                              ),
                              const SizedBox(height: 14),
                              _ModernBarChart(data: _monthlyData),
                              const SizedBox(height: 24),
                              const _SectionTitle(
                                title: 'Detalle por mes',
                                subtitle: 'Tus ingresos y trabajos completados',
                                icon: Icons.calendar_month_rounded,
                              ),
                              const SizedBox(height: 14),
                              ..._monthlyData.reversed.map(
                                (item) => _MonthDetailCard(data: item),
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
}

class _StatsHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _StatsHeader({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
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
              onTap: onBack,
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
                  'Estadísticas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Visualiza tus ganancias y rendimiento',
                  style: TextStyle(
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
              Icons.insights_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopSummary extends StatelessWidget {
  final double total;
  final double currentMonth;
  final int totalJobs;
  final double avgPerJob;
  final String? bestMonth;

  const _TopSummary({
    required this.total,
    required this.currentMonth,
    required this.totalJobs,
    required this.avgPerJob,
    required this.bestMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatSummaryCard(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Total ganado',
                value: Helpers.formatCurrency(total),
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatSummaryCard(
                icon: Icons.payments_outlined,
                title: 'Este mes',
                value: Helpers.formatCurrency(currentMonth),
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatSummaryCard(
                icon: Icons.work_outline_rounded,
                title: 'Trabajos',
                value: '$totalJobs',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatSummaryCard(
                icon: Icons.trending_up_rounded,
                title: 'Promedio',
                value: Helpers.formatCurrency(avgPerJob),
                color: Colors.purple,
              ),
            ),
          ],
        ),
        if (bestMonth != null) ...[
          const SizedBox(height: 12),
          _BestMonthCard(bestMonth: bestMonth!),
        ],
      ],
    );
  }
}

class _StatSummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatSummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171B22) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withOpacity(0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.8,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF162033),
            ),
          ),
        ],
      ),
    );
  }
}

class _BestMonthCard extends StatelessWidget {
  final String bestMonth;

  const _BestMonthCard({
    required this.bestMonth,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse('$bestMonth-01');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.14),
            Colors.orange.withOpacity(0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.orange.withOpacity(0.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tu mejor mes fue ${DateFormat('MMMM yyyy', 'es').format(date)}',
              style: const TextStyle(
                fontSize: 14.2,
                fontWeight: FontWeight.w700,
                color: Color(0xFF162033),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightBanner extends StatelessWidget {
  final double total;
  final String? bestMonth;
  final double bestMonthEarnings;

  const _InsightBanner({
    required this.total,
    required this.bestMonth,
    required this.bestMonthEarnings,
  });

  @override
  Widget build(BuildContext context) {
    String message = 'Sigue completando trabajos para aumentar tus ingresos.';

    if (bestMonth != null) {
      final monthDate = DateTime.parse('$bestMonth-01');
      message =
          'Tu mejor rendimiento fue en ${DateFormat('MMMM', 'es').format(monthDate)} con ${Helpers.formatCurrency(bestMonthEarnings)}.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13.8,
                height: 1.45,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172033),
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
}

class _ModernBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _ModernBarChart({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxEarnings = data
        .map((e) => (e['earnings'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Container(
      height: 260,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171B22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFE8EEF6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((monthData) {
          final earnings = (monthData['earnings'] as num).toDouble();
          final jobs = monthData['jobs'] as int;
          final month = DateTime.parse('${monthData['month']}-01');

          final height = maxEarnings <= 0 ? 8.0 : (earnings / maxEarnings) * 145;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    Helpers.formatCurrency(earnings),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF344054),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    height: height < 12 ? 12 : height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.65),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                        bottom: Radius.circular(10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.20),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM', 'es').format(month).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$jobs',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MonthDetailCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _MonthDetailCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final month = DateTime.parse('${data['month']}-01');
    final earnings = (data['earnings'] as num).toDouble();
    final jobs = data['jobs'] as int;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171B22) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFE8EEF6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
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
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                DateFormat('MMM', 'es').format(month).toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _capitalize(
                    DateFormat('MMMM yyyy', 'es').format(month),
                  ),
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF162033),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$jobs ${jobs == 1 ? 'trabajo completado' : 'trabajos completados'}',
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
            Helpers.formatCurrency(earnings),
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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
            'Cargando estadísticas...',
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

class _EmptyStatsView extends StatelessWidget {
  const _EmptyStatsView();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9EEF6)),
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
              Icons.bar_chart_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aún no hay estadísticas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completa trabajos para empezar a ver tus ganancias y rendimiento mensual.',
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