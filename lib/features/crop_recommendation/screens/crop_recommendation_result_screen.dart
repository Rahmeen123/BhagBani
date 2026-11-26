import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/primary_button.dart';
import '../models/crop_farm_location.dart';
import '../models/crop_recommendation_result.dart';
import '../repository/crop_recommendation_repository.dart';
import '../services/crop_recommendation_api_service.dart';
import '../widgets/crop_feature_card.dart';

class CropRecommendationResultScreen extends StatefulWidget {
  const CropRecommendationResultScreen({
    super.key,
    required this.location,
    this.repository,
  });

  final CropFarmLocation location;
  final CropRecommendationRepository? repository;

  @override
  State<CropRecommendationResultScreen> createState() =>
      _CropRecommendationResultScreenState();
}

class _CropRecommendationResultScreenState
    extends State<CropRecommendationResultScreen> {
  late final CropRecommendationRepository _repository;
  late final bool _ownsRepository;
  CropRecommendationResult? _result;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ownsRepository = widget.repository == null;
    _repository = widget.repository ??
        CropRecommendationRepository(CropRecommendationApiService());
    _loadRecommendations();
  }

  @override
  void dispose() {
    if (_ownsRepository) _repository.close();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repository.recommend(
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
      );
      if (mounted) setState(() => _result = result);
    } on CropRecommendationApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Exception catch (error) {
      debugPrint('Crop recommendation request failed: $error');
      if (mounted) {
        setState(() {
          _error = 'Could not load recommendations. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(title: const Text('Crop Recommendations')),
        body: SafeArea(
          top: false,
          child: _loading
              ? const _LoadingState()
              : _error != null
                  ? _ErrorState(
                      message: _error!,
                      onRetry: _loadRecommendations,
                    )
                  : _SuccessState(
                      location: widget.location.address,
                      weather: _result!.weather,
                      recommendations: _result!.recommendations,
                    ),
        ),
      );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 18),
              Text(
                'Analyzing your land and weather conditions...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
                Icons.cloud_off_outlined,
                color: AppColors.farmAccent,
                size: 48,
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.dark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      );
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({
    required this.location,
    required this.weather,
    required this.recommendations,
  });

  final String location;
  final CropWeather weather;
  final List<CropRecommendation> recommendations;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          CropFeatureCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.farmTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.farmAccent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Farm location',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        location,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CropWeatherCard(weather: weather),
          const SizedBox(height: 22),
          const Text(
            'Top crop recommendations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 12),
          for (final recommendation in recommendations.take(3)) ...[
            CropPredictionCard(
              cropName: recommendation.cropName,
              confidencePercentage: recommendation.confidencePercentage,
            ),
            const SizedBox(height: 10),
          ],
        ],
      );
}
