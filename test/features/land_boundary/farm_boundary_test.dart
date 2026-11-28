import 'dart:math' as math;

import 'package:baghbani/features/tree_recommendation/models/land_location.dart';
import 'package:baghbani/features/tree_recommendation/services/location_service.dart';
import 'package:baghbani/models/land.dart';
import 'package:baghbani/models/land_coordinate.dart';
import 'package:baghbani/models/land_offer.dart';
import 'package:baghbani/models/user_profile.dart';
import 'package:baghbani/providers/auth_scope.dart';
import 'package:baghbani/screens/land/land_marketplace_screens.dart';
import 'package:baghbani/screens/land/offer_land_screen.dart';
import 'package:baghbani/screens/land/select_farm_boundary_screen.dart';
import 'package:baghbani/services/auth_service.dart';
import 'package:baghbani/services/land_service.dart';
import 'package:baghbani/utils/land_geometry.dart';
import 'package:baghbani/widgets/land_boundary_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LandGeometry and persistence', () {
    test('calculates area in acres, perimeter, and centroid accurately', () {
      const lat0 = 31.5204;
      const lon0 = 74.3587;
      // 63.614907m x 63.614907m square == 1.00 acre, perimeter ~254.46m
      const sideMeters = 63.614907;
      const dLat = (sideMeters / LandGeometry.earthRadiusMeters) * 180 / math.pi;
      final dLon = (sideMeters /
              (LandGeometry.earthRadiusMeters *
                  math.cos(lat0 * math.pi / 180))) *
          180 /
          math.pi;

      final square = [
        const LandCoordinate(latitude: lat0, longitude: lon0),
        const LandCoordinate(latitude: lat0 + dLat, longitude: lon0),
        LandCoordinate(latitude: lat0 + dLat, longitude: lon0 + dLon),
        LandCoordinate(latitude: lat0, longitude: lon0 + dLon),
      ];

      expect(LandGeometry.areaAcres(square), closeTo(1.0, 0.01));
      expect(LandGeometry.perimeterMeters(square), closeTo(254.46, 1.5));

      final center = LandGeometry.centerOf(square)!;
      expect(center.latitude, closeTo(lat0 + dLat / 2, 0.0001));
      expect(center.longitude, closeTo(lon0 + dLon / 2, 0.0001));
    });

    test('saves and restores polygon coordinates without storing images',
        () async {
      SharedPreferences.setMockInitialValues({});
      final service = LandService();
      const polygon = [
        LandCoordinate(latitude: 31.5200, longitude: 74.3580),
        LandCoordinate(latitude: 31.5210, longitude: 74.3580),
        LandCoordinate(latitude: 31.5210, longitude: 74.3590),
        LandCoordinate(latitude: 31.5200, longitude: 74.3590),
      ];
      final areaAcres = LandGeometry.areaAcres(polygon);
      final perimeter = LandGeometry.perimeterMeters(polygon);
      final center = LandGeometry.centerOf(polygon)!;

      await service.submitLandOffer(
        LandOffer(
          id: 'boundary_land_1',
          userId: 'owner@example.com',
          ownerName: 'Chaudhry Tariq',
          title: 'Irrigated Wheat Plot',
          location: 'Raiwind Road, Lahore',
          acreage: '${areaAcres.toStringAsFixed(2)} Acres',
          waterSource: 'Canal Water',
          partnershipType: 'Crop Sharing',
          description: 'Fertile plot with road access.',
          createdAt: DateTime(2026, 7, 1),
          soilType: 'Loamy',
          preferredCrop: 'Wheat',
          polygonCoordinates: polygon,
          centerLocation: center,
          perimeterMeters: perimeter,
        ),
      );

      final lands = await service.getLands();
      final saved = lands.firstWhere((l) => l.id == 'boundary_land_1');

      expect(saved.images, isEmpty);
      expect(saved.hasBoundary, isTrue);
      expect(saved.polygonCoordinates, polygon);
      expect(saved.centerLocation, center);
      expect(saved.perimeterMeters, perimeter);
      expect(saved.location, 'Raiwind Road, Lahore');
    });
  });

  group('Offer a Land -> Select Farm Boundary -> Find Land Details UI', () {
    late AuthController auth;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      auth = AuthController(AuthService())
        ..profile = const UserProfile(
          name: 'Tariq Mahmood',
          email: 'owner@example.com',
          phone: '03001234567',
          location: 'Lahore, Punjab',
        )
        ..isAuthenticated = true;
    });

    tearDown(() => auth.dispose());

    testWidgets(
        'OfferLandScreen navigates to SelectFarmBoundaryScreen after form validation',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        AuthScope(
          controller: auth,
          child: const MaterialApp(home: OfferLandScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Canal Wheat Plot');
      await tester.enterText(fields.at(1), 'Lahore, Punjab');
      await tester.enterText(fields.at(2), '5');
      await tester.enterText(fields.at(3), 'Loamy');
      await tester.enterText(fields.at(4), 'Wheat');
      await tester.enterText(fields.at(5), 'Laser leveled agricultural land.');

      await tester.ensureVisible(find.text('Select Farm Boundary'));
      await tester.tap(find.text('Select Farm Boundary'));
      await tester.pumpAndSettle();

      expect(find.byType(SelectFarmBoundaryScreen), findsOneWidget);
    });

    testWidgets(
        'SelectFarmBoundaryScreen supports draw, undo, clear, confirm/edit, search, satellite/normal toggle, and save',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      BoundaryMapConfig? lastConfig;
      final fakeLocationService = _FakeLocationService();
      final landService = LandService();

      await tester.pumpWidget(
        AuthScope(
          controller: auth,
          child: MaterialApp(
            home: SelectFarmBoundaryScreen(
              draft: const OfferLandDraft(
                title: 'South Orchard Plot',
                location: 'Multan',
                estimatedAreaAcres: 4,
                soilType: 'Alluvial',
                preferredCrop: 'Mango',
                waterSource: 'Canal Water',
                partnershipType: 'Crop Sharing',
                description: 'Rich soil.',
              ),
              landService: landService,
              locationService: fakeLocationService,
              mapBuilder: (context, config) {
                lastConfig = config;
                return GestureDetector(
                  key: const Key('fake-map-surface'),
                  onTap: () {
                    final count = config.markers.length;
                    const points = [
                      LatLng(31.5200, 74.3580),
                      LatLng(31.5210, 74.3580),
                      LatLng(31.5210, 74.3590),
                      LatLng(31.5200, 74.3590),
                    ];
                    if (count < points.length) {
                      config.onTap?.call(points[count]);
                    }
                  },
                  child: Container(color: Colors.green.shade900),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Starts in satellite view.
      expect(lastConfig?.mapType, MapType.satellite);

      // Search location works.
      await tester.enterText(find.byType(TextField).first, 'Multan');
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();
      expect(find.text('Multan, Punjab, Pakistan'), findsOneWidget);
      await tester.tap(find.text('Multan, Punjab, Pakistan'));
      await tester.pumpAndSettle();

      // Toggle Normal -> Satellite.
      await tester.tap(find.text('Normal'));
      await tester.pumpAndSettle();
      expect(lastConfig?.mapType, MapType.normal);
      await tester.tap(find.text('Satellite'));
      await tester.pumpAndSettle();
      expect(lastConfig?.mapType, MapType.satellite);

      // Draw 3 points, test Undo and Clear, then draw 4 points.
      final mapSurface = find.byKey(const Key('fake-map-surface'));
      await tester.tap(mapSurface);
      await tester.tap(mapSurface);
      await tester.pumpAndSettle();
      expect(lastConfig?.markers, hasLength(2));
      expect(lastConfig?.polylines, hasLength(1));
      expect(lastConfig?.polygons, isEmpty);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(lastConfig?.markers, hasLength(1));

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(lastConfig?.markers, isEmpty);

      // Draw 4 points -> forms polygon + calculates acres & perimeter.
      for (var i = 0; i < 4; i++) {
        await tester.tap(mapSurface);
        await tester.pumpAndSettle();
      }
      expect(lastConfig?.markers, hasLength(4));
      expect(lastConfig?.polygons, hasLength(1));
      expect(find.textContaining('Acres'), findsWidgets);

      // Confirm then Edit Boundary unlocks before saving.
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Boundary'), findsOneWidget);

      await tester.tap(find.text('Edit Boundary'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm'), findsOneWidget);

      // Save listing.
      await tester.tap(find.text('Save & Publish Land'));
      await tester.pumpAndSettle();

      expect(find.text('Land Listed Successfully!'), findsOneWidget);

      final savedLands = await landService.getLandsByOwner('owner@example.com');
      expect(savedLands, hasLength(1));
      expect(savedLands.single.images, isEmpty);
      expect(savedLands.single.polygonCoordinates, hasLength(4));
      expect(savedLands.single.centerLocation, isNotNull);
      expect(savedLands.single.perimeterMeters, greaterThan(0));
      expect(savedLands.single.area, greaterThan(0));
    });

    testWidgets(
        'Find Land LandDetailScreen renders saved polygon on interactive satellite map with toggle',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      BoundaryMapConfig? viewerConfig;
      const polygon = [
        LandCoordinate(latitude: 31.5200, longitude: 74.3580),
        LandCoordinate(latitude: 31.5210, longitude: 74.3580),
        LandCoordinate(latitude: 31.5210, longitude: 74.3590),
        LandCoordinate(latitude: 31.5200, longitude: 74.3590),
      ];
      final land = Land(
        id: 'land_view_1',
        ownerUserId: 'owner@example.com',
        ownerName: 'Chaudhry Riaz',
        landName: 'Sheikhupura Canal Plot',
        location: 'Sheikhupura, Punjab',
        area: 2.61,
        areaUnit: 'Acres',
        soilType: 'Alluvial',
        waterSource: 'Canal Water',
        preferredCrop: 'Wheat',
        description: 'Fertile land.',
        images: const [],
        status: 'Available',
        createdAt: DateTime(2026, 7, 1),
        polygonCoordinates: polygon,
        centerLocation: LandGeometry.centerOf(polygon),
        perimeterMeters: LandGeometry.perimeterMeters(polygon),
      );

      await tester.pumpWidget(
        AuthScope(
          controller: auth,
          child: MaterialApp(
            home: LandDetailScreen(
              land: land,
              service: LandService(),
              mapBuilder: (context, config) {
                viewerConfig = config;
                return Container(color: Colors.green.shade800);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(viewerConfig, isNotNull);
      expect(viewerConfig!.mapType, MapType.satellite);
      expect(viewerConfig!.polygons, hasLength(1));
      expect(viewerConfig!.polygons.single.points, hasLength(4));
      expect(viewerConfig!.onTap, isNull); // Read-only view in Find Land.

      // Toggle Normal -> Satellite.
      await tester.tap(find.text('Normal'));
      await tester.pumpAndSettle();
      expect(viewerConfig!.mapType, MapType.normal);

      await tester.tap(find.text('Satellite'));
      await tester.pumpAndSettle();
      expect(viewerConfig!.mapType, MapType.satellite);
    });
  });
}

class _FakeLocationService extends LocationService {
  @override
  Future<List<LandLocation>> search(String query) async => const [
        LandLocation(
          name: 'Multan, Punjab, Pakistan',
          latitude: 30.1575,
          longitude: 71.5249,
        ),
      ];

  @override
  Future<String> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async =>
      'Raiwind Road, Lahore, Punjab';
}
