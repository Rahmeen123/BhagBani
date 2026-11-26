class LandAnalysisResult {
  const LandAnalysisResult({
    required this.vegetationPercentage,
    required this.bareLandPercentage,
    required this.cloudPercentage,
    required this.averageNdvi,
    required this.analysisStatus,
    required this.observationDate,
    this.message,
  });

  final double? vegetationPercentage;
  final double? bareLandPercentage;
  final double? cloudPercentage;
  final double? averageNdvi;
  final String analysisStatus;
  final DateTime? observationDate;
  final String? message;

  bool get isInconclusive => analysisStatus != 'conclusive';

  const LandAnalysisResult.inconclusive({this.message})
      : vegetationPercentage = null,
        bareLandPercentage = null,
        cloudPercentage = null,
        averageNdvi = null,
        analysisStatus = 'inconclusive',
        observationDate = null;

  factory LandAnalysisResult.fromJson(Map<String, dynamic> json) {
    final status = json['analysis_status'];
    if (status is! String ||
        (status != 'conclusive' && status != 'inconclusive')) {
      throw const FormatException('Invalid satellite analysis status.');
    }
    final observationDate = json['observation_date'];
    if (observationDate != null && observationDate is! String) {
      throw const FormatException('Invalid satellite observation date.');
    }
    return LandAnalysisResult(
      vegetationPercentage:
          _optionalNumber(json, 'vegetation_percentage', min: 0, max: 100),
      bareLandPercentage:
          _optionalNumber(json, 'bare_land_percentage', min: 0, max: 100),
      cloudPercentage:
          _optionalNumber(json, 'cloud_percentage', min: 0, max: 100),
      averageNdvi: _optionalNumber(json, 'average_ndvi', min: -1, max: 1),
      analysisStatus: status,
      observationDate: observationDate == null
          ? null
          : DateTime.tryParse(observationDate)?.toLocalDate() ??
              (throw const FormatException(
                  'Invalid satellite observation date.')),
    );
  }
}

double? _optionalNumber(
  Map<String, dynamic> json,
  String key, {
  required double min,
  required double max,
}) {
  final value = json[key];
  if (value == null) return null;
  if (value is! num || !value.isFinite || value < min || value > max) {
    throw FormatException('Invalid satellite analysis value for $key.');
  }
  return value.toDouble();
}

extension on DateTime {
  DateTime toLocalDate() => DateTime(year, month, day);
}
