import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/plant.dart';
import '../models/plant_preferences.dart';
import '../services/plant_recommendation_service.dart';

/// Shared page scaffold matching the Baghbani Figma design system.
class PlantScreenScaffold extends StatelessWidget {
  const PlantScreenScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          top: false,
          child: child,
        ),
      );
}

/// Shared rounded surface container matching [TreeInfoCard] and dashboard cards.
class PlantInfoCard extends StatelessWidget {
  const PlantInfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: child,
      );
}

/// Minimal botanical visual used as the plant card/hero image across screens.
class PlantVisualAvatar extends StatelessWidget {
  const PlantVisualAvatar({
    super.key,
    required this.plant,
    this.size = 76,
    this.borderRadius = 18,
  });

  final Plant plant;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final sunlight = PlantRecommendationService.normalizeSunlight(plant.sunlight);
    final isLowLight = sunlight == SunlightPreference.lowLight;
    final isFullSun = sunlight == SunlightPreference.fullSun;
    final background = isFullSun
        ? AppColors.farmTint
        : isLowLight
            ? AppColors.soft
            : AppColors.gardenTint;
    final accent = isFullSun
        ? AppColors.farmAccent
        : isLowLight
            ? AppColors.primary
            : AppColors.gardenAccent;
    final icon = isFullSun
        ? Icons.wb_sunny_outlined
        : isLowLight
            ? Icons.eco_rounded
            : Icons.local_florist_rounded;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.local_florist_rounded,
            size: size * 0.54,
            color: accent,
          ),
          Positioned(
            right: size * 0.1,
            bottom: size * 0.1,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: size * 0.16,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable preference option card with icon/emoji, title, and plain-text subtitle.
class PlantPreferenceOptionCard extends StatelessWidget {
  const PlantPreferenceOptionCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.emoji,
    this.subtitle,
  });

  final String title;
  final String? emoji;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? AppColors.soft : AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                if (emoji != null) ...[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.white : AppColors.gardenTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        emoji!,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
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
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.muted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? AppColors.primary : AppColors.muted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      );
}
