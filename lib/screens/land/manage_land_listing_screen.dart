import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/land.dart';
import '../../services/land_service.dart';
import '../../widgets/primary_button.dart';
import 'land_applications_screen.dart';
import 'offer_land_screen.dart';

class ManageLandListingScreen extends StatefulWidget {
  const ManageLandListingScreen({
    super.key,
    required this.land,
    required this.ownerUserId,
  });

  final Land land;
  final String ownerUserId;

  @override
  State<ManageLandListingScreen> createState() =>
      _ManageLandListingScreenState();
}

class _ManageLandListingScreenState extends State<ManageLandListingScreen> {
  final _service = LandService();
  late Land _land;
  late Future<int> _countFuture;

  @override
  void initState() {
    super.initState();
    _land = widget.land;
    _countFuture = _loadCount();
  }

  Future<int> _loadCount() => _service.getApplicationCountForLand(_land.id);

  void _refresh() {
    setState(() {
      _countFuture = _loadCount();
    });
  }

  Future<void> _editListing() async {
    final updated = await Navigator.push<Land?>(
      context,
      MaterialPageRoute<Land?>(
        builder: (_) => OfferLandScreen(land: _land),
      ),
    );
    // Reload land from service in case it was updated
    final lands = await _service.getLandsByOwner(widget.ownerUserId);
    final current = lands.where((item) => item.id == _land.id);
    if (mounted && current.isNotEmpty) {
      setState(() {
        _land = current.first;
      });
      _refresh();
    } else if (updated != null && mounted) {
      setState(() => _land = updated);
      _refresh();
    }
  }

  Future<void> _toggleCloseListing() async {
    final willClose = _land.status.toLowerCase() != 'closed';
    final newStatus = willClose ? 'Closed' : 'Available';

    try {
      final updated = _land.copyWith(status: newStatus);
      await _service.updateLand(updated);
      if (!mounted) return;
      setState(() => _land = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            willClose
                ? 'Listing has been closed to new applicants.'
                : 'Listing is now available for applicants.',
          ),
          backgroundColor:
              willClose ? AppColors.muted : AppColors.farmAccent,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update status: $error')),
      );
    }
  }

  Future<void> _deleteListing() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Delete Listing?',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.dark),
        ),
        content: const Text(
          'This will permanently delete this land listing and all farmer applications submitted for it. This action cannot be undone.',
          style: TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteLand(_land.id, widget.ownerUserId);
      if (!mounted) return;
      Navigator.pop(context, true); // return to listings screen with deleted flag
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete listing: $error')),
      );
    }
  }

  void _openApplications() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LandApplicationsScreen(
          land: _land,
          ownerUserId: widget.ownerUserId,
        ),
      ),
    ).then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = _land.status.toLowerCase() == 'closed';
    final image = _land.images.isEmpty ? null : _land.images.first;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Manage Listing'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          // Land Image
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: image != null && image.startsWith('http')
                ? Image.network(
                    image,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderImage(),
                  )
                : _placeholderImage(),
          ),
          const SizedBox(height: 18),

          // Land Name and Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _land.landName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _statusChip(isClosed ? 'Closed' : 'Available', isClosed),
            ],
          ),
          const SizedBox(height: 10),

          // Location
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.farmAccent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _land.location,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Feature chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip(
                icon: Icons.square_foot_rounded,
                text:
                    '${_land.area % 1 == 0 ? _land.area.toInt() : _land.area} ${_land.areaUnit}',
              ),
              _infoChip(
                icon: Icons.grass_rounded,
                text: _land.preferredCrop,
              ),
              _infoChip(
                icon: Icons.water_drop_outlined,
                text: _land.waterSource,
              ),
              _infoChip(
                icon: Icons.terrain_rounded,
                text: _land.soilType,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Applications Button with Badge
          FutureBuilder<int>(
            future: _countFuture,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: _openApplications,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.farmTint,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.people_alt_outlined,
                              color: AppColors.farmAccent,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Applications',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.dark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  count == 0
                                      ? 'No farmer applications yet'
                                      : '$count ${count == 1 ? 'farmer applied for this land' : 'farmers applied for this land'}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Badge showing total count
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.farmAccent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          // About This Land Description
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
                const Text(
                  'About this land',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _land.description.isEmpty
                      ? 'No additional description provided.'
                      : _land.description,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Manage Actions: Edit Listing, Close Listing, Delete Listing
          const Text(
            'Listing Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 12),

          // Edit Listing Button
          OutlinedButton.icon(
            onPressed: _editListing,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Listing'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Close / Reopen Listing Button
          OutlinedButton.icon(
            onPressed: _toggleCloseListing,
            icon: Icon(isClosed
                ? Icons.restart_alt_rounded
                : Icons.inventory_2_outlined),
            label: Text(isClosed ? 'Reopen Listing' : 'Close Listing'),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  isClosed ? AppColors.farmAccent : AppColors.muted,
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Delete Listing Button
          TextButton.icon(
            onPressed: _deleteListing,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete Listing'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() => Container(
        height: 200,
        width: double.infinity,
        color: AppColors.farmTint,
        child: const Icon(
          Icons.landscape_rounded,
          color: AppColors.farmAccent,
          size: 56,
        ),
      );

  Widget _infoChip({required IconData icon, required String text}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.farmTint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.farmAccent),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.dark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _statusChip(String label, bool isClosed) {
    final color = isClosed ? AppColors.muted : AppColors.farmAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
