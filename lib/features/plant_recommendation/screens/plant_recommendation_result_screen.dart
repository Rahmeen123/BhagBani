import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/primary_button.dart';
import '../models/plant_preferences.dart';
import '../models/plant_recommendation.dart';
import '../repositories/plant_repository.dart';
import '../services/plant_recommendation_service.dart';
import '../widgets/plant_widgets.dart';
import 'plant_detail_screen.dart';

class PlantRecommendationResultScreen extends StatefulWidget {
  PlantRecommendationResultScreen({
    super.key,
    required this.preferences,
    PlantRepository? repository,
    PlantRecommendationService? service,
  })  : repository = repository ?? PlantRepository(),
        service = service ?? PlantRecommendationService();

  final PlantPreferences preferences;
  final PlantRepository repository;
  final PlantRecommendationService service;

  @override
  State<PlantRecommendationResultScreen> createState() =>
      _PlantRecommendationResultScreenState();
}

class _PlantRecommendationResultScreenState
    extends State<PlantRecommendationResultScreen> {
  bool _loading = true;
  String? _error;
  List<PlantRecommendation> _recommendations = const [];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final plants = await widget.repository.getPlants();
      final results = widget.service.recommend(
        plants: plants,
        preferences: widget.preferences,
      );
      if (!mounted) return;
      setState(() {
        _recommendations = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'We could not load the plant guide right now. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => PlantScreenScaffold(
        title: 'Recommended Plants',
        child: _loading
            ? const _LoadingView()
            : _error != null
                ? _ErrorView(
                    message: _error!,
                    onRetry: () {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      _loadRecommendations();
                    },
                  )
                : _recommendations.isEmpty
                    ? _EmptyResultsView(
                        onAdjust: () => Navigator.pop(context),
                      )
                    : _ResultsListView(
                        preferences: widget.preferences,
                        recommendations: _recommendations,
                      ),
      );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 20),
              Text(
                'Finding your best plant matches...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Matching home plants to your light and watering routine.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 52,
                color: AppColors.muted,
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.dark, height: 1.45),
              ),
              const SizedBox(height: 18),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
}

class _EmptyResultsView extends StatelessWidget {
  const _EmptyResultsView({required this.onAdjust});

  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.gardenTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_florist_outlined,
                  size: 44,
                  color: AppColors.gardenAccent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No matching plants found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try picking another light or watering option to discover suitable plants for your garden.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Adjust Preferences',
                onPressed: onAdjust,
              ),
            ],
          ),
        ),
      );
}

class _ResultsListView extends StatelessWidget {
  const _ResultsListView({
    required this.preferences,
    required this.recommendations,
  });

  final PlantPreferences preferences;
  final List<PlantRecommendation> recommendations;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gardenTint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Garden Profile',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PreferencePill(
                      text:
                          '${preferences.sunlight.emoji} ${preferences.sunlight.title}',
                    ),
                    _PreferencePill(
                      text:
                          '${preferences.watering.emoji} ${preferences.watering.title}',
                    ),
                    if (preferences.soilType != null)
                      _PreferencePill(
                        text: 'Soil: ${preferences.soilType!.label}',
                      ),
                    if (preferences.growth != GrowthPreference.noPreference)
                      _PreferencePill(
                        text: preferences.growth.label,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Top ${recommendations.length} Recommended ${recommendations.length == 1 ? 'Plant' : 'Plants'}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ranked by how closely each plant fits your light and care routine.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          for (final recommendation in recommendations)
            _PlantRecommendationCard(
              recommendation: recommendation,
              onViewDetails: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PlantDetailScreen(
                    recommendation: recommendation,
                  ),
                ),
              ),
            ),
        ],
      );
}

class _PreferencePill extends StatelessWidget {
  const _PreferencePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
        ),
      );
}

class _PlantRecommendationCard extends StatelessWidget {
  const _PlantRecommendationCard({
    required this.recommendation,
    required this.onViewDetails,
  });

  final PlantRecommendation recommendation;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final plant = recommendation.plant;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlantVisualAvatar(plant: plant, size: 74),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        recommendation.easyName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'اردو نام: ${recommendation.urduName}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Why this plant is recommended:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 6),
            for (final reason in recommendation.reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'View Details',
              outlined: true,
              height: 44,
              borderRadius: 14,
              onPressed: onViewDetails,
            ),
          ],
        ),
      ),
    );
  }
}
