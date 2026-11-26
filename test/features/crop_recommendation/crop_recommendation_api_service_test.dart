import 'dart:convert';

import 'package:baghbani/features/crop_recommendation/models/crop_recommendation_result.dart';
import 'package:baghbani/features/crop_recommendation/services/crop_recommendation_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('posts coordinates and parses weather and top three crops', () async {
    final service = CropRecommendationApiService(
      baseUri: Uri.parse('https://api.example.test'),
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/recommend-crop');
        expect(
          jsonDecode(request.body),
          {'latitude': 31.52, 'longitude': 74.35},
        );
        return http.Response(
          jsonEncode({
            'location': 'Lahore',
            'weather': {
              'temperature': 27.5,
              'rainfall': 6,
              'humidity': null,
            },
            'recommendations': [
              {'crop_name': 'Wheat', 'confidence_percentage': 91.5},
              {'crop_name': 'Rice', 'confidence_percentage': 72},
              {'crop_name': 'Maize', 'confidence_percentage': 60},
              {'crop_name': 'Cotton', 'confidence_percentage': 40},
            ],
          }),
          200,
        );
      }),
    );

    final result = await service.recommend(latitude: 31.52, longitude: 74.35);

    expect(result.location, 'Lahore');
    expect(result.weather.temperature, 27.5);
    expect(result.weather.humidity, isNull);
    expect(result.recommendations, hasLength(3));
    expect(result.recommendations.first.cropName, 'Wheat');
    service.close();
  });

  test('surfaces server error detail', () async {
    final service = CropRecommendationApiService(
      baseUri: Uri.parse('https://api.example.test'),
      client: MockClient(
        (_) async => http.Response('{"detail":"Weather unavailable"}', 502),
      ),
    );

    await expectLater(
      service.recommend(latitude: 31.52, longitude: 74.35),
      throwsA(
        isA<CropRecommendationApiException>()
            .having((error) => error.message, 'message', 'Weather unavailable'),
      ),
    );
    service.close();
  });

  test('rejects invalid confidence values', () {
    expect(
      () => CropRecommendation.fromJson({
        'crop_name': 'Wheat',
        'confidence_percentage': 101,
      }),
      throwsFormatException,
    );
  });

  test('validates coordinates before sending a request', () async {
    final service = CropRecommendationApiService(
      client: MockClient((_) async {
        fail('Invalid coordinates must not be sent.');
      }),
    );

    await expectLater(
      service.recommend(latitude: 91, longitude: 74.35),
      throwsA(isA<CropRecommendationApiException>()),
    );
    service.close();
  });
}
