/// Represents a geographic latitude/longitude point in a farm boundary polygon.
class LandCoordinate {
  const LandCoordinate({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lng': longitude,
      };

  factory LandCoordinate.fromJson(Map<String, dynamic> json) => LandCoordinate(
        latitude: (json['lat'] as num?)?.toDouble() ??
            (json['latitude'] as num?)?.toDouble() ??
            0,
        longitude: (json['lng'] as num?)?.toDouble() ??
            (json['longitude'] as num?)?.toDouble() ??
            0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LandCoordinate &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}
