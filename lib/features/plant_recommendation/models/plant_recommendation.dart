import 'plant.dart';

/// A plant recommendation with localized names and practical care tips.
class PlantRecommendation {
  const PlantRecommendation({
    required this.plant,
    required this.easyName,
    required this.urduName,
    required this.careTips,
  });

  final Plant plant;
  final String easyName;
  final String urduName;
  final List<String> careTips;
}
