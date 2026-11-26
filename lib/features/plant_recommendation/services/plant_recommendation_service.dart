import '../data/plant_local_names.dart';
import '../models/plant.dart';
import '../models/plant_preferences.dart';
import '../models/plant_recommendation.dart';

/// Scoring-based home plant matching engine (non-ML).
class PlantRecommendationService {
  static const int _sunlightWeight = 45;
  static const int _wateringWeight = 45;
  static const int _soilWeight = 5;
  static const int _growthWeight = 5;
  static const int _maxResults = 5;

  static const Map<String, WateringPreference> _wateringMapping = {
    'water weekly': WateringPreference.lowCare,
    'water when soil is dry': WateringPreference.lowCare,
    'let soil dry between watering': WateringPreference.lowCare,
    'water when topsoil is dry': WateringPreference.lowCare,
    'water when soil feels dry': WateringPreference.lowCare,
    'regular, well-drained soil': WateringPreference.regularCare,
    'regular watering': WateringPreference.regularCare,
    'keep soil slightly moist': WateringPreference.regularCare,
    'regular, moist soil': WateringPreference.highCare,
    'keep soil moist': WateringPreference.highCare,
    'keep soil consistently moist': WateringPreference.highCare,
    'keep soil evenly moist': WateringPreference.highCare,
  };

  /// Scores [plants] against [preferences] and returns up to the top 5
  /// distinct plant recommendations ordered from highest to lowest score.
  List<PlantRecommendation> recommend({
    required List<Plant> plants,
    required PlantPreferences preferences,
  }) {
    final bestByName = <String, _ScoredPlant>{};

    for (var index = 0; index < plants.length; index++) {
      final plant = plants[index];
      final sunlightMatched =
          normalizeSunlight(plant.sunlight) == preferences.sunlight;
      final wateringMatched =
          classifyWatering(plant.watering) == preferences.watering;

      // Sunlight and watering are highest-priority core requirements.
      if (!sunlightMatched || !wateringMatched) {
        continue;
      }

      var score = _sunlightWeight + _wateringWeight;

      final soilMatched = preferences.soilType != null &&
          plant.soil.trim().toLowerCase() ==
              preferences.soilType!.datasetValue;
      if (soilMatched) {
        score += _soilWeight;
      }

      final growthScore = _scoreGrowth(plant.growth, preferences.growth);
      score += growthScore;

      final normalizedName = plant.name.trim().toLowerCase();
      final existing = bestByName[normalizedName];
      if (existing == null || score > existing.score) {
        final localName = PlantLocalNames.resolve(plant.name);
        bestByName[normalizedName] = _ScoredPlant(
          recommendation: PlantRecommendation(
            plant: plant,
            easyName: localName.easyName,
            urduName: localName.urduName,
            matchPercentage: score.clamp(0, 100),
            reasons: _buildReasons(
              plant: plant,
              preferences: preferences,
              soilMatched: soilMatched,
              growthMatched:
                  preferences.growth != GrowthPreference.noPreference &&
                      growthScore == _growthWeight,
            ),
            careTips: buildCareTips(plant),
          ),
          score: score,
          originalIndex: existing?.originalIndex ?? index,
        );
      }
    }

    final ranked = bestByName.values.toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return a.originalIndex.compareTo(b.originalIndex);
      });

    return ranked
        .take(_maxResults)
        .map((entry) => entry.recommendation)
        .toList(growable: false);
  }

  /// Maps dataset sunlight text to [SunlightPreference].
  static SunlightPreference? normalizeSunlight(String rawSunlight) {
    final value = rawSunlight.trim().toLowerCase();
    for (final option in SunlightPreference.values) {
      if (option.datasetValue == value) return option;
    }
    if (value.contains('full') || value.contains('direct')) {
      return SunlightPreference.fullSun;
    }
    if (value.contains('partial')) {
      return SunlightPreference.partialSun;
    }
    if (value.contains('indirect') || value.contains('low')) {
      return SunlightPreference.lowLight;
    }
    return null;
  }

  /// Maps dataset watering instructions to [WateringPreference].
  static WateringPreference classifyWatering(String rawWatering) {
    final value = rawWatering.trim().toLowerCase();
    final exact = _wateringMapping[value];
    if (exact != null) return exact;

    if (value.contains('dry') || value.contains('weekly')) {
      return WateringPreference.lowCare;
    }
    if (value.contains('consistently') ||
        value.contains('evenly') ||
        value == 'keep soil moist' ||
        value == 'regular, moist soil') {
      return WateringPreference.highCare;
    }
    return WateringPreference.regularCare;
  }

  static int _scoreGrowth(String rawGrowth, GrowthPreference preference) {
    final target = preference.datasetValue;
    if (target == null) return _growthWeight;
    final actual = rawGrowth.trim().toLowerCase();
    if (actual == target) return _growthWeight;
    if (actual == 'moderate') return 2;
    return 0;
  }

  static List<String> _buildReasons({
    required Plant plant,
    required PlantPreferences preferences,
    required bool soilMatched,
    required bool growthMatched,
  }) {
    final reasons = <String>[
      switch (preferences.sunlight) {
        SunlightPreference.fullSun => 'Suitable for full sun spots',
        SunlightPreference.partialSun => 'Thrives in partial sunlight',
        SunlightPreference.lowLight => 'Suitable for low light',
      },
      switch (preferences.watering) {
        WateringPreference.lowCare => 'Requires less watering',
        WateringPreference.regularCare => 'Fits a regular watering routine',
        WateringPreference.highCare => 'Thrives with frequent watering',
      },
    ];

    if (soilMatched && preferences.soilType != null) {
      reasons.add('Matches your ${preferences.soilType!.label.toLowerCase()} soil');
    } else if (growthMatched) {
      reasons.add('Matches your ${preferences.growth.label.toLowerCase()} goal');
    } else if (plant.fertilizationType.trim().toLowerCase() == 'no' ||
        preferences.watering == WateringPreference.lowCare) {
      reasons.add('Easy to maintain');
    } else {
      reasons.add('Grows well in ${plant.soil.trim().toLowerCase()} soil');
    }

    return reasons;
  }

  /// Formats dataset sunlight value for display on the detail screen.
  static String formatSunlightLabel(String rawSunlight) {
    final normalized = normalizeSunlight(rawSunlight);
    return normalized?.internalLabel ?? _titleCase(rawSunlight);
  }

  /// Formats dataset growth value for display.
  static String formatGrowthLabel(String rawGrowth) {
    return switch (rawGrowth.trim().toLowerCase()) {
      'fast' => 'Fast Growing',
      'moderate' => 'Moderate Growth',
      'slow' => 'Slow Growing',
      _ => _titleCase(rawGrowth),
    };
  }

  /// Formats dataset soil value for display.
  static String formatSoilLabel(String rawSoil) {
    return switch (rawSoil.trim().toLowerCase()) {
      'well-drained' => 'Well-Drained Soil',
      'loamy' => 'Loamy Soil',
      'sandy' => 'Sandy Soil',
      'moist' => 'Moist Soil',
      'acidic' => 'Acidic Soil',
      _ => _titleCase(rawSoil),
    };
  }

  /// Formats dataset fertilization value for display.
  static String formatFertilizationLabel(String rawFertilization) {
    final trimmed = rawFertilization.trim();
    if (trimmed.toLowerCase() == 'no') {
      return 'Minimal / Not Required';
    }
    return '$trimmed Fertilizer';
  }

  /// Generates practical, plain-language care tips for [plant].
  static List<String> buildCareTips(Plant plant) {
    final sunlightTip = switch (normalizeSunlight(plant.sunlight)) {
      SunlightPreference.fullSun =>
        'Place in an open sunny spot or bright balcony with 6+ hours of direct sunlight.',
      SunlightPreference.partialSun =>
        'Keep in bright morning sun or dappled shade away from harsh afternoon heat.',
      SunlightPreference.lowLight =>
        'Position indoors near a shaded window or bright room without harsh direct sun.',
      null => 'Provide ${plant.sunlight.trim().toLowerCase()} for steady growth.',
    };

    final wateringTip = switch (classifyWatering(plant.watering)) {
      WateringPreference.lowCare =>
        '${plant.watering.trim()} — avoid overwatering by letting excess water drain completely.',
      WateringPreference.regularCare =>
        '${plant.watering.trim()} — check the top inch of soil every few days before watering.',
      WateringPreference.highCare =>
        '${plant.watering.trim()} — mist or water consistently so the soil stays evenly hydrated.',
    };

    final soilTip =
        'Plant in ${formatSoilLabel(plant.soil).toLowerCase()} with drainage holes in the pot.';

    final fertRaw = plant.fertilizationType.trim().toLowerCase();
    final fertilizationTip = fertRaw == 'no'
        ? 'No heavy feeding needed — a light seasonal compost top-up is plenty.'
        : 'Feed during active growing months with ${plant.fertilizationType.trim().toLowerCase()} fertilizer.';

    return [sunlightTip, wateringTip, soilTip, fertilizationTip];
  }

  static String _titleCase(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    return words
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

class _ScoredPlant {
  const _ScoredPlant({
    required this.recommendation,
    required this.score,
    required this.originalIndex,
  });

  final PlantRecommendation recommendation;
  final int score;
  final int originalIndex;
}

