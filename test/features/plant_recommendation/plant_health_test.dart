import 'dart:convert';
import 'dart:typed_data';

import 'package:baghbani/features/plant_recommendation/services/plant_health_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('uploads the selected plant image and parses the analysis result',
      () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/health-analysis');
      expect(request, isA<http.Request>());
      final body = utf8.decode(request.bodyBytes);
      expect(body, contains('name="plant_name"'));
      expect(body, contains('Tomato'));
      expect(body, contains('name="image"; filename="plant-photo.jpg"'));
      return http.Response(
        jsonEncode({
          'status': 'disease',
          'label': 'Early Blight',
          'confidence': 0.84,
          'treatment_tips': ['Improve airflow.'],
          'message': null,
          'disclaimer':
              'This is an AI estimate, not a replacement for an expert diagnosis.',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = PlantHealthApiService(
      client: client,
      baseUri: Uri.parse('https://garden.example'),
    );

    final result = await service.analyze(
      image: XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'tomato-leaf.jpg',
        mimeType: 'image/jpeg',
      ),
      plantName: 'Tomato',
    );

    expect(result.status, 'disease');
    expect(result.label, 'Early Blight');
    expect(result.confidence, 0.84);
    expect(result.treatmentTips, ['Improve airflow.']);
    service.close();
  });

  test('explains that the backend must be running when connection fails',
      () async {
    final service = PlantHealthApiService(
      client: MockClient(
        (_) async => throw http.ClientException('Connection refused'),
      ),
      baseUri: Uri.parse('http://localhost:8000'),
    );

    await expectLater(
      service.analyze(
        image: XFile.fromData(
          Uint8List.fromList([1, 2, 3]),
          name: 'tomato-leaf.jpg',
          mimeType: 'image/jpeg',
        ),
        plantName: 'Tomato',
      ),
      throwsA(
        isA<PlantHealthApiException>().having(
          (error) => error.message,
          'message',
          contains('Start the backend'),
        ),
      ),
    );
    service.close();
  });
}
