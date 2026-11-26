import '../models/land_analysis_request.dart';
import '../models/land_analysis_result.dart';
import '../services/satellite_analysis_api_service.dart';

class SatelliteAnalysisRepository {
  SatelliteAnalysisRepository({
    SatelliteAnalysisApiService? apiService,
  }) : _apiService = apiService ?? SatelliteAnalysisApiService();

  final SatelliteAnalysisApiService _apiService;

  Future<LandAnalysisResult> analyze(LandAnalysisRequest request) =>
      _apiService.analyze(request);

  void close() => _apiService.close();
}
