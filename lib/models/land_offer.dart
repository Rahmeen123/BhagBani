import 'land_coordinate.dart';

class LandOffer {
  const LandOffer({
    required this.id,
    required this.userId,
    required this.ownerName,
    required this.title,
    required this.location,
    required this.acreage,
    required this.waterSource,
    required this.partnershipType,
    required this.description,
    required this.createdAt,
    this.soilType = 'Not specified',
    this.preferredCrop = 'Mixed crops',
    this.polygonCoordinates = const [],
    this.centerLocation,
    this.perimeterMeters,
  });

  final String id;
  final String userId;
  final String ownerName;
  final String title;
  final String location;
  final String acreage;
  final String waterSource;
  final String partnershipType;
  final String description;
  final DateTime createdAt;
  final String soilType;
  final String preferredCrop;
  final List<LandCoordinate> polygonCoordinates;
  final LandCoordinate? centerLocation;
  final double? perimeterMeters;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'ownerName': ownerName,
        'title': title,
        'location': location,
        'acreage': acreage,
        'waterSource': waterSource,
        'partnershipType': partnershipType,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'soilType': soilType,
        'preferredCrop': preferredCrop,
        'polygonCoordinates':
            polygonCoordinates.map((point) => point.toJson()).toList(),
        if (centerLocation != null) 'centerLocation': centerLocation!.toJson(),
        if (perimeterMeters != null) 'perimeterMeters': perimeterMeters,
      };

  factory LandOffer.fromJson(Map<String, dynamic> json) => LandOffer(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        ownerName: json['ownerName'] as String? ?? '',
        title: json['title'] as String? ?? '',
        location: json['location'] as String? ?? '',
        acreage: json['acreage'] as String? ?? '',
        waterSource: json['waterSource'] as String? ?? '',
        partnershipType: json['partnershipType'] as String? ?? '',
        description: json['description'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        soilType: json['soilType'] as String? ?? 'Not specified',
        preferredCrop: json['preferredCrop'] as String? ?? 'Mixed crops',
        polygonCoordinates:
            (json['polygonCoordinates'] as List<dynamic>? ?? const [])
                .whereType<Map>()
                .map((item) =>
                    LandCoordinate.fromJson(Map<String, dynamic>.from(item)))
                .toList(growable: false),
        centerLocation: json['centerLocation'] is Map
            ? LandCoordinate.fromJson(
                Map<String, dynamic>.from(json['centerLocation'] as Map))
            : null,
        perimeterMeters: (json['perimeterMeters'] as num?)?.toDouble(),
      );
}
