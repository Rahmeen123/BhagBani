import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../models/land.dart';
import '../../providers/auth_scope.dart';
import '../../services/land_service.dart';
import '../../utils/land_geometry.dart';
import '../../widgets/direct_contact_card.dart';
import '../../widgets/land_boundary_map.dart';
import '../../widgets/primary_button.dart';

class FindLandScreen extends StatefulWidget {
  const FindLandScreen({super.key});

  @override
  State<FindLandScreen> createState() => _FindLandScreenState();
}

class _FindLandScreenState extends State<FindLandScreen> {
  final _service = LandService();
  final _searchController = TextEditingController();
  late Future<List<Land>> _landsFuture;
  String? _location;
  String? _area;
  String? _crop;
  String? _water;

  @override
  void initState() {
    super.initState();
    _landsFuture = _service.getLands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openLand(Land land) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LandDetailScreen(land: land, service: _service),
      ),
    );
  }

  bool _matches(Land land) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty &&
        !land.landName.toLowerCase().contains(query) &&
        !land.location.toLowerCase().contains(query)) {
      return false;
    }
    if (_location != null && land.location != _location) return false;
    if (_crop != null && land.preferredCrop != _crop) return false;
    if (_water != null && land.waterSource != _water) return false;
    if (_area == 'Under 5 acres' && land.area >= 5) return false;
    if (_area == '5-20 acres' && (land.area < 5 || land.area > 20)) {
      return false;
    }
    if (_area == 'Over 20 acres' && land.area <= 20) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final isGuest = auth.isGuest || (auth.profile?.isGuest ?? false);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: const Text('Find Land'),
        actions: [
          if (!isGuest)
            IconButton(
              tooltip: 'My land listings',
              onPressed: () => Navigator.pushNamed(
                context,
                '/my-land-listings',
                arguments: AuthScope.of(context).profile?.email ?? '',
              ),
              icon: const Icon(Icons.landscape_outlined),
            ),
        ],
      ),
      body: FutureBuilder<List<Land>>(
        future: _landsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load land listings',
              detail: snapshot.error.toString(),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final available = snapshot.data!
              .where((land) => land.status.toLowerCase() == 'available')
              .toList();
          final filtered = available.where(_matches).toList();
          final locations =
              available.map((land) => land.location).toSet().toList()..sort();
          final crops = available
              .map((land) => land.preferredCrop)
              .toSet()
              .toList()
            ..sort();
          final waters = available
              .map((land) => land.waterSource)
              .toSet()
              .toList()
            ..sort();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.agriculture_rounded,
                        color: AppColors.farmAccent, size: 34),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grow something great',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Explore farmland shared by owners, inspect boundaries, and contact owners directly.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search land by name or location',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _filter<String>(
                    label: 'Location',
                    value: _location,
                    options: locations,
                    onChanged: (value) => setState(() => _location = value),
                  ),
                  _filter<String>(
                    label: 'Preferred crop',
                    value: _crop,
                    options: crops,
                    onChanged: (value) => setState(() => _crop = value),
                  ),
                  _filter<String>(
                    label: 'Water source',
                    value: _water,
                    options: waters,
                    onChanged: (value) => setState(() => _water = value),
                  ),
                  _filter<String>(
                    label: 'Area',
                    value: _area,
                    options: const [
                      'Under 5 acres',
                      '5-20 acres',
                      'Over 20 acres'
                    ],
                    onChanged: (value) => setState(() => _area = value),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '${filtered.length} available ${filtered.length == 1 ? 'land' : 'lands'}',
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (filtered.isEmpty)
                const _LoadMessage(
                  icon: Icons.search_off_rounded,
                  title: 'No matching land found',
                  detail: 'Try adjusting your search or filters.',
                )
              else
                ...filtered.map(
                  (land) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _LandCard(land: land, onView: () => _openLand(land)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class LandDetailScreen extends StatelessWidget {
  const LandDetailScreen({
    super.key,
    required this.land,
    required this.service,
    this.mapBuilder,
  });

  final Land land;
  final LandService service;
  final BoundaryMapBuilder? mapBuilder;

  @override
  Widget build(BuildContext context) {
    final boundaryAcres = land.hasBoundary
        ? LandGeometry.areaAcres(land.polygonCoordinates)
        : land.area;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: const Text('Land Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // ── Map Section ───────────────────────────────────────────────────
          if (land.hasBoundary || land.centerLocation != null) ...[
            LandBoundaryMap(
              points: land.polygonCoordinates,
              centerPoint: land.centerLocation,
              editable: false,
              initialMapType: MapType.satellite,
              height: 260,
              borderRadius: 22,
              mapBuilder: mapBuilder,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.satellite_alt_rounded,
                    size: 18,
                    color: AppColors.farmAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected Land Area: ${LandGeometry.formatAcres(boundaryAcres)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                  if (land.perimeterMeters != null && land.perimeterMeters! > 0)
                    Text(
                      LandGeometry.formatPerimeter(land.perimeterMeters!),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
          ] else
            _LandGallery(land: land, height: 230),
          const SizedBox(height: 18),

          // ── Land Information ──────────────────────────────────────────────
          Text(
            land.landName,
            style: const TextStyle(
              color: AppColors.dark,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          _DetailLine(icon: Icons.location_on_outlined, text: land.location),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.square_foot_rounded,
                text: 'Area: ${_areaText(land)}',
              ),
              _InfoChip(
                icon: Icons.grass_rounded,
                text: 'Crop: ${land.preferredCrop}',
              ),
              _InfoChip(
                icon: Icons.water_drop_outlined,
                text:
                    'Irrigation: ${land.irrigationAvailable ? 'Available' : 'Not Available'}',
              ),
              _InfoChip(
                icon: Icons.opacity_rounded,
                text: 'Water: ${land.waterSource}',
              ),
              _InfoChip(
                icon: Icons.terrain_rounded,
                text: 'Soil: ${land.soilType}',
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle('Land Description'),
          const SizedBox(height: 8),
          Text(
            land.description,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // ── Contact Section ───────────────────────────────────────────────
          const _SectionTitle('Contact Owner'),
          const SizedBox(height: 10),
          DirectContactCard(
            roleLabel: 'Land Owner',
            name: land.ownerName,
            phoneNumber: land.ownerPhone,
            whatsappNumber: land.ownerWhatsapp,
            address: land.ownerAddress,
            callButtonLabel: 'Call Owner',
            whatsAppButtonLabel: 'WhatsApp Owner',
            whatsAppMessage:
                'Assalam-o-Alaikum ${land.ownerName}, I saw your land "${land.landName}" on Baghbani.',
            accentColor: AppColors.farmAccent,
            tintColor: AppColors.farmTint,
          ),
        ],
      ),
    );
  }
}

class _LandCard extends StatelessWidget {
  const _LandCard({required this.land, required this.onView});
  final Land land;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (land.hasBoundary)
            LandBoundaryPreview(
              points: land.polygonCoordinates,
              height: 174,
              badgeText: '${_areaText(land)} • Farm Boundary',
            )
          else
            _LandImage(land: land, height: 174),
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
                const SizedBox(height: 7),
                _DetailLine(
                    icon: Icons.location_on_outlined, text: land.location),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                        icon: Icons.square_foot_rounded, text: _areaText(land)),
                    _InfoChip(
                        icon: Icons.grass_rounded, text: land.preferredCrop),
                    _InfoChip(
                      icon: Icons.water_drop_outlined,
                      text: land.irrigationAvailable
                          ? 'Irrigation: ${land.waterSource}'
                          : 'Irrigation: Not Available',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  land.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child:
                      PrimaryButton(label: 'View Details', onPressed: onView),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LandImage extends StatelessWidget {
  const _LandImage({
    required this.land,
    required this.height,
    this.imageOverride,
  });
  final Land land;
  final double height;
  final String? imageOverride;

  @override
  Widget build(BuildContext context) {
    final image =
        imageOverride ?? (land.images.isEmpty ? null : land.images.first);
    if (image != null && image.startsWith('http')) {
      return Image.network(
        image,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(height),
      );
    }

    return _placeholder(height);
  }

  Widget _placeholder(double height) => Container(
        width: double.infinity,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.farmTint, AppColors.soft],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.landscape_rounded,
              color: AppColors.farmAccent, size: 54),
        ),
      );
}

class _LandGallery extends StatelessWidget {
  const _LandGallery({required this.land, required this.height});
  final Land land;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (land.images.length < 2) {
      return _LandImage(land: land, height: height);
    }
    return SizedBox(
      height: height,
      child: PageView.builder(
        itemCount: land.images.length,
        itemBuilder: (context, index) => _LandImage(
          land: land,
          height: height,
          imageOverride: land.images[index],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ),
        ],
      );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.farmTint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.farmAccent),
            const SizedBox(width: 5),
            Text(text,
                style: const TextStyle(color: AppColors.dark, fontSize: 11.5)),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
            color: AppColors.dark, fontSize: 16, fontWeight: FontWeight.w700),
      );
}

class _LoadMessage extends StatelessWidget {
  const _LoadMessage(
      {required this.icon, required this.title, required this.detail});
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Center(
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
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      );
}

Widget _filter<T>({
  required String label,
  required T? value,
  required List<T> options,
  required ValueChanged<T?> onChanged,
}) {
  return Container(
    constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: DropdownButton<T>(
      value: value,
      isExpanded: true,
      underline: const SizedBox.shrink(),
      hint: Text(label, overflow: TextOverflow.ellipsis),
      items: [
        DropdownMenuItem<T>(value: null, child: Text('All $label')),
        ...options.map((option) =>
            DropdownMenuItem<T>(value: option, child: Text('$option'))),
      ],
      onChanged: onChanged,
    ),
  );
}

String _areaText(Land land) =>
    '${land.area % 1 == 0 ? land.area.toInt() : land.area} ${land.areaUnit}';
