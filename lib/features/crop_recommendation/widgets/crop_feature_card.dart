import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/crop_recommendation_result.dart';

class CropFeatureCard extends StatelessWidget {
  const CropFeatureCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: child,
      );
}

class CropWeatherCard extends StatelessWidget {
  const CropWeatherCard({super.key, required this.weather});

  final CropWeather weather;

  @override
  Widget build(BuildContext context) => CropFeatureCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current weather',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _WeatherValue(
                  icon: Icons.thermostat_rounded,
                  label: 'Temperature',
                  value: '${weather.temperature.toStringAsFixed(1)} °C',
                ),
                _WeatherValue(
                  icon: Icons.water_drop_outlined,
                  label: 'Rainfall',
                  value: '${weather.rainfall.toStringAsFixed(1)} mm',
                ),
                _WeatherValue(
                  icon: Icons.water_rounded,
                  label: 'Humidity',
                  value: weather.humidity == null
                      ? 'Unavailable'
                      : '${weather.humidity!.toStringAsFixed(0)}%',
                ),
              ],
            ),
          ],
        ),
      );
}

class _WeatherValue extends StatelessWidget {
  const _WeatherValue({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      );
}

class CropPredictionCard extends StatelessWidget {
  const CropPredictionCard({
    super.key,
    required this.cropName,
    required this.confidencePercentage,
  });

  final String cropName;
  final double confidencePercentage;

  @override
  Widget build(BuildContext context) {
    final confidence = confidencePercentage % 1 == 0
        ? confidencePercentage.toStringAsFixed(0)
        : confidencePercentage.toStringAsFixed(1);
    return CropFeatureCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.farmTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: AppColors.farmAccent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cropName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confidence: $confidence%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Suitable based on current climate conditions.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
