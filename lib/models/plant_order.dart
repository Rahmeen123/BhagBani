class PlantOrder {
  const PlantOrder({
    required this.id,
    required this.buyerUserId,
    required this.buyerName,
    required this.buyerPhone,
    required this.nurseryId,
    required this.nurseryName,
    required this.plantId,
    required this.plantName,
    required this.plantImage,
    required this.quantity,
    required this.totalPrice,
    this.paymentMethod = 'Cash on Pickup',
    this.status = 'Pending',
    required this.pickupAddress,
    this.pickupNotes,
    required this.createdAt,
  });

  final String id;
  final String buyerUserId;
  final String buyerName;
  final String buyerPhone;
  final String nurseryId;
  final String nurseryName;
  final String plantId;
  final String plantName;
  final String plantImage;
  final int quantity;
  final double totalPrice;
  final String paymentMethod;
  final String status; // 'Pending', 'Ready for Pickup', 'Completed', 'Cancelled'
  final String pickupAddress;
  final String? pickupNotes;
  final DateTime createdAt;

  PlantOrder copyWith({
    String? id,
    String? buyerUserId,
    String? buyerName,
    String? buyerPhone,
    String? nurseryId,
    String? nurseryName,
    String? plantId,
    String? plantName,
    String? plantImage,
    int? quantity,
    double? totalPrice,
    String? paymentMethod,
    String? status,
    String? pickupAddress,
    String? pickupNotes,
    DateTime? createdAt,
  }) => PlantOrder(
    id: id ?? this.id,
    buyerUserId: buyerUserId ?? this.buyerUserId,
    buyerName: buyerName ?? this.buyerName,
    buyerPhone: buyerPhone ?? this.buyerPhone,
    nurseryId: nurseryId ?? this.nurseryId,
    nurseryName: nurseryName ?? this.nurseryName,
    plantId: plantId ?? this.plantId,
    plantName: plantName ?? this.plantName,
    plantImage: plantImage ?? this.plantImage,
    quantity: quantity ?? this.quantity,
    totalPrice: totalPrice ?? this.totalPrice,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    status: status ?? this.status,
    pickupAddress: pickupAddress ?? this.pickupAddress,
    pickupNotes: pickupNotes ?? this.pickupNotes,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'buyerUserId': buyerUserId,
    'buyerName': buyerName,
    'buyerPhone': buyerPhone,
    'nurseryId': nurseryId,
    'nurseryName': nurseryName,
    'plantId': plantId,
    'plantName': plantName,
    'plantImage': plantImage,
    'quantity': quantity,
    'totalPrice': totalPrice,
    'paymentMethod': paymentMethod,
    'status': status,
    'pickupAddress': pickupAddress,
    'pickupNotes': pickupNotes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PlantOrder.fromJson(Map<String, dynamic> json) => PlantOrder(
    id: json['id'] as String? ?? '',
    buyerUserId: json['buyerUserId'] as String? ?? '',
    buyerName: json['buyerName'] as String? ?? 'Valued Customer',
    buyerPhone: json['buyerPhone'] as String? ?? '',
    nurseryId: json['nurseryId'] as String? ?? '',
    nurseryName: json['nurseryName'] as String? ?? '',
    plantId: json['plantId'] as String? ?? '',
    plantName: json['plantName'] as String? ?? '',
    plantImage: json['plantImage'] as String? ?? '',
    quantity: json['quantity'] as int? ?? 1,
    totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
    paymentMethod: json['paymentMethod'] as String? ?? 'Cash on Pickup',
    status: json['status'] as String? ?? 'Pending',
    pickupAddress: json['pickupAddress'] as String? ?? '',
    pickupNotes: json['pickupNotes'] as String?,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}
