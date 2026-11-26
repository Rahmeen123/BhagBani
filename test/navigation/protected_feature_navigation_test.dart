import 'package:baghbani/features/tree_recommendation/screens/tree_intro_screen.dart';
import 'package:baghbani/models/user_profile.dart';
import 'package:baghbani/providers/auth_scope.dart';
import 'package:baghbani/screens/auth/login_screen.dart';
import 'package:baghbani/screens/auth/onboarding_screen.dart';
import 'package:baghbani/screens/auth/signup_screen.dart';
import 'package:baghbani/screens/auth/splash_screen.dart';
import 'package:baghbani/screens/auth/welcome_screen.dart';
import 'package:baghbani/features/crop_recommendation/screens/crop_recommendation_intro_screen.dart';
import 'package:baghbani/screens/dashboard/dashboard_screen.dart';
import 'package:baghbani/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthController auth;
  late _TestAuthService authService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    authService = _TestAuthService();
    auth = AuthController(authService);
  });

  tearDown(() => auth.dispose());

  Future<void> pumpIntro(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      AuthScope(
        controller: auth,
        child: const MaterialApp(home: TreeIntroScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
  }

  Future<void> pumpWelcome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      AuthScope(
        controller: auth,
        child: const MaterialApp(home: WelcomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('guest login resumes at location selection', (tester) async {
    await auth.register(
      const UserProfile(
        name: 'Test Farmer',
        email: 'farmer@example.com',
        phone: '5550100',
        location: 'Lahore',
      ),
      'password123',
    );
    await auth.continueAsGuest();

    await pumpIntro(tester);
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.enterText(
        find.byType(TextFormField).at(0), 'farmer@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Select Land Location'), findsOneWidget);
    expect(find.text('Good morning,'), findsNothing);
  });

  testWidgets('authenticated user proceeds directly to location selection',
      (tester) async {
    await auth.register(
      const UserProfile(
        name: 'Test Farmer',
        email: 'farmer@example.com',
        phone: '5550100',
        location: 'Lahore',
      ),
      'password123',
    );

    await pumpIntro(tester);

    expect(find.text('Select Land Location'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('signup also resumes the protected feature', (tester) async {
    await pumpIntro(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.byType(SignupScreen), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'New Farmer');
    await tester.enterText(fields.at(1), 'newfarmer@example.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), '5550123');
    await tester.enterText(fields.at(4), 'Lahore');
    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Create account'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Select Land Location'), findsOneWidget);
  });

  testWidgets('dashboard crop flow resumes at its intro after login',
      (tester) async {
    await auth.register(
      const UserProfile(
        name: 'Test Farmer',
        email: 'farmer@example.com',
        phone: '5550100',
        location: 'Lahore',
      ),
      'password123',
    );
    await auth.continueAsGuest();
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      AuthScope(
        controller: auth,
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Crop Recommendation'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Crop Recommendation'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'farmer@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.byType(CropRecommendationIntroScreen), findsOneWidget);
    expect(find.text('Good morning,'), findsNothing);
  });

  testWidgets('splash preserves onboarding and welcome for signed-out users',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      AuthScope(
        controller: auth,
        child: const MaterialApp(home: SplashScreen()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.byType(SignupScreen), findsOneWidget);
  });

  testWidgets('welcome login authenticates and opens the dashboard',
      (tester) async {
    authService.seed(
      const UserProfile(
        name: 'Test Farmer',
        email: 'farmer@example.com',
        phone: '5550100',
        location: 'Lahore',
      ),
      'password123',
    );
    await pumpWelcome(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'farmer@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Good morning,'), findsOneWidget);
  });

  testWidgets('welcome signup creates an account and opens the dashboard',
      (tester) async {
    await pumpWelcome(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Create account'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'New Farmer');
    await tester.enterText(fields.at(1), 'newfarmer@example.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), '5550123');
    await tester.enterText(fields.at(4), 'Lahore');
    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Create account'),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Good morning,'), findsOneWidget);
  });
}

class _TestAuthService extends AuthService {
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
    if (_profile?.email.toLowerCase() == profile.email.toLowerCase()) {
      return false;
    }
    _profile = profile;
    _password = password;
    _isGuest = false;
    return true;
  }

  @override
  Future<bool> signIn(String email, String password) async {
    if (_profile?.email.toLowerCase() != email.trim().toLowerCase() ||
        _password != password) {
      return false;
    }
    _isGuest = false;
    return true;
  }

  @override
  Future<UserProfile?> restoreProfile() async =>
      _isGuest ? UserProfile.guest : _profile;
}
