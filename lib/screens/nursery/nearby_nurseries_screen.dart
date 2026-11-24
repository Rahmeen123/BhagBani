import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'
    hide LocationServiceDisabledException;

import '../../core/theme/app_theme.dart';
import '../../features/tree_recommendation/models/land_location.dart';
import '../../features/tree_recommendation/services/location_service.dart';
import '../../models/nursery.dart';
import '../../services/nursery_service.dart';
import 'browse_plants_screen.dart';
import 'widgets/nursery_card.dart';

class NearbyNurseriesScreen extends StatefulWidget {
  const NearbyNurseriesScreen({
    super.key,
    this.nurseryService,
    this.locationService,
  });

  final NurseryService? nurseryService;
  final LocationService? locationService;

  @override
  State<NearbyNurseriesScreen> createState() => _NearbyNurseriesScreenState();
}

class _NearbyNurseriesScreenState extends State<NearbyNurseriesScreen>
    with WidgetsBindingObserver {
  late final _service = widget.nurseryService ?? NurseryService();
  late final _locationService = widget.locationService ?? LocationService();
  final _searchController = TextEditingController();
  final _cityController = TextEditingController();

  List<Nursery> _allNurseries = [];
  List<Nursery> _filteredNurseries = [];
  List<LandLocation> _locationResults = const [];
  LandLocation? _userLocation;
  bool _isLoading = true;
  bool _isLocating = true;
  bool _isSearchingCity = false;
  bool _showCitySearch = false;
  bool _permissionPermanentlyDenied = false;
  bool _locationServicesDisabled = false;
  String? _nurseriesError;
  String? _locationError;
  String? _citySearchError;
  String? _locationNotice;
  String _selectedCity = 'All';

  final List<String> _cities = ['All', 'Lahore', 'Islamabad', 'Sahiwal'];

  final Map<String, int> _mockPlantCounts = {
    'nurs_1': 45,
    'nurs_2': 60,
    'nurs_3': 38,
    'nurs_4': 52,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_applyFilters);
    _loadNurseries();
    _locateUser();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_isLocating &&
        (_permissionPermanentlyDenied || _locationServicesDisabled)) {
      _locateUser();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _cityController.dispose();
    _locationService.close();
    super.dispose();
  }

  Future<void> _loadNurseries() async {
    setState(() {
      _isLoading = true;
      _nurseriesError = null;
    });
    try {
      final list = await _service.getNurseries();
      if (!mounted) return;
      setState(() {
        _allNurseries = list.where((nursery) => nursery.isApproved).toList();
        _isLoading = false;
        _updateFilteredNurseries();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _nurseriesError = 'Could not load nurseries. Please try again.';
      });
    }
  }

  Future<void> _locateUser() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
      _locationNotice = null;
      _permissionPermanentlyDenied = false;
      _locationServicesDisabled = false;
    });
    try {
      final coordinates =
          await _locationService.currentCoordinates(requirePrecise: true);
      final currentCoordinates = LandLocation(
        name: 'Current location',
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        label: 'Current Location',
      );
      if (!mounted) return;
      setState(() {
        _userLocation = currentCoordinates;
        _isLocating = false;
        _showCitySearch = false;
        _updateFilteredNurseries();
      });

      try {
        final address = await _locationService.reverseGeocode(
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
        );
        if (!mounted) return;
        if (_isCurrentLocation(coordinates)) {
          setState(() {
            _userLocation = LandLocation(
              name: address,
              latitude: coordinates.latitude,
              longitude: coordinates.longitude,
              label: 'Current Location',
            );
          });
        }
      } catch (error) {
        if (!mounted) return;
        if (_isCurrentLocation(coordinates)) {
          setState(() {
            _locationNotice =
                'Could not resolve your address. Nurseries are still sorted using your GPS location.';
          });
        }
      }
    } on LocationPermissionDeniedException {
      if (!mounted) return;
      setState(() {
        _isLocating = false;
        _locationError =
            'Location access is required to find nearby nurseries.';
      });
    } on LocationPermissionDeniedForeverException {
      if (!mounted) return;
      setState(() {
        _isLocating = false;
        _permissionPermanentlyDenied = true;
        _locationError =
            'Location access is required to find nearby nurseries.';
      });
    } on LocationAccuracyReducedException {
      if (!mounted) return;
      setState(() {
        _isLocating = false;
        _permissionPermanentlyDenied = true;
        _locationError =
            'Precise location access is needed to show your exact area. Enable precise location in app settings, or search by city.';
      });
    } on LocationServiceDisabledException {
      if (!mounted) return;
      setState(() {
        _isLocating = false;
        _locationServicesDisabled = true;
        _locationError =
            'Location access is required to find nearby nurseries.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLocating = false;
        _locationError =
            'Unable to detect your location. Enable location or search by city.';
      });
    }
  }

  bool _isCurrentLocation(LandLocation location) =>
      _userLocation?.latitude == location.latitude &&
      _userLocation?.longitude == location.longitude;

  Future<void> _enableLocation() async {
    if (_permissionPermanentlyDenied) {
      final opened = await _locationService.openAppSettings();
      if (!opened && mounted) {
        setState(() {
          _locationError =
              'Unable to open app settings. Enable location access in your device settings, or search by city.';
        });
      }
      return;
    }
    if (_locationServicesDisabled) {
      final opened = await _locationService.openLocationSettings();
      if (!opened && mounted) {
        setState(() {
          _locationError =
              'Unable to open location settings. Turn on location services, or search by city.';
        });
      }
      return;
    }
    await _locateUser();
  }

  Future<void> _searchCity() async {
    final query = _cityController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _citySearchError = 'Enter a town, city, or address to search.';
        _locationResults = const [];
      });
      return;
    }
    setState(() {
      _isSearchingCity = true;
      _citySearchError = null;
      _locationResults = const [];
    });
    try {
      final results = await _locationService.search(query);
      if (!mounted) return;
      setState(() {
        _locationResults = results;
        if (results.isEmpty) {
          _citySearchError = 'No locations found. Try another city or address.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _citySearchError =
            'Could not search locations. Check your connection and try again.';
      });
    } finally {
      if (mounted) setState(() => _isSearchingCity = false);
    }
  }

  void _selectLocation(LandLocation location) {
    setState(() {
      _userLocation = location;
      _showCitySearch = false;
      _locationError = null;
      _locationNotice = null;
      _locationResults = const [];
      _selectedCity = 'All';
      _updateFilteredNurseries();
    });
  }

  void _applyFilters() {
    if (!mounted) return;
    setState(_updateFilteredNurseries);
  }

  void _updateFilteredNurseries() {
    final query = _searchController.text.trim().toLowerCase();
    final location = _userLocation;
    _filteredNurseries = _allNurseries.where((nursery) {
      final matchesQuery = query.isEmpty ||
          nursery.nurseryName.toLowerCase().contains(query) ||
          nursery.address.toLowerCase().contains(query) ||
          nursery.city.toLowerCase().contains(query);
      final matchesCity = _selectedCity == 'All' ||
          nursery.city.toLowerCase() == _selectedCity.toLowerCase();
      return matchesQuery && matchesCity;
    }).toList();

    if (location != null) {
      _filteredNurseries.sort((first, second) {
        final firstDistance = _distanceTo(first, location);
        final secondDistance = _distanceTo(second, location);
        return firstDistance.compareTo(secondDistance);
      });
    }
  }

  double _distanceTo(Nursery nursery, LandLocation location) =>
      Geolocator.distanceBetween(
        location.latitude,
        location.longitude,
        nursery.latitude,
        nursery.longitude,
      );

  String _formatDistance(Nursery nursery) {
    final location = _userLocation!;
    final meters = _distanceTo(nursery, location);
    if (meters < 1000) return '${meters.round()} m away';
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Nearby Nurseries'),
      ),
      body: _showCitySearch
          ? _buildCitySearch()
          : _userLocation == null
              ? _buildLocationRequired()
              : _buildNearbyNurseries(),
    );
  }

  Widget _buildLocationRequired() {
    if (_isLocating) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 14),
            Text(
              'Finding nurseries near you...',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      );
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.nurseryTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _locationError ??
                    'Location access is required to find nearby nurseries.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _enableLocation,
                  icon: const Icon(Icons.my_location_rounded),
                  label: const Text('Enable Location'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _showCitySearch = true;
                    _citySearchError = null;
                  }),
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Search by City'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCitySearch() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
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
                'Search by City',
                style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a city or address to find nurseries nearby.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchCity(),
                      decoration: const InputDecoration(
                        hintText: 'Enter a city or address',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSearchingCity ? null : _searchCity,
                    icon: _isSearchingCity
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_citySearchError != null) ...[
          const SizedBox(height: 12),
          Text(
            _citySearchError!,
            style: const TextStyle(color: Color(0xFFB3261E), fontSize: 13),
          ),
        ],
        if (_locationResults.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Search results',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          for (final location in _locationResults)
            Card(
              color: AppColors.white,
              child: ListTile(
                leading: const Icon(
                  Icons.place_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  location.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _selectLocation(location),
              ),
            ),
        ],
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => setState(() {
            _showCitySearch = false;
            _locationResults = const [];
          }),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Back'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildNearbyNurseries() {
    return Column(
      children: [
        _buildLocationCard(),
        if (_locationNotice != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _locationNotice!,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    color: AppColors.muted, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search nursery by name or city...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      hintStyle:
                          TextStyle(color: AppColors.muted, fontSize: 13.5),
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear,
                        size: 18, color: AppColors.muted),
                    onPressed: _searchController.clear,
                  ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _cities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final city = _cities[index];
              final isSelected = _selectedCity == city;
              return ChoiceChip(
                label: Text(city),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.white,
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.dark,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedCity = city;
                    _updateFilteredNurseries();
                  });
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredNurseries.length} Nurseries Found',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const Text(
                'Sorted by distance',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _nurseriesError != null
                  ? _loadErrorState()
                  : _filteredNurseries.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _loadNurseries,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                            itemCount: _filteredNurseries.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final nursery = _filteredNurseries[index];
                              return NurseryCard(
                                nursery: nursery,
                                distance: _formatDistance(nursery),
                                availablePlantsCount:
                                    _mockPlantCounts[nursery.id] ?? 30,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => BrowsePlantsScreen(
                                        initialNurseryId: nursery.id,
                                        initialNurseryName: nursery.nurseryName,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded,
                color: AppColors.primary, size: 23),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Location',
                    style: TextStyle(
                      color: AppColors.dark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _userLocation!.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _showCitySearch = true;
                _locationResults = const [];
                _citySearchError = null;
              }),
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadErrorState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _nurseriesError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _loadNurseries,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.nurseryTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.store_mall_directory_outlined,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Nurseries Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try selecting another city or adjusting your search keywords.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
}
