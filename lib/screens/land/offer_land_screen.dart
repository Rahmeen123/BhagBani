import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/land_offer.dart';
import '../../models/land.dart';
import '../../providers/auth_scope.dart';
import '../../services/land_service.dart';
import '../../widgets/primary_button.dart';
import '../farmer/widgets/community_login_gate.dart';
import 'my_land_listings_screen.dart';

class OfferLandScreen extends StatefulWidget {
  const OfferLandScreen({super.key, this.land});

  final Land? land;

  @override
  State<OfferLandScreen> createState() => _OfferLandScreenState();
}

class _OfferLandScreenState extends State<OfferLandScreen> {
  final _form = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _acreageController = TextEditingController();
  final _soilTypeController = TextEditingController();
  final _cropController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _landService = LandService();

  String _selectedWaterSource = 'Canal Water';
  String _selectedPartnership = 'Crop Sharing';
  bool _isSubmitting = false;
  bool _didInitialize = false;

  final List<String> _waterSources = [
    'Canal Water',
    'Tube-well',
    'Drip System',
    'Canal + Tube-well',
    'Rainfed',
  ];

  final List<String> _partnershipTypes = [
    'Crop Sharing',
    'Full Management',
    'Seasonal Lease',
    'Contract Farming',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = AuthScope.of(context).profile;
    if (_didInitialize) return;
    _didInitialize = true;
    final land = widget.land;
    if (land != null) {
      _titleController.text = land.landName;
      _locationController.text = land.location;
      _acreageController.text = land.area.toString();
      _soilTypeController.text = land.soilType;
      _cropController.text = land.preferredCrop;
      _descriptionController.text = land.description;
      _selectedWaterSource = land.waterSource;
      return;
    }
    if (_locationController.text.isEmpty &&
        user?.location != null &&
        !user!.isGuest) {
      _locationController.text = user.location;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _acreageController.dispose();
    _soilTypeController.dispose();
    _cropController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitLandOffer() async {
    final user = AuthScope.of(context).profile;
    if (user == null || user.isGuest) {
      await requireCommunityLogin(context, actionName: 'offer your land');
      return;
    }
    if (!_form.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      if (widget.land case final land?) {
        await _landService.updateLand(
          land.copyWith(
            landName: _titleController.text.trim(),
            location: _locationController.text.trim(),
            area: double.parse(_acreageController.text.trim()),
            areaUnit: 'Acres',
            soilType: _soilTypeController.text.trim(),
            waterSource: _selectedWaterSource,
            preferredCrop: _cropController.text.trim(),
            description: _descriptionController.text.trim(),
          ),
        );
      } else {
        final offer = LandOffer(
          id: 'land_${DateTime.now().millisecondsSinceEpoch}',
          userId: user.email,
          ownerName: user.name,
          title: _titleController.text.trim(),
          location: _locationController.text.trim(),
          acreage: '${_acreageController.text.trim()} Acres',
          waterSource: _selectedWaterSource,
          partnershipType: _selectedPartnership,
          description: _descriptionController.text.trim(),
          createdAt: DateTime.now(),
          soilType: _soilTypeController.text.trim(),
          preferredCrop: _cropController.text.trim(),
        );
        await _landService.submitLandOffer(offer);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save land listing: $error')),
      );
      return;
    }

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
                color: AppColors.farmTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.landscape_rounded,
                  color: AppColors.farmAccent, size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              widget.land == null
                  ? 'Land Listed Successfully!'
                  : 'Listing Updated Successfully!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.land == null
                  ? 'Your land requirement has been published in the Baghbani Community. Suitable farmers in your district will be able to review and connect.'
                  : 'Your land listing details have been updated.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13.5, color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Done',
              onPressed: () {
                Navigator.pop(context); // close dialog
                if (widget.land != null) {
                  Navigator.pop(context);
                } else {
                  final ownerUserId =
                      AuthScope.of(context).profile?.email ?? '';
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => MyLandListingsScreen(
                        ownerUserId: ownerUserId,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
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
        title: Text(widget.land == null ? 'Offer Land' : 'Edit Listing'),
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
              child: Row(
                children: [
                  const Icon(Icons.landscape_rounded,
                      color: AppColors.farmAccent, size: 34),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.land == null
                              ? 'Find Farmers for Your Land'
                              : 'Update Your Land Listing',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'List your available acreage, water resources, and partnership terms to connect with experienced growers.',
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
            const SizedBox(height: 20),

            // Listing Title
            _label('Listing Title'),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g. 15 Acres Agricultural Land for Wheat & Cotton',
                prefixIcon: Icon(Icons.title_rounded, color: AppColors.muted),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: 18),

            // Location
            _label('Land Location / District / Tehsil'),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'e.g. Near Raiwind Road, Lahore',
                prefixIcon:
                    Icon(Icons.location_on_outlined, color: AppColors.muted),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter land location' : null,
            ),
            const SizedBox(height: 18),

            // Acreage
            _label('Total Land Size (Acres)'),
            TextFormField(
              controller: _acreageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g. 12',
                prefixIcon:
                    Icon(Icons.square_foot_rounded, color: AppColors.muted),
                suffixText: 'Acres',
              ),
              validator: (v) {
                final area = double.tryParse(v?.trim() ?? '');
                if (area == null || area <= 0) return 'Enter a valid area';
                return null;
              },
            ),
            const SizedBox(height: 20),

            _label('Soil Type'),
            TextFormField(
              controller: _soilTypeController,
              decoration: const InputDecoration(
                hintText: 'e.g. Loamy, alluvial, sandy',
                prefixIcon: Icon(Icons.terrain_rounded, color: AppColors.muted),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter the soil type'
                  : null,
            ),
            const SizedBox(height: 18),

            _label('Preferred Crop'),
            TextFormField(
              controller: _cropController,
              decoration: const InputDecoration(
                hintText: 'e.g. Wheat, rice, vegetables',
                prefixIcon: Icon(Icons.grass_rounded, color: AppColors.muted),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a preferred crop'
                  : null,
            ),
            const SizedBox(height: 18),

            // Water Source Selection
            _label('Primary Water Source'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _waterSources.map((source) {
                final isSelected = _selectedWaterSource == source;
                return ChoiceChip(
                  label: Text(source),
                  selected: isSelected,
                  selectedColor: AppColors.farmAccent,
                  backgroundColor: AppColors.white,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.dark,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.farmAccent : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedWaterSource = source);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Partnership Type Selection
            _label('Partnership / Service Model'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _partnershipTypes.map((type) {
                final isSelected = _selectedPartnership == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.white,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.dark,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedPartnership = type);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Description
            _label('Land Details & Soil Condition'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Describe soil quality, current standing crops (if any), electricity availability, tractor access, or specific requirements…',
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please describe your land'
                  : null,
            ),
            const SizedBox(height: 28),

            // Submit Button
            PrimaryButton(
              label: widget.land == null
                  ? 'Submit Land Requirement'
                  : 'Save Changes',
              icon: Icons.check_circle_rounded,
              busy: _isSubmitting,
              onPressed: _isSubmitting ? null : _submitLandOffer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
      );
}
