import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/contact_information.dart';
import '../../models/farmer.dart';
import '../../providers/auth_scope.dart';
import '../../services/farmer_service.dart';
import '../../widgets/primary_button.dart';

class BecomeFarmerScreen extends StatefulWidget {
  const BecomeFarmerScreen({super.key});

  @override
  State<BecomeFarmerScreen> createState() => _BecomeFarmerScreenState();
}

class _BecomeFarmerScreenState extends State<BecomeFarmerScreen> {
  final _form = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _experienceController = TextEditingController();
  final _servicesController = TextEditingController();
  final _aboutMeController = TextEditingController();
  final _rateController = TextEditingController(text: 'Rs. 2,000 / day');
  final _farmerService = FarmerService();

  String? _selectedAvatarUrl;
  bool _isAvailable = true;
  bool _isSubmitting = false;
  bool _initialized = false;

  final Map<String, bool> _skills = {
    'Crop Farming': true,
    'Tree Plantation': false,
    'Irrigation Management': true,
    'Farm Maintenance': false,
    'Pest Management': false,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final user = AuthScope.of(context).profile;
    if (user != null && !user.isGuest) {
      _nameController.text = user.name;
      _locationController.text = user.location;
      _addressController.text =
          user.address.isNotEmpty ? user.address : user.location;
      if (user.phone != 'Not provided') {
        _phoneController.text = user.phone;
      }
      _whatsappController.text = user.whatsappNumber;
      _selectedAvatarUrl = user.avatarPath;
    }
    _servicesController.text = 'Field Preparation, Sowing, Crop Management';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _experienceController.dispose();
    _servicesController.dispose();
    _aboutMeController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatarUrl() async {
    final controller = TextEditingController(text: _selectedAvatarUrl ?? '');
    final chosen = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Profile Picture',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.dark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter an image URL for your profile photo (optional), or leave blank to use your initials avatar.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Profile Photo URL',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Clear'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (chosen != null && mounted) {
      setState(() => _selectedAvatarUrl = chosen.isEmpty ? null : chosen);
    }
  }

  Future<void> _submitProfile() async {
    if (!_form.currentState!.validate()) return;

    final selectedSkills = _skills.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one farming skill'),
          backgroundColor: AppColors.gardenAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = AuthScope.of(context);
    final user = auth.profile;
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    final whatsapp = _whatsappController.text.trim();
    final expYears = int.tryParse(_experienceController.text.trim()) ?? 1;

    final parsedServices = _servicesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final contactInfo = ContactInformation(
      name: name,
      phoneNumber: phone,
      whatsappNumber: whatsapp.isNotEmpty ? whatsapp : phone,
      address: address,
      location: location,
    );

    final newFarmer = Farmer(
      id: 'farmer_${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.email ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      location: location,
      address: address,
      experienceYears: expYears,
      skills: selectedSkills,
      services: parsedServices.isNotEmpty
          ? parsedServices
          : selectedSkills.map((s) => '$s Service').toList(),
      availability: _isAvailable,
      rating: 5.0,
      reviewsCount: 1,
      dailyRate: _rateController.text.trim().isNotEmpty
          ? _rateController.text.trim()
          : 'Rs. 2,000 / day',
      phone: phone,
      whatsapp: whatsapp.isNotEmpty ? whatsapp : phone,
      profileImage: _selectedAvatarUrl,
      contactInformation: contactInfo,
      description: _aboutMeController.text.trim().isNotEmpty
          ? _aboutMeController.text.trim()
          : 'Experienced farmer offering ${selectedSkills.join(', ')} in $location.',
    );

    await _farmerService.addFarmer(newFarmer);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.soft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 18),
            const Text(
              'Profile Registered!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your farmer profile is now visible in Hire Farmer. Land owners can call or WhatsApp you directly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5, color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Done',
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context, true); // return
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _nameController.text.trim();
    final initials = displayName.isNotEmpty
        ? displayName
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
        : 'F';
    final hasPhoto =
        _selectedAvatarUrl != null && _selectedAvatarUrl!.startsWith('http');

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Become a Farmer'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            // Intro Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Row(
                children: [
                  Icon(Icons.eco_rounded, color: AppColors.primary, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offer Your Farming Services',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Register your profile on Baghbani so land owners can contact you directly.',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.muted,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 1: Personal Information
            _sectionHeader('Personal Information'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  // Profile Picture Picker
                  Center(
                    child: GestureDetector(
                      onTap: _pickAvatarUrl,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.soft,
                            backgroundImage:
                                hasPhoto ? NetworkImage(_selectedAvatarUrl!) : null,
                            child: hasPhoto
                                ? null
                                : Text(
                                    initials.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _pickAvatarUrl,
                    child: const Text(
                      'Set Profile Picture',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g. Tariq Mehmood',
                      prefixIcon: Icon(Icons.person_outline_rounded,
                          color: AppColors.muted),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 14),

                  // Location
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location / District',
                      hintText: 'e.g. Sahiwal, Punjab',
                      prefixIcon: Icon(Icons.location_on_outlined,
                          color: AppColors.muted),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter your location'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Address
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: 'e.g. Chak 89/6-R, Tehsil & District Sahiwal',
                      prefixIcon:
                          Icon(Icons.home_outlined, color: AppColors.muted),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter your address'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 2: Contact Information
            _sectionHeader('Contact Information'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'e.g. 0300 1234567',
                      prefixIcon:
                          Icon(Icons.phone_outlined, color: AppColors.muted),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter your phone number'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp Number',
                      hintText: 'e.g. 0300 1234567',
                      prefixIcon:
                          Icon(Icons.chat_outlined, color: AppColors.muted),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter your WhatsApp number'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 3: Farming Information
            _sectionHeader('Farming Information'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Experience Years & Rate
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _experienceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Experience (Years)',
                            hintText: 'e.g. 5',
                            prefixIcon: Icon(Icons.work_history_outlined,
                                color: AppColors.muted),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (int.tryParse(v.trim()) == null) {
                              return 'Numbers only';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _rateController,
                          decoration: const InputDecoration(
                            labelText: 'Daily Rate',
                            hintText: 'Rs. 2,000 / day',
                            prefixIcon: Icon(Icons.payments_outlined,
                                color: AppColors.muted),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Skills Checkboxes
                  const Text(
                    'Skills',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._skills.keys.map((skill) {
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.dark,
                        ),
                      ),
                      value: _skills[skill],
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _skills[skill] = val ?? false);
                      },
                    );
                  }),
                  const SizedBox(height: 14),

                  // Services Offered Field
                  TextFormField(
                    controller: _servicesController,
                    decoration: const InputDecoration(
                      labelText: 'Services Offered',
                      hintText: 'e.g. Soil Tillage, Sowing, Laser Leveling',
                      prefixIcon:
                          Icon(Icons.handyman_outlined, color: AppColors.muted),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter your services'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // About Me Field (optional)
                  TextFormField(
                    controller: _aboutMeController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'About Me (Optional)',
                      hintText:
                          'Share your agricultural background, crops managed, or machinery operated…',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Availability Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Availability',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isAvailable ? 'Available' : 'Not Available',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: _isAvailable
                                  ? AppColors.primary
                                  : Colors.orange[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isAvailable,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _isAvailable = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Submit Button
            PrimaryButton(
              label: 'Create Farmer Profile',
              icon: Icons.check_circle_rounded,
              busy: _isSubmitting,
              onPressed: _isSubmitting ? null : _submitProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
      );
}
