import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baghbani/models/contact_information.dart';
import 'package:baghbani/models/land.dart';
import 'package:baghbani/models/user_profile.dart';
import 'package:baghbani/navigation/protected_feature_navigation.dart';
import 'package:baghbani/providers/auth_scope.dart';
import 'package:baghbani/screens/auth/login_screen.dart';
import 'package:baghbani/screens/farmer/become_farmer_screen.dart';
import 'package:baghbani/screens/farmer/farmer_listing_screen.dart';
import 'package:baghbani/screens/farmer/farmer_profile_screen.dart';
import 'package:baghbani/screens/land/land_marketplace_screens.dart';
import 'package:baghbani/screens/land/manage_land_listing_screen.dart';
import 'package:baghbani/screens/land/my_land_listings_screen.dart';
import 'package:baghbani/screens/land/offer_land_screen.dart';
import 'package:baghbani/services/auth_service.dart';
import 'package:baghbani/services/farmer_service.dart';
import 'package:baghbani/services/land_service.dart';
import 'package:baghbani/utils/direct_contact_launcher.dart';

class _FakeAuthService extends AuthService {
  UserProfile? _profile;
  String? _password;
  bool _isGuest = false;

  void seed(UserProfile profile, String password) {
    _profile = profile;
    _password = password;
  }

  @override
  Future<void> setGuestMode() async {
    _isGuest = true;
  }

  @override
  Future<bool> register(UserProfile profile, String password) async {
    _profile = profile;
    _password = password;
    _isGuest = false;
    return true;
  }

  @override
  Future<bool> signIn(String email, String password) async {
    if (_profile?.email == email && _password == password) {
      _isGuest = false;
      return true;
    }
    return false;
  }

  @override
  Future<UserProfile?> restoreProfile() async =>
      _isGuest ? UserProfile.guest : _profile;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LandService landService;
  late FarmerService farmerService;
  late _FakeAuthService fakeAuthService;
  late AuthController authController;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    landService = LandService();
    farmerService = FarmerService();
    fakeAuthService = _FakeAuthService();
    authController = AuthController(fakeAuthService);
    DirectContactLauncher.testLauncher = null;
  });

  tearDown(() {
    DirectContactLauncher.testLauncher = null;
    authController.dispose();
  });

  Widget buildApp(Widget child) {
    return AuthScope(
      controller: authController,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('OfferLandLandingScreen shows Add New Land and My Land Listings',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildApp(const OfferLandLandingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Offer Farmland'), findsOneWidget);
    expect(find.text('Add New Land'), findsAtLeastNWidgets(1));
    expect(find.text('My Land Listings'), findsAtLeastNWidgets(1));
  });

  testWidgets(
      'My Land Listings displays land card details and Manage Listing without applications',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final land = Land(
      id: 'test_land_1',
      ownerUserId: 'owner@example.com',
      ownerName: 'Test Owner',
      landName: 'Green Valley Farmland',
      location: 'Sheikhupura, Punjab',
      area: 25,
      areaUnit: 'Acres',
      soilType: 'Loamy',
      waterSource: 'Canal Water',
      preferredCrop: 'Wheat & Rice',
      description: 'Fertile land with direct canal access.',
      images: const [],
      status: 'Available',
      irrigationAvailable: true,
      createdAt: DateTime.now(),
    );
    await landService.updateLand(land);

    await tester.pumpWidget(
      buildApp(const MyLandListingsScreen(ownerUserId: 'owner@example.com')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Green Valley Farmland'), findsOneWidget);
    expect(find.text('Sheikhupura, Punjab'), findsOneWidget);
    expect(find.text('25 Acres'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Irrigation Available'), findsOneWidget);
    expect(find.text('Manage Listing'), findsOneWidget);
    expect(find.textContaining('Total Applications'), findsNothing);
  });

  testWidgets(
      'Manage Listing screen shows Land Details, Contact Summary, Edit, Close, and Delete',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final land = Land(
      id: 'test_land_manage',
      ownerUserId: 'owner@example.com',
      ownerName: 'Test Owner',
      landName: 'Sunny Acres Farm',
      location: 'Okara, Punjab',
      area: 18,
      areaUnit: 'Acres',
      soilType: 'Alluvial',
      waterSource: 'Tube-well',
      preferredCrop: 'Potato & Maize',
      description: 'Excellent soil for crop rotation.',
      images: const [],
      status: 'Available',
      createdAt: DateTime.now(),
      ownerContact: const ContactInformation(
        name: 'Test Owner',
        phoneNumber: '0300 7654321',
        whatsappNumber: '0300 7654321',
        address: 'Depalpur Road, Okara',
      ),
    );
    await landService.updateLand(land);

    await tester.pumpWidget(
      buildApp(
        ManageLandListingScreen(
          land: land,
          ownerUserId: 'owner@example.com',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sunny Acres Farm'), findsOneWidget);
    expect(find.text('Okara, Punjab'), findsOneWidget);
    expect(find.text('18 Acres'), findsOneWidget);
    expect(find.text('Published Contact Information'), findsOneWidget);
    expect(find.text('0300 7654321'), findsWidgets);
    expect(find.text('Depalpur Road, Okara'), findsOneWidget);
    expect(find.text('Applications'), findsNothing);
    expect(find.text('Edit Listing'), findsOneWidget);
    expect(find.text('Close Listing'), findsOneWidget);
    expect(find.text('Delete Listing'), findsOneWidget);

    await tester.tap(find.text('Close Listing'));
    await tester.pumpAndSettle();

    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Reopen Listing'), findsOneWidget);
  });

  testWidgets(
      'Guest can view Find Land & LandDetailScreen and directly Call or WhatsApp owner',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await authController.continueAsGuest();

    final launchedUris = <Uri>[];
    DirectContactLauncher.testLauncher = (uri) async {
      launchedUris.add(uri);
      return true;
    };

    final land = Land(
      id: 'market_direct_1',
      ownerUserId: 'owner_1',
      ownerName: 'Chaudhry Riaz',
      landName: 'Canal-side wheat and rice farm',
      location: 'Sheikhupura, Punjab',
      area: 25,
      areaUnit: 'Acres',
      soilType: 'Alluvial',
      waterSource: 'Canal + solar tube-well',
      preferredCrop: 'Wheat and rice',
      description: 'Fertile land.',
      images: const [],
      status: 'Available',
      irrigationAvailable: true,
      createdAt: DateTime.now(),
      ownerContact: const ContactInformation(
        name: 'Chaudhry Riaz',
        phoneNumber: '0300 1234567',
        whatsappNumber: '0301 9876543',
        address: 'Chak 45, Sheikhupura Road',
      ),
    );

    await tester.pumpWidget(
      buildApp(LandDetailScreen(land: land, service: landService)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chaudhry Riaz'), findsOneWidget);
    expect(find.text('0300 1234567'), findsOneWidget);
    expect(find.text('0301 9876543'), findsOneWidget);
    expect(find.text('Chak 45, Sheikhupura Road'), findsOneWidget);
    expect(find.text('Apply Now'), findsNothing);
    expect(find.text('Request Contact'), findsNothing);

    await tester.ensureVisible(find.text('Call Owner'));
    await tester.tap(find.text('Call Owner'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('WhatsApp Owner'));
    await tester.tap(find.text('WhatsApp Owner'));
    await tester.pumpAndSettle();

    expect(launchedUris, hasLength(2));
    expect(launchedUris[0].scheme, 'tel');
    expect(launchedUris[0].path, '03001234567');
    expect(launchedUris[1].host, 'wa.me');
    expect(launchedUris[1].path, '/923019876543');
  });

  testWidgets(
      'BecomeFarmerScreen creates farmer profile visible in Hire Farmer with direct Call & WhatsApp',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    authController
      ..profile = const UserProfile(
        name: 'Bilal Ahmad',
        email: 'bilal@example.com',
        phone: '0305 1112233',
        whatsappNumber: '0305 1112233',
        location: 'Multan, Punjab',
        address: 'Bosan Road, Multan',
      )
      ..isAuthenticated = true;

    await tester.pumpWidget(buildApp(const BecomeFarmerScreen()));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    // Field index 5 is Experience (Years): 0=Name, 1=Location, 2=Address, 3=Phone, 4=WhatsApp, 5=Exp
    await tester.enterText(fields.at(5), '7');

    await tester.ensureVisible(find.text('Create Farmer Profile'));
    await tester.tap(find.text('Create Farmer Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile Registered!'), findsOneWidget);

    final farmers = await farmerService.getFarmers();
    final created = farmers.firstWhere((f) => f.userId == 'bilal@example.com');
    expect(created.name, 'Bilal Ahmad');
    expect(created.phone, '0305 1112233');
    expect(created.whatsapp, '0305 1112233');
    expect(created.address, 'Bosan Road, Multan');
    expect(created.experienceYears, 7);

    // Verify FarmerListingScreen & FarmerProfileScreen show direct contact
    final launchedUris = <Uri>[];
    DirectContactLauncher.testLauncher = (uri) async {
      launchedUris.add(uri);
      return true;
    };

    await tester.pumpWidget(buildApp(const FarmerListingScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Bilal Ahmad'), findsOneWidget);

    await tester.pumpWidget(buildApp(FarmerProfileScreen(farmer: created)));
    await tester.pumpAndSettle();

    expect(find.text('Call Farmer'), findsOneWidget);
    expect(find.text('WhatsApp Farmer'), findsOneWidget);
    expect(find.text('Send Hiring Request'), findsNothing);
    expect(find.text('Request Contact'), findsNothing);

    await tester.ensureVisible(find.text('Call Farmer'));
    await tester.tap(find.text('Call Farmer'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('WhatsApp Farmer'));
    await tester.tap(find.text('WhatsApp Farmer'));
    await tester.pumpAndSettle();

    expect(launchedUris, hasLength(2));
    expect(launchedUris[0].scheme, 'tel');
    expect(launchedUris[1].host, 'wa.me');
  });

  testWidgets(
      'Guest clicking Become a Farmer / Offer a Land is gated by Login and continues to action without dashboard redirect',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    fakeAuthService.seed(
      const UserProfile(
        name: 'Registered Grower',
        email: 'grower@example.com',
        phone: '03001234567',
        location: 'Sargodha',
      ),
      'secret123',
    );
    await authController.continueAsGuest();

    await tester.pumpWidget(
      buildApp(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => ProtectedFeatureNavigation.open(
                  context,
                  destination: (_) => const BecomeFarmerScreen(),
                  loginScreenBuilder: (dest) => LoginScreen(onAuthenticated: dest),
                ),
                child: const Text('Become a Farmer'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Become a Farmer'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'grower@example.com');
    await tester.enterText(fields.at(1), 'secret123');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.byType(BecomeFarmerScreen), findsOneWidget);
    expect(find.text('Good morning,'), findsNothing);
  });
}
