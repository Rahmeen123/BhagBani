import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_scope.dart';
import '../../widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _location;
  late final TextEditingController _address;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final user = AuthScope.of(context).profile ?? UserProfile.guest;
    _name = TextEditingController(text: user.name);
    _email = TextEditingController(text: user.email);
    _phone = TextEditingController(text: user.phone);
    _whatsapp = TextEditingController(text: user.whatsappNumber);
    _location = TextEditingController(text: user.location);
    _address = TextEditingController(text: user.address);
    _initialized = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _location.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final previous = AuthScope.of(context).profile;
    final updated = UserProfile(
      id: previous?.id ?? '',
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      whatsappNumber: _whatsapp.text.trim(),
      location: _location.text.trim(),
      address: _address.text.trim(),
      avatarPath: previous?.avatarPath,
      isGuest: false,
    );
    await AuthScope.of(context).updateProfile(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      backgroundColor: AppColors.cream,
      title: const Text('Edit Profile'),
      elevation: 0,
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.soft,
                      child: Text(
                        (_name.text.isEmpty ? 'B' : _name.text[0]).toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Avatar image uploading will be available in next update.'),
                    ),
                  ),
                  child: const Text(
                    'Change photo',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _field(_name, 'Full name', Icons.person_outline_rounded),
          const SizedBox(height: 14),
          _field(
            _email,
            'Email address',
            Icons.mail_outline_rounded,
            keyboard: TextInputType.emailAddress,
            email: true,
          ),
          const SizedBox(height: 14),
          _field(
            _phone,
            'Phone number',
            Icons.phone_outlined,
            keyboard: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _field(
            _whatsapp,
            'WhatsApp number (optional)',
            Icons.chat_outlined,
            keyboard: TextInputType.phone,
            requiredField: false,
          ),
          const SizedBox(height: 14),
          _field(_location, 'City or location', Icons.location_on_outlined),
          const SizedBox(height: 14),
          _field(
            _address,
            'Address (optional)',
            Icons.home_outlined,
            requiredField: false,
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Save Changes', onPressed: _save),
        ],
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    bool email = false,
    bool requiredField = true,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboard,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.muted),
    ),
    validator: (value) {
      if (requiredField && (value == null || value.trim().isEmpty)) {
        return 'This field is required';
      }
      if (email && value != null && (!value.contains('@') || !value.contains('.'))) {
        return 'Enter a valid email address';
      }
      return null;
    },
  );
}
