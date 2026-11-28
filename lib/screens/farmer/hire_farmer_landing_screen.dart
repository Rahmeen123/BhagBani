import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import 'farmer_listing_screen.dart';

class HireFarmerLandingScreen extends StatelessWidget {
  const HireFarmerLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Hire Farmer'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 32),
          children: [
            // Hero Illustration / Icon Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.communityTint,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.handshake_rounded,
                          color: AppColors.communityAccent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Find Experienced Farmers',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Connect with skilled farmers for your land management needs.',
                        style: TextStyle(
                          color: AppColors.sageLight,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Value Highlights
            const Text(
              'Why hire through Baghbani?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 14),

            _valuePropTile(
              icon: Icons.verified_user_outlined,
              title: 'Verified Local Growers',
              description: 'Farmers evaluated on past agricultural experience and skill expertise.',
              tint: AppColors.soft,
              accent: AppColors.primary,
            ),
            const SizedBox(height: 10),

            _valuePropTile(
              icon: Icons.agriculture_outlined,
              title: 'All Farming Disciplines',
              description: 'From crop planting & canal irrigation to fruit orchards and tractor tillage.',
              tint: AppColors.farmTint,
              accent: AppColors.farmAccent,
            ),
            const SizedBox(height: 10),

            _valuePropTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Direct Contact',
              description: 'Call or WhatsApp farmers directly without middlemen or hidden commission.',
              tint: AppColors.communityTint,
              accent: AppColors.communityAccent,
            ),
            const SizedBox(height: 32),

            // Main Action Button
            PrimaryButton(
              label: 'Browse Farmers',
              icon: Icons.search_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const FarmerListingScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _valuePropTile({
    required IconData icon,
    required String title,
    required String description,
    required Color tint,
    required Color accent,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
