import 'package:flutter/material.dart';
import '../farmer/widgets/community_login_gate.dart';
import '../../core/theme/app_theme.dart';
import '../../features/plant_recommendation/screens/plant_intro_screen.dart';
import '../../features/crop_recommendation/screens/crop_recommendation_intro_screen.dart';
import '../../features/satellite_analysis/screens/land_analysis_screen.dart';

import '../../features/tree_recommendation/screens/tree_intro_screen.dart';
import '../../navigation/protected_feature_navigation.dart';
import '../../providers/auth_scope.dart';
import '../../widgets/feature_tile.dart';
import '../../widgets/section_heading.dart';
import '../auth/login_screen.dart';
import '../coming_soon_screen.dart';
import '../farmer/become_farmer_screen.dart';
import '../farmer/farmer_listing_screen.dart';
import '../farmer/hire_farmer_landing_screen.dart';
import '../farmer/widgets/login_required_dialog.dart';
import '../help/help_guide_screen.dart';
import '../land/offer_land_screen.dart';
import '../notifications/notifications_screen.dart';
import '../nursery/browse_plants_screen.dart';
import '../nursery/my_orders_screen.dart';
import '../nursery/nearby_nurseries_screen.dart';
import '../nursery/nursery_gate_screen.dart';
import '../nursery/plant_details_screen.dart';
import '../nursery/wishlist_screen.dart';
import '../profile/profile_screen.dart';
import '../../models/plant.dart';
import '../../services/nursery_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _HomeTab(
          onOpenNotifications: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const NotificationsScreen()),
              )),
      const _PlantsExploreTab(),
      const _CommunityExploreTab(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.white,
          indicatorColor: AppColors.soft,
          elevation: 0,
          selectedIndex: _tab,
          onDestinationSelected: (value) => setState(() => _tab = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: AppColors.muted),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_florist_outlined, color: AppColors.muted),
              selectedIcon:
                  Icon(Icons.local_florist_rounded, color: AppColors.primary),
              label: 'Plants',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined, color: AppColors.muted),
              selectedIcon:
                  Icon(Icons.groups_rounded, color: AppColors.primary),
              label: 'Community',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: AppColors.muted),
              selectedIcon:
                  Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.onOpenNotifications});
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.profile;
    final isGuest = auth.isGuest || (user?.isGuest ?? false);
    final displayName =
        isGuest ? 'Guest' : (user?.name.split(' ').first ?? 'Gardener');

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // Header (Greeting + Notification button matching Figma 3:810)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good morning,',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Welcome, $displayName',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                ],
              ),
              // Notifications button: circular white pill from Figma (node 3:814)
              InkWell(
                onTap: onOpenNotifications,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.dark,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Search Bar matching Figma (node 3:17)
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    color: AppColors.muted, size: 22),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Search plants, crops, nurseries…',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(Icons.tune_rounded,
                    color: AppColors.muted.withValues(alpha: 0.6), size: 18),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Hero Banner matching Figma (node 3:817)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  right: -30,
                  top: -40,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plan your next harvest',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Analyze your land with satellite insights and get tailored crop advice.',
                      style: TextStyle(
                        color: AppColors.sageLight,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () =>
                          _openComingSoon(context, 'Land Satellite Analysis'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 11),
                        decoration: BoxDecoration(
                          color: AppColors.sageLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Get started',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions Row matching Figma (node 3:823)
          const Text(
            'Quick actions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QuickActionTile(
                label: 'Explore',
                icon: Icons.grid_view_rounded,
                tint: AppColors.nurseryTint,
                iconColor: AppColors.nurseryAccent,
                onTap: () => _openComingSoon(context, 'Explore Baghbani'),
              ),
              _QuickActionTile(
                label: 'Crops',
                icon: Icons.agriculture_rounded,
                tint: AppColors.farmTint,
                iconColor: AppColors.farmAccent,
                onTap: () => _openProtected(
                  context,
                  (_) => const CropRecommendationIntroScreen(),
                ),
              ),
              _QuickActionTile(
                label: 'Plants',
                icon: Icons.local_florist_rounded,
                tint: AppColors.gardenTint,
                iconColor: AppColors.gardenAccent,
                onTap: () => _openPlantRecommendation(context),
              ),
              _QuickActionTile(
                label: 'Trees',
                icon: Icons.park_rounded,
                tint: AppColors.farmTint,
                iconColor: AppColors.farmAccent,
                onTap: () => _openTreeRecommendation(context),
              ),
            ],
          ),
          const SizedBox(height: 26),

          // 🌾 FARM Section Card matching Figma (node 3:830)
          _SectionContainer(
            title: 'Farm',
            subtitle: 'Smart land & crop planning',
            accentColor: AppColors.farmAccent,
            children: [
              FeatureRowTile(
                title: 'Crop Recommendation',
                subtitle: 'Match crops to your land & season',
                icon: Icons.agriculture_rounded,
                tint: AppColors.farmTint,
                iconColor: AppColors.farmAccent,
                showDivider: true,
                onTap: () => _openProtected(
                  context,
                  (_) => const CropRecommendationIntroScreen(),
                ),
              ),
              FeatureRowTile(
                title: 'Tree Recommendation',
                subtitle: 'Choose trees suited for your climate',
                icon: Icons.park_rounded,
                tint: AppColors.farmTint,
                iconColor: AppColors.farmAccent,
                showDivider: true,
                onTap: () => _openTreeRecommendation(context),
              ),
              FeatureRowTile(
                title: 'Plantation Planning',
                subtitle: 'Organize schedule and field layout',
                icon: Icons.calendar_month_rounded,
                tint: AppColors.farmTint,
                iconColor: AppColors.farmAccent,
                onTap: () => _openProtected(
                  context,
                  (_) => const ComingSoonScreen(feature: 'Plantation Planning'),
                ),
              ),
              FeatureRowTile(
                title: 'Land Analysis',
                subtitle: 'Review vegetation within a farm boundary',
                icon: Icons.satellite_alt_rounded,
                tint: AppColors.soft,
                iconColor: AppColors.primary,
                onTap: () => _openProtected(
                  context,
                  (_) => const LandAnalysisScreen(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 🏡 GARDEN Section Card matching Figma (node 3:838)
          _SectionContainer(
            title: 'Garden',
            subtitle: 'Care for your home garden',
            accentColor: AppColors.gardenAccent,
            children: [
              FeatureRowTile(
                title: 'Plant Recommendation',
                subtitle: 'Find indoor and outdoor plants',
                icon: Icons.local_florist_rounded,
                tint: AppColors.gardenTint,
                iconColor: AppColors.gardenAccent,
                showDivider: true,
                onTap: () => _openPlantRecommendation(context),
              ),
              FeatureRowTile(
                title: 'Plant Health Analysis',
                subtitle: 'Diagnose leaf and stem symptoms',
                icon: Icons.health_and_safety_rounded,
                tint: AppColors.gardenTint,
                iconColor: AppColors.gardenAccent,
                onTap: () => _openProtected(
                  context,
                  (_) =>
                      const ComingSoonScreen(feature: 'Plant Health Analysis'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 🌱 NURSERY Section Card matching Figma (node 3:846)
          _SectionContainer(
            title: 'Nursery',
            subtitle: 'Find and buy healthy plants',
            accentColor: AppColors.nurseryAccent,
            children: [
              FeatureRowTile(
                title: 'Browse Plants',
                subtitle: 'Explore full catalog with prices',
                icon: Icons.yard_rounded,
                tint: AppColors.nurseryTint,
                iconColor: AppColors.nurseryAccent,
                showDivider: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const BrowsePlantsScreen(),
                  ),
                ),
              ),
              FeatureRowTile(
                title: 'Nearby Nurseries',
                subtitle: 'Locate verified nurseries near you',
                icon: Icons.storefront_rounded,
                tint: AppColors.nurseryTint,
                iconColor: AppColors.nurseryAccent,
                showDivider: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const NearbyNurseriesScreen(),
                  ),
                ),
              ),
              _NurseryEntryTile(
                userId: isGuest || user == null ? null : user.email,
                onOpenNursery: () => _openNursery(context),
              ),
              FeatureRowTile(
                title: 'Wishlist',
                subtitle: 'Save favorites for next season',
                icon: Icons.favorite_border_rounded,
                tint: AppColors.nurseryTint,
                iconColor: AppColors.nurseryAccent,
                onTap: () => _openProtected(
                  context,
                  (_) => const WishlistScreen(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 🤝 COMMUNITY Section Card matching Figma (node 3:854)
          _SectionContainer(
            title: 'Community',
            subtitle: 'Connect with farmers & landowners',
            accentColor: AppColors.communityAccent,
            children: [
              FeatureRowTile(
                title: 'Hire Farmer',
                subtitle: 'Find skilled farmers for your land',
                icon: Icons.groups_rounded,
                tint: AppColors.communityTint,
                iconColor: AppColors.communityAccent,
                showDivider: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const HireFarmerLandingScreen(),
                  ),
                ),
              ),
              FeatureRowTile(
                title: 'Become a Farmer',
                subtitle: 'Offer your farming services',
                icon: Icons.person_add_alt_1_rounded,
                tint: AppColors.soft,
                iconColor: AppColors.primary,
                showDivider: true,
                onTap: () => _openProtected(
                  context,
                  (_) => const BecomeFarmerScreen(),
                ),
              ),
              FeatureRowTile(
                title: 'Offer a Land',
                subtitle: 'Add new land or manage listings',
                icon: Icons.landscape_rounded,
                tint: AppColors.farmTint,
                iconColor: AppColors.farmAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const OfferLandLandingScreen(),
                    ),
                  );
                },
              ),
              FeatureRowTile(
                title: 'Find Land',
                subtitle: 'Browse available farmland',
                icon: Icons.search_rounded,
                tint: AppColors.farmTint,
                iconColor: AppColors.farmAccent,
                onTap: () => Navigator.pushNamed(context, '/find-land'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openComingSoon(BuildContext context, String feature) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ComingSoonScreen(feature: feature),
      ),
    );
  }

  void _openProtected(BuildContext context, WidgetBuilder destination) {
    ProtectedFeatureNavigation.open(
      context,
      destination: destination,
      loginScreenBuilder: (dest) => LoginScreen(onAuthenticated: dest),
    );
  }

  Future<void> _openNursery(BuildContext context) {
    final auth = AuthScope.of(context);
    final destination = (_) => const NurseryGateScreen();
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: auth.isAuthenticated && !auth.isGuest
            ? destination
            : (_) => LoginScreen(onAuthenticated: destination),
      ),
    );
  }

  void _openPlantRecommendation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const PlantIntroScreen()),
    );
  }

  void _openTreeRecommendation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const TreeIntroScreen()),
    );
  }
}

class _NurseryEntryTile extends StatefulWidget {
  const _NurseryEntryTile({
    required this.userId,
    required this.onOpenNursery,
  });

  final String? userId;
  final Future<void> Function() onOpenNursery;

  @override
  State<_NurseryEntryTile> createState() => _NurseryEntryTileState();
}

class _NurseryEntryTileState extends State<_NurseryEntryTile> {
  final _service = NurseryService();
  Future<bool>? _hasNursery;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent ?? true) {
      _loadNurseryStatus();
    }
  }

  @override
  void didUpdateWidget(covariant _NurseryEntryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) _loadNurseryStatus();
  }

  void _loadNurseryStatus() {
    final userId = widget.userId;
    _hasNursery = userId == null
        ? Future<bool>.value(false)
        : _service.getUserNursery(userId).then((nursery) => nursery != null);
  }

  Future<void> _openNursery() async {
    await widget.onOpenNursery();
    if (mounted) setState(_loadNurseryStatus);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
        future: _hasNursery,
        builder: (context, snapshot) {
          final hasNursery = snapshot.data ?? false;
          return FeatureRowTile(
            title: hasNursery ? 'My Nursery' : 'Add your nursery',
            subtitle: snapshot.hasError
                ? 'Tap to retry or manage your nursery'
                : hasNursery
                    ? 'Manage your registered nursery'
                    : 'Register and manage your nursery',
            icon: hasNursery
                ? Icons.storefront_rounded
                : Icons.add_business_rounded,
            tint: AppColors.nurseryTint,
            iconColor: AppColors.nurseryAccent,
            showDivider: true,
            onTap: _openNursery,
          );
        },
      );
}

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.children,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF245C43).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            title: title,
            subtitle: subtitle,
            accentColor: accentColor,
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.label,
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantsExploreTab extends StatefulWidget {
  const _PlantsExploreTab();

  @override
  State<_PlantsExploreTab> createState() => _PlantsExploreTabState();
}

class _PlantsExploreTabState extends State<_PlantsExploreTab> {
  final _service = NurseryService();
  List<Plant> _featured = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeatured();
  }

  Future<void> _loadFeatured() async {
    final plants = await _service.getPlants();
    if (mounted) {
      setState(() {
        _featured = plants.take(6).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Header
            const Text(
              'Plants & Nurseries',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Buy plants, find nurseries, grow your garden',
              style: TextStyle(fontSize: 13.5, color: AppColors.muted),
            ),
            const SizedBox(height: 20),

            // Quick nav row
            Row(
              children: [
                _quickNav(
                  context,
                  icon: Icons.search_rounded,
                  label: 'Browse All',
                  tint: AppColors.nurseryTint,
                  color: AppColors.nurseryAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const BrowsePlantsScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _quickNav(
                  context,
                  icon: Icons.storefront_rounded,
                  label: 'Nurseries',
                  tint: AppColors.gardenTint,
                  color: AppColors.gardenAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const NearbyNurseriesScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _quickNav(
                  context,
                  icon: Icons.favorite_rounded,
                  label: 'Wishlist',
                  tint: const Color(0xFFFFEBEE),
                  color: const Color(0xFFE53935),
                  onTap: () => ProtectedFeatureNavigation.open(
                    context,
                    destination: (_) => const WishlistScreen(),
                    loginScreenBuilder: (dest) =>
                        LoginScreen(onAuthenticated: dest),
                  ),
                ),
                const SizedBox(width: 10),
                _quickNav(
                  context,
                  icon: Icons.receipt_long_rounded,
                  label: 'My Orders',
                  tint: AppColors.farmTint,
                  color: AppColors.farmAccent,
                  onTap: () => ProtectedFeatureNavigation.open(
                    context,
                    destination: (_) => const MyOrdersScreen(),
                    loginScreenBuilder: (dest) =>
                        LoginScreen(onAuthenticated: dest),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Featured plants
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Featured Plants',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const BrowsePlantsScreen(),
                    ),
                  ),
                  child: const Text(
                    'See all →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.nurseryAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_featured.isEmpty)
              const Center(
                child: Text(
                  'No plants available yet.',
                  style: TextStyle(color: AppColors.muted),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _featured.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, i) {
                  final plant = _featured[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => PlantDetailsScreen(plant: plant),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Plant icon hero
                          Container(
                            height: 110,
                            decoration: BoxDecoration(
                              color: AppColors.nurseryTint,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _categoryEmoji(plant.category),
                                style: const TextStyle(fontSize: 44),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plant.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.dark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  plant.category,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rs ${plant.price.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.nurseryAccent,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.soft,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${plant.quantity} left',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),

            // Categories section
            const Text(
              'Shop by Category',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _categoryChip(context, 'Indoor', '🪴'),
                _categoryChip(context, 'Outdoor', '🌳'),
                _categoryChip(context, 'Fruit Trees', '🍊'),
                _categoryChip(context, 'Flowering', '🌸'),
                _categoryChip(context, 'Succulents', '🌵'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickNav(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color tint,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _categoryChip(BuildContext context, String category, String emoji) =>
      GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => BrowsePlantsScreen(initialCategory: category),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                category,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
      );

  String _categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'indoor':
        return '🪴';
      case 'outdoor':
        return '🌳';
      case 'fruit trees':
        return '🍊';
      case 'flowering':
        return '🌸';
      case 'succulents':
        return '🌵';
      default:
        return '🌿';
    }
  }
}

class _CommunityExploreTab extends StatelessWidget {
  const _CommunityExploreTab();
  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final isGuest = auth.isGuest || (auth.profile?.isGuest ?? false);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Grower Community')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.communityTint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.handshake_rounded,
                      color: AppColors.communityAccent, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agricultural Community',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Connecting landowners, skilled farmers, and service providers across Pakistan.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.muted, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1. Hire Farmer Card
          _communityActionCard(
            context,
            icon: Icons.groups_rounded,
            title: 'Hire Farmer',
            subtitle: 'Find skilled farmers for your land',
            description:
                'Browse verified growers, view ratings & skills, and send direct hiring requests.',
            tint: AppColors.communityTint,
            accent: AppColors.communityAccent,
            buttonText: 'Browse Farmers',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const HireFarmerLandingScreen(),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Become a Farmer Card
          _communityActionCard(
            context,
            icon: Icons.person_add_alt_1_rounded,
            title: 'Become a Farmer',
            subtitle: 'Offer your farming services',
            description:
                'Register your skills, daily rates, and availability to receive work requests.',
            tint: AppColors.soft,
            accent: AppColors.primary,
            buttonText: 'Register as Farmer',
            onTap: () => ProtectedFeatureNavigation.open(
              context,
              destination: (_) => const BecomeFarmerScreen(),
              loginScreenBuilder: (dest) => LoginScreen(onAuthenticated: dest),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Offer Land Card
          _communityActionCard(
            context,
            icon: Icons.landscape_rounded,
            title: 'Offer a Land',
            subtitle: 'Add new land & manage listings',
            description:
                'List your agricultural acreage, manage your listings, and review incoming farmer applications.',
            tint: AppColors.farmTint,
            accent: AppColors.farmAccent,
            buttonText: 'Offer a Land',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const OfferLandLandingScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          _communityActionCard(
            context,
            icon: Icons.search_rounded,
            title: 'Find Land',
            subtitle: 'Browse available farmland',
            description:
                'Explore land listings and apply for farming opportunities that suit you.',
            tint: AppColors.farmTint,
            accent: AppColors.farmAccent,
            buttonText: 'Browse Land',
            onTap: () => Navigator.pushNamed(context, '/find-land'),
          ),
        ],
      ),
    );
  }

  Widget _communityActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required Color tint,
    required Color accent,
    required String buttonText,
    required VoidCallback onTap,
  }) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
              ),
            ),
          ],
        ),
      );
}
