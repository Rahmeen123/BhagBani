import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/primary_button.dart';
import '../models/land_analysis_request.dart';
import '../repository/satellite_analysis_repository.dart';
import 'satellite_analysis_loading_screen.dart';

class LandAnalysisScreen extends StatefulWidget {
  const LandAnalysisScreen({
    super.key,
    this.repository,
  });

  final SatelliteAnalysisRepository? repository;

  @override
  State<LandAnalysisScreen> createState() => _LandAnalysisScreenState();
}

class _LandAnalysisScreenState extends State<LandAnalysisScreen> {
  static const _pakistanCenter = LatLng(30.3753, 69.3451);

  final List<LatLng> _boundary = [];
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isConfirmed = false;
  String? _selectionError;
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _addPoint(LatLng point) {
    if (_isConfirmed) return;
    if (_boundary.length >= 500) {
      setState(
          () => _selectionError = 'A boundary can contain up to 500 points.');
      return;
    }
    setState(() {
      _boundary.add(point);
      _selectionError = null;
    });
  }

  Future<void> _selectDate({required bool start}) async {
    final earliestDate = DateTime(2015);
    final today = DateTime.now();
    final minimumStart =
        _endDate.subtract(const Duration(days: 365)).isAfter(earliestDate)
            ? _endDate.subtract(const Duration(days: 365))
            : earliestDate;
    final maximumEnd = _startDate.add(const Duration(days: 365)).isBefore(today)
        ? _startDate.add(const Duration(days: 365))
        : today;
    final selected = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : _endDate,
      firstDate: start ? minimumStart : _startDate,
      lastDate: start ? _endDate : maximumEnd,
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (start) {
        _startDate = selected.isAfter(_endDate) ? _endDate : selected;
      } else {
        _endDate = selected.isBefore(_startDate) ? _startDate : selected;
      }
    });
  }

  Future<void> _analyze() async {
    final request = LandAnalysisRequest(
      boundary: _boundary
          .map((point) => <double>[point.longitude, point.latitude])
          .toList(growable: false),
      startDate: _startDate,
      endDate: _endDate,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SatelliteAnalysisLoadingScreen(
          request: request,
          repository: widget.repository,
        ),
      ),
    );
  }

  String _displayDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: const Text('Land Analysis'),
          actions: [
            if (_boundary.isNotEmpty)
              IconButton(
                tooltip: 'Clear boundary',
                onPressed: () => setState(() {
                  _boundary.clear();
                  _isConfirmed = false;
                  _selectionError = null;
                }),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
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
                      onTap: _addPoint,
                      mapToolbarEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      markers: {
                        for (var index = 0; index < _boundary.length; index++)
                          Marker(
                            markerId: MarkerId('boundary-$index'),
                            position: _boundary[index],
                            infoWindow: InfoWindow(title: 'Point ${index + 1}'),
                          ),
                      },
                      polylines: _boundary.length < 2
                          ? const {}
                          : {
                              Polyline(
                                polylineId: const PolylineId('farm-boundary'),
                                points: [
                                  ..._boundary,
                                  if (_isConfirmed) _boundary.first,
                                ],
                                color: AppColors.primary,
                                width: 3,
                              ),
                            },
                      polygons: !_isConfirmed || _boundary.length < 3
                          ? const {}
                          : {
                              Polygon(
                                polygonId: const PolygonId('farm-area'),
                                points: _boundary,
                                strokeColor: AppColors.primary,
                                strokeWidth: 2,
                                fillColor:
                                    AppColors.primary.withValues(alpha: 0.18),
                              ),
                            },
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _isConfirmed
                              ? 'Boundary confirmed · ${_boundary.length} points'
                              : 'Tap the map to draw your farm boundary',
                          style: const TextStyle(
                            color: AppColors.dark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                    if (!_isConfirmed) ...[
                      Text(
                        '${_boundary.length} boundary point${_boundary.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      PrimaryButton(
                        label: 'Confirm land',
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: _boundary.length < 3
                            ? null
                            : () => setState(() {
                                  _isConfirmed = true;
                                  _selectionError = null;
                                }),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _selectDate(start: true),
                              child: Text('From ${_displayDate(_startDate)}'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _selectDate(start: false),
                              child: Text('To ${_displayDate(_endDate)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      PrimaryButton(
                        label: 'Analyze land',
                        icon: Icons.satellite_alt_rounded,
                        onPressed: _analyze,
                      ),
                    ],
                    if (_selectionError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _selectionError!,
                        style: const TextStyle(
                          color: Color(0xFFB3261E),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (_isConfirmed)
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () => setState(() => _isConfirmed = false),
                          child: const Text('Edit boundary'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
