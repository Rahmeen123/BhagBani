import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baghbani/models/land_application.dart';
import 'package:baghbani/models/land_offer.dart';
import 'package:baghbani/services/demo_notification_service.dart';
import 'package:baghbani/services/land_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LandService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = LandService();
  });

  test('provides nine available demo listings', () async {
    final lands = await service.getLands();

    expect(lands, hasLength(9));
    expect(lands.every((land) => land.status == 'Available'), isTrue);
  });

  test('published land offers appear in Find Land', () async {
    await service.submitLandOffer(
      LandOffer(
        id: 'offer_1',
        userId: 'owner@example.com',
        ownerName: 'Land Owner',
        title: 'Wheat field',
        location: 'Lahore',
        acreage: '12 Acres',
        waterSource: 'Canal Water',
        partnershipType: 'Crop Sharing',
        description: 'A productive field.',
        createdAt: DateTime(2026, 1, 1),
        soilType: 'Alluvial',
        preferredCrop: 'Wheat',
      ),
    );

    final lands = await service.getLands();
    final listing = lands.firstWhere((land) => land.id == 'offer_1');

    expect(listing.ownerUserId, 'owner@example.com');
    expect(listing.landName, 'Wheat field');
    expect(listing.area, 12);
    expect(listing.soilType, 'Alluvial');
    expect(listing.preferredCrop, 'Wheat');
    expect(listing.images, isNotEmpty);
  });

  test('applications are delivered to owners and status updates persist',
      () async {
    await service.submitLandOffer(
      LandOffer(
        id: 'offer_2',
        userId: 'owner@example.com',
        ownerName: 'Land Owner',
        title: 'Rice field',
        location: 'Gujranwala',
        acreage: '8 Acres',
        waterSource: 'Canal Water',
        partnershipType: 'Crop Sharing',
        description: 'Suitable for rice.',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    final application = LandApplication(
      id: 'application_1',
      landId: 'offer_2',
      farmerUserId: 'farmer@example.com',
      farmerName: 'Farmer',
      experience: 'Five years',
      skills: 'Rice cultivation',
      location: 'Lahore',
      message: 'I would like to apply.',
      status: LandApplication.pending,
      createdAt: DateTime(2026, 1, 2),
    );
    await service.submitApplication(application);
    await service.submitApplication(
      LandApplication(
        id: 'application_2',
        landId: 'offer_2',
        farmerUserId: 'farmer2@example.com',
        farmerName: 'Farmer Two',
        message: 'I would also like to apply.',
        status: LandApplication.pending,
        createdAt: DateTime(2026, 1, 3),
      ),
    );

    final received = await service.getApplicationsForOwner('owner@example.com');
    expect(received, hasLength(2));
    expect(
      received
          .firstWhere((item) => item.application.id == application.id)
          .application
          .status,
      LandApplication.pending,
    );
    expect(
      received.every(
        (item) => item.application.ownerUserId == 'owner@example.com',
      ),
      isTrue,
    );
    final ownerNotifications =
        await DemoNotificationService().getForUser('owner@example.com');
    expect(ownerNotifications, hasLength(2));
    expect(
      ownerNotifications.map((item) => item.body),
      contains('Farmer has applied for your land.'),
    );

    await service.updateApplicationStatus(
      application.id,
      LandApplication.accepted,
      ownerUserId: 'owner@example.com',
    );
    final otherApplication =
        (await service.getApplicationsByFarmer('farmer2@example.com')).single;
    expect(otherApplication.status, LandApplication.pending);
    final applied = await service.getApplicationsByFarmer('farmer@example.com');
    expect(applied.single.status, LandApplication.accepted);
    final farmerNotifications =
        await DemoNotificationService().getForUser('farmer@example.com');
    expect(
      farmerNotifications.single.body,
      'Your application has been accepted.',
    );
  });

  test('owners can close and delete their listings', () async {
    await service.submitLandOffer(
      LandOffer(
        id: 'offer_3',
        userId: 'owner@example.com',
        ownerName: 'Land Owner',
        title: 'Barley field',
        location: 'Lahore',
        acreage: '4 Acres',
        waterSource: 'Canal Water',
        partnershipType: 'Crop Sharing',
        description: 'A small field.',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    final listing = (await service.getLandsByOwner('owner@example.com')).single;
    await service.updateLand(listing.copyWith(status: 'Closed'));
    expect(
      (await service.getLandsByOwner('owner@example.com')).single.status,
      'Closed',
    );

    await service.deleteLand(listing.id, 'owner@example.com');
    expect(await service.getLandsByOwner('owner@example.com'), isEmpty);
    expect(
      (await service.getLands()).any((land) => land.id == listing.id),
      isFalse,
    );
  });

  test('a farmer cannot apply to the same land twice', () async {
    final application = LandApplication(
      id: 'application_2',
      landId: 'market_1',
      farmerUserId: 'farmer@example.com',
      message: 'Interested.',
      status: LandApplication.pending,
      createdAt: DateTime(2026, 1, 2),
    );
    await service.submitApplication(application);

    await expectLater(
      service.submitApplication(application.copyWith()),
      throwsA(isA<StateError>()),
    );
  });
}
