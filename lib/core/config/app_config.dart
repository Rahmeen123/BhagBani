abstract final class AppConfig {
  static const cropRecommendationApiBaseUrl = String.fromEnvironment(
    'CROP_RECOMMENDATION_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const satelliteAnalysisApiBaseUrl = String.fromEnvironment(
    'SATELLITE_ANALYSIS_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
