import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:baghbani/features/satellite_analysis/models/land_analysis_request.dart';
import 'package:baghbani/features/satellite_analysis/models/land_analysis_result.dart';
import 'package:baghbani/features/satellite_analysis/services/satellite_analysis_api_service.dart';

void main() {
  final request = LandAnalysisRequest(
    boundary: const [
      [74.35, 31.52],
      [74.351, 31.52],
      [74.351, 31.521],
    ],
    startDate: DateTime(2026, 11, 1),
    endDate: DateTime(2026, 11, 20),
  );

  test('request serializes a closed GeoJSON polygon and date range', () {
    final json = request.toJson();
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;
    final ring = coordinates.single as List<dynamic>;

    expect(geometry['type'], 'Polygon');
    expect(ring.first, ring.last);
    expect(json['start_date'], '2026-11-01');
    expect(json['end_date'], '2026-11-20');
  });

  test('API service posts the polygon and parses satellite metrics', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'vegetation_percentage': 68.2,
          'bare_land_percentage': 18.4,
          'cloud_percentage': 7.1,
          'average_ndvi': 0.47,
          'analysis_status': 'conclusive',
          'observation_date': '2026-11-18',
        }),
        200,
      );
    });
    final service = SatelliteAnalysisApiService(
      client: client,
      baseUri: Uri.parse('https://satellite.example'),
    );

    final result = await service.analyze(request);

    expect(capturedRequest.url.path, '/analyze-land');
    expect(capturedRequest.method, 'POST');
    expect(
      (jsonDecode(capturedRequest.body) as Map<String, dynamic>)['geometry'],
      request.toJson()['geometry'],
    );
    expect(result.vegetationPercentage, 68.2);
    expect(result.observationDate, DateTime(2026, 11, 18));
    service.close();
  });

  test('inconclusive response permits unavailable metrics', () {
    final result = LandAnalysisResult.fromJson({
      'vegetation_percentage': null,
      'bare_land_percentage': null,
      'cloud_percentage': null,
      'average_ndvi': null,
      'analysis_status': 'inconclusive',
      'observation_date': null,
    });

    expect(result.isInconclusive, isTrue);
    expect(result.vegetationPercentage, isNull);
  });
}
