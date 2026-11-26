import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/primary_button.dart';
import '../widgets/crop_feature_card.dart';
import 'crop_location_screen.dart';

class CropRecommendationIntroScreen extends StatelessWidget {
  const CropRecommendationIntroScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(title: const Text('Crop Recommendation')),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Container(
                height: 190,
                decoration: BoxDecoration(
                  color: AppColors.farmTint,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.agriculture_rounded,
                  color: AppColors.farmAccent,
                  size: 86,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Find crops suited to your farm',
                style: TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'We combine your farm location with local weather conditions '
                'to suggest suitable field crops.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 22),
              const CropFeatureCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IntroPoint(
                      icon: Icons.map_outlined,
                      text: 'Select your farm on the map',
                    ),
                    SizedBox(height: 14),
                    _IntroPoint(
                      icon: Icons.cloud_outlined,
                      text: 'Use current NASA weather conditions',
                    ),
                    SizedBox(height: 14),
                    _IntroPoint(
                      icon: Icons.grass_rounded,
                      text: 'Compare the top three crop recommendations',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Get started',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CropLocationScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _IntroPoint extends StatelessWidget {
  const _IntroPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 21, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.dark,
                height: 1.35,
              ),
            ),
          ),
        ],
      );
}
