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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtros Avanzados'),
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Limpiar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        children: [
          // Distrito
          _buildSectionTitle('📍 Distrito'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDistrict,
                hint: const Text('Seleccionar distrito'),
                isExpanded: true,
                items: _districts.map((district) {
                  return DropdownMenuItem(
                    value: district == 'Todos' ? null : district,
                    child: Text(district),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedDistrict = value);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Rango de Pago
          _buildSectionTitle('💰 Rango de Pago'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'S/ ${_minPayment.toInt()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('-'),
                    Text(
                      'S/ ${_maxPayment.toInt()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
          ),
          const SizedBox(height: 24),

          // Categorías
          _buildSectionTitle('🏷️ Categorías'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MockData.getCategories().map((category) {
              final isSelected = _selectedCategories.contains(category);
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.remove(category);
                    }
                  });
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Fecha
          _buildSectionTitle('📅 Fecha de Publicación'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dateFilters.map((filter) {
              final isSelected = _dateFilter == filter;
              return ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _dateFilter = filter);
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Solo Urgentes
          _buildSectionTitle('⚡ Opciones'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: const Text('Solo trabajos urgentes'),
              subtitle: const Text('Mostrar únicamente trabajos marcados como urgentes'),
              value: _onlyUrgent,
              onChanged: (value) {
                setState(() => _onlyUrgent = value);
              },
              activeColor: AppColors.urgent,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _onlyUrgent
                      ? AppColors.urgent.withOpacity(0.1)
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber,
                  color: _onlyUrgent ? AppColors.urgent : Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Botón Aplicar
          ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Aplicar Filtros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
