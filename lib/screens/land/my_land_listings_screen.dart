import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/land.dart';
import '../../services/land_service.dart';
import '../../widgets/primary_button.dart';
import 'land_marketplace_screens.dart';

class MyLandListingsScreen extends StatefulWidget {
  const MyLandListingsScreen({super.key, required this.ownerUserId});

  final String ownerUserId;

  @override
  State<MyLandListingsScreen> createState() => _MyLandListingsScreenState();
}

class _MyLandListingsScreenState extends State<MyLandListingsScreen> {
  final _service = LandService();
  late Future<List<({Land land, int applications})>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<({Land land, int applications})>> _load() async {
    final lands = await _service.getLandsByOwner(widget.ownerUserId);
    final result = <({Land land, int applications})>[];
    for (final land in lands) {
      result.add((
        land: land,
        applications: await _service.getApplicationCountForLand(land.id),
      ));
    }
    return result;
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _close(Land land) async {
    try {
      await _service.updateLand(
        land.copyWith(status: land.status == 'Closed' ? 'Available' : 'Closed'),
      );
      if (mounted) _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _delete(Land land) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Delete listing?'),
        content: const Text(
          'This will permanently remove the listing and its applications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteLand(land.id, widget.ownerUserId);
      if (mounted) _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _edit(Land land) async {
    try {
      await Navigator.pushNamed<void>(
        context,
        '/offer-land',
        arguments: land,
      );
      if (mounted) _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not update listing: $error')),
    );
  }

  void _applications(Land land) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MyLandApplicationsScreen(
          ownerUserId: widget.ownerUserId,
          landId: land.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          title: const Text('My Land Listings'),
        ),
        body: FutureBuilder<List<({Land land, int applications})>>(
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
              return _empty(
                Icons.landscape_outlined,
                'No land listings yet',
                'Land you offer will appear here.',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final item in listings)
                  _listingCard(item.land, item.applications),
              ],
            );
          },
        ),
      );

  Widget _listingCard(Land land, int applicationCount) {
    final isClosed = land.status.toLowerCase() == 'closed';
    final image = land.images.isEmpty ? null : land.images.first;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                Text(
                  land.landName,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _detail(Icons.location_on_outlined, land.location),
                const SizedBox(height: 6),
                _detail(
                  Icons.square_foot_rounded,
                  '${land.area % 1 == 0 ? land.area.toInt() : land.area} ${land.areaUnit}',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _statusChip(isClosed ? 'Closed' : 'Active', isClosed),
                    const SizedBox(width: 8),
                    _statusChip(
                      '$applicationCount ${applicationCount == 1 ? 'Application' : 'Applications'}',
                      false,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'View Applications',
                    icon: Icons.inbox_outlined,
                    onPressed: () => _applications(land),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _edit(land),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Listing'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(46),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _close(land),
                        icon: Icon(isClosed
                            ? Icons.restart_alt_rounded
                            : Icons.inventory_2_outlined),
                        label: Text(isClosed ? 'Reopen' : 'Close Listing'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.farmAccent,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _delete(land),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Delete Listing'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.gardenAccent,
                        ),
                      ),
                    ),
                  ],
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
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.muted)),
          ),
        ],
      );

  Widget _statusChip(String label, bool isClosed) {
    final color = isClosed ? AppColors.muted : AppColors.farmAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
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
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 5),
              Text(detail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ],
          ),
        ),
      );
}
