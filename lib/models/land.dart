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
      );
}
