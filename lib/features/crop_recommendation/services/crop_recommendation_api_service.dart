import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../models/crop_recommendation_result.dart';

class CropRecommendationApiService {
  CropRecommendationApiService({
    http.Client? client,
    Uri? baseUri,
  })  : _client = client ?? http.Client(),
        _baseUri = baseUri ?? Uri.parse(AppConfig.cropRecommendationApiBaseUrl);

  final http.Client _client;
  final Uri _baseUri;

  Future<CropRecommendationResult> recommend({
    required double latitude,
    required double longitude,
  }) async {
    if (!latitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        !longitude.isFinite ||
        longitude < -180 ||
        longitude > 180) {
      throw const CropRecommendationApiException(
        'Select a valid farm location and try again.',
      );
    }
    final uri = _baseUri.resolve('/recommend-crop');
    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw const CropRecommendationApiException(
        'The request timed out. Check your connection and try again.',
      );
    } on http.ClientException {
      throw const CropRecommendationApiException(
        'Could not connect to the crop recommendation service.',
      );
    }

    final decoded = _decodeJson(response.body);
    if (response.statusCode != 200) {
      final detail = decoded is Map ? decoded['detail'] : null;
      throw CropRecommendationApiException(
        detail is String && detail.isNotEmpty
            ? detail
            : 'Crop recommendations are temporarily unavailable '
                '(HTTP ${response.statusCode}).',
      );
    }
    if (decoded is! Map) {
      throw const CropRecommendationApiException(
        'The recommendation service returned an invalid response.',
      );
    }
    try {
      return CropRecommendationResult.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } on FormatException catch (error) {
      throw CropRecommendationApiException(error.message);
    } on TypeError {
      throw const CropRecommendationApiException(
        'The recommendation service returned an invalid response.',
      );
    }
  }

  dynamic _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const CropRecommendationApiException(
        'The recommendation service returned an unreadable response.',
      );
    }
  }

  void close() => _client.close();
}

class CropRecommendationApiException implements Exception {
  const CropRecommendationApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
