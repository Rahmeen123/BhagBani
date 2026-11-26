import 'plant.dart';

/// A scored plant recommendation with human-readable match reasons and care tips.
class PlantRecommendation {
  const PlantRecommendation({
    required this.plant,
    required this.easyName,
    required this.urduName,
    required this.matchPercentage,
    required this.reasons,
    required this.careTips,
  });

  final Plant plant;
  final String easyName;
  final String urduName;
  final int matchPercentage;
  final List<String> reasons;
  final List<String> careTips;
}

