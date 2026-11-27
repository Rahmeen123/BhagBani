/// Represents a home gardening plant loaded from the plant dataset.
class Plant {
  const Plant({
    required this.name,
    required this.growth,
    required this.soil,
    required this.sunlight,
    required this.watering,
    required this.fertilizationType,
    this.careLevel = 'Regular',
    this.healthSupported = false,
    this.healthLabelPrefix = '',
  });

  final String name;
  final String growth;
  final String soil;
  final String sunlight;
  final String watering;
  final String fertilizationType;
  final String careLevel;
  final bool healthSupported;
  final String healthLabelPrefix;

  /// Parses a CSV row map into a [Plant] instance.
  factory Plant.fromCsvRow(Map<String, String> row) {
    String readField(String key) {
      final value = (row[key] ?? '').trim();
      if (value.isEmpty) {
        throw FormatException('Missing "$key" value in plant dataset.');
      }
      return value;
    }

    return Plant(
      name: readField('Plant Name'),
      growth: readField('Growth'),
      soil: readField('Soil'),
      sunlight: readField('Sunlight'),
      watering: readField('Watering'),
      fertilizationType: readField('Fertilization Type'),
      careLevel: _careLevelForWatering(readField('Watering')),
    );
  }

  factory Plant.fromCleanCsvRow(Map<String, String> row) {
    String readField(String key) {
      final value = (row[key] ?? '').trim();
      if (value.isEmpty && key != 'health_label_prefix') {
        throw FormatException('Missing "$key" value in cleaned plant dataset.');
      }
      return value;
    }

    final healthSupported =
        switch (readField('health_supported').toLowerCase()) {
      'true' => true,
      'false' => false,
      _ => throw const FormatException(
          'Invalid health_supported value in cleaned plant dataset.',
        ),
    };

    return Plant(
      name: readField('name'),
      growth: readField('growth'),
      soil: readField('soil'),
      sunlight: readField('sunlight'),
      watering: readField('watering_text'),
      fertilizationType: readField('fertilization'),
      careLevel: readField('care_level'),
      healthSupported: healthSupported,
      healthLabelPrefix: readField('health_label_prefix'),
    );
  }

  static String _careLevelForWatering(String watering) =>
      switch (watering.trim().toLowerCase()) {
        'water when soil is dry' ||
        'let soil dry between watering' ||
        'water when topsoil is dry' ||
        'water when soil feels dry' =>
          'Low',
        'water weekly' ||
        'regular watering' ||
        'regular, well-drained soil' ||
        'keep soil slightly moist' =>
          'Regular',
        'keep soil moist' ||
        'keep soil consistently moist' ||
        'keep soil evenly moist' ||
        'regular, moist soil' =>
          'High',
        _ => throw FormatException('Unknown watering instruction: $watering'),
      };
}
