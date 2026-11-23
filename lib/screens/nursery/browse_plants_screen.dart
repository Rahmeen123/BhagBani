import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/plant.dart';
import '../../navigation/protected_feature_navigation.dart';
import '../../providers/auth_scope.dart';
import '../../services/nursery_service.dart';
import '../auth/login_screen.dart';
import 'nearby_nurseries_screen.dart';
import 'plant_details_screen.dart';
import 'widgets/plant_card.dart';
import 'wishlist_screen.dart';

class BrowsePlantsScreen extends StatefulWidget {
  const BrowsePlantsScreen({
    super.key,
    this.initialNurseryId,
    this.initialNurseryName,
    this.initialCategory,
  });

  final String? initialNurseryId;
  final String? initialNurseryName;
  final String? initialCategory;

  @override
  State<BrowsePlantsScreen> createState() => _BrowsePlantsScreenState();
}

class _BrowsePlantsScreenState extends State<BrowsePlantsScreen> {
  final _service = NurseryService();
  final _searchController = TextEditingController();

  List<Plant> _plants = [];
  Set<String> _wishlistIds = {};
  bool _isLoading = true;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Indoor',
    'Outdoor',
    'Fruit Trees',
    'Flowering',
    'Succulents',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null &&
        _categories.contains(widget.initialCategory)) {
      _selectedCategory = widget.initialCategory!;
    }
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = AuthScope.of(context).profile;
    final userId = user?.email ?? 'guest';

    final results = await Future.wait([
      _service.getPlants(
        nurseryId: widget.initialNurseryId,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        query: _searchController.text,
      ),
      if (userId != 'guest') _service.getWishlist(userId) else Future.value(<String>[]),
    ]);

    if (!mounted) return;
    setState(() {
      _plants = results[0] as List<Plant>;
      _wishlistIds = (results[1] as List<String>).toSet();
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    _loadData();
  }

  Future<void> _toggleWishlist(Plant plant) async {
    final auth = AuthScope.of(context);
    final isGuest = auth.isGuest || (auth.profile?.isGuest ?? false);

    if (isGuest) {
      ProtectedFeatureNavigation.open(
        context,
        destination: (_) => const WishlistScreen(),
        loginScreenBuilder: (dest) => LoginScreen(onAuthenticated: dest),
      );
      return;
    }

    final userId = auth.profile?.email ?? 'user';
    final nowInWishlist = await _service.toggleWishlist(userId, plant.id);

    if (!mounted) return;
    setState(() {
      if (nowInWishlist) {
        _wishlistIds.add(plant.id);
      } else {
        _wishlistIds.remove(plant.id);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowInWishlist ? 'Added ${plant.name} to Wishlist' : 'Removed from Wishlist',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.initialNurseryName != null
        ? widget.initialNurseryName!
        : 'Browse Plants';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Nearby Nurseries',
            icon: const Icon(Icons.storefront_rounded, color: AppColors.dark),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const NearbyNurseriesScreen(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Wishlist',
            icon: const Icon(Icons.favorite_outline_rounded, color: AppColors.dark),
            onPressed: () => ProtectedFeatureNavigation.open(
              context,
              destination: (_) => const WishlistScreen(),
              loginScreenBuilder: (dest) => LoginScreen(onAuthenticated: dest),
            ),
          ),
          const SizedBox(width: 6),
        ],
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
                        hintText: 'Search plants, indoor, fruit saplings…',
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

          // Horizontal Category Chips
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
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
                    setState(() => _selectedCategory = cat);
                    _loadData();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Count & Filter info header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_plants.length} Plants Available',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  'Cash on Pickup Available',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Plants List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _plants.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadData,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                          itemCount: _plants.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final plant = _plants[i];
                            final isWishlisted = _wishlistIds.contains(plant.id);
                            return PlantCard(
                              plant: plant,
                              isWishlisted: isWishlisted,
                              onToggleWishlist: () => _toggleWishlist(plant),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => PlantDetailsScreen(plant: plant),
                                  ),
                                );
                                if (mounted) _loadData();
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
            child: const Icon(
              Icons.nature_people_rounded,
              color: AppColors.primary,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Plants Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try selecting another category or clear your search keywords.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    ),
  );
}
