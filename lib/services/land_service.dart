import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/land.dart';
import '../models/land_application.dart';
import '../models/land_coordinate.dart';
import '../models/land_offer.dart';
import '../utils/land_geometry.dart';
import 'demo_notification_service.dart';

class LandService {
  static const _landOffersKey = 'baghbani.land_offers';
  static const _landsKey = 'baghbani.lands';
  static const _applicationsKey = 'baghbani.land_applications';
  static const _sampleLandImage =
      'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=900&q=80';

  static final List<LandOffer> _sampleOffers = [
    LandOffer(
      id: 'land_1',
      userId: 'usr_sample_1',
      ownerName: 'Chaudhry Riaz',
      title: '25 Acres Agricultural Land for Wheat & Rice',
      location: 'Sheikhupura Road, Punjab',
      acreage: '25 Acres',
      waterSource: 'Canal + Solar Tube-well',
      partnershipType: 'Seasonal Crop Sharing',
      description:
          'Fertile alluvial soil with continuous canal water access. Looking for experienced crop manager for upcoming Rabi and Kharif seasons. Laser leveled last month.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    LandOffer(
      id: 'land_2',
      userId: 'usr_sample_2',
      ownerName: 'Mian Aslam',
      title: '15 Acres Orchard & Crop Land',
      location: 'Khanewal, Punjab',
      acreage: '15 Acres',
      waterSource: 'Drip System Installed',
      partnershipType: 'Full Management Contract',
      description:
          '10 acres vacant for cash crops, 5 acres young citrus orchard. Drip lines already laid. Seeking dedicated farm manager or experienced team.',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  static List<LandCoordinate> _rectPolygon(
    double lat,
    double lng,
    double dLat,
    double dLng,
  ) =>
      [
        LandCoordinate(latitude: lat - dLat, longitude: lng - dLng),
        LandCoordinate(latitude: lat + dLat, longitude: lng - dLng),
        LandCoordinate(latitude: lat + dLat * 0.9, longitude: lng + dLng),
        LandCoordinate(latitude: lat - dLat * 0.95, longitude: lng + dLng * 0.85),
      ];

  static final List<Land> _sampleLands = [
    _buildSampleLand(
      id: 'market_1',
      ownerUserId: 'owner_1',
      ownerName: 'Chaudhry Riaz',
      landName: 'Canal-side wheat and rice farm',
      location: 'Sheikhupura, Punjab',
      area: 25,
      soilType: 'Alluvial',
      waterSource: 'Canal + solar tube-well',
      preferredCrop: 'Wheat and rice',
      description:
          'Fertile, laser-levelled land with reliable irrigation and access to the main road.',
      createdAt: DateTime(2026, 6, 10),
      polygon: _rectPolygon(31.7167, 73.9850, 0.0014, 0.0018),
    ),
    _buildSampleLand(
      id: 'market_2',
      ownerUserId: 'owner_2',
      ownerName: 'Mian Aslam',
      landName: 'Citrus orchard and crop land',
      location: 'Khanewal, Punjab',
      area: 15,
      soilType: 'Sandy loam',
      waterSource: 'Drip irrigation',
      preferredCrop: 'Citrus and vegetables',
      description:
          'Young citrus trees with additional acreage available for seasonal crops.',
      createdAt: DateTime(2026, 6, 7),
      polygon: _rectPolygon(30.3017, 71.9321, 0.0011, 0.0014),
    ),
    _buildSampleLand(
      id: 'market_3',
      ownerUserId: 'owner_3',
      ownerName: 'Ayesha Malik',
      landName: 'Vegetable growing opportunity',
      location: 'Multan, Punjab',
      area: 8,
      soilType: 'Loamy',
      waterSource: 'Tube-well',
      preferredCrop: 'Cotton and vegetables',
      description:
          'Open, level fields near the city with a working tube-well and storage shed.',
      createdAt: DateTime(2026, 6, 5),
      polygon: _rectPolygon(30.1575, 71.5249, 0.0008, 0.0010),
    ),
    _buildSampleLand(
      id: 'market_4',
      ownerUserId: 'owner_4',
      ownerName: 'Naveed Ahmed',
      landName: 'Organic vegetable fields',
      location: 'Lahore, Punjab',
      area: 4.5,
      soilType: 'Clay loam',
      waterSource: 'Canal water',
      preferredCrop: 'Seasonal vegetables',
      description:
          'Small farm suited to intensive vegetable cultivation and organic practices.',
      createdAt: DateTime(2026, 6, 2),
      polygon: _rectPolygon(31.4250, 74.2280, 0.0006, 0.0008),
    ),
    _buildSampleLand(
      id: 'market_5',
      ownerUserId: 'owner_5',
      ownerName: 'Sana Iqbal',
      landName: 'Cotton and maize acreage',
      location: 'Bahawalpur, Punjab',
      area: 32,
      soilType: 'Sandy',
      waterSource: 'Canal + tube-well',
      preferredCrop: 'Cotton and maize',
      description:
          'Spacious irrigated fields with farm access and a long-term management option.',
      createdAt: DateTime(2026, 5, 28),
      polygon: _rectPolygon(29.3956, 71.6836, 0.0016, 0.0020),
    ),
    _buildSampleLand(
      id: 'market_6',
      ownerUserId: 'owner_6',
      ownerName: 'Bilal Hussain',
      landName: 'Rice cultivation land',
      location: 'Gujranwala, Punjab',
      area: 12,
      soilType: 'Clay',
      waterSource: 'Canal water',
      preferredCrop: 'Rice',
      description:
          'Established paddy fields with dependable water access during the growing season.',
      createdAt: DateTime(2026, 5, 24),
      polygon: _rectPolygon(32.1877, 74.1945, 0.0010, 0.0012),
    ),
    _buildSampleLand(
      id: 'market_7',
      ownerUserId: 'owner_7',
      ownerName: 'Imran Shah',
      landName: 'Orchard management plot',
      location: 'Sargodha, Punjab',
      area: 10,
      soilType: 'Sandy loam',
      waterSource: 'Drip irrigation',
      preferredCrop: 'Citrus',
      description:
          'Established citrus orchard seeking an experienced grower for seasonal care.',
      createdAt: DateTime(2026, 5, 19),
      polygon: _rectPolygon(32.0740, 72.6711, 0.0009, 0.0011),
    ),
    _buildSampleLand(
      id: 'market_8',
      ownerUserId: 'owner_8',
      ownerName: 'Fatima Noor',
      landName: 'Mixed crop farm near the canal',
      location: 'Okara, Punjab',
      area: 18,
      soilType: 'Alluvial',
      waterSource: 'Canal water',
      preferredCrop: 'Potato and maize',
      description:
          'Productive land with crop rotation history and easy access for farm machinery.',
      createdAt: DateTime(2026, 5, 15),
      polygon: _rectPolygon(30.8138, 73.4534, 0.0012, 0.0015),
    ),
    _buildSampleLand(
      id: 'market_9',
      ownerUserId: 'owner_9',
      ownerName: 'Zahid Mahmood',
      landName: 'Rain-fed farming opportunity',
      location: 'Chakwal, Punjab',
      area: 22,
      soilType: 'Loamy',
      waterSource: 'Rain-fed',
      preferredCrop: 'Groundnut and millet',
      description:
          'Open fields suited to drought-tolerant crops, with road access and boundary fencing.',
      createdAt: DateTime(2026, 5, 11),
      polygon: _rectPolygon(32.9328, 72.8630, 0.0013, 0.0016),
    ),
  ];

  static Land _buildSampleLand({
    required String id,
    required String ownerUserId,
    required String ownerName,
    required String landName,
    required String location,
    required double area,
    required String soilType,
    required String waterSource,
    required String preferredCrop,
    required String description,
    required DateTime createdAt,
    required List<LandCoordinate> polygon,
  }) =>
      Land(
        id: id,
        ownerUserId: ownerUserId,
        ownerName: ownerName,
        landName: landName,
        location: location,
        area: area,
        areaUnit: 'Acres',
        soilType: soilType,
        waterSource: waterSource,
        preferredCrop: preferredCrop,
        description: description,
        images: const [],
        status: 'Available',
        createdAt: createdAt,
        polygonCoordinates: polygon,
        centerLocation: LandGeometry.centerOf(polygon),
        perimeterMeters: LandGeometry.perimeterMeters(polygon),
      );

  Future<List<LandOffer>> getLandOffers() async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getStringList(_landOffersKey) ?? [];
    final customOffers = customRaw.map((e) {
      return LandOffer.fromJson(jsonDecode(e) as Map<String, dynamic>);
    }).toList();

    return [...customOffers, ..._sampleOffers];
  }

  Land _landFromOffer(LandOffer offer) {
    final hasBoundary = offer.polygonCoordinates.length >= 3;
    final parsedArea =
        double.tryParse(offer.acreage.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final resolvedArea =
        hasBoundary && parsedArea <= 0
            ? LandGeometry.areaAcres(offer.polygonCoordinates)
            : parsedArea;
    return Land(
      id: offer.id,
      ownerUserId: offer.userId,
      ownerName: offer.ownerName,
      landName: offer.title,
      location: offer.location,
      area: resolvedArea,
      areaUnit: 'Acres',
      soilType: offer.soilType,
      waterSource: offer.waterSource,
      preferredCrop: offer.preferredCrop,
      description: offer.description,
      images: hasBoundary ? const [] : const [_sampleLandImage],
      status: 'Available',
      createdAt: offer.createdAt,
      polygonCoordinates: offer.polygonCoordinates,
      centerLocation: offer.centerLocation ??
          LandGeometry.centerOf(offer.polygonCoordinates),
      perimeterMeters: offer.perimeterMeters ??
          (hasBoundary
              ? LandGeometry.perimeterMeters(offer.polygonCoordinates)
              : null),
    );
  }

  Future<void> submitLandOffer(LandOffer offer) async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getStringList(_landOffersKey) ?? [];
    customRaw.insert(0, jsonEncode(offer.toJson()));
    await prefs.setStringList(_landOffersKey, customRaw);

    final lands = await _readLands(prefs);
    if (!lands.any((land) => land.id == offer.id)) {
      lands.insert(0, _landFromOffer(offer));
      await prefs.setStringList(
        _landsKey,
        lands.map((land) => jsonEncode(land.toJson())).toList(),
      );
    }
  }

  Future<List<Land>> getLands() async {
    final prefs = await SharedPreferences.getInstance();
    final lands = await _readLands(prefs);
    final customRaw = prefs.getStringList(_landOffersKey) ?? [];
    final knownIds = lands.map((land) => land.id).toSet();
    for (final raw in customRaw) {
      final offer = LandOffer.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (knownIds.add(offer.id)) {
        lands.add(_landFromOffer(offer));
      }
    }
    return [...lands, ..._sampleLands];
  }

  Future<void> submitApplication(LandApplication application) async {
    final prefs = await SharedPreferences.getInstance();
    final applications = await _readApplications(prefs);
    final lands = await getLands();
    final matchingLands = lands.where((item) => item.id == application.landId);
    final land = matchingLands.isEmpty ? null : matchingLands.first;
    if (land == null || land.status.toLowerCase() != 'available') {
      throw StateError('This land listing is no longer available.');
    }
    if (application.ownerUserId.isNotEmpty &&
        application.ownerUserId != land.ownerUserId) {
      throw StateError('The land owner does not match this listing.');
    }
    if (applications.any(
      (item) =>
          item.landId == application.landId &&
          item.farmerUserId == application.farmerUserId,
    )) {
      throw StateError('You have already applied for this land.');
    }
    applications.insert(
      0,
      application.copyWith(ownerUserId: land.ownerUserId),
    );
    await prefs.setStringList(
      _applicationsKey,
      applications.map((item) => jsonEncode(item.toJson())).toList(),
    );
    await DemoNotificationService().add(
      userId: land.ownerUserId,
      title: 'New land application',
      body: '${application.farmerName} has applied for your land.',
      createdAt: application.createdAt,
    );
  }

  Future<List<LandApplication>> getApplicationsByFarmer(
      String farmerUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final applications = await _readApplications(prefs);
    return applications
        .where((item) => item.farmerUserId == farmerUserId)
        .toList();
  }

  Future<List<({Land land, LandApplication application})>>
      getApplicationsForOwner(String ownerUserId, {String? landId}) async {
    final prefs = await SharedPreferences.getInstance();
    final lands = await getLands();
    final applications = await _readApplications(prefs);
    final landById = {for (final land in lands) land.id: land};
    return applications
        .where((application) {
          final land = landById[application.landId];
          return land != null &&
              land.ownerUserId == ownerUserId &&
              (application.ownerUserId.isEmpty ||
                  application.ownerUserId == ownerUserId) &&
              (landId == null || land.id == landId);
        })
        .map((application) => (
              land: landById[application.landId]!,
              application: application,
            ))
        .toList();
  }

  Future<List<({Land land, LandApplication application})>>
      getApplicationsForLand(String landId, {String? ownerUserId}) async {
    final prefs = await SharedPreferences.getInstance();
    final lands = await getLands();
    final applications = await _readApplications(prefs);
    final matchingLands = lands.where((land) => land.id == landId);
    if (matchingLands.isEmpty) return [];
    final land = matchingLands.first;
    return applications
        .where((application) =>
            application.landId == landId &&
            (ownerUserId == null ||
                ownerUserId.isEmpty ||
                land.ownerUserId.isEmpty ||
                land.ownerUserId == ownerUserId))
        .map((application) => (
              land: land,
              application: application,
            ))
        .toList();
  }

  Future<void> updateApplicationStatus(
    String applicationId,
    String status, {
    required String ownerUserId,
  }) async {
    if (status != LandApplication.accepted &&
        status != LandApplication.rejected) {
      throw ArgumentError.value(
          status, 'status', 'Expected Accepted or Rejected');
    }
    final prefs = await SharedPreferences.getInstance();
    final applications = await _readApplications(prefs);
    final index = applications.indexWhere((item) => item.id == applicationId);
    if (index == -1) throw StateError('Application not found.');
    final application = applications[index];
    final lands = await getLands();
    final matchingLands = lands.where((land) => land.id == application.landId);
    if (matchingLands.isEmpty ||
        matchingLands.first.ownerUserId != ownerUserId) {
      throw StateError('Only the land owner can update this application.');
    }
    if (application.status != LandApplication.pending) {
      throw StateError('This application has already been reviewed.');
    }
    applications[index] = application.copyWith(status: status);
    await prefs.setStringList(
      _applicationsKey,
      applications.map((item) => jsonEncode(item.toJson())).toList(),
    );
    await DemoNotificationService().add(
      userId: application.farmerUserId,
      title: status == LandApplication.accepted
          ? 'Application accepted'
          : 'Application update',
      body: status == LandApplication.accepted
          ? 'Your application has been accepted.'
          : 'Your application has been rejected.',
      createdAt: DateTime.now(),
    );
  }

  Future<List<Land>> getLandsByOwner(String ownerUserId) async {
    final lands = await getLands();
    return lands.where((land) => land.ownerUserId == ownerUserId).toList();
  }

  Future<int> getApplicationCountForLand(String landId) async {
    final prefs = await SharedPreferences.getInstance();
    final applications = await _readApplications(prefs);
    return applications.where((item) => item.landId == landId).length;
  }

  Future<void> updateLand(Land updatedLand) async {
    final prefs = await SharedPreferences.getInstance();
    final lands = await _readLands(prefs);
    final index = lands.indexWhere((land) => land.id == updatedLand.id);
    if (index == -1) {
      lands.insert(0, updatedLand);
    } else {
      if (lands[index].ownerUserId != updatedLand.ownerUserId) {
        throw StateError('Only the land owner can update this listing.');
      }
      lands[index] = updatedLand;
    }
    await prefs.setStringList(
      _landsKey,
      lands.map((land) => jsonEncode(land.toJson())).toList(),
    );
  }

  Future<void> deleteLand(String landId, String ownerUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final lands = await _readLands(prefs);
    final matchingLands = lands.where((item) => item.id == landId);
    final land = matchingLands.isEmpty ? null : matchingLands.first;
    if (land == null) throw StateError('Land listing not found.');
    if (land.ownerUserId != ownerUserId) {
      throw StateError('Only the land owner can delete this listing.');
    }
    lands.removeWhere((item) => item.id == landId);
    await prefs.setStringList(
      _landsKey,
      lands.map((item) => jsonEncode(item.toJson())).toList(),
    );
    final applications = await _readApplications(prefs);
    applications.removeWhere((item) => item.landId == landId);
    await prefs.setStringList(
      _applicationsKey,
      applications.map((item) => jsonEncode(item.toJson())).toList(),
    );
    final offers = prefs.getStringList(_landOffersKey) ?? [];
    offers.removeWhere((raw) {
      final offer = LandOffer.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return offer.id == landId && offer.userId == ownerUserId;
    });
    await prefs.setStringList(_landOffersKey, offers);
  }

  Future<List<Land>> _readLands(SharedPreferences prefs) async {
    final raw = prefs.getStringList(_landsKey) ?? [];
    return raw
        .map(
            (entry) => Land.fromJson(jsonDecode(entry) as Map<String, dynamic>))
        .toList();
  }

  Future<List<LandApplication>> _readApplications(
      SharedPreferences prefs) async {
    final raw = prefs.getStringList(_applicationsKey) ?? [];
    return raw
        .map((entry) =>
            LandApplication.fromJson(jsonDecode(entry) as Map<String, dynamic>))
        .toList();
  }
}
