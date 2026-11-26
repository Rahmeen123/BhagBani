import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/primary_button.dart';
import '../models/crop_farm_location.dart';
import '../services/crop_location_service.dart';
import '../widgets/crop_feature_card.dart';
import 'crop_recommendation_result_screen.dart';

class CropLocationScreen extends StatefulWidget {
  const CropLocationScreen({super.key});

  @override
  State<CropLocationScreen> createState() => _CropLocationScreenState();
}

class _CropLocationScreenState extends State<CropLocationScreen> {
  static const _pakistanCenter = LatLng(30.3753, 69.3451);

  final _locationService = CropLocationService();
  GoogleMapController? _mapController;
  LatLng? _selectedPoint;
  String? _selectedAddress;
  String? _error;
  bool _isGeocoding = false;
  bool _isLocating = false;
  int _selectionRequest = 0;

  Future<void> _selectPoint(LatLng point) async {
    final request = ++_selectionRequest;
    setState(() {
      _selectedPoint = point;
      _selectedAddress = null;
      _error = null;
      _isLocating = false;
      _isGeocoding = true;
    });
    try {
      final farmLocation = await _locationService.fromCoordinates(
        latitude: point.latitude,
        longitude: point.longitude,
      );
      if (!mounted || request != _selectionRequest) return;
      setState(() => _selectedAddress = farmLocation.address);
    } on CropLocationException catch (error) {
      if (mounted && request == _selectionRequest) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted && request == _selectionRequest) {
        setState(() => _isGeocoding = false);
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    final request = ++_selectionRequest;
    setState(() {
      _isLocating = true;
      _isGeocoding = false;
      _selectedPoint = null;
      _selectedAddress = null;
      _error = null;
    });
    try {
      final farmLocation = await _locationService.currentLocation();
      if (!mounted || request != _selectionRequest) return;
      final point = LatLng(
        farmLocation.latitude,
        farmLocation.longitude,
      );
      setState(() {
        _selectedPoint = point;
        _selectedAddress = farmLocation.address;
      });
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: point, zoom: 16),
        ),
      );
    } on CropLocationException catch (error) {
      if (mounted && request == _selectionRequest) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted && request == _selectionRequest) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _continue() {
    final point = _selectedPoint;
    final address = _selectedAddress;
    if (point == null || address == null) return;
    final location = CropFarmLocation(
      latitude: point.latitude,
      longitude: point.longitude,
      address: address,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CropRecommendationResultScreen(
          location: location,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(title: const Text('Select Farm Location')),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: _pakistanCenter,
                        zoom: 5,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      onTap: _selectPoint,
                      markers: _selectedPoint == null
                          ? const <Marker>{}
                          : {
                              Marker(
                                markerId: const MarkerId('farm-location'),
                                position: _selectedPoint!,
                              ),
                            },
                      mapToolbarEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: FloatingActionButton.small(
                        heroTag: 'crop-current-location',
                        tooltip: 'Use current location',
                        onPressed: _isLocating ? null : _useCurrentLocation,
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.primary,
                        child: _isLocating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CropFeatureCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.farmAccent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Farm location',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (_isGeocoding)
                                  const Text(
                                    'Finding address...',
                                    style: TextStyle(color: AppColors.dark),
                                  )
                                else
                                  Text(
                                    _selectedAddress ??
                                        'Tap the map or use your current location',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                if (_error != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Color(0xFFB3261E),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _selectedAddress == null || _isGeocoding
                          ? null
                          : _continue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
