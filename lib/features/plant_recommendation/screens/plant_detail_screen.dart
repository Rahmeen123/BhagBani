import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/plant_recommendation.dart';
import '../services/plant_recommendation_service.dart';
import '../widgets/plant_widgets.dart';

class PlantDetailScreen extends StatelessWidget {
  const PlantDetailScreen({
    super.key,
    required this.recommendation,
  });

  final PlantRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final plant = recommendation.plant;
    return PlantScreenScaffold(
      title: 'Plant Details',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Stack(
              children: [
                Center(
                  child: PlantVisualAvatar(
                    plant: plant,
                    size: 112,
                    borderRadius: 28,
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.soft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${recommendation.matchPercentage}% Match',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            plant.name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${recommendation.easyName}  •  ${recommendation.urduName}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 16),

          // Plant Requirements Card
          PlantInfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Growing Requirements',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 14),
                _DetailRow(label: 'Plant Name', value: plant.name),
                _DetailRow(label: 'Common / Easy Name', value: recommendation.easyName),
                _DetailRow(label: 'Urdu Name (اردو نام)', value: recommendation.urduName),
                _DetailRow(
                  label: 'Growth Type',
                  value: PlantRecommendationService.formatGrowthLabel(
                    plant.growth,
                  ),
                ),
                _DetailRow(
                  label: 'Soil Requirement',
                  value: PlantRecommendationService.formatSoilLabel(
                    plant.soil,
                  ),
                ),
                _DetailRow(
                  label: 'Sunlight Requirement',
                  value: PlantRecommendationService.formatSunlightLabel(
                    plant.sunlight,
                  ),
                ),
                _DetailRow(
                  label: 'Watering Requirement',
                  value: plant.watering,
                ),
                _DetailRow(
                  label: 'Fertilization Type',
                  value: PlantRecommendationService.formatFertilizationLabel(
                    plant.fertilizationType,
                  ),
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Care Tips Section
          PlantInfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Care Tips',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < recommendation.careTips.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == recommendation.careTips.length - 1 ? 0 : 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.soft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            recommendation.careTips[i],
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.dark,
                              height: 1.45,
                            ),
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
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ),
          ],
        ),
      );
}
