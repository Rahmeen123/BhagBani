class PlantHealthAnalysis {
  const PlantHealthAnalysis({
    required this.status,
    required this.treatmentTips,
    required this.disclaimer,
    this.label,
    this.confidence,
    this.message,
  });

  factory PlantHealthAnalysis.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    final tips = json['treatment_tips'];
    if (status is! String || tips is! List || json['disclaimer'] is! String) {
      throw const FormatException('Invalid plant health response.');
    }

    return PlantHealthAnalysis(
      status: status,
      label: json['label'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      treatmentTips: tips.cast<String>(),
      message: json['message'] as String?,
      disclaimer: json['disclaimer'] as String,
    );
  }

  final String status;
  final String? label;
  final double? confidence;
  final List<String> treatmentTips;
  final String? message;
  final String disclaimer;

  bool get isHealthy => status == 'healthy';
  bool get needsRetake => status == 'retake';
}
