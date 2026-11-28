import 'land_coordinate.dart';

class Land {
  const Land({
    required this.id,
    required this.ownerUserId,
    required this.landName,
    required this.location,
    required this.area,
    required this.areaUnit,
    required this.soilType,
    required this.waterSource,
    required this.preferredCrop,
    required this.description,
    required this.images,
    required this.status,
    required this.createdAt,
    this.ownerName = 'Land Owner',
    this.polygonCoordinates = const [],
    this.centerLocation,
    this.perimeterMeters,
  });

  final String id;
  final String ownerUserId;
  final String landName;
  final String location;
  final double area;
  final String areaUnit;
  final String soilType;
  final String waterSource;
  final String preferredCrop;
  final String description;
  final List<String> images;
  final String status;
  final DateTime createdAt;
  final String ownerName;
  final List<LandCoordinate> polygonCoordinates;
  final LandCoordinate? centerLocation;
  final double? perimeterMeters;

  bool get hasBoundary => polygonCoordinates.length >= 3;

  Land copyWith({
    String? landName,
    String? location,
    double? area,
    String? areaUnit,
    String? soilType,
    String? waterSource,
    String? preferredCrop,
    String? description,
    List<String>? images,
    String? status,
    List<LandCoordinate>? polygonCoordinates,
    LandCoordinate? centerLocation,
    double? perimeterMeters,
  }) =>
      Land(
        id: id,
        ownerUserId: ownerUserId,
        landName: landName ?? this.landName,
        location: location ?? this.location,
        area: area ?? this.area,
        areaUnit: areaUnit ?? this.areaUnit,
        soilType: soilType ?? this.soilType,
        waterSource: waterSource ?? this.waterSource,
        preferredCrop: preferredCrop ?? this.preferredCrop,
        description: description ?? this.description,
        images: images ?? this.images,
        status: status ?? this.status,
        createdAt: createdAt,
        ownerName: ownerName,
        polygonCoordinates: polygonCoordinates ?? this.polygonCoordinates,
        centerLocation: centerLocation ?? this.centerLocation,
        perimeterMeters: perimeterMeters ?? this.perimeterMeters,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerUserId': ownerUserId,
        'landName': landName,
        'location': location,
        'area': area,
        'areaUnit': areaUnit,
        'soilType': soilType,
        'waterSource': waterSource,
        'preferredCrop': preferredCrop,
        'description': description,
        'images': images,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'ownerName': ownerName,
        'polygonCoordinates':
            polygonCoordinates.map((point) => point.toJson()).toList(),
        if (centerLocation != null) 'centerLocation': centerLocation!.toJson(),
        if (perimeterMeters != null) 'perimeterMeters': perimeterMeters,
      };

  factory Land.fromJson(Map<String, dynamic> json) => Land(
        id: json['id'] as String? ?? '',
        ownerUserId: json['ownerUserId'] as String? ?? '',
        landName: json['landName'] as String? ?? '',
        location: json['location'] as String? ?? '',
        area: (json['area'] as num?)?.toDouble() ?? 0,
        areaUnit: json['areaUnit'] as String? ?? 'Acres',
        soilType: json['soilType'] as String? ?? 'Not specified',
        waterSource: json['waterSource'] as String? ?? 'Not specified',
        preferredCrop: json['preferredCrop'] as String? ?? 'Mixed crops',
        description: json['description'] as String? ?? '',
        images: (json['images'] as List<dynamic>? ?? const []).cast<String>(),
        status: json['status'] as String? ?? 'Available',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        ownerName: json['ownerName'] as String? ?? 'Land Owner',
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
