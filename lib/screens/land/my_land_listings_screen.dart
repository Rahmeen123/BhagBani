import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/land.dart';
import '../../services/land_service.dart';
import '../../widgets/primary_button.dart';
import 'manage_land_listing_screen.dart';
import 'offer_land_screen.dart';

class MyLandListingsScreen extends StatefulWidget {
  const MyLandListingsScreen({super.key, required this.ownerUserId});

  final String ownerUserId;

  @override
  State<MyLandListingsScreen> createState() => _MyLandListingsScreenState();
}

class _MyLandListingsScreenState extends State<MyLandListingsScreen> {
  final _service = LandService();
  late Future<List<Land>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Land>> _load() => _service.getLandsByOwner(widget.ownerUserId);

  void _refresh() => setState(() => _future = _load());

  Future<void> _manageListing(Land land) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ManageLandListingScreen(
          land: land,
          ownerUserId: widget.ownerUserId,
        ),
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _addNewLand() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const OfferLandScreen(),
      ),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          elevation: 0,
          title: const Text('My Land Listings'),
          actions: [
            IconButton(
              tooltip: 'Add New Land',
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: _addNewLand,
            ),
          ],
        ),
        body: FutureBuilder<List<Land>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _empty(
                Icons.cloud_off_outlined,
                'Could not load your listings',
                snapshot.error.toString(),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final listings = snapshot.data!;
            if (listings.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.landscape_outlined,
                        color: AppColors.farmAccent,
                        size: 56,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No Land Listings Yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.dark,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Offer your land so experienced farmers can contact you directly.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'Add New Land',
                        icon: Icons.add_rounded,
                        onPressed: _addNewLand,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
              children: [
                for (final land in listings) _listingCard(land),
              ],
            );
          },
        ),
      );

  Widget _listingCard(Land land) {
    final isClosed = land.status.toLowerCase() == 'closed';
    final image = land.images.isEmpty ? null : land.images.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Land Image
          if (image != null && image.startsWith('http'))
            Image.network(
              image,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imagePlaceholder(),
            )
          else
            _imagePlaceholder(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Land Name
                Text(
                  land.landName,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 17.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),

                // 3. Location
                _detail(Icons.location_on_outlined, land.location),
                const SizedBox(height: 6),

                // 4. Area
                _detail(
                  Icons.square_foot_rounded,
                  '${land.area % 1 == 0 ? land.area.toInt() : land.area} ${land.areaUnit}',
                ),
                const SizedBox(height: 10),

                // 5. Status & Irrigation
                Row(
                  children: [
                    _statusChip(isClosed ? 'Closed' : 'Available', isClosed),
                    const SizedBox(width: 8),
                    _irrigationChip(land.irrigationAvailable),
                  ],
                ),
                const SizedBox(height: 16),

                // Each card should have: Manage Listing
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Manage Listing',
                    icon: Icons.tune_rounded,
                    onPressed: () => _manageListing(land),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        height: 160,
        width: double.infinity,
        color: AppColors.farmTint,
        child: const Icon(
          Icons.landscape_rounded,
          color: AppColors.farmAccent,
          size: 48,
        ),
      );

  Widget _detail(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.farmAccent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      );

  Widget _statusChip(String label, bool isClosed) {
    final color = isClosed ? AppColors.muted : AppColors.farmAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  Widget _irrigationChip(bool available) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.water_drop_outlined,
            size: 13,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            available ? 'Irrigation Available' : 'Rainfed',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(IconData icon, String title, String detail) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.farmAccent, size: 42),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
}
