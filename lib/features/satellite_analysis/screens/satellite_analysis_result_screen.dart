import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/land_analysis_result.dart';
import '../widgets/analysis_metric_card.dart';

class SatelliteAnalysisResultScreen extends StatelessWidget {
  const SatelliteAnalysisResultScreen({
    super.key,
    required this.result,
  });

  final LandAnalysisResult result;

  String _percentage(double? value) =>
      value == null ? '--' : '${value.toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final condition = result.isInconclusive
        ? 'Inconclusive analysis'
        : (result.vegetationPercentage ?? 0) > 0
            ? 'Vegetation detected'
            : 'Low vegetation detected';
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Land Analysis')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color:
                    result.isInconclusive ? AppColors.farmTint : AppColors.soft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    result.isInconclusive
                        ? Icons.info_outline_rounded
                        : Icons.eco_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          condition,
                          style: const TextStyle(
                            color: AppColors.dark,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          result.message ??
                              (result.isInconclusive
                                  ? 'Satellite data was unavailable or too cloudy to assess this boundary. Try another date range.'
                                  : 'These estimates describe vegetation and surface conditions, not specific crops or plantation identification.'),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
              children: [
                AnalysisMetricCard(
                  title: 'Vegetation Coverage',
                  value: _percentage(result.vegetationPercentage),
                  description: 'Vegetation detected by NDVI',
                  icon: Icons.grass_rounded,
                  tint: AppColors.soft,
                  iconColor: AppColors.primary,
                ),
                AnalysisMetricCard(
                  title: 'Bare Land',
                  value: _percentage(result.bareLandPercentage),
                  description: 'Low NDVI surface estimate',
                  icon: Icons.landscape_rounded,
                  tint: AppColors.farmTint,
                  iconColor: AppColors.farmAccent,
                ),
                AnalysisMetricCard(
                  title: 'Cloud Coverage',
                  value: _percentage(result.cloudPercentage),
                  description: 'Cloud-obscured pixels',
                  icon: Icons.cloud_outlined,
                  tint: AppColors.gardenTint,
                  iconColor: AppColors.gardenAccent,
                ),
                AnalysisMetricCard(
                  title: 'Land Condition',
                  value: condition,
                  description: result.averageNdvi == null
                      ? 'No reliable observation'
                      : 'Average NDVI ${result.averageNdvi!.toStringAsFixed(2)}',
                  icon: Icons.park_outlined,
                  tint: AppColors.nurseryTint,
                  iconColor: AppColors.nurseryAccent,
                ),
              ],
            ),
            if (result.observationDate != null) ...[
              const SizedBox(height: 16),
              Text(
                'Observation date: ${_formatDate(result.observationDate!)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
