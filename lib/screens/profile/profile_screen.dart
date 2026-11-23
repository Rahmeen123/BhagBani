import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../navigation/protected_feature_navigation.dart';
import '../../providers/auth_scope.dart';
import '../../widgets/primary_button.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../help/help_guide_screen.dart';
import '../notifications/notifications_screen.dart';
import '../nursery/my_orders_screen.dart';
import '../nursery/nursery_gate_screen.dart';
import '../nursery/wishlist_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.profile;
    final isGuest = auth.isGuest || (user?.isGuest ?? false);
    final name = isGuest ? 'Guest User' : (user?.name ?? 'Farmer / Gardener');
    final email = isGuest ? 'Browsing without an account' : (user?.email ?? '');

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('My Profile'),
        actions: [
          if (!isGuest)
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const EditProfileScreen(),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, color: AppColors.dark),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: isGuest ? AppColors.farmTint : AppColors.soft,
                      child: Text(
                        isGuest ? 'G' : (name.isEmpty ? 'B' : name[0].toUpperCase()),
                        style: TextStyle(
                          color: isGuest ? AppColors.farmAccent : AppColors.primary,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isGuest)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.farmAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline, size: 14, color: Colors.white),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13.5),
                ),
                const SizedBox(height: 10),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isGuest ? AppColors.farmTint : AppColors.soft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isGuest ? 'Guest Access' : 'Verified Member',
                    style: TextStyle(
                      color: isGuest ? AppColors.farmAccent : AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Guest Banner if in Guest Mode
          if (isGuest) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.farmTint.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.farmAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.farmAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Save your progress',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create an account or sign in to save your land boundaries, plantation plans, and wishlist.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Create Account',
                          height: 42,
                          borderRadius: 14,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(builder: (_) => const SignupScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Log In',
                          outlined: true,
                          height: 42,
                          borderRadius: 14,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Details List
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                _detailTile(
                  icon: Icons.phone_outlined,
                  label: 'Phone number',
                  value: isGuest ? 'Add phone after sign up' : (user?.phone ?? 'Not set'),
                  tint: AppColors.nurseryTint,
                  accent: AppColors.primary,
                  showDivider: true,
                ),
                _detailTile(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: isGuest ? 'Pakistan' : (user?.location ?? 'Not set'),
                  tint: AppColors.communityTint,
                  accent: AppColors.communityAccent,
                  showDivider: true,
                ),
                _detailTile(
                  icon: Icons.storefront_rounded,
                  label: 'My Nursery',
                  value: 'Manage your registered nursery',
                  tint: AppColors.nurseryTint,
                  accent: AppColors.nurseryAccent,
                  showDivider: true,
                  onTap: () => ProtectedFeatureNavigation.open(
                    context,
                    destination: (_) => const NurseryGateScreen(),
                    loginScreenBuilder: (dest) => LoginScreen(onAuthenticated: dest),
                  ),
                ),
                _detailTile(
                  icon: Icons.receipt_long_rounded,
                  label: 'My Plant Orders',
                  value: 'Track your plant pickup orders',
                  tint: AppColors.gardenTint,
                  accent: AppColors.gardenAccent,
                  showDivider: true,
                  onTap: () => ProtectedFeatureNavigation.open(
                    context,
                    destination: (_) => const MyOrdersScreen(),
                    loginScreenBuilder: (dest) => LoginScreen(onAuthenticated: dest),
                  ),
                ),
                _detailTile(
                  icon: Icons.favorite_rounded,
                  label: 'My Wishlist',
                  value: 'Plants you saved for later',
                  tint: const Color(0xFFFFEBEE),
                  accent: const Color(0xFFE53935),
                  showDivider: true,
                  onTap: () => ProtectedFeatureNavigation.open(
                    context,
                    destination: (_) => const WishlistScreen(),
                    loginScreenBuilder: (dest) => LoginScreen(onAuthenticated: dest),
                  ),
                ),
                _detailTile(
                  icon: Icons.menu_book_outlined,
                  label: 'Help & Guides',
                  value: 'How Baghbani works & farming tips',
                  tint: AppColors.gardenTint,
                  accent: AppColors.gardenAccent,
                  showDivider: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const HelpGuideScreen()),
                  ),
                ),
                _detailTile(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  value: 'App alerts and season updates',
                  tint: AppColors.farmTint,
                  accent: AppColors.farmAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Action Buttons
          if (!isGuest) ...[
            PrimaryButton(
              label: 'Edit Profile',
              icon: Icons.edit_outlined,
              outlined: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const EditProfileScreen()),
              ),
            ),
            const SizedBox(height: 12),
          ],
          PrimaryButton(
            label: isGuest ? 'Exit Guest Mode' : 'Sign out',
            icon: Icons.logout_rounded,
            outlined: true,
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => const LoginScreen(),
                  ),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _detailTile({
    required IconData icon,
    required String label,
    required String value,
    required Color tint,
    required Color accent,
    bool showDivider = false,
    VoidCallback? onTap,
  }) => Column(
    children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
      if (showDivider)
        const Divider(color: AppColors.border, height: 1, indent: 18, endIndent: 18),
    ],
  );
}
