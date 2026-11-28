import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/contact_information.dart';
import '../../models/land_coordinate.dart';
import '../../models/land_offer.dart';
import '../../providers/auth_scope.dart';
import '../../services/land_service.dart';
import '../../utils/land_geometry.dart';
import '../../widgets/primary_button.dart';
import 'my_land_listings_screen.dart';
import 'select_farm_boundary_screen.dart';

/// Step 3 of "Offer a Land": collect direct contact info before publishing.
class LandContactInfoScreen extends StatefulWidget {
  LandContactInfoScreen({
    super.key,
    required this.draft,
    required this.boundaryPoints,
    required this.centerLocation,
    required this.calculatedAreaAcres,
    required this.perimeterMeters,
    required this.resolvedAddress,
    LandService? landService,
  }) : landService = landService ?? LandService();

  final OfferLandDraft draft;
  final List<LandCoordinate> boundaryPoints;
  final LandCoordinate centerLocation;
  final double calculatedAreaAcres;
  final double perimeterMeters;
  final String resolvedAddress;
  final LandService landService;

  @override
  State<LandContactInfoScreen> createState() => _LandContactInfoScreenState();
}

class _LandContactInfoScreenState extends State<LandContactInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();

  bool _initialized = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final user = AuthScope.of(context).profile;
    final existing = widget.draft.existingLand;

    _ownerNameController.text = existing?.ownerName ??
        (user != null && !user.isGuest ? user.name : '');
    _phoneController.text = existing?.ownerPhone.isNotEmpty == true
        ? existing!.ownerPhone
        : (user != null && !user.isGuest && user.phone != 'Not provided'
            ? user.phone
            : '');
    _whatsappController.text = existing?.ownerContact.whatsappNumber.isNotEmpty == true
        ? existing!.ownerContact.whatsappNumber
        : (user != null && !user.isGuest ? user.whatsappNumber : '');
    _addressController.text = existing?.ownerAddress.isNotEmpty == true
        ? existing!.ownerAddress
        : (widget.resolvedAddress.trim().isNotEmpty
            ? widget.resolvedAddress.trim()
            : widget.draft.location);
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _publishLand() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    final user = AuthScope.of(context).profile;
    final ownerName = _ownerNameController.text.trim();
    final phone = _phoneController.text.trim();
    final whatsapp = _whatsappController.text.trim();
    final address = _addressController.text.trim();
    final contact = ContactInformation(
      name: ownerName,
      phoneNumber: phone,
      whatsappNumber: whatsapp,
      address: address,
      location: widget.resolvedAddress.isNotEmpty
          ? widget.resolvedAddress
          : widget.draft.location,
    );

    final effectiveArea = widget.draft.estimatedAreaAcres > 0
        ? widget.draft.estimatedAreaAcres
        : double.parse(widget.calculatedAreaAcres.toStringAsFixed(2));
    final areaUnit = widget.draft.areaUnit;
    final soilType = widget.draft.soilType.trim().isEmpty
        ? 'Not specified'
        : widget.draft.soilType.trim();

    setState(() => _isSaving = true);
    try {
      final existing = widget.draft.existingLand;
      if (existing != null) {
        await widget.landService.updateLand(
          existing.copyWith(
            ownerName: ownerName,
            landName: widget.draft.title,
            location: widget.resolvedAddress.isNotEmpty
                ? widget.resolvedAddress
                : widget.draft.location,
            area: effectiveArea,
            areaUnit: areaUnit,
            soilType: soilType,
            irrigationAvailable: widget.draft.irrigationAvailable,
            waterSource: widget.draft.waterSource,
            preferredCrop: widget.draft.preferredCrop,
            description: widget.draft.description,
            images: const [],
            polygonCoordinates:
                List<LandCoordinate>.unmodifiable(widget.boundaryPoints),
            centerLocation: widget.centerLocation,
            perimeterMeters: widget.perimeterMeters,
            ownerContact: contact,
          ),
        );
      } else {
        final offer = LandOffer(
          id: 'land_${DateTime.now().millisecondsSinceEpoch}',
          userId: user?.email ?? '',
          ownerName: ownerName,
          title: widget.draft.title,
          location: widget.resolvedAddress.isNotEmpty
              ? widget.resolvedAddress
              : widget.draft.location,
          acreage: '${effectiveArea.toStringAsFixed(2)} $areaUnit',
          areaUnit: areaUnit,
          waterSource: widget.draft.waterSource,
          partnershipType: widget.draft.partnershipType,
          description: widget.draft.description,
          createdAt: DateTime.now(),
          soilType: soilType,
          preferredCrop: widget.draft.preferredCrop,
          irrigationAvailable: widget.draft.irrigationAvailable,
          polygonCoordinates:
              List<LandCoordinate>.unmodifiable(widget.boundaryPoints),
          centerLocation: widget.centerLocation,
          perimeterMeters: widget.perimeterMeters,
          ownerContact: contact,
        );
        await widget.landService.submitLandOffer(offer);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not publish land listing: $error')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    await showDialog<void>(
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
              child: const Icon(
                Icons.landscape_rounded,
                color: AppColors.farmAccent,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.draft.existingLand == null
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
              widget.draft.existingLand == null
                  ? 'Your farm boundary (${LandGeometry.formatAcres(widget.calculatedAreaAcres)}) and contact details are now visible to farmers in Find Land.'
                  : 'Your farm boundary, land details, and contact information have been updated.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Done',
              onPressed: () {
                Navigator.pop(context); // close dialog
                if (widget.draft.existingLand != null) {
                  Navigator.pop(context); // close contact screen
                  Navigator.pop(context); // close boundary screen
                  Navigator.pop(context); // close edit form
                } else {
                  final ownerUserId =
                      AuthScope.of(context).profile?.email ?? '';
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => MyLandListingsScreen(
                        ownerUserId: ownerUserId,
                      ),
                    ),
                    (route) => route.isFirst,
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
        title: const Text('Add Contact Information'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            // Satellite / GIS Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.satellite_alt_rounded,
                          color: AppColors.farmAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Selected Farm Boundary',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _summaryPill(
                          'Boundary Points',
                          '${widget.boundaryPoints.length} points',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryPill(
                          'Calculated Area',
                          LandGeometry.formatAcres(widget.calculatedAreaAcres),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Owner Contact Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Interested farmers in Find Land can call or message you directly using these details.',
              style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 16),

            _fieldLabel('Owner Name'),
            TextFormField(
              controller: _ownerNameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Chaudhry Riaz',
                prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.muted),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter owner name' : null,
            ),
            const SizedBox(height: 16),

            _fieldLabel('Phone Number'),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'e.g. 0300 1234567',
                prefixIcon: Icon(Icons.phone_outlined, color: AppColors.muted),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter phone number' : null,
            ),
            const SizedBox(height: 16),

            _fieldLabel('WhatsApp Number (Optional)'),
            TextFormField(
              controller: _whatsappController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'e.g. 0300 1234567 (defaults to phone if empty)',
                prefixIcon: Icon(Icons.chat_outlined, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 16),

            _fieldLabel('Address'),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Village, Chak, or Road address for visiting the land',
                prefixIcon: Icon(Icons.home_outlined, color: AppColors.muted),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter address' : null,
            ),
            const SizedBox(height: 28),

            PrimaryButton(
              label: widget.draft.existingLand == null
                  ? 'Publish Land'
                  : 'Save & Update Listing',
              icon: Icons.check_circle_rounded,
              busy: _isSaving,
              onPressed: _isSaving ? null : _publishLand,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
      );

  Widget _summaryPill(String label, String value) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
}
