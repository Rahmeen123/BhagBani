class Nursery {
  const Nursery({
    required this.id,
    required this.ownerUserId,
    required this.nurseryName,
    required this.ownerName,
    required this.phone,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.openingHours,
    required this.image,
    this.approvalStatus = 'Approved',
    this.rating = 4.8,
    this.reviewsCount = 18,
    required this.createdAt,
  });

  final String id;
  final String ownerUserId;
  final String nurseryName;
  final String ownerName;
  final String phone;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final String description;
  final String openingHours;
  final String image;
  final String approvalStatus; // 'Pending', 'Approved', 'Rejected'
  final double rating;
  final int reviewsCount;
  final DateTime createdAt;

  bool get isApproved => approvalStatus.toLowerCase() == 'approved';
  bool get isPending => approvalStatus.toLowerCase() == 'pending';

  Nursery copyWith({
    String? id,
    String? ownerUserId,
    String? nurseryName,
    String? ownerName,
    String? phone,
    String? address,
    String? city,
    double? latitude,
    double? longitude,
    String? description,
    String? openingHours,
    String? image,
    String? approvalStatus,
    double? rating,
    int? reviewsCount,
    DateTime? createdAt,
  }) => Nursery(
    id: id ?? this.id,
    ownerUserId: ownerUserId ?? this.ownerUserId,
    nurseryName: nurseryName ?? this.nurseryName,
    ownerName: ownerName ?? this.ownerName,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    city: city ?? this.city,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    description: description ?? this.description,
    openingHours: openingHours ?? this.openingHours,
    image: image ?? this.image,
    approvalStatus: approvalStatus ?? this.approvalStatus,
    rating: rating ?? this.rating,
    reviewsCount: reviewsCount ?? this.reviewsCount,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerUserId': ownerUserId,
    'nurseryName': nurseryName,
    'ownerName': ownerName,
    'phone': phone,
    'address': address,
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
    'description': description,
    'openingHours': openingHours,
    'image': image,
    'approvalStatus': approvalStatus,
    'rating': rating,
    'reviewsCount': reviewsCount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Nursery.fromJson(Map<String, dynamic> json) => Nursery(
    id: json['id'] as String? ?? '',
    ownerUserId: json['ownerUserId'] as String? ?? '',
    nurseryName: json['nurseryName'] as String? ?? '',
    ownerName: json['ownerName'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    address: json['address'] as String? ?? '',
    city: json['city'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 31.5204,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 74.3587,
    description: json['description'] as String? ?? '',
    openingHours: json['openingHours'] as String? ?? '8:00 AM - 7:00 PM',
    image: json['image'] as String? ?? '',
    approvalStatus: json['approvalStatus'] as String? ?? 'Approved',
    rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
    reviewsCount: json['reviewsCount'] as int? ?? 0,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}
