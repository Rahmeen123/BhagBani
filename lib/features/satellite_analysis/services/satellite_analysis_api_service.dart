import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../models/land_analysis_request.dart';
import '../models/land_analysis_result.dart';

class SatelliteAnalysisApiService {
  SatelliteAnalysisApiService({
    http.Client? client,
    Uri? baseUri,
  })  : _client = client ?? http.Client(),
        _baseUri = baseUri ?? Uri.parse(AppConfig.satelliteAnalysisApiBaseUrl);

  final http.Client _client;
  final Uri _baseUri;

  Future<LandAnalysisResult> analyze(LandAnalysisRequest request) async {
    late final http.Response response;
    try {
      response = await _client
          .post(
            _baseUri.resolve('/analyze-land'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw const SatelliteAnalysisApiException(
        'Satellite analysis timed out. Try again later.',
      );
    } on http.ClientException {
      throw const SatelliteAnalysisApiException(
        'Could not connect to the satellite analysis service.',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const SatelliteAnalysisApiException(
        'The satellite service returned an unreadable response.',
      );
    }
    if (response.statusCode != 200) {
      final detail = decoded is Map ? decoded['detail'] : null;
      final validationMessage = detail is List && detail.isNotEmpty
          ? (detail.first is Map ? detail.first['msg'] : null)
          : null;
      throw SatelliteAnalysisApiException(
        detail is String && detail.isNotEmpty
            ? detail
            : validationMessage is String && validationMessage.isNotEmpty
                ? validationMessage
                : 'Satellite analysis is unavailable (HTTP ${response.statusCode}).',
      );
    }
    if (decoded is! Map) {
      throw const SatelliteAnalysisApiException(
        'The satellite service returned an invalid response.',
      );
    }
    try {
      return LandAnalysisResult.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException catch (error) {
      throw SatelliteAnalysisApiException(error.message);
    } on TypeError {
      throw const SatelliteAnalysisApiException(
        'The satellite service returned an invalid response.',
      );
    }
  }

  void close() => _client.close();
}

class SatelliteAnalysisApiException implements Exception {
  const SatelliteAnalysisApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
