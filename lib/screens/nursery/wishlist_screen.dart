import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/plant.dart';
import '../../providers/auth_scope.dart';
import '../../services/nursery_service.dart';
import '../../widgets/primary_button.dart';
import 'browse_plants_screen.dart';
import 'plant_details_screen.dart';
import 'widgets/plant_card.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final _service = NurseryService();
  List<Plant> _wishlistPlants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() => _isLoading = true);
    final user = AuthScope.of(context).profile;
    final userId = user?.email ?? 'demo_user';

    final plantIds = await _service.getWishlist(userId);
    final allPlants = await _service.getPlants();

    if (!mounted) return;
    setState(() {
      _wishlistPlants = allPlants.where((p) => plantIds.contains(p.id)).toList();
      _isLoading = false;
    });
  }

  Future<void> _removeFromWishlist(Plant plant) async {
    final user = AuthScope.of(context).profile;
    final userId = user?.email ?? 'demo_user';
    await _service.toggleWishlist(userId, plant.id);

    if (!mounted) return;
    setState(() {
      _wishlistPlants.removeWhere((p) => p.id == plant.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${plant.name} from Wishlist'),
        backgroundColor: AppColors.dark,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('My Wishlist'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _wishlistPlants.isEmpty
              ? _emptyWishlist()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadWishlist,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                    itemCount: _wishlistPlants.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final plant = _wishlistPlants[i];
                      return PlantCard(
                        plant: plant,
                        isWishlisted: true,
                        onToggleWishlist: () => _removeFromWishlist(plant),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => PlantDetailsScreen(plant: plant),
                            ),
                          );
                          if (mounted) _loadWishlist();
                        },
                      );
                    },
                  ),
                ),
    );
  }

  Widget _emptyWishlist() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: AppColors.nurseryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border_rounded, color: AppColors.gardenAccent, size: 38),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your Wishlist is Empty',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.dark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explore healthy plants from nearby nurseries and tap the heart icon to save your favorites.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.45),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Explore Plants',
            icon: Icons.search_rounded,
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(builder: (_) => const BrowsePlantsScreen()),
              );
            },
          ),
        ],
      ),
    ),
  );
}
