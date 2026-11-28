import 'dart:async';

import 'package:baghbani/features/plant_recommendation/data/plant_local_names.dart';
import 'package:baghbani/features/plant_recommendation/models/plant.dart';
import 'package:baghbani/features/plant_recommendation/models/plant_preferences.dart';
import 'package:baghbani/features/plant_recommendation/repositories/plant_repository.dart';
import 'package:baghbani/features/plant_recommendation/screens/plant_detail_screen.dart';
import 'package:baghbani/features/plant_recommendation/screens/plant_intro_screen.dart';
import 'package:baghbani/features/plant_recommendation/screens/plant_preference_screen.dart';
import 'package:baghbani/features/plant_recommendation/screens/plant_recommendation_result_screen.dart';
import 'package:baghbani/features/plant_recommendation/services/plant_recommendation_service.dart';
import 'package:baghbani/models/user_profile.dart';
import 'package:baghbani/providers/auth_scope.dart';
import 'package:baghbani/screens/auth/login_screen.dart';
import 'package:baghbani/screens/auth/signup_screen.dart';
import 'package:baghbani/screens/dashboard/dashboard_screen.dart';
import 'package:baghbani/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlantRepository and PlantRecommendationService', () {
    final service = PlantRecommendationService();

    test('loads deduplicated cleaned plants and preserves source names',
        () async {
      final plants = await PlantRepository().getPlants();

      expect(plants, hasLength(387));
      final snakePlant = plants.firstWhere((p) => p.name == 'Snake Plant');
      expect(snakePlant.growth, 'slow');
      expect(snakePlant.soil, 'well-drained');
      expect(snakePlant.sunlight, 'indirect sunlight');
      expect(snakePlant.watering, 'Water when soil is dry');
      expect(snakePlant.fertilizationType, 'No');
      expect(snakePlant.careLevel, 'Low');
      expect(snakePlant.healthSupported, isFalse);

      expect(
        plants.any((p) => p.name == 'Devil’s Ivy'),
        isTrue,
      );
      expect(
        plants.any((p) => p.name == 'Bachelor’s Button'),
        isTrue,
      );
    });

    test('decodes mixed UTF-8 and Windows-1252 bytes cleanly', () {
      final bytes = Uint8List.fromList([
        0x44, 0x65, 0x76, 0x69, 0x6C, 0x92, 0x73, 0x20, 0x49, 0x76,
        0x79, // Devil’s Ivy
      ]);
      expect(PlantRepository.decodeCsvBytes(bytes), 'Devil’s Ivy');
    });

    test('exactly filters sunlight and care without scoring or result caps',
        () async {
      final plants = await PlantRepository().getPlants();
      final results = service.recommend(
        plants: plants,
        preferences: const PlantPreferences(
          sunlight: SunlightPreference.lowLight,
          watering: WateringPreference.lowCare,
          soilType: null,
          growth: GrowthPreference.noPreference,
        ),
      );

      expect(results.length, greaterThan(5));
      expect(
        results.map((r) => r.plant.name.toLowerCase()).toSet(),
        hasLength(results.length),
      );

      expect(
        results.map((r) => r.plant.name),
        contains('Snake Plant'),
      );
      expect(
        results.every(
          (r) =>
              r.plant.sunlight == 'indirect sunlight' &&
              r.plant.careLevel == 'Low',
        ),
        isTrue,
      );

      // Every plant in the CSV should resolve to an explicit Urdu & easy name.
      for (final plant in plants) {
        final local = PlantLocalNames.resolve(plant.name);
        expect(
          local.urduName.contains('گھریلو پودا'),
          isFalse,
          reason: 'Missing local Urdu mapping for ${plant.name}',
        );
      }
    });

    test('applies optional soil and growth filters exactly', () {
      const samplePlants = [
        Plant(
          name: 'Snake Plant',
          growth: 'slow',
          soil: 'well-drained',
          sunlight: 'indirect sunlight',
          watering: 'Water when soil is dry',
          fertilizationType: 'No',
          careLevel: 'Low',
        ),
        Plant(
          name: 'ZZ Plant',
          growth: 'slow',
          soil: 'loamy',
          sunlight: 'indirect sunlight',
          watering: 'Water weekly',
          fertilizationType: 'Balanced',
          careLevel: 'Regular',
        ),
      ];

      final results = service.recommend(
        plants: samplePlants,
        preferences: const PlantPreferences(
          sunlight: SunlightPreference.lowLight,
          watering: WateringPreference.lowCare,
          soilType: PlantSoilType.wellDrained,
          growth: GrowthPreference.slowGrowing,
        ),
      );

      expect(results, hasLength(1));
      expect(results[0].plant.name, 'Snake Plant');
    });

    test('relaxes growth, then soil, then adjacent care only when needed', () {
      const samplePlants = [
        Plant(
          name: 'Sandy Fast',
          growth: 'fast',
          soil: 'sandy',
          sunlight: 'full sunlight',
          watering: 'Water weekly',
          fertilizationType: 'Organic',
          careLevel: 'Regular',
        ),
        Plant(
          name: 'Sandy Slow',
          growth: 'slow',
          soil: 'sandy',
          sunlight: 'full sunlight',
          watering: 'Water weekly',
          fertilizationType: 'Organic',
          careLevel: 'Regular',
        ),
        Plant(
          name: 'Loamy Moderate',
          growth: 'moderate',
          soil: 'loamy',
          sunlight: 'full sunlight',
          watering: 'Water weekly',
          fertilizationType: 'Organic',
          careLevel: 'Regular',
        ),
        Plant(
          name: 'Adjacent Care',
          growth: 'fast',
          soil: 'acidic',
          sunlight: 'full sunlight',
          watering: 'Water weekly',
          fertilizationType: 'Organic',
          careLevel: 'Regular',
        ),
      ];

      final growthFallback = service.recommend(
        plants: samplePlants,
        preferences: const PlantPreferences(
          sunlight: SunlightPreference.fullSun,
          watering: WateringPreference.regularCare,
          soilType: PlantSoilType.sandy,
          growth: GrowthPreference.moderateGrowing,
        ),
      );
      expect(
        growthFallback.map((recommendation) => recommendation.plant.name),
        ['Sandy Fast', 'Sandy Slow'],
      );

      final soilFallback = service.recommend(
        plants: samplePlants,
        preferences: const PlantPreferences(
          sunlight: SunlightPreference.fullSun,
          watering: WateringPreference.regularCare,
          soilType: PlantSoilType.moist,
          growth: GrowthPreference.slowGrowing,
        ),
      );
      expect(
        soilFallback.map((recommendation) => recommendation.plant.name),
        ['Sandy Fast', 'Sandy Slow', 'Loamy Moderate', 'Adjacent Care'],
      );

      final careFallback = service.recommend(
        plants: samplePlants,
        preferences: const PlantPreferences(
          sunlight: SunlightPreference.fullSun,
          watering: WateringPreference.lowCare,
        ),
      );
      expect(
        careFallback.map((recommendation) => recommendation.plant.name),
        [
          'Sandy Fast',
          'Sandy Slow',
          'Loamy Moderate',
          'Adjacent Care',
        ],
      );
    });

    test('returns empty list when no plants match sunlight and watering', () {
      const sunOnlyPlant = [
        Plant(
          name: 'Cactus',
          growth: 'slow',
          soil: 'sandy',
          sunlight: 'full sunlight',
          watering: 'Let soil dry between watering',
          fertilizationType: 'Low-nitrogen',
        ),
      ];

      final results = service.recommend(
        plants: sunOnlyPlant,
        preferences: const PlantPreferences(
          sunlight: SunlightPreference.lowLight,
          watering: WateringPreference.highCare,
        ),
      );

      expect(results, isEmpty);
    });
  });

  group('Plant Recommendation UI & Auth flow', () {
    late AuthController auth;
    late _InMemoryAuthService authService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authService = _InMemoryAuthService();
      auth = AuthController(authService);
    });

    tearDown(() => auth.dispose());

    testWidgets(
        'Dashboard Garden -> Plant Recommendation -> Intro -> Guest login redirects directly to preference form',
        (tester) async {
      await auth.register(
        const UserProfile(
          name: 'Garden User',
          email: 'gardener@example.com',
          phone: '03001234567',
          location: 'Lahore',
        ),
        'password123',
      );
      await auth.continueAsGuest();

      tester.view.physicalSize = const Size(800, 1200);
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
        find.text('Plant Recommendation'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Plant Recommendation'));
      await tester.pumpAndSettle();

      expect(find.byType(PlantIntroScreen), findsOneWidget);

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'gardener@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
      await tester.pumpAndSettle();

      expect(find.byType(PlantPreferenceScreen), findsOneWidget);
      expect(find.text('Good morning,'), findsNothing);
    });

    testWidgets(
        'Signup from Plant Recommendation auth gate continues directly to preference form',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        AuthScope(
          controller: auth,
          child: const MaterialApp(home: PlantIntroScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Create account'));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'New Gardener');
      await tester.enterText(fields.at(1), 'newgardener@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), '03001234567');
      await tester.enterText(fields.at(4), 'Islamabad');
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Create account'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.byType(PlantPreferenceScreen), findsOneWidget);
    });

    testWidgets(
        'Authenticated user selects options, sees exact results and Plant Details',
        (tester) async {
      await auth.register(
        const UserProfile(
          name: 'Logged In Gardener',
          email: 'user@example.com',
          phone: '03001234567',
          location: 'Karachi',
        ),
        'password123',
      );

      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        AuthScope(
          controller: auth,
          child: const MaterialApp(home: PlantIntroScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.byType(PlantPreferenceScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // Soil chips are hidden by default ("No").
      expect(find.text('sandy'), findsNothing);

      // Tapping "Yes" shows soil chips, tapping "No" hides them again.
      await tester.ensureVisible(find.text('Yes'));
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('sandy'));
      expect(find.text('well-drained'), findsOneWidget);
      expect(find.text('sandy'), findsOneWidget);
      expect(find.text('loamy'), findsOneWidget);
      expect(find.text('moist'), findsOneWidget);
      expect(find.text('acidic'), findsOneWidget);

      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      expect(find.text('sandy'), findsNothing);

      await tester.ensureVisible(find.text('Moderate'));
      expect(find.text('Moderate'), findsOneWidget);

      // Select Low Light + Low care.
      await tester.ensureVisible(find.text('Low Light'));
      await tester.tap(find.text('Low Light'));
      await tester.ensureVisible(find.text('Low'));
      await tester.tap(find.text('Low'));

      await tester.ensureVisible(find.text('Get Recommendations'));
      await tester.tap(find.text('Get Recommendations'));
      await tester.pumpAndSettle();

      expect(find.byType(PlantRecommendationResultScreen), findsOneWidget);
      expect(find.text('Recommended Plants'), findsWidgets);
      expect(find.text('Snake Plant'), findsOneWidget);
      expect(find.text('Naag Phani / Sansevieria'), findsOneWidget);
      expect(find.text('اردو نام: ناگ پھنی (سنیک پلانٹ)'), findsOneWidget);
      expect(find.text('View Details'), findsWidgets);
      expect(find.text('Check Health'), findsNothing);

      await tester.tap(find.text('View Details').first);
      await tester.pumpAndSettle();

      expect(find.byType(PlantDetailScreen), findsOneWidget);
      expect(find.text('Soil Requirement'), findsOneWidget);
      expect(find.text('Watering Requirement'), findsOneWidget);
      expect(find.text('Fertilization Type'), findsOneWidget);
      expect(find.text('Growth Type'), findsNothing);
      expect(find.text('Care Tips'), findsNothing);
      expect(find.text('Check Health'), findsNothing);
    });

    testWidgets('supported plants expose the camera and gallery health action',
        (tester) async {
      final plants = await PlantRepository().getPlants();
      final tomato = PlantRecommendationService()
          .recommend(
            plants: plants,
            preferences: const PlantPreferences(
              sunlight: SunlightPreference.fullSun,
              watering: WateringPreference.regularCare,
            ),
          )
          .firstWhere(
              (recommendation) => recommendation.plant.name == 'Tomato');

      expect(tomato.plant.healthSupported, isTrue);
      await tester.pumpWidget(
        MaterialApp(home: PlantDetailScreen(recommendation: tomato)),
      );
      await tester.ensureVisible(find.text('Check Health'));
      await tester.tap(find.text('Check Health'));
      await tester.pumpAndSettle();

      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
    });

    testWidgets('Shows loading state and empty state when no plants match',
        (tester) async {
      final completer = Completer<List<Plant>>();
      final repository = _FakePlantRepository(completer.future);

      await tester.pumpWidget(
        MaterialApp(
          home: PlantRecommendationResultScreen(
            preferences: const PlantPreferences(
              sunlight: SunlightPreference.lowLight,
              watering: WateringPreference.highCare,
            ),
            repository: repository,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Finding your best plant matches...'), findsOneWidget);

      completer.complete(const []);
      await tester.pumpAndSettle();

      expect(find.text('No matching plants found'), findsOneWidget);
      expect(find.text('Adjust Preferences'), findsOneWidget);
    });
  });
}

class _FakePlantRepository extends PlantRepository {
  _FakePlantRepository(this._future) : super(bundle: _EmptyAssetBundle());

  final Future<List<Plant>> _future;

  @override
  Future<List<Plant>> getPlants() => _future;
}

class _EmptyAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData(0);
}

class _InMemoryAuthService extends AuthService {
  UserProfile? _profile;
  String? _password;
  bool _isGuest = false;

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
