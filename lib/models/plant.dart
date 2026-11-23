class Plant {
  const Plant({
    required this.id,
    required this.nurseryId,
    required this.nurseryName,
    required this.name,
    required this.scientificName,
    required this.category,
    required this.price,
    required this.quantity,
    required this.height,
    required this.description,
    required this.images,
    this.availability = true,
    this.rating = 4.8,
    required this.createdAt,
  });

  final String id;
  final String nurseryId;
  final String nurseryName;
  final String name;
  final String scientificName;
  final String category;
  final double price;
  final int quantity;
  final String height;
  final String description;
  final List<String> images;
  final bool availability;
  final double rating;
  final DateTime createdAt;

  bool get inStock => availability && quantity > 0;

  Plant copyWith({
    String? id,
    String? nurseryId,
    String? nurseryName,
    String? name,
    String? scientificName,
    String? category,
    double? price,
    int? quantity,
    String? height,
    String? description,
    List<String>? images,
    bool? availability,
    double? rating,
    DateTime? createdAt,
  }) => Plant(
    id: id ?? this.id,
    nurseryId: nurseryId ?? this.nurseryId,
    nurseryName: nurseryName ?? this.nurseryName,
    name: name ?? this.name,
    scientificName: scientificName ?? this.scientificName,
    category: category ?? this.category,
    price: price ?? this.price,
    quantity: quantity ?? this.quantity,
    height: height ?? this.height,
    description: description ?? this.description,
    images: images ?? this.images,
    availability: availability ?? this.availability,
    rating: rating ?? this.rating,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nurseryId': nurseryId,
    'nurseryName': nurseryName,
    'name': name,
    'scientificName': scientificName,
    'category': category,
    'price': price,
    'quantity': quantity,
    'height': height,
    'description': description,
    'images': images,
    'availability': availability,
    'rating': rating,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Plant.fromJson(Map<String, dynamic> json) => Plant(
    id: json['id'] as String? ?? '',
    nurseryId: json['nurseryId'] as String? ?? '',
    nurseryName: json['nurseryName'] as String? ?? 'Verified Nursery',
    name: json['name'] as String? ?? '',
    scientificName: json['scientificName'] as String? ?? '',
    category: json['category'] as String? ?? 'General',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    quantity: json['quantity'] as int? ?? 0,
    height: json['height'] as String? ?? 'Standard',
    description: json['description'] as String? ?? '',
    images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    availability: json['availability'] as bool? ?? true,
    rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}
