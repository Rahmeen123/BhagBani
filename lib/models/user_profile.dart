class UserProfile {
  const UserProfile({
    this.id = '',
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    this.whatsappNumber = '',
    this.address = '',
    this.avatarPath,
    this.isGuest = false,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String location;
  final String whatsappNumber;
  final String address;
  final String? avatarPath;
  final bool isGuest;

  String get phoneNumber => phone;
  String get effectiveWhatsapp =>
      whatsappNumber.trim().isNotEmpty ? whatsappNumber.trim() : phone.trim();

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? location,
    String? whatsappNumber,
    String? address,
    String? avatarPath,
    bool? isGuest,
  }) =>
      UserProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        location: location ?? this.location,
        whatsappNumber: whatsappNumber ?? this.whatsappNumber,
        address: address ?? this.address,
        avatarPath: avatarPath ?? this.avatarPath,
        isGuest: isGuest ?? this.isGuest,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
        'whatsappNumber': whatsappNumber,
        'address': address,
        'avatarPath': avatarPath,
        'isGuest': isGuest,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ??
            json['phoneNumber'] as String? ??
            '',
        location: json['location'] as String? ?? '',
        whatsappNumber: json['whatsappNumber'] as String? ?? '',
        address: json['address'] as String? ?? '',
        avatarPath: json['avatarPath'] as String?,
        isGuest: json['isGuest'] as bool? ?? false,
      );

  static const guest = UserProfile(
    id: 'guest',
    name: 'Guest User',
    email: 'guest@baghbani.local',
    phone: 'Not provided',
    location: 'Pakistan',
    isGuest: true,
  );
}
