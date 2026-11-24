import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/land.dart';
import '../models/land_application.dart';
import '../models/land_offer.dart';
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

  static final List<Land> _sampleLands = [
    Land(
      id: 'market_1',
      ownerUserId: 'owner_1',
      ownerName: 'Chaudhry Riaz',
      landName: 'Canal-side wheat and rice farm',
      location: 'Sheikhupura, Punjab',
      area: 25,
      areaUnit: 'Acres',
      soilType: 'Alluvial',
      waterSource: 'Canal + solar tube-well',
      preferredCrop: 'Wheat and rice',
      description:
          'Fertile, laser-levelled land with reliable irrigation and access to the main road.',
      images: const [_sampleLandImage],
      status: 'Available',
      createdAt: DateTime(2026, 6, 10),
    ),
    Land(
      id: 'market_2',
      ownerUserId: 'owner_2',
      ownerName: 'Mian Aslam',
      landName: 'Citrus orchard and crop land',
      location: 'Khanewal, Punjab',
      area: 15,
      areaUnit: 'Acres',
      soilType: 'Sandy loam',
      waterSource: 'Drip irrigation',
      preferredCrop: 'Citrus and vegetables',
      description:
          'Young citrus trees with additional acreage available for seasonal crops.',
      images: const [_sampleLandImage],
      status: 'Available',
      createdAt: DateTime(2026, 6, 7),
    ),
    Land(
      id: 'market_3',
      ownerUserId: 'owner_3',
      ownerName: 'Ayesha Malik',
      landName: 'Vegetable growing opportunity',
      location: 'Multan, Punjab',
      area: 8,
      areaUnit: 'Acres',
      soilType: 'Loamy',
      waterSource: 'Tube-well',
      preferredCrop: 'Cotton and vegetables',
      description:
          'Open, level fields near the city with a working tube-well and storage shed.',
      images: const [_sampleLandImage],
      status: 'Available',
      createdAt: DateTime(2026, 6, 5),
    ),
    Land(
      id: 'market_4',
      ownerUserId: 'owner_4',
      ownerName: 'Naveed Ahmed',
      landName: 'Organic vegetable fields',
      location: 'Lahore, Punjab',
      area: 4.5,
      areaUnit: 'Acres',
      soilType: 'Clay loam',
      waterSource: 'Canal water',
      preferredCrop: 'Seasonal vegetables',
      description:
          'Small farm suited to intensive vegetable cultivation and organic practices.',
      images: const [_sampleLandImage],
      status: 'Available',
      createdAt: DateTime(2026, 6, 2),
    ),
    Land(
      id: 'market_5',
      ownerUserId: 'owner_5',
      ownerName: 'Sana Iqbal',
      landName: 'Cotton and maize acreage',
      location: 'Bahawalpur, Punjab',
      area: 32,
      areaUnit: 'Acres',
      soilType: 'Sandy',
      waterSource: 'Canal + tube-well',
      preferredCrop: 'Cotton and maize',
      description:
          'Spacious irrigated fields with farm access and a long-term management option.',
      images: const [_sampleLandImage],
      status: 'Available',
      createdAt: DateTime(2026, 5, 28),
    ),
    Land(
      id: 'market_6',
      ownerUserId: 'owner_6',
      ownerName: 'Bilal Hussain',
      landName: 'Rice cultivation land',
      location: 'Gujranwala, Punjab',
      area: 12,
      areaUnit: 'Acres',
      soilType: 'Clay',
      waterSource: 'Canal water',
      preferredCrop: 'Rice',
      description:
          'Established paddy fields with dependable water access during the growing season.',
      images: const [_sampleLandImage],
      status: 'Available',
      createdAt: DateTime(2026, 5, 24),
    ),
    Land(
      id: 'market_7',
      ownerUserId: 'owner_7',
      ownerName: 'Imran Shah',
      landName: 'Orchard management plot',
      location: 'Sargodha, Punjab',
      area: 10,
      areaUnit: 'Acres',
      soilType: 'Sandy loam',
      waterSource: 'Drip irrigation',
      preferredCrop: 'Citrus',
      description:
          'Established citrus orchard seeking an experienced grower for seasonal care.',
      images: const [_sampleLandImage],
      status: 'Available',
      createdAt: DateTime(2026, 5, 19),
    ),
    Land(
      id: 'market_8',
      ownerUserId: 'owner_8',
      ownerName: 'Fatima Noor',
      landName: 'Mixed crop farm near the canal',
      location: 'Okara, Punjab',
      area: 18,
      areaUnit: 'Acres',
      soilType: 'Alluvial',
      waterSource: 'Canal water',
      preferredCrop: 'Potato and maize',
      description:
          'Productive land with crop rotation history and easy access for farm machinery.',
      images: const [_sampleLandImage],
      status: 'Available',
      createdAt: DateTime(2026, 5, 15),
    ),
    Land(
      id: 'market_9',
      ownerUserId: 'owner_9',
      ownerName: 'Zahid Mahmood',
      landName: 'Rain-fed farming opportunity',
      location: 'Chakwal, Punjab',
      area: 22,
      areaUnit: 'Acres',
      soilType: 'Loamy',
      waterSource: 'Rain-fed',
      preferredCrop: 'Groundnut and millet',
      description:
          'Open fields suited to drought-tolerant crops, with road access and boundary fencing.',
      images: const [_sampleLandImage],
      status: 'Available',
      createdAt: DateTime(2026, 5, 11),
    ),
  ];

  Future<List<LandOffer>> getLandOffers() async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getStringList(_landOffersKey) ?? [];
    final customOffers = customRaw.map((e) {
      return LandOffer.fromJson(jsonDecode(e) as Map<String, dynamic>);
    }).toList();

    return [...customOffers, ..._sampleOffers];
  }

  Future<void> submitLandOffer(LandOffer offer) async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getStringList(_landOffersKey) ?? [];
    customRaw.insert(0, jsonEncode(offer.toJson()));
    await prefs.setStringList(_landOffersKey, customRaw);

    final lands = await _readLands(prefs);
    if (!lands.any((land) => land.id == offer.id)) {
      lands.insert(
        0,
        Land(
          id: offer.id,
          ownerUserId: offer.userId,
          ownerName: offer.ownerName,
          landName: offer.title,
          location: offer.location,
          area: double.tryParse(
                  offer.acreage.replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0,
          areaUnit: 'Acres',
          soilType: offer.soilType,
          waterSource: offer.waterSource,
          preferredCrop: offer.preferredCrop,
          description: offer.description,
          images: const [_sampleLandImage],
          status: 'Available',
          createdAt: offer.createdAt,
        ),
      );
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
        lands.add(
          Land(
            id: offer.id,
            ownerUserId: offer.userId,
            ownerName: offer.ownerName,
            landName: offer.title,
            location: offer.location,
            area: double.tryParse(
                    offer.acreage.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                0,
            areaUnit: 'Acres',
            soilType: offer.soilType,
            waterSource: offer.waterSource,
            preferredCrop: offer.preferredCrop,
            description: offer.description,
            images: const [_sampleLandImage],
            status: 'Available',
            createdAt: offer.createdAt,
          ),
        );
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
    if (index == -1) throw StateError('Land listing not found.');
    if (lands[index].ownerUserId != updatedLand.ownerUserId) {
      throw StateError('Only the land owner can update this listing.');
    }
    lands[index] = updatedLand;
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
