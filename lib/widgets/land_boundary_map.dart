import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/theme/app_theme.dart';
import '../models/land_coordinate.dart';
import '../utils/land_geometry.dart';

/// Signature allowing tests to substitute a lightweight stand-in for [GoogleMap].
typedef BoundaryMapBuilder = Widget Function(
  BuildContext context,
  BoundaryMapConfig config,
);

/// Configuration passed to [GoogleMap] or a test [BoundaryMapBuilder].
class BoundaryMapConfig {
  const BoundaryMapConfig({
    required this.initialCameraPosition,
    required this.mapType,
    required this.markers,
    required this.polylines,
    required this.polygons,
    required this.onMapCreated,
    required this.onTap,
  });

  final CameraPosition initialCameraPosition;
  final MapType mapType;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;
  final void Function(GoogleMapController controller) onMapCreated;
  final void Function(LatLng position)? onTap;
}

/// Interactive map widget used for drawing farm boundaries (Offer a Land)
/// and inspecting saved farm boundaries (Find Land).
class LandBoundaryMap extends StatefulWidget {
  const LandBoundaryMap({
    super.key,
    required this.points,
    this.centerPoint,
    this.editable = false,
    this.initialMapType = MapType.satellite,
    this.focusTarget,
    this.focusZoom = 16,
    this.onTapPoint,
    this.onDragPoint,
    this.onMyLocationPressed,
    this.isLocating = false,
    this.height,
    this.borderRadius = 20,
    this.mapBuilder,
  });

  final List<LandCoordinate> points;
  final LandCoordinate? centerPoint;
  final bool editable;
  final MapType initialMapType;
  final LandCoordinate? focusTarget;
  final double focusZoom;
  final ValueChanged<LandCoordinate>? onTapPoint;
  final void Function(int index, LandCoordinate updated)? onDragPoint;
  final VoidCallback? onMyLocationPressed;
  final bool isLocating;
  final double? height;
  final double borderRadius;
  final BoundaryMapBuilder? mapBuilder;

  @override
  State<LandBoundaryMap> createState() => _LandBoundaryMapState();
}

class _LandBoundaryMapState extends State<LandBoundaryMap> {
  static const _pakistanCenter = LatLng(30.3753, 69.3451);

  late MapType _mapType;
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    _mapType = widget.initialMapType;
  }

  @override
  void didUpdateWidget(covariant LandBoundaryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusTarget != null &&
        widget.focusTarget != oldWidget.focusTarget) {
      _moveCameraToPoint(widget.focusTarget!, zoom: widget.focusZoom);
    } else if (!widget.editable &&
        widget.points.length >= 3 &&
        widget.points != oldWidget.points) {
      _fitPolygonBounds();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  CameraPosition _initialCameraPosition() {
    if (widget.focusTarget != null) {
      return CameraPosition(
        target: LatLng(
          widget.focusTarget!.latitude,
          widget.focusTarget!.longitude,
        ),
        zoom: widget.focusZoom,
      );
    }
    if (widget.points.isNotEmpty) {
      final center =
          widget.centerPoint ?? LandGeometry.centerOf(widget.points)!;
      return CameraPosition(
        target: LatLng(center.latitude, center.longitude),
        zoom: 16,
      );
    }
    if (widget.centerPoint != null) {
      return CameraPosition(
        target: LatLng(
          widget.centerPoint!.latitude,
          widget.centerPoint!.longitude,
        ),
        zoom: 15,
      );
    }
    return const CameraPosition(target: _pakistanCenter, zoom: 5.5);
  }

  Future<void> _moveCameraToPoint(
    LandCoordinate target, {
    double zoom = 16,
  }) async {
    try {
      await _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(target.latitude, target.longitude),
            zoom: zoom,
          ),
        ),
      );
    } catch (_) {
      // Ignore controller calls when map platform view is unavailable in tests.
    }
  }

  Future<void> _fitPolygonBounds() async {
    if (widget.points.isEmpty) return;
    if (widget.points.length == 1) {
      await _moveCameraToPoint(widget.points.first, zoom: 16);
      return;
    }

    var minLat = widget.points.first.latitude;
    var maxLat = widget.points.first.latitude;
    var minLng = widget.points.first.longitude;
    var maxLng = widget.points.first.longitude;

    for (final point in widget.points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    if ((maxLat - minLat).abs() < 1e-6 && (maxLng - minLng).abs() < 1e-6) {
      await _moveCameraToPoint(widget.points.first, zoom: 16);
      return;
    }

    try {
      await _controller?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          56,
        ),
      );
    } catch (_) {
      // Ignore controller errors if view is not yet laid out.
    }
  }

  Future<void> _zoomBy(double delta) async {
    try {
      await _controller?.animateCamera(
        delta > 0 ? CameraUpdate.zoomIn() : CameraUpdate.zoomOut(),
      );
    } catch (_) {
      // Ignore in headless tests.
    }
  }

  Set<Marker> _buildMarkers() {
    if (widget.editable) {
      return {
        for (var i = 0; i < widget.points.length; i++)
          Marker(
            markerId: MarkerId('boundary-point-$i'),
            position: LatLng(
              widget.points[i].latitude,
              widget.points[i].longitude,
            ),
            draggable: widget.onDragPoint != null,
            infoWindow: InfoWindow(title: 'Point ${i + 1}'),
            onDragEnd: widget.onDragPoint == null
                ? null
                : (pos) => widget.onDragPoint!(
                      i,
                      LandCoordinate(
                        latitude: pos.latitude,
                        longitude: pos.longitude,
                      ),
                    ),
          ),
      };
    }

    final center = widget.centerPoint ?? LandGeometry.centerOf(widget.points);
    if (center == null) return const {};
    return {
      Marker(
        markerId: const MarkerId('farm-center'),
        position: LatLng(center.latitude, center.longitude),
        infoWindow: const InfoWindow(title: 'Farm Location'),
      ),
    };
  }

  Set<Polyline> _buildPolylines() {
    if (widget.points.length < 2) return const {};
    final latLngs = widget.points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(growable: true);
    if (widget.points.length >= 3) {
      latLngs.add(latLngs.first);
    }
    return {
      Polyline(
        polylineId: const PolylineId('farm-boundary-line'),
        points: latLngs,
        color: _mapType == MapType.satellite
            ? const Color(0xFF7CE89E)
            : AppColors.primary,
        width: 3,
      ),
    };
  }

  Set<Polygon> _buildPolygons() {
    if (widget.points.length < 3) return const {};
    return {
      Polygon(
        polygonId: const PolygonId('farm-boundary-polygon'),
        points: widget.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(growable: false),
        strokeColor: _mapType == MapType.satellite
            ? const Color(0xFF7CE89E)
            : AppColors.primary,
        strokeWidth: 2,
        fillColor: (_mapType == MapType.satellite
                ? const Color(0xFF4ADE80)
                : AppColors.primary)
            .withValues(alpha: 0.25),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final config = BoundaryMapConfig(
      initialCameraPosition: _initialCameraPosition(),
      mapType: _mapType,
      markers: _buildMarkers(),
      polylines: _buildPolylines(),
      polygons: _buildPolygons(),
      onMapCreated: (controller) {
        _controller = controller;
        if (widget.points.length >= 3) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _fitPolygonBounds();
          });
        }
      },
      onTap: widget.editable && widget.onTapPoint != null
          ? (latLng) => widget.onTapPoint!(
                LandCoordinate(
                  latitude: latLng.latitude,
                  longitude: latLng.longitude,
                ),
              )
          : null,
    );

    final mapWidget = widget.mapBuilder?.call(context, config) ??
        GoogleMap(
          initialCameraPosition: config.initialCameraPosition,
          mapType: config.mapType,
          markers: config.markers,
          polylines: config.polylines,
          polygons: config.polygons,
          onMapCreated: config.onMapCreated,
          onTap: config.onTap,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        );

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        children: [
          Positioned.fill(child: mapWidget),
          // Satellite / Normal Toggle
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapTypeChip(
                    label: 'Satellite',
                    icon: Icons.satellite_alt_rounded,
                    selected: _mapType == MapType.satellite,
                    onTap: () => setState(() => _mapType = MapType.satellite),
                  ),
                  const SizedBox(width: 2),
                  _MapTypeChip(
                    label: 'Normal',
                    icon: Icons.map_outlined,
                    selected: _mapType == MapType.normal,
                    onTap: () => setState(() => _mapType = MapType.normal),
                  ),
                ],
              ),
            ),
          ),

          // Right-hand controls: My Location, Fit Boundary, Zoom In/Out
          Positioned(
            right: 12,
            top: 12,
            child: Column(
              children: [
                if (widget.onMyLocationPressed != null) ...[
                  _MapOverlayButton(
                    tooltip: 'Use current location',
                    onPressed:
                        widget.isLocating ? null : widget.onMyLocationPressed,
                    child: widget.isLocating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (widget.points.length >= 3) ...[
                  _MapOverlayButton(
                    tooltip: 'Center on boundary',
                    onPressed: _fitPolygonBounds,
                    child: const Icon(
                      Icons.center_focus_strong_rounded,
                      size: 20,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _MapOverlayButton(
                  tooltip: 'Zoom in',
                  onPressed: () => _zoomBy(1),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                _MapOverlayButton(
                  tooltip: 'Zoom out',
                  onPressed: () => _zoomBy(-1),
                  child: const Icon(
                    Icons.remove_rounded,
                    size: 20,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.height != null) {
      return SizedBox(
        width: double.infinity,
        height: widget.height,
        child: content,
      );
    }
    return content;
  }
}

class _MapTypeChip extends StatelessWidget {
  const _MapTypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : AppColors.dark,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.dark,
                ),
              ),
            ],
          ),
        ),
      );
}

class _MapOverlayButton extends StatelessWidget {
  const _MapOverlayButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: AppColors.white.withValues(alpha: 0.95),
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Center(child: child),
            ),
          ),
        ),
      );
}

/// Vector preview of a saved farm boundary polygon used in listing cards
/// so no images need to be stored or fetched.
class LandBoundaryPreview extends StatelessWidget {
  const LandBoundaryPreview({
    super.key,
    required this.points,
    this.height = 174,
    this.badgeText = 'Mapped Boundary',
  });

  final List<LandCoordinate> points;
  final double height;
  final String badgeText;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F3B2C), Color(0xFF2E5941)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _PolygonPreviewPainter(points: points),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.pentagon_outlined,
                      size: 14,
                      color: Color(0xFF7CE89E),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _PolygonPreviewPainter extends CustomPainter {
  const _PolygonPreviewPainter({required this.points});

  final List<LandCoordinate> points;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 28.0;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.length < 3) return;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points.skip(1)) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    final spanLng = math.max(maxLng - minLng, 1e-6);
    final spanLat = math.max(maxLat - minLat, 1e-6);
    const padX = 48.0;
    const padY = 34.0;
    final drawWidth = math.max(size.width - padX * 2, 20.0);
    final drawHeight = math.max(size.height - padY * 2, 20.0);
    final scale = math.min(drawWidth / spanLng, drawHeight / spanLat);
    final offsetX = (size.width - spanLng * scale) / 2;
    final offsetY = (size.height - spanLat * scale) / 2;

    final path = Path();
    final vertexOffsets = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final x = offsetX + (p.longitude - minLng) * scale;
      final y = offsetY + (maxLat - p.latitude) * scale;
      final offset = Offset(x, y);
      vertexOffsets.add(offset);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final fillPaint = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF7CE89E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    final dotPaint = Paint()..color = Colors.white;
    for (final vertex in vertexOffsets) {
      canvas.drawCircle(vertex, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PolygonPreviewPainter oldDelegate) =>
      oldDelegate.points != points;
}
