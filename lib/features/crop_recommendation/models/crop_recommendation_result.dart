class CropWeather {
  const CropWeather({
    required this.temperature,
    required this.rainfall,
    required this.humidity,
  });

  final double temperature;
  final double rainfall;
  final double? humidity;

  factory CropWeather.fromJson(Map<String, dynamic> json) => CropWeather(
        temperature: _requiredNumber(json, 'temperature'),
        rainfall: _requiredNumber(json, 'rainfall'),
        humidity: _optionalNumber(json, 'humidity'),
      );
}

class CropRecommendation {
  const CropRecommendation({
    required this.cropName,
    required this.confidencePercentage,
  });

  final String cropName;
  final double confidencePercentage;

  factory CropRecommendation.fromJson(Map<String, dynamic> json) {
    final cropName = json['crop_name'];
    final confidence = json['confidence_percentage'];
    if (cropName is! String || cropName.trim().isEmpty || confidence is! num) {
      throw const FormatException('Invalid crop recommendation data.');
    }
    if (!confidence.isFinite || confidence < 0 || confidence > 100) {
      throw const FormatException('Invalid crop confidence percentage.');
    }
    return CropRecommendation(
      cropName: cropName,
      confidencePercentage: confidence.toDouble(),
    );
  }
}

class CropRecommendationResult {
  const CropRecommendationResult({
    required this.location,
    required this.weather,
    required this.recommendations,
  });

  final String location;
  final CropWeather weather;
  final List<CropRecommendation> recommendations;

  factory CropRecommendationResult.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final weatherJson = json['weather'];
    final recommendationsJson = json['recommendations'];
    if (location is! String ||
        location.trim().isEmpty ||
        weatherJson is! Map ||
        recommendationsJson is! List ||
        !recommendationsJson.every((item) => item is Map)) {
      throw const FormatException('Invalid crop recommendation response.');
    }
    final recommendations = recommendationsJson
        .map(
          (item) => CropRecommendation.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .take(3)
        .toList(growable: false);
    if (recommendations.isEmpty) {
      throw const FormatException(
        'The crop recommendation response has no predictions.',
      );
    }
    return CropRecommendationResult(
      location: location,
      weather: CropWeather.fromJson(
        Map<String, dynamic>.from(weatherJson),
      ),
      recommendations: recommendations,
    );
  }
}

double _requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num || !value.isFinite) {
    throw FormatException('Invalid weather value for $key.');
  }
  return value.toDouble();
}

double? _optionalNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! num || !value.isFinite) {
    throw FormatException('Invalid weather value for $key.');
  }
  return value.toDouble();
}
