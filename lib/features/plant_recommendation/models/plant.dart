/// Represents a home gardening plant loaded from the plant dataset.
class Plant {
  const Plant({
    required this.name,
    required this.growth,
    required this.soil,
    required this.sunlight,
    required this.watering,
    required this.fertilizationType,
  });

  final String name;
  final String growth;
  final String soil;
  final String sunlight;
  final String watering;
  final String fertilizationType;

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
    );
  }
}

