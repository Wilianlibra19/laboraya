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
  final _firestore = FirebaseFirestore.instance;
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
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Obtener trabajos completados de los últimos 6 meses
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      
      final jobsSnapshot = await _firestore
          .collection('jobs')
          .where('workerId', isEqualTo: user.id)
          .where('status', isEqualTo: 'completed')
          .where('completedAt', isGreaterThan: Timestamp.fromDate(sixMonthsAgo))
          .get();

      // Agrupar por mes
      final monthlyEarnings = <String, double>{};
      final monthlyJobs = <String, int>{};
      
      for (var doc in jobsSnapshot.docs) {
        final data = doc.data();
        final completedAt = (data['completedAt'] as Timestamp).toDate();
        final monthKey = DateFormat('yyyy-MM').format(completedAt);
        final price = (data['price'] as num).toDouble();
        
        monthlyEarnings[monthKey] = (monthlyEarnings[monthKey] ?? 0) + price;
        monthlyJobs[monthKey] = (monthlyJobs[monthKey] ?? 0) + 1;
      }

      // Convertir a lista ordenada
      final sortedMonths = monthlyEarnings.keys.toList()..sort();
      final monthlyData = sortedMonths.map((month) {
        return {
          'month': month,
          'earnings': monthlyEarnings[month]!,
          'jobs': monthlyJobs[month]!,
        };
      }).toList();

      // Calcular estadísticas
      final totalEarnings = monthlyEarnings.values.fold(0.0, (a, b) => a + b);
      final totalJobs = monthlyJobs.values.fold(0, (a, b) => a + b);
      final avgPerJob = totalJobs > 0 ? totalEarnings / totalJobs : 0.0;
      final maxMonth = monthlyEarnings.entries.isEmpty
          ? null
          : monthlyEarnings.entries.reduce((a, b) => a.value > b.value ? a : b);

      setState(() {
        _monthlyData = monthlyData;
        _stats = {
          'total': totalEarnings,
          'totalJobs': totalJobs,
          'avgPerJob': avgPerJob,
          'bestMonth': maxMonth?.key,
          'bestMonthEarnings': maxMonth?.value ?? 0.0,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando estadísticas: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas de Ganancias'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Resumen
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.attach_money,
                    title: 'Total Ganado',
                    value: Helpers.formatCurrency(_stats['total'] ?? 0.0),
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.work,
                    title: 'Trabajos',
                    value: '${_stats['totalJobs'] ?? 0}',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.trending_up,
                    title: 'Promedio/Trabajo',
                    value: Helpers.formatCurrency(_stats['avgPerJob'] ?? 0.0),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.star,
                    title: 'Mejor Mes',
                    value: _stats['bestMonth'] != null
                        ? DateFormat('MMM yyyy', 'es').format(
                            DateTime.parse('${_stats['bestMonth']}-01'))
                        : 'N/A',
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Gráfico de barras simple
            if (_monthlyData.isNotEmpty) ...[
              const Text(
                'Ganancias Mensuales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _SimpleBarChart(data: _monthlyData),
              const SizedBox(height: 32),
            ],

            // Lista detallada
            const Text(
              'Detalle por Mes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_monthlyData.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No hay datos de ganancias aún',
                    style: TextStyle(color: AppColors.grey),
                  ),
                ),
              )
            else
              ..._monthlyData.reversed.map((data) {
                final month = DateTime.parse('${data['month']}-01');
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            DateFormat('MMM', 'es').format(month).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
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
                              DateFormat('MMMM yyyy', 'es').format(month),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${data['jobs']} trabajos completados',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Helpers.formatCurrency(data['earnings']),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _SimpleBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxEarnings = data.map((d) => d['earnings'] as double).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: data.map((monthData) {
          final earnings = monthData['earnings'] as double;
          final height = (earnings / maxEarnings) * 150;
          final month = DateTime.parse('${monthData['month']}-01');

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    Helpers.formatCurrency(earnings),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM', 'es').format(month).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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
