import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/nursery.dart';
import '../../services/nursery_service.dart';
import 'browse_plants_screen.dart';
import 'widgets/nursery_card.dart';

class NearbyNurseriesScreen extends StatefulWidget {
  const NearbyNurseriesScreen({super.key});

  @override
  State<NearbyNurseriesScreen> createState() => _NearbyNurseriesScreenState();
}

class _NearbyNurseriesScreenState extends State<NearbyNurseriesScreen> {
  final _service = NurseryService();
  final _searchController = TextEditingController();

  List<Nursery> _allNurseries = [];
  List<Nursery> _filteredNurseries = [];
  bool _isLoading = true;
  String _selectedCity = 'All';

  final List<String> _cities = ['All', 'Lahore', 'Islamabad', 'Sahiwal'];

  final Map<String, String> _mockDistances = {
    'nurs_1': '2.1 km away',
    'nurs_2': '4.5 km away',
    'nurs_3': '8.2 km away',
    'nurs_4': '12.0 km away',
  };

  final Map<String, int> _mockPlantCounts = {
    'nurs_1': 45,
    'nurs_2': 60,
    'nurs_3': 38,
    'nurs_4': 52,
  };

  @override
  void initState() {
    super.initState();
    _loadNurseries();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNurseries() async {
    setState(() => _isLoading = true);
    final list = await _service.getNurseries();
    if (!mounted) return;
    setState(() {
      _allNurseries = list.where((n) => n.isApproved).toList();
      _filteredNurseries = _allNurseries;
      _isLoading = false;
    });
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredNurseries = _allNurseries.where((n) {
        final matchesQuery = query.isEmpty ||
            n.nurseryName.toLowerCase().contains(query) ||
            n.address.toLowerCase().contains(query) ||
            n.city.toLowerCase().contains(query);

        if (!matchesQuery) return false;

        if (_selectedCity == 'All') return true;
        return n.city.toLowerCase() == _selectedCity.toLowerCase();
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Nearby Nurseries'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.muted, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search nursery by name or city…',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: TextStyle(color: AppColors.muted, fontSize: 13.5),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: AppColors.muted),
                      onPressed: () => _searchController.clear(),
                    ),
                ],
              ),
            ),
          ),

          // City Chips
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _cities.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final city = _cities[i];
                final isSelected = _selectedCity == city;
                return ChoiceChip(
                  label: Text(city),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.white,
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.dark,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (val) {
                    setState(() => _selectedCity = city);
                    _applyFilters();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredNurseries.length} Nurseries Found',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  'Punjab & Federal',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Nurseries List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredNurseries.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadNurseries,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                          itemCount: _filteredNurseries.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, i) {
                            final nursery = _filteredNurseries[i];
                            final distance = _mockDistances[nursery.id] ?? '3.0 km away';
                            final count = _mockPlantCounts[nursery.id] ?? 30;

                            return NurseryCard(
                              nursery: nursery,
                              distance: distance,
                              availablePlantsCount: count,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => BrowsePlantsScreen(
                                      initialNurseryId: nursery.id,
                                      initialNurseryName: nursery.nurseryName,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.nurseryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.store_mall_directory_outlined, color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Nurseries Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try selecting another city or adjusting your search keywords.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}
