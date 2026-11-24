import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baghbani/models/land.dart';
import 'package:baghbani/models/land_application.dart';
import 'package:baghbani/models/user_profile.dart';
import 'package:baghbani/providers/auth_scope.dart';
import 'package:baghbani/screens/auth/login_screen.dart';
import 'package:baghbani/screens/land/land_applications_screen.dart';
import 'package:baghbani/screens/land/land_marketplace_screens.dart';
import 'package:baghbani/screens/land/manage_land_listing_screen.dart';
import 'package:baghbani/screens/land/my_land_listings_screen.dart';
import 'package:baghbani/screens/land/offer_land_screen.dart';
import 'package:baghbani/services/auth_service.dart';
import 'package:baghbani/services/land_service.dart';

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
  late _FakeAuthService fakeAuthService;
  late AuthController authController;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    landService = LandService();
    fakeAuthService = _FakeAuthService();
    authController = AuthController(fakeAuthService);
  });

  tearDown(() => authController.dispose());

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
      'My Land Listings displays land card details and Manage Listing button',
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
      createdAt: DateTime.now(),
    );
    await landService.updateLand(land);

    final app = LandApplication(
      id: 'app_1',
      landId: 'test_land_1',
      ownerUserId: 'owner@example.com',
      farmerUserId: 'farmer1@example.com',
      farmerName: 'Ahmad Farmer',
      experience: '7 years',
      skills: 'Wheat management',
      location: 'Lahore',
      message: 'Interested in working on this land.',
      status: LandApplication.pending,
      createdAt: DateTime.now(),
    );
    await landService.submitApplication(app);

    await tester.pumpWidget(
      buildApp(const MyLandListingsScreen(ownerUserId: 'owner@example.com')),
    );
    await tester.pumpAndSettle();

    // Check Land Name, Location, Area, Status, Total Applications
    expect(find.text('Green Valley Farmland'), findsOneWidget);
    expect(find.text('Sheikhupura, Punjab'), findsOneWidget);
    expect(find.text('25 Acres'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Total Applications: 1'), findsOneWidget);

    // Check Manage Listing button
    expect(find.text('Manage Listing'), findsOneWidget);
  });

  testWidgets(
      'Manage Listing screen shows Land Details, Edit, Close, Delete, and Applications badge',
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

    // Land Details
    expect(find.text('Sunny Acres Farm'), findsOneWidget);
    expect(find.text('Okara, Punjab'), findsOneWidget);
    expect(find.text('18 Acres'), findsOneWidget);
    expect(find.text('Potato & Maize'), findsOneWidget);
    expect(find.text('Tube-well'), findsOneWidget);
    expect(find.text('Alluvial'), findsOneWidget);
    expect(find.text('Excellent soil for crop rotation.'), findsOneWidget);

    // Applications badge and controls
    expect(find.text('Applications'), findsOneWidget);
    expect(find.text('Edit Listing'), findsOneWidget);
    expect(find.text('Close Listing'), findsOneWidget);
    expect(find.text('Delete Listing'), findsOneWidget);

    // Toggle close listing
    await tester.tap(find.text('Close Listing'));
    await tester.pumpAndSettle();

    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Reopen Listing'), findsOneWidget);
  });

  testWidgets(
      'Land Applications screen displays only applicants for THIS land and allows Accept/Reject',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final land1 = Land(
      id: 'land_a',
      ownerUserId: 'owner@example.com',
      ownerName: 'Test Owner',
      landName: 'Land Alpha',
      location: 'Lahore',
      area: 10,
      areaUnit: 'Acres',
      soilType: 'Loamy',
      waterSource: 'Canal',
      preferredCrop: 'Wheat',
      description: 'Land Alpha desc',
      images: const [],
      status: 'Available',
      createdAt: DateTime.now(),
    );
    final land2 = Land(
      id: 'land_b',
      ownerUserId: 'owner@example.com',
      ownerName: 'Test Owner',
      landName: 'Land Beta',
      location: 'Multan',
      area: 20,
      areaUnit: 'Acres',
      soilType: 'Sandy',
      waterSource: 'Canal',
      preferredCrop: 'Cotton',
      description: 'Land Beta desc',
      images: const [],
      status: 'Available',
      createdAt: DateTime.now(),
    );
    await landService.updateLand(land1);
    await landService.updateLand(land2);

    final app1 = LandApplication(
      id: 'app_for_a',
      landId: 'land_a',
      ownerUserId: 'owner@example.com',
      farmerUserId: 'farmer_a@example.com',
      farmerName: 'Zahid Farmer',
      experience: '10 years experience',
      skills: 'Wheat & Rice harvest',
      location: 'Lahore district',
      message: 'I have modern equipment for Land Alpha.',
      status: LandApplication.pending,
      createdAt: DateTime.now(),
    );
    final app2 = LandApplication(
      id: 'app_for_b',
      landId: 'land_b',
      ownerUserId: 'owner@example.com',
      farmerUserId: 'farmer_b@example.com',
      farmerName: 'Bilal Farmer',
      experience: '4 years experience',
      skills: 'Cotton farming',
      location: 'Multan district',
      message: 'Looking for cotton field.',
      status: LandApplication.pending,
      createdAt: DateTime.now(),
    );
    await landService.submitApplication(app1);
    await landService.submitApplication(app2);

    await tester.pumpWidget(
      buildApp(
        LandApplicationsScreen(
          land: land1,
          ownerUserId: 'owner@example.com',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check that ONLY applicant for land1 appears, not land2
    expect(find.text('Zahid Farmer'), findsOneWidget);
    expect(find.text('Bilal Farmer'), findsNothing);

    // Card contains Farmer Name, Experience, Skills, Location, Message, Buttons
    expect(find.text('10 years experience'), findsOneWidget);
    expect(find.text('Wheat & Rice harvest'), findsOneWidget);
    expect(find.text('Lahore district'), findsOneWidget);
    expect(find.text('I have modern equipment for Land Alpha.'), findsOneWidget);
    expect(find.text('View Profile'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);

    // Accept application
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    // Status updated
    expect(find.text('Accepted'), findsAtLeastNWidgets(1));
    final updated =
        (await landService.getApplicationsByFarmer('farmer_a@example.com'))
            .first;
    expect(updated.status, LandApplication.accepted);
  });

  testWidgets(
      'Guest clicking Apply in LandDetailScreen is gated by Login, and after login continues to application form',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    fakeAuthService.seed(
      const UserProfile(
        name: 'Registered Farmer',
        email: 'regfarmer@example.com',
        phone: '03001234567',
        location: 'Sargodha',
      ),
      'secret123',
    );
    await authController.continueAsGuest();

    final land = Land(
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
      description: 'Fertile land.',
      images: const [],
      status: 'Available',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      buildApp(LandDetailScreen(land: land, service: landService)),
    );
    await tester.pumpAndSettle();

    // Guest taps Apply Now
    await tester.tap(find.text('Apply Now'));
    await tester.pumpAndSettle();

    // Should open LoginScreen (guest cannot apply)
    expect(find.byType(LoginScreen), findsOneWidget);

    // User logs in
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'regfarmer@example.com');
    await tester.enterText(fields.at(1), 'secret123');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    // Does NOT redirect to dashboard, continues directly to ApplyLandScreen!
    expect(find.byType(ApplyLandScreen), findsOneWidget);
    expect(find.text('Apply for Canal-side wheat and rice farm'), findsOneWidget);
    expect(find.text('Good morning,'), findsNothing);

    // Fill application form
    final formInputs = find.byType(TextFormField);
    await tester.enterText(formInputs.at(0), 'Hello, I am an experienced farmer.');
    await tester.enterText(formInputs.at(1), 'Expert in rice and wheat.');
    await tester.enterText(formInputs.at(2), '8 years of cultivation.');

    // Submit Application
    await tester.tap(find.text('Submit Application'));
    await tester.pumpAndSettle();

    // Submitting redirects directly to My Applications (MyAppliedLandsScreen)!
    expect(find.byType(MyAppliedLandsScreen), findsOneWidget);
    expect(find.text('Canal-side wheat and rice farm'), findsOneWidget);
    expect(find.text('Owner: Chaudhry Riaz'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets(
      'My Applications displays Land Name, Owner, and Status (Pending, Accepted, Rejected)',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final land = Land(
      id: 'demo_land_app',
      ownerUserId: 'owner_demo',
      ownerName: 'Mian Aslam',
      landName: 'Citrus orchard plot',
      location: 'Khanewal',
      area: 15,
      areaUnit: 'Acres',
      soilType: 'Sandy loam',
      waterSource: 'Drip',
      preferredCrop: 'Citrus',
      description: 'Orchard plot',
      images: const [],
      status: 'Available',
      createdAt: DateTime.now(),
    );
    await landService.updateLand(land);

    final application = LandApplication(
      id: 'app_citrus',
      landId: 'demo_land_app',
      ownerUserId: 'owner_demo',
      farmerUserId: 'farmer_citrus@example.com',
      farmerName: 'Citrus Grower',
      experience: '5 years',
      skills: 'Citrus management',
      location: 'Khanewal',
      message: 'Ready to manage orchard.',
      status: LandApplication.accepted,
      createdAt: DateTime.now(),
    );
    await landService.submitApplication(application);

    await tester.pumpWidget(
      buildApp(
        const MyAppliedLandsScreen(farmerUserId: 'farmer_citrus@example.com'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Citrus orchard plot'), findsOneWidget);
    expect(find.text('Owner: Mian Aslam'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
  });
}
