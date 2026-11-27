import '../data/plant_local_names.dart';
import '../models/plant.dart';
import '../models/plant_preferences.dart';
import '../models/plant_recommendation.dart';

/// Exact-filter home plant matching engine (non-ML).
class PlantRecommendationService {
  static const Map<String, WateringPreference> _wateringMapping = {
    'water when soil is dry': WateringPreference.lowCare,
    'let soil dry between watering': WateringPreference.lowCare,
    'water when topsoil is dry': WateringPreference.lowCare,
    'water when soil feels dry': WateringPreference.lowCare,
    'water weekly': WateringPreference.regularCare,
    'regular, well-drained soil': WateringPreference.regularCare,
    'regular watering': WateringPreference.regularCare,
    'keep soil slightly moist': WateringPreference.regularCare,
    'regular, moist soil': WateringPreference.highCare,
    'keep soil moist': WateringPreference.highCare,
    'keep soil consistently moist': WateringPreference.highCare,
    'keep soil evenly moist': WateringPreference.highCare,
  };

  /// Applies exact preference filters and relaxes optional filters in order.
  List<PlantRecommendation> recommend({
    required List<Plant> plants,
    required PlantPreferences preferences,
  }) {
    final sunlightAndCare = plants
        .where(
          (plant) =>
              normalizeSunlight(plant.sunlight) == preferences.sunlight &&
              plant.careLevel.trim().toLowerCase() ==
                  preferences.watering.careLevel.toLowerCase(),
        )
        .toList(growable: false);

    var matches = _applyOptionalFilters(sunlightAndCare, preferences);
    if (matches.isEmpty) {
      matches = _applyOptionalFilters(
        sunlightAndCare,
        preferences,
        includeGrowth: false,
      );
    }
    if (matches.isEmpty && preferences.soilType != null) {
      matches = _applyOptionalFilters(
        sunlightAndCare,
        preferences,
        includeSoil: false,
        includeGrowth: false,
      );
    }
    if (matches.isEmpty) {
      final careLevels = WateringPreference.values
          .map((preference) => preference.careLevel.toLowerCase())
          .toList(growable: false);
      final selectedIndex =
          careLevels.indexOf(preferences.watering.careLevel.toLowerCase());
      final adjacent = <String>{
        if (selectedIndex > 0) careLevels[selectedIndex - 1],
        if (selectedIndex + 1 < careLevels.length)
          careLevels[selectedIndex + 1],
      };
      matches = plants
          .where(
            (plant) =>
                normalizeSunlight(plant.sunlight) == preferences.sunlight &&
                adjacent.contains(plant.careLevel.trim().toLowerCase()),
          )
          .toList(growable: false);
    }

    return matches.map((plant) {
      final localName = PlantLocalNames.resolve(plant.name);
      return PlantRecommendation(
        plant: plant,
        easyName: localName.easyName,
        urduName: localName.urduName,
        careTips: buildCareTips(plant),
      );
    }).toList(growable: false);
  }

  static List<Plant> _applyOptionalFilters(
    List<Plant> plants,
    PlantPreferences preferences, {
    bool includeSoil = true,
    bool includeGrowth = true,
  }) {
    return plants
        .where(
          (plant) =>
              (!includeSoil ||
                  preferences.soilType == null ||
                  plant.soil.trim().toLowerCase() ==
                      preferences.soilType!.datasetValue) &&
              (!includeGrowth ||
                  preferences.growth.datasetValue == null ||
                  plant.growth.trim().toLowerCase() ==
                      preferences.growth.datasetValue),
        )
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

    if (value.contains('dry')) {
      return WateringPreference.lowCare;
    }
    if (value.contains('weekly')) return WateringPreference.regularCare;
    if (value.contains('consistently') ||
        value.contains('evenly') ||
        value == 'keep soil moist' ||
        value == 'regular, moist soil') {
      return WateringPreference.highCare;
    }
    return WateringPreference.regularCare;
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
      null =>
        'Provide ${plant.sunlight.trim().toLowerCase()} for steady growth.',
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
