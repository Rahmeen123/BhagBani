import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/farmer.dart';
import '../../services/farmer_service.dart';
import 'farmer_profile_screen.dart';
import 'widgets/farmer_card.dart';

class FarmerListingScreen extends StatefulWidget {
  const FarmerListingScreen({super.key});

  @override
  State<FarmerListingScreen> createState() => _FarmerListingScreenState();
}

class _FarmerListingScreenState extends State<FarmerListingScreen> {
  final _farmerService = FarmerService();
  final _searchController = TextEditingController();

  List<Farmer> _allFarmers = [];
  List<Farmer> _filteredFarmers = [];
  bool _isLoading = true;
  String _selectedSkill = 'All';

  final List<String> _skillFilters = [
    'All',
    'Crop Farming',
    'Tree Plantation',
    'Irrigation Management',
    'Farm Maintenance',
    'Pest Management',
    'Lahore',
    'Multan',
    'Sahiwal',
  ];

  @override
  void initState() {
    super.initState();
    _loadFarmers();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFarmers() async {
    setState(() => _isLoading = true);
    final list = await _farmerService.getFarmers();
    if (!mounted) return;
    setState(() {
      _allFarmers = list;
      _filteredFarmers = list;
      _isLoading = false;
    });
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredFarmers = _allFarmers.where((farmer) {
        final matchesQuery = query.isEmpty ||
            farmer.name.toLowerCase().contains(query) ||
            farmer.location.toLowerCase().contains(query) ||
            farmer.skills.any((s) => s.toLowerCase().contains(query));

        if (!matchesQuery) return false;

        if (_selectedSkill == 'All') return true;

        if (_selectedSkill == 'Lahore' ||
            _selectedSkill == 'Multan' ||
            _selectedSkill == 'Sahiwal') {
          return farmer.location.toLowerCase().contains(_selectedSkill.toLowerCase());
        }

        return farmer.skills.any(
          (s) => s.toLowerCase().contains(_selectedSkill.toLowerCase()),
        );
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
        title: const Text('Available Farmers'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
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
                        hintText: 'Search by name, location, or skill…',
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

          // Horizontal Filter Chips
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _skillFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final filter = _skillFilters[i];
                final isSelected = _selectedSkill == filter;
                return ChoiceChip(
                  label: Text(filter),
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
                    setState(() => _selectedSkill = filter);
                    _applyFilters();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Listing Count Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredFarmers.length} Farmers Found',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  'Punjab Region',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Farmer Cards List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _filteredFarmers.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadFarmers,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                          itemCount: _filteredFarmers.length,
                          itemBuilder: (context, i) {
                            final farmer = _filteredFarmers[i];
                            return FarmerCard(
                              farmer: farmer,
                              onViewProfile: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => FarmerProfileScreen(farmer: farmer),
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
              color: AppColors.communityTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search_rounded,
              color: AppColors.communityAccent,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Farmers Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your search terms or filters.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}
