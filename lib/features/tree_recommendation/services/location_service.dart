import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/land_location.dart';

class LocationService {
  LocationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<LandLocation>> search(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '5',
    });
    final response = await _client.get(uri, headers: {
      'User-Agent': 'BaghbaniTreeRecommendation/1.0',
    }).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(
          'Location search returned status ${response.statusCode}.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException(
          'Location search returned an invalid response.');
    }
    return decoded.whereType<Map>().map((item) {
      final latitude = double.tryParse('${item['lat']}');
      final longitude = double.tryParse('${item['lon']}');
      if (latitude == null || longitude == null) {
        throw const FormatException(
            'A location result has invalid coordinates.');
      }
      final address = item['address'];
      return LandLocation(
        name: _formatAddress(
          address is Map ? address : null,
          '${item['display_name'] ?? query}',
        ),
        latitude: latitude,
        longitude: longitude,
      );
    }).toList(growable: false);
  }

  Future<LandLocation> currentLocation() async {
    final location = await currentCoordinates();
    final address = await reverseGeocode(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    return LandLocation(
      name: address,
      latitude: location.latitude,
      longitude: location.longitude,
      label: 'Current Location',
    );
  }

  Future<LandLocation> currentCoordinates({
    bool requirePrecise = false,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceDisabledException();
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationPermissionDeniedException();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedForeverException();
    }
    if (requirePrecise &&
        await Geolocator.getLocationAccuracy() ==
            LocationAccuracyStatus.reduced) {
      throw const LocationAccuracyReducedException();
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return LandLocation(
      name: '',
      latitude: position.latitude,
      longitude: position.longitude,
      label: 'Current Location',
    );
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<String> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'format': 'jsonv2',
      'addressdetails': '1',
      'zoom': '18',
    });
    final response = await _client.get(uri, headers: {
      'User-Agent': 'BaghbaniTreeRecommendation/1.0',
    }).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw const LocationAddressNotFoundException();
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const LocationAddressNotFoundException();
    }
    final address = decoded['address'];
    final displayName = decoded['display_name'];
    final formatted = _formatAddress(
      address is Map ? address : null,
      displayName is String ? displayName : '',
    );
    if (formatted.isEmpty) throw const LocationAddressNotFoundException();
    return formatted;
  }

  String _formatAddress(Map? address, String fallback) {
    if (address == null) return fallback.trim();
    final parts = <String>[];
    final houseNumber = address['house_number'];
    final street = _firstAddressValue(
      address,
      ['road', 'pedestrian', 'residential', 'footway'],
    );
    if (houseNumber is String &&
        houseNumber.trim().isNotEmpty &&
        street != null) {
      parts.add('${houseNumber.trim()} $street');
    } else if (street != null) {
      parts.add(street);
    }
    const localityFields = [
      'neighbourhood',
      'city_block',
      'quarter',
      'suburb',
      'city_district',
      'city',
      'town',
      'village',
      'municipality',
    ];
    for (final field in localityFields) {
      final value = address[field];
      if (value is String && value.trim().isNotEmpty) {
        final name = value.trim();
        if (!parts.any((part) => part.toLowerCase() == name.toLowerCase())) {
          parts.add(name);
        }
      }
    }
    for (final field in ['state', 'country']) {
      final value = address[field];
      if (value is String && value.trim().isNotEmpty) {
        final name = value.trim();
        if (!parts.any((part) => part.toLowerCase() == name.toLowerCase())) {
          parts.add(name);
        }
      }
    }
    return parts.isEmpty ? fallback.trim() : parts.join(', ');
  }

  String? _firstAddressValue(Map address, List<String> fields) {
    for (final field in fields) {
      final value = address[field];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  void close() => _client.close();
}

class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException();
}

class LocationPermissionDeniedForeverException implements Exception {
  const LocationPermissionDeniedForeverException();
}

class LocationAccuracyReducedException implements Exception {
  const LocationAccuracyReducedException();
}

class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException();
}

class LocationAddressNotFoundException implements Exception {
  const LocationAddressNotFoundException();
}
