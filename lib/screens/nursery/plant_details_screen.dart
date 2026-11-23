import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/nursery.dart';
import '../../models/plant.dart';
import '../../navigation/protected_feature_navigation.dart';
import '../../providers/auth_scope.dart';
import '../../services/nursery_service.dart';
import '../../widgets/primary_button.dart';
import '../auth/login_screen.dart';
import 'buy_plant_screen.dart';

class PlantDetailsScreen extends StatefulWidget {
  const PlantDetailsScreen({super.key, required this.plant});

  final Plant plant;

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  final _service = NurseryService();
  Nursery? _nursery;
  bool _isWishlisted = false;
  bool _isLoadingNursery = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final user = AuthScope.of(context).profile;
    final userId = user?.email ?? 'guest';

    final results = await Future.wait([
      _service.getNurseryById(widget.plant.nurseryId),
      if (userId != 'guest')
        _service.isPlantInWishlist(userId, widget.plant.id)
      else
        Future.value(false),
    ]);

    if (!mounted) return;
    setState(() {
      _nursery = results[0] as Nursery?;
      _isWishlisted = results[1] as bool;
      _isLoadingNursery = false;
    });
  }

  Future<void> _toggleWishlist() async {
    final auth = AuthScope.of(context);
    final isGuest = auth.isGuest || (auth.profile?.isGuest ?? false);

    if (isGuest) {
      ProtectedFeatureNavigation.open(
        context,
        destination: (_) => PlantDetailsScreen(plant: widget.plant),
        loginScreenBuilder: (dest) => LoginScreen(onAuthenticated: dest),
      );
      return;
    }

    final userId = auth.profile?.email ?? 'user';
    final nowInWishlist = await _service.toggleWishlist(userId, widget.plant.id);

    if (!mounted) return;
    setState(() => _isWishlisted = nowInWishlist);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowInWishlist ? 'Saved to Wishlist' : 'Removed from Wishlist',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _onBuyNow() {
    ProtectedFeatureNavigation.open(
      context,
      destination: (_) => BuyPlantScreen(plant: widget.plant, nursery: _nursery),
      loginScreenBuilder: (destination) =>
          LoginScreen(onAuthenticated: destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Plant Details'),
        actions: [
          IconButton(
            onPressed: _toggleWishlist,
            icon: Icon(
              _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isWishlisted ? AppColors.gardenAccent : AppColors.dark,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
        children: [
          // Hero Illustration / Image Card
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.borderLight),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.soft.withValues(alpha: 0.5),
                  AppColors.white,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.nurseryTint,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_florist_rounded,
                      color: AppColors.primary,
                      size: 64,
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      plant.category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: plant.inStock ? AppColors.soft : AppColors.gardenTint,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: plant.inStock ? AppColors.primary.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          plant.inStock ? Icons.check_circle_rounded : Icons.info_outline,
                          size: 13,
                          color: plant.inStock ? AppColors.primary : AppColors.gardenAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          plant.inStock ? '${plant.quantity} in stock' : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: plant.inStock ? AppColors.primary : AppColors.gardenAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Title & Pricing Row
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plant.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.dark,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            plant.scientificName,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontStyle: FontStyle.italic,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rs. ${plant.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const Text(
                          'Per Plant Unit',
                          style: TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Key Plant Specs Badges
                Row(
                  children: [
                    _specBadge(icon: Icons.height_rounded, label: 'Plant Size', value: plant.height),
                    const SizedBox(width: 10),
                    _specBadge(icon: Icons.star_rounded, label: 'Quality Rating', value: '${plant.rating.toStringAsFixed(1)} ★'),
                    const SizedBox(width: 10),
                    _specBadge(icon: Icons.storefront_rounded, label: 'Order Type', value: 'Pickup'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Description Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notes_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'About this Plant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  plant.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.dark,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Care Instructions Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.water_drop_outlined, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Care Recommendations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _careRow(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Sunlight',
                  desc: plant.category == 'Indoor'
                      ? 'Bright indirect light. Protect from harsh afternoon sun.'
                      : 'Full sun to partial shade (4-6 hours direct light).',
                ),
                const SizedBox(height: 10),
                _careRow(
                  icon: Icons.opacity_outlined,
                  title: 'Watering',
                  desc: 'Water thoroughly when the top 1-2 inches of soil feel dry.',
                ),
                const SizedBox(height: 10),
                _careRow(
                  icon: Icons.compost_outlined,
                  title: 'Soil & Feeding',
                  desc: 'Well-draining potting mix with organic compost or perlite.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nursery Information Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_outlined, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Nursery & Pickup Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.nurseryTint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nursery?.nurseryName ?? plant.nurseryName,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _nursery != null ? '${_nursery!.address}, ${_nursery!.city}' : 'Verified Local Nursery, Pakistan',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.soft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payments_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment: Cash on Pickup',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              _nursery?.openingHours != null
                                  ? 'Hours: ${_nursery!.openingHours}'
                                  : 'Pay when picking up your plant at the nursery counter.',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Fixed Bottom Actions Bar
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Wishlist Button
            InkWell(
              onTap: _toggleWishlist,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isWishlisted ? AppColors.gardenAccent : AppColors.dark,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Buy Now Button
            Expanded(
              child: PrimaryButton(
                label: 'Buy Now',
                icon: Icons.shopping_bag_outlined,
                onPressed: plant.inStock ? _onBuyNow : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specBadge({required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _careRow({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: AppColors.dark, height: 1.4),
              children: [
                TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
