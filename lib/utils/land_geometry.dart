import 'dart:math' as math;

import '../models/land_coordinate.dart';

/// Pure-Dart geodesic calculations for farm boundary polygons.
abstract final class LandGeometry {
  static const double earthRadiusMeters = 6378137.0;
  static const double squareMetersPerAcre = 4046.8564224;

  /// Calculates the spherical surface area of [points] in square meters.
  static double areaSquareMeters(List<LandCoordinate> points) {
    final count = points.length;
    if (count < 3) return 0;

    var total = 0.0;
    for (var i = 0; i < count; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % count];
      final p3 = points[(i + 2) % count];

      final lon1 = _toRadians(p1.longitude);
      final lon3 = _toRadians(p3.longitude);
      final lat2 = _toRadians(p2.latitude);

      var deltaLon = lon3 - lon1;
      if (deltaLon > math.pi) {
        deltaLon -= 2 * math.pi;
      } else if (deltaLon < -math.pi) {
        deltaLon += 2 * math.pi;
      }
      total += deltaLon * math.sin(lat2);
    }

    return (total * earthRadiusMeters * earthRadiusMeters / 2.0).abs();
  }

  /// Calculates the polygon area in acres.
  static double areaAcres(List<LandCoordinate> points) =>
      areaSquareMeters(points) / squareMetersPerAcre;

  /// Calculates the closed polygon perimeter (or polyline length for 2 points)
  /// in meters using the Haversine formula.
  static double perimeterMeters(List<LandCoordinate> points) {
    final count = points.length;
    if (count < 2) return 0;

    var total = 0.0;
    final segments = count >= 3 ? count : count - 1;
    for (var i = 0; i < segments; i++) {
      total += distanceMeters(points[i], points[(i + 1) % count]);
    }
    return total;
  }

  /// Calculates the Haversine distance between [a] and [b] in meters.
  static double distanceMeters(LandCoordinate a, LandCoordinate b) {
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);
    final dLat = lat2 - lat1;
    final dLon = _toRadians(b.longitude - a.longitude);

    final sinHalfLat = math.sin(dLat / 2);
    final sinHalfLon = math.sin(dLon / 2);
    final h = sinHalfLat * sinHalfLat +
        math.cos(lat1) * math.cos(lat2) * sinHalfLon * sinHalfLon;
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(math.max(0.0, 1.0 - h)));
    return earthRadiusMeters * c;
  }

  /// Calculates the center coordinate (polygon centroid with vertex-mean fallback).
  static LandCoordinate? centerOf(List<LandCoordinate> points) {
    if (points.isEmpty) return null;
    if (points.length < 3) {
      return _meanCoordinate(points);
    }

    var signedArea = 0.0;
    var cx = 0.0;
    var cy = 0.0;
    for (var i = 0; i < points.length; i++) {
      final p0 = points[i];
      final p1 = points[(i + 1) % points.length];
      final cross = p0.longitude * p1.latitude - p1.longitude * p0.latitude;
      signedArea += cross;
      cx += (p0.longitude + p1.longitude) * cross;
      cy += (p0.latitude + p1.latitude) * cross;
    }

    if (signedArea.abs() < 1e-12) {
      return _meanCoordinate(points);
    }

    final factor = 1.0 / (3.0 * signedArea);
    return LandCoordinate(
      latitude: cy * factor,
      longitude: cx * factor,
    );
  }

  static LandCoordinate _meanCoordinate(List<LandCoordinate> points) {
    var sumLat = 0.0;
    var sumLon = 0.0;
    for (final point in points) {
      sumLat += point.latitude;
      sumLon += point.longitude;
    }
    return LandCoordinate(
      latitude: sumLat / points.length,
      longitude: sumLon / points.length,
    );
  }

  static String formatAcres(double acres) {
    if (acres <= 0) return '0.00 Acres';
    if (acres < 1) return '${acres.toStringAsFixed(2)} Acres';
    return '${acres.toStringAsFixed(2)} Acres';
  }

  static String formatPerimeter(double meters) {
    if (meters <= 0) return '0 m';
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.round()} m';
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
}
