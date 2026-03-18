import 'package:flutter/material.dart';
import '../../data/mock/mock_data.dart';
import '../../utils/constants.dart';

class FilterScreen extends StatefulWidget {
  final Map<String, dynamic>? currentFilters;

  const FilterScreen({super.key, this.currentFilters});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  String? _selectedDistrict;
  double _minPayment = 0;
  double _maxPayment = 500;
  Set<String> _selectedCategories = {};
  bool _onlyUrgent = false;
  String _dateFilter = 'Todos';
  double _minRating = 0;
  double _maxDistance = 50;

  final List<String> _districts = [
    'Todos',
    'Miraflores',
    'San Isidro',
    'Surco',
    'La Molina',
    'San Borja',
    'Barranco',
    'Chorrillos',
    'San Miguel',
    'Jesús María',
    'Lince',
  ];

  final List<String> _dateFilters = [
    'Todos',
    'Hoy',
    'Esta semana',
    'Este mes',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.currentFilters != null) {
      _selectedDistrict = widget.currentFilters!['district'];
      _minPayment = widget.currentFilters!['minPayment'] ?? 0;
      _maxPayment = widget.currentFilters!['maxPayment'] ?? 500;
      _selectedCategories = Set<String>.from(
        widget.currentFilters!['categories'] ?? [],
      );
      _onlyUrgent = widget.currentFilters!['onlyUrgent'] ?? false;
      _dateFilter = widget.currentFilters!['dateFilter'] ?? 'Todos';
      _minRating = widget.currentFilters!['minRating'] ?? 0;
      _maxDistance = widget.currentFilters!['maxDistance'] ?? 50;
    }
  }

  void _applyFilters() {
    final filters = {
      'district': _selectedDistrict,
      'minPayment': _minPayment,
      'maxPayment': _maxPayment,
      'categories': _selectedCategories.toList(),
      'onlyUrgent': _onlyUrgent,
      'dateFilter': _dateFilter,
      'minRating': _minRating,
      'maxDistance': _maxDistance,
    };

    Navigator.pop(context, filters);
  }

  void _clearFilters() {
    setState(() {
      _selectedDistrict = null;
      _minPayment = 0;
      _maxPayment = 500;
      _selectedCategories.clear();
      _onlyUrgent = false;
      _dateFilter = 'Todos';
      _minRating = 0;
      _maxDistance = 50;
    });
  }

  int _activeFiltersCount() {
    int count = 0;
    if (_selectedDistrict != null) count++;
    if (_minPayment > 0 || _maxPayment < 500) count++;
    if (_selectedCategories.isNotEmpty) count++;
    if (_onlyUrgent) count++;
    if (_dateFilter != 'Todos') count++;
    if (_minRating > 0) count++;
    if (_maxDistance < 50) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCount = _activeFiltersCount();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
      body: Column(
        children: [
          _buildHeader(activeCount),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
              children: [
                _buildSectionCard(
                  isDark: isDark,
                  title: 'Distrito',
                  icon: Icons.location_on_outlined,
                  iconColor: AppColors.primary,
                  child: _buildDistrictDropdown(isDark),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  isDark: isDark,
                  title: 'Rango de pago',
                  icon: Icons.payments_outlined,
                  iconColor: Colors.green,
                  child: _buildPaymentRange(isDark),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  isDark: isDark,
                  title: 'Categorías',
                  icon: Icons.sell_outlined,
                  iconColor: Colors.orange,
                  child: _buildCategories(isDark),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  isDark: isDark,
                  title: 'Fecha de publicación',
                  icon: Icons.calendar_today_outlined,
                  iconColor: Colors.indigo,
                  child: _buildDateFilters(isDark),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  isDark: isDark,
                  title: 'Rating mínimo',
                  icon: Icons.star_outline_rounded,
                  iconColor: Colors.amber,
                  child: _buildRatingFilter(isDark),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  isDark: isDark,
                  title: 'Distancia máxima',
                  icon: Icons.near_me_outlined,
                  iconColor: Colors.teal,
                  child: _buildDistanceFilter(isDark),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  isDark: isDark,
                  title: 'Opciones rápidas',
                  icon: Icons.tune_rounded,
                  iconColor: Colors.redAccent,
                  child: _buildUrgentOption(isDark),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isDark, activeCount),
    );
  }

  Widget _buildHeader(int activeCount) {
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtros avanzados',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Encuentra trabajos más relevantes para ti',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (activeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$activeCount activos',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDistrictDropdown(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField<String?>(
        value: _selectedDistrict,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Seleccionar distrito',
          prefixIcon: const Icon(Icons.location_city_outlined),
          filled: true,
          fillColor: isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.8,
            ),
          ),
        ),
        items: _districts.map((district) {
          return DropdownMenuItem<String?>(
            value: district == 'Todos' ? null : district,
            child: Text(district),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _selectedDistrict = value);
        },
      ),
    );
  }

  Widget _buildPaymentRange(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ValueBox(
                  title: 'Desde',
                  value: 'S/ ${_minPayment.toInt()}',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ValueBox(
                  title: 'Hasta',
                  value: 'S/ ${_maxPayment.toInt()}',
                  color: Colors.green,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          RangeSlider(
            values: RangeValues(_minPayment, _maxPayment),
            min: 0,
            max: 500,
            divisions: 50,
            labels: RangeLabels(
              'S/ ${_minPayment.toInt()}',
              'S/ ${_maxPayment.toInt()}',
            ),
            onChanged: (values) {
              setState(() {
                _minPayment = values.start;
                _maxPayment = values.end;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MockData.getCategories().map((category) {
        final isSelected = _selectedCategories.contains(category);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedCategories.remove(category);
              } else {
                _selectedCategories.add(category);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.12)
                  : (isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC)),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CategoryIcons.icons[category] ?? Icons.work_outline_rounded,
                  size: 14,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white70 : const Color(0xFF708090)),
                ),
                const SizedBox(width: 6),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? Colors.white : const Color(0xFF162033)),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateFilters(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _dateFilters.map((filter) {
        final isSelected = _dateFilter == filter;

        return GestureDetector(
          onTap: () {
            setState(() => _dateFilter = filter);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.indigo.withOpacity(0.12)
                  : (isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC)),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? Colors.indigo : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Text(
              filter,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.indigo
                    : (isDark ? Colors.white : const Color(0xFF162033)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingFilter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Mínimo requerido',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _minRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            value: _minRating,
            min: 0,
            max: 5,
            divisions: 10,
            label: _minRating.toStringAsFixed(1),
            onChanged: (value) {
              setState(() => _minRating = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceFilter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Radio de búsqueda',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_maxDistance.toInt()} km',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            value: _maxDistance,
            min: 1,
            max: 50,
            divisions: 49,
            label: '${_maxDistance.toInt()} km',
            onChanged: (value) {
              setState(() => _maxDistance = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentOption(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF24282D) : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _onlyUrgent
              ? AppColors.urgent.withOpacity(0.22)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: _onlyUrgent
                  ? AppColors.urgent.withOpacity(0.12)
                  : Colors.grey.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: _onlyUrgent ? AppColors.urgent : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solo trabajos urgentes',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Mostrar únicamente trabajos marcados como urgentes',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _onlyUrgent,
            onChanged: (value) {
              setState(() => _onlyUrgent = value);
            },
            activeColor: AppColors.urgent,
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
    required Widget child,
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
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark, int activeCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EEF6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _clearFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary.withOpacity(0.35),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Limpiar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _applyFilters,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            activeCount > 0
                                ? 'Aplicar filtros ($activeCount)'
                                : 'Aplicar filtros',
                            style: const TextStyle(
                              fontSize: 15,
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
          ],
        ),
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

class _ValueBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final bool alignEnd;

  const _ValueBox({
    required this.title,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}