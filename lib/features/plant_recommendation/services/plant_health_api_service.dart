import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../models/plant_health_analysis.dart';

class PlantHealthApiService {
  PlantHealthApiService({
    http.Client? client,
    Uri? baseUri,
  })  : _client = client ?? http.Client(),
        _baseUri = baseUri ??
            Uri.parse(
              const String.fromEnvironment(
                'PLANT_HEALTH_API_BASE_URL',
                defaultValue: kIsWeb
                    ? 'http://localhost:8000'
                    : AppConfig.cropRecommendationApiBaseUrl,
              ),
            );

  final http.Client _client;
  final Uri _baseUri;

  Future<PlantHealthAnalysis> analyze({
    required XFile image,
    required String plantName,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _baseUri.resolve('/health-analysis'),
    )
      ..fields['plant_name'] = plantName
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          await image.readAsBytes(),
          filename: image.name.isEmpty ? 'plant-photo.jpg' : image.name,
        ),
      );

    late final http.Response response;
    try {
      response = await http.Response.fromStream(
          await _client.send(request).timeout(const Duration(seconds: 90)));
    } on TimeoutException {
      throw const PlantHealthApiException(
        'The health check timed out. Check your connection and try again.',
      );
    } on http.ClientException {
      throw const PlantHealthApiException(
        'Could not connect to the plant health service. Start the backend and try again.',
      );
    }

    final decoded = _decodeJson(response.body);
    if (response.statusCode != 200) {
      final detail = decoded is Map ? decoded['detail'] : null;
      throw PlantHealthApiException(
        detail is String && detail.isNotEmpty
            ? detail
            : 'Plant health analysis failed (HTTP ${response.statusCode}).',
      );
    }
    if (decoded is! Map) {
      throw const PlantHealthApiException(
        'The health service returned an invalid response.',
      );
    }
    try {
      return PlantHealthAnalysis.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } on FormatException catch (error) {
      throw PlantHealthApiException(error.message);
    } on TypeError {
      throw const PlantHealthApiException(
        'The health service returned an invalid response.',
      );
    }
  }

  dynamic _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const PlantHealthApiException(
        'The health service returned an unreadable response.',
      );
    }
  }

  @visibleForTesting
  void close() => _client.close();
}

class PlantHealthApiException implements Exception {
  const PlantHealthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
