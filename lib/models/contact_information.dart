/// Direct contact information attached to a land listing or farmer profile.
class ContactInformation {
  const ContactInformation({
    this.name = '',
    this.phoneNumber = '',
    this.whatsappNumber = '',
    this.address = '',
    this.location = '',
  });

  final String name;
  final String phoneNumber;
  final String whatsappNumber;
  final String address;
  final String location;

  String get effectiveWhatsapp =>
      whatsappNumber.trim().isNotEmpty ? whatsappNumber.trim() : phoneNumber.trim();

  ContactInformation copyWith({
    String? name,
    String? phoneNumber,
    String? whatsappNumber,
    String? address,
    String? location,
  }) =>
      ContactInformation(
        name: name ?? this.name,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        whatsappNumber: whatsappNumber ?? this.whatsappNumber,
        address: address ?? this.address,
        location: location ?? this.location,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'phoneNumber': phoneNumber,
        'whatsappNumber': whatsappNumber,
        'address': address,
        'location': location,
      };

  factory ContactInformation.fromJson(Map<String, dynamic> json) =>
      ContactInformation(
        name: json['name'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String? ?? '',
        whatsappNumber: json['whatsappNumber'] as String? ?? '',
        address: json['address'] as String? ?? '',
        location: json['location'] as String? ?? '',
      );
}
