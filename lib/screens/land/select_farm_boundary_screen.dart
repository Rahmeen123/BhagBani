import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../features/tree_recommendation/models/land_location.dart';
import '../../features/tree_recommendation/services/location_service.dart';
import '../../models/land.dart';
import '../../models/land_coordinate.dart';
import '../../models/land_offer.dart';
import '../../providers/auth_scope.dart';
import '../../services/land_service.dart';
import '../../utils/land_geometry.dart';
import '../../widgets/land_boundary_map.dart';
import '../../widgets/primary_button.dart';
import 'my_land_listings_screen.dart';

/// Holds the land details entered on [OfferLandScreen] before boundary selection.
class OfferLandDraft {
  const OfferLandDraft({
    required this.title,
    required this.location,
    required this.estimatedAreaAcres,
    required this.soilType,
    required this.preferredCrop,
    required this.waterSource,
    required this.partnershipType,
    required this.description,
    this.existingLand,
  });

  final String title;
  final String location;
  final double estimatedAreaAcres;
  final String soilType;
  final String preferredCrop;
  final String waterSource;
  final String partnershipType;
  final String description;
  final Land? existingLand;
}

class SelectFarmBoundaryScreen extends StatefulWidget {
  SelectFarmBoundaryScreen({
    super.key,
    required this.draft,
    LandService? landService,
    LocationService? locationService,
    this.mapBuilder,
  })  : landService = landService ?? LandService(),
        locationService = locationService ?? LocationService();

  final OfferLandDraft draft;
  final LandService landService;
  final LocationService locationService;
  final BoundaryMapBuilder? mapBuilder;

  @override
  State<SelectFarmBoundaryScreen> createState() =>
      _SelectFarmBoundaryScreenState();
}

class _SelectFarmBoundaryScreenState extends State<SelectFarmBoundaryScreen> {
  final _searchController = TextEditingController();
  late final TextEditingController _addressController;

  List<LandCoordinate> _points = [];
  List<LandLocation> _searchResults = const [];
  LandCoordinate? _focusTarget;
  bool _isConfirmed = false;
  bool _isSearching = false;
  bool _isLocating = false;
  bool _isResolvingAddress = false;
  bool _isSaving = false;
  String? _statusError;
  int _addressRequestId = 0;

  @override
  void initState() {
    super.initState();
    final existing = widget.draft.existingLand;
    if (existing != null && existing.polygonCoordinates.isNotEmpty) {
      _points = List<LandCoordinate>.from(existing.polygonCoordinates);
      _focusTarget =
          existing.centerLocation ?? LandGeometry.centerOf(_points);
      _isConfirmed = _points.length >= 3;
    }
    _addressController = TextEditingController(text: widget.draft.location);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addressController.dispose();
    widget.locationService.close();
    super.dispose();
  }

  double get _areaAcres => LandGeometry.areaAcres(_points);
  double get _perimeterMeters => LandGeometry.perimeterMeters(_points);
  LandCoordinate? get _center => LandGeometry.centerOf(_points);

  void _addPoint(LandCoordinate point) {
    if (_isConfirmed) return;
    setState(() {
      _points = [..._points, point];
      _statusError = null;
    });
    if (_points.length >= 3) {
      _resolveAddressForCenter();
    }
  }

  void _updatePoint(int index, LandCoordinate updated) {
    if (_isConfirmed || index < 0 || index >= _points.length) return;
    setState(() {
      final copy = List<LandCoordinate>.from(_points);
      copy[index] = updated;
      _points = copy;
    });
    if (_points.length >= 3) {
      _resolveAddressForCenter();
    }
  }

  void _undoLastPoint() {
    if (_isConfirmed || _points.isEmpty) return;
    setState(() {
      _points = _points.sublist(0, _points.length - 1);
      _statusError = null;
    });
    if (_points.length >= 3) {
      _resolveAddressForCenter();
    }
  }

  void _clearPoints() {
    if (_points.isEmpty) return;
    setState(() {
      _points = [];
      _isConfirmed = false;
      _statusError = null;
    });
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _statusError = 'Enter a town, village, or area to search.');
      return;
    }
    setState(() {
      _isSearching = true;
      _statusError = null;
    });
    try {
      final results = await widget.locationService.search(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        if (results.isEmpty) {
          _statusError = 'No locations found for "$query".';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusError = 'Could not search location. Check your connection.';
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(LandLocation location) {
    setState(() {
      _focusTarget = LandCoordinate(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      _searchResults = const [];
      _statusError = null;
      if (_points.isEmpty) {
        _addressController.text = location.name;
      }
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _statusError = null;
    });
    try {
      final current = await widget.locationService.currentCoordinates();
      if (!mounted) return;
      final coord = LandCoordinate(
        latitude: current.latitude,
        longitude: current.longitude,
      );
      setState(() {
        _focusTarget = coord;
      });
      final resolved = await _reverseGeocode(coord);
      if (mounted && resolved != null && resolved.isNotEmpty) {
        _addressController.text = resolved;
      }
    } on LocationPermissionDeniedException {
      if (mounted) {
        setState(() => _statusError = 'Location permission denied.');
      }
    } on LocationPermissionDeniedForeverException {
      if (mounted) {
        setState(() => _statusError =
            'Location permission disabled. Enable it in settings or search manually.');
      }
    } on LocationServiceDisabledException {
      if (mounted) {
        setState(() => _statusError = 'Turn on device GPS/location services.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _statusError = 'Could not detect current location.');
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _resolveAddressForCenter() async {
    final center = _center;
    if (center == null) return;
    final requestId = ++_addressRequestId;
    setState(() => _isResolvingAddress = true);
    final resolved = await _reverseGeocode(center);
    if (!mounted || requestId != _addressRequestId) return;
    setState(() {
      _isResolvingAddress = false;
      if (resolved != null && resolved.isNotEmpty) {
        _addressController.text = resolved;
      }
    });
  }

  Future<String?> _reverseGeocode(LandCoordinate point) async {
    try {
      return await widget.locationService.reverseGeocode(
        latitude: point.latitude,
        longitude: point.longitude,
      );
    } catch (_) {
      try {
        final placemarks = await geocoding.Geocoding().placemarkFromCoordinates(
          point.latitude,
          point.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.subLocality,
            p.locality ?? p.subAdministrativeArea,
            p.administrativeArea,
          ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty);
          final joined = parts.toSet().join(', ');
          if (joined.isNotEmpty) return joined;
        }
      } catch (_) {
        // Keep existing form address if offline.
      }
    }
    return null;
  }

  Future<void> _saveListing() async {
    if (_points.length < 3) {
      setState(() {
        _statusError = 'Tap at least 3 points on the map to draw your farm boundary.';
      });
      return;
    }

    final user = AuthScope.of(context).profile;
    final center = _center!;
    final calculatedAcres = double.parse(_areaAcres.toStringAsFixed(2));
    final perimeter = double.parse(_perimeterMeters.toStringAsFixed(1));
    final address = _addressController.text.trim().isNotEmpty
        ? _addressController.text.trim()
        : widget.draft.location;

    setState(() {
      _isSaving = true;
      _statusError = null;
    });

    try {
      final existing = widget.draft.existingLand;
      if (existing != null) {
        await widget.landService.updateLand(
          existing.copyWith(
            landName: widget.draft.title,
            location: address,
            area: calculatedAcres,
            areaUnit: 'Acres',
            soilType: widget.draft.soilType,
            waterSource: widget.draft.waterSource,
            preferredCrop: widget.draft.preferredCrop,
            description: widget.draft.description,
            images: const [],
            polygonCoordinates: List<LandCoordinate>.unmodifiable(_points),
            centerLocation: center,
            perimeterMeters: perimeter,
          ),
        );
      } else {
        final offer = LandOffer(
          id: 'land_${DateTime.now().millisecondsSinceEpoch}',
          userId: user?.email ?? '',
          ownerName: user?.name ?? 'Land Owner',
          title: widget.draft.title,
          location: address,
          acreage: '${calculatedAcres.toStringAsFixed(2)} Acres',
          waterSource: widget.draft.waterSource,
          partnershipType: widget.draft.partnershipType,
          description: widget.draft.description,
          createdAt: DateTime.now(),
          soilType: widget.draft.soilType,
          preferredCrop: widget.draft.preferredCrop,
          polygonCoordinates: List<LandCoordinate>.unmodifiable(_points),
          centerLocation: center,
          perimeterMeters: perimeter,
        );
        await widget.landService.submitLandOffer(offer);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save land listing: $error')),
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
                  ? 'Your farm boundary (${LandGeometry.formatAcres(calculatedAcres)}) and details are now visible to farmers in Find Land.'
                  : 'Your farm boundary and land listing details have been updated.',
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
    final hasPolygon = _points.length >= 3;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Select Farm Boundary'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _searchLocation(),
                          decoration: const InputDecoration(
                            hintText: 'Search village, town, or district',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppColors.muted,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSearching ? null : _searchLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSearching
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Search'),
                        ),
                      ),
                    ],
                  ),
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      constraints: const BoxConstraints(maxHeight: 160),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: AppColors.border,
                        ),
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.place_outlined,
                              color: AppColors.farmAccent,
                            ),
                            title: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                            onTap: () => _selectSearchResult(item),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Interactive Map
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    LandBoundaryMap(
                      points: _points,
                      centerPoint: _center,
                      editable: !_isConfirmed,
                      initialMapType: MapType.satellite,
                      focusTarget: _focusTarget,
                      onTapPoint: _addPoint,
                      onDragPoint: _updatePoint,
                      onMyLocationPressed: _useCurrentLocation,
                      isLocating: _isLocating,
                      mapBuilder: widget.mapBuilder,
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Text(
                          _isConfirmed
                              ? 'Boundary locked (${_points.length} points). Tap Edit Boundary to adjust.'
                              : _points.isEmpty
                                  ? 'Tap corners of your farm on the map to draw the boundary'
                                  : _points.length < 3
                                      ? '${_points.length} point${_points.length == 1 ? '' : 's'} placed — tap ${3 - _points.length} more to form polygon'
                                      : '${_points.length} boundary points placed — drag pins or tap to add more',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Controls + Auto-Calculated Summary
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isConfirmed || _points.isEmpty
                              ? null
                              : _undoLastPoint,
                          icon: const Icon(Icons.undo_rounded, size: 18),
                          label: const Text('Undo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.dark,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _points.isEmpty ? null : _clearPoints,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
                          label: const Text('Clear'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB3261E),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: !hasPolygon
                              ? null
                              : () => setState(
                                    () => _isConfirmed = !_isConfirmed,
                                  ),
                          icon: Icon(
                            _isConfirmed
                                ? Icons.edit_location_alt_outlined
                                : Icons.check_rounded,
                            size: 18,
                          ),
                          label: Text(_isConfirmed ? 'Edit Boundary' : 'Confirm'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Calculated Area & Perimeter
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MetricBlock(
                                label: 'Total Land Area',
                                value: hasPolygon
                                    ? LandGeometry.formatAcres(_areaAcres)
                                    : '0.00 Acres',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: AppColors.border,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: _MetricBlock(
                                  label: 'Perimeter',
                                  value: _points.length >= 2
                                      ? LandGeometry.formatPerimeter(
                                          _perimeterMeters,
                                        )
                                      : '0 m',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: AppColors.farmAccent,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _isResolvingAddress
                                    ? 'Resolving farm address...'
                                    : _addressController.text.trim().isEmpty
                                        ? 'Address will update from boundary center'
                                        : _addressController.text.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.dark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_center != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Center: ${_center!}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (_statusError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _statusError!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB3261E),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: widget.draft.existingLand == null
                        ? 'Save & Publish Land'
                        : 'Save Listing Changes',
                    icon: Icons.check_circle_rounded,
                    busy: _isSaving,
                    onPressed: _isSaving || !hasPolygon ? null : _saveListing,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      );
}
