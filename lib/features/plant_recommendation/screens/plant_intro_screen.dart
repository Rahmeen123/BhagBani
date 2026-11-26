import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../navigation/protected_feature_navigation.dart';
import '../../../screens/auth/login_screen.dart';
import '../../../widgets/primary_button.dart';
import '../widgets/plant_widgets.dart';
import 'plant_preference_screen.dart';

class PlantIntroScreen extends StatelessWidget {
  const PlantIntroScreen({super.key});

  @override
  Widget build(BuildContext context) => PlantScreenScaffold(
        title: 'Plant Recommendation',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Container(
              height: 190,
              decoration: BoxDecoration(
                color: AppColors.gardenTint,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Icon(
                  Icons.local_florist_rounded,
                  color: AppColors.gardenAccent,
                  size: 86,
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Find the right plants for your home',
              style: TextStyle(
                fontSize: 24,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Answer a few simple questions about sunlight and watering, and we will recommend home plants that thrive in your space.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 22),
            const PlantInfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IntroHighlight(
                    icon: Icons.wb_sunny_outlined,
                    text: 'Choose where you will place your plant at home',
                  ),
                  SizedBox(height: 14),
                  _IntroHighlight(
                    icon: Icons.water_drop_outlined,
                    text: 'Pick how often you are comfortable watering',
                  ),
                  SizedBox(height: 14),
                  _IntroHighlight(
                    icon: Icons.eco_outlined,
                    text: 'Optional soil and growth preferences for a closer fit',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Get Started',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => ProtectedFeatureNavigation.open(
                context,
                destination: (_) => const PlantPreferenceScreen(),
                loginScreenBuilder: (destination) =>
                    LoginScreen(onAuthenticated: destination),
              ),
            ),
          ],
        ),
      );
}

class _IntroHighlight extends StatelessWidget {
  const _IntroHighlight({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 21, color: AppColors.gardenAccent),
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
