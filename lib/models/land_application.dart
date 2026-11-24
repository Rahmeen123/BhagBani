class LandApplication {
  const LandApplication({
    required this.id,
    required this.landId,
    required this.farmerUserId,
    required this.message,
    required this.status,
    required this.createdAt,
    this.ownerUserId = '',
    this.farmerName = 'Farmer',
    this.experience = '',
    this.skills = '',
    this.location = '',
  });

  static const pending = 'Pending';
  static const accepted = 'Accepted';
  static const rejected = 'Rejected';

  final String id;
  final String landId;
  final String ownerUserId;
  final String farmerUserId;
  final String message;
  final String status;
  final DateTime createdAt;
  final String farmerName;
  final String experience;
  final String skills;
  final String location;

  LandApplication copyWith({String? status, String? ownerUserId}) =>
      LandApplication(
        id: id,
        landId: landId,
        ownerUserId: ownerUserId ?? this.ownerUserId,
        farmerUserId: farmerUserId,
        message: message,
        status: status ?? this.status,
        createdAt: createdAt,
        farmerName: farmerName,
        experience: experience,
        skills: skills,
        location: location,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'landId': landId,
        'ownerUserId': ownerUserId,
        'farmerUserId': farmerUserId,
        'message': message,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'farmerName': farmerName,
        'experience': experience,
        'skills': skills,
        'location': location,
      };

  factory LandApplication.fromJson(Map<String, dynamic> json) =>
      LandApplication(
        id: json['id'] as String? ?? '',
        landId: json['landId'] as String? ?? '',
        ownerUserId: json['ownerUserId'] as String? ?? '',
        farmerUserId: json['farmerUserId'] as String? ?? '',
        message: json['message'] as String? ?? '',
        status: json['status'] as String? ?? pending,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        farmerName: json['farmerName'] as String? ?? 'Farmer',
        experience: json['experience'] as String? ?? '',
        skills: json['skills'] as String? ?? '',
        location: json['location'] as String? ?? '',
      );
}
