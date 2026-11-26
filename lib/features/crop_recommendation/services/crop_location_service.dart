import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/crop_farm_location.dart';

class CropLocationService {
  final _geocoding = Geocoding();

  Future<CropFarmLocation> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const CropLocationException(
        'Turn on location services or tap the map to select your farm.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const CropLocationException(
        'Allow location access in Settings or tap the map to select your farm.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return await fromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on CropLocationException {
      rethrow;
    } on PlatformException {
      throw const CropLocationException(
        'Could not read your location. Tap the map to select your farm.',
      );
    } on Exception {
      throw const CropLocationException(
        'Could not read your location. Tap the map to select your farm.',
      );
    }
  }

  Future<CropFarmLocation> fromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isEmpty) {
        throw const CropLocationException(
          'No readable address found. Try a nearby map location.',
        );
      }
      final address = _formatAddress(placemarks.first);
      if (address.isEmpty) {
        throw const CropLocationException(
          'No readable address found. Try a nearby map location.',
        );
      }
      return CropFarmLocation(
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
    } on CropLocationException {
      rethrow;
    } on PlatformException {
      throw const CropLocationException(
        'Could not find an address. Check your connection and try again.',
      );
    } on Exception {
      throw const CropLocationException(
        'Could not find an address. Check your connection and try again.',
      );
    }
  }

  String _formatAddress(Placemark placemark) {
    final locality = _firstNonEmpty([
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.subLocality,
    ]);
    final parts = [
      placemark.subLocality,
      placemark.thoroughfare,
      locality,
      placemark.administrativeArea,
    ].whereType<String>().map((part) => part.trim()).where((part) {
      return part.isNotEmpty;
    }).toList();

    final uniqueParts = <String>[];
    for (final part in parts) {
      if (!uniqueParts.any(
        (existing) => existing.toLowerCase() == part.toLowerCase(),
      )) {
        uniqueParts.add(part);
      }
    }
    if (uniqueParts.isNotEmpty) return uniqueParts.join(', ');
    return '';
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return null;
  }
}

class CropLocationException implements Exception {
  const CropLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}
