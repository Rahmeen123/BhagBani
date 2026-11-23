import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/nursery.dart';
import '../../providers/auth_scope.dart';
import '../../services/nursery_service.dart';
import '../../widgets/primary_button.dart';
import 'nursery_approval_screen.dart';

class RegisterNurseryScreen extends StatefulWidget {
  const RegisterNurseryScreen({super.key});

  @override
  State<RegisterNurseryScreen> createState() => _RegisterNurseryScreenState();
}

class _RegisterNurseryScreenState extends State<RegisterNurseryScreen> {
  final _form = GlobalKey<FormState>();
  final _nurseryNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Lahore');
  final _locationController = TextEditingController(text: 'Gulberg / Cantt');
  final _descriptionController = TextEditingController();
  final _hoursController = TextEditingController(text: '8:00 AM - 7:30 PM (Daily)');
  final _service = NurseryService();

  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = AuthScope.of(context).profile;
    if (_ownerNameController.text.isEmpty && user?.name != null && !user!.isGuest) {
      _ownerNameController.text = user.name;
    }
    if (_phoneController.text.isEmpty && user?.phone != null && !user!.isGuest && user.phone != 'Not set') {
      _phoneController.text = user.phone;
    }
    if (_addressController.text.isEmpty && user?.location != null && !user!.isGuest && user.location != 'Not set') {
      _addressController.text = user.location;
    }
  }

  @override
  void dispose() {
    _nurseryNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final user = AuthScope.of(context).profile;
    final userId = user?.email ?? 'user_owner_${DateTime.now().millisecondsSinceEpoch}';
    final nurseryId = 'nurs_${DateTime.now().millisecondsSinceEpoch}';

    final nursery = Nursery(
      id: nurseryId,
      ownerUserId: userId,
      nurseryName: _nurseryNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      latitude: 31.5204,
      longitude: 74.3587,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : 'Local verified nursery providing healthy saplings and gardening tools.',
      openingHours: _hoursController.text.trim(),
      image: 'nursery_default',
      approvalStatus: 'Pending',
      rating: 5.0,
      reviewsCount: 1,
      createdAt: DateTime.now(),
    );

    await _service.registerNursery(nursery);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => NurseryApprovalScreen(nursery: nursery),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Register Your Nursery'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            // Hero card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.storefront_rounded, color: AppColors.sageLight, size: 36),
                  SizedBox(height: 12),
                  Text(
                    'Join the Baghbani Nursery Network',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'List your plant inventory, receive pickup orders directly from local plant lovers, and expand your business.',
                    style: TextStyle(fontSize: 13, color: AppColors.sageLight, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Fields
            _sectionHeader('Nursery Information'),
            const SizedBox(height: 12),

            _label('Nursery Name *'),
            TextFormField(
              controller: _nurseryNameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Flora Greens Botanical Nursery',
                prefixIcon: Icon(Icons.store_outlined, color: AppColors.muted),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter your nursery name' : null,
            ),
            const SizedBox(height: 16),

            _label('Owner / Manager Name *'),
            TextFormField(
              controller: _ownerNameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Muhammad Aslam',
                prefixIcon: Icon(Icons.person_outline, color: AppColors.muted),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter owner name' : null,
            ),
            const SizedBox(height: 16),

            _label('Contact Phone Number *'),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'e.g. 0300 1234567',
                prefixIcon: Icon(Icons.phone_outlined, color: AppColors.muted),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter contact phone' : null,
            ),
            const SizedBox(height: 22),

            _sectionHeader('Location & Hours'),
            const SizedBox(height: 12),

            _label('Physical Street Address *'),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'e.g. Plot 12-B, Canal Bank Road',
                prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.muted),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter nursery street address' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('City *'),
                      TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Lahore',
                          prefixIcon: Icon(Icons.location_city_outlined, color: AppColors.muted),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter city' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Area / Sector'),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Gulberg',
                          prefixIcon: Icon(Icons.map_outlined, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _label('Opening Hours *'),
            TextFormField(
              controller: _hoursController,
              decoration: const InputDecoration(
                hintText: 'e.g. 8:00 AM - 7:30 PM (Daily)',
                prefixIcon: Icon(Icons.access_time_rounded, color: AppColors.muted),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter opening hours' : null,
            ),
            const SizedBox(height: 22),

            _sectionHeader('Nursery Description & Plants'),
            const SizedBox(height: 12),

            _label('About Your Nursery'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe your plant varieties, fruit saplings, soil fertilizers, and nursery specialty…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),

            PrimaryButton(
              label: 'Submit for Admin Approval',
              icon: Icons.send_rounded,
              busy: _isSubmitting,
              onPressed: _isSubmitting ? null : _submitApplication,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark),
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: AppColors.dark,
      ),
    ),
  );
}
