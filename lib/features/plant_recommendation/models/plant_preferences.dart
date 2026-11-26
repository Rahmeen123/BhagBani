/// User-friendly sunlight placement choices mapped to internal dataset terms.
enum SunlightPreference {
  fullSun(
    emoji: '☀️',
    title: 'Full Sun',
    description: 'Open area with 6+ hours of direct sunlight',
    internalLabel: 'Direct Sunlight',
    datasetValue: 'full sunlight',
  ),
  partialSun(
    emoji: '🌤',
    title: 'Partial Sun',
    description: 'Some sunlight during the day',
    internalLabel: 'Partial Sunlight',
    datasetValue: 'partial sunlight',
  ),
  lowLight(
    emoji: '🌥',
    title: 'Low Light',
    description: 'Indoor area with little sunlight',
    internalLabel: 'Low/Indirect Sunlight',
    datasetValue: 'indirect sunlight',
  );

  const SunlightPreference({
    required this.emoji,
    required this.title,
    required this.description,
    required this.internalLabel,
    required this.datasetValue,
  });

  final String emoji;
  final String title;
  final String description;
  final String internalLabel;
  final String datasetValue;
}

/// User-friendly care/watering effort levels mapped to internal requirements.
enum WateringPreference {
  lowCare(
    emoji: '💧',
    title: 'Low Care',
    description: 'I can water occasionally',
    internalLabel: 'Low Water Requirement',
  ),
  regularCare(
    emoji: '💧',
    title: 'Regular Care',
    description: 'I can water every few days',
    internalLabel: 'Medium Watering',
  ),
  highCare(
    emoji: '💧',
    title: 'High Care',
    description: 'I can water frequently',
    internalLabel: 'High Water Requirement',
  );

  const WateringPreference({
    required this.emoji,
    required this.title,
    required this.description,
    required this.internalLabel,
  });

  final String emoji;
  final String title;
  final String description;
  final String internalLabel;
}

/// Optional soil types supported by the plant dataset.
enum PlantSoilType {
  wellDrained(label: 'Well-Drained', datasetValue: 'well-drained'),
  loamy(label: 'Loamy', datasetValue: 'loamy'),
  sandy(label: 'Sandy', datasetValue: 'sandy'),
  moist(label: 'Moist', datasetValue: 'moist'),
  acidic(label: 'Acidic', datasetValue: 'acidic');

  const PlantSoilType({
    required this.label,
    required this.datasetValue,
  });

  final String label;
  final String datasetValue;
}

/// Optional growth speed preference.
enum GrowthPreference {
  fastGrowing(label: 'Fast Growing', datasetValue: 'fast'),
  slowGrowing(label: 'Slow Growing', datasetValue: 'slow'),
  noPreference(label: 'No Preference', datasetValue: null);

  const GrowthPreference({
    required this.label,
    required this.datasetValue,
  });

  final String label;
  final String? datasetValue;
}

/// Captures the gardener's plant preference form inputs.
class PlantPreferences {
  const PlantPreferences({
    required this.sunlight,
    required this.watering,
    this.soilType,
    this.growth = GrowthPreference.noPreference,
  });

  final SunlightPreference sunlight;
  final WateringPreference watering;
  final PlantSoilType? soilType;
  final GrowthPreference growth;
}

