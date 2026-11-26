import '../models/crop_recommendation_result.dart';
import '../services/crop_recommendation_api_service.dart';

class CropRecommendationRepository {
  CropRecommendationRepository(this._apiService);

  final CropRecommendationApiService _apiService;

  Future<CropRecommendationResult> recommend({
    required double latitude,
    required double longitude,
  }) =>
      _apiService.recommend(latitude: latitude, longitude: longitude);

  void close() => _apiService.close();
}
