import 'dart:convert';

import 'package:baghbani/models/nursery.dart';
import 'package:baghbani/models/user_profile.dart';
import 'package:baghbani/providers/auth_scope.dart';
import 'package:baghbani/screens/dashboard/dashboard_screen.dart';
import 'package:baghbani/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'places Add your nursery in Dashboard and removes it from Profile',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AuthController(AuthService());

    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          controller: controller,
          child: const DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Add your nursery'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Add your nursery'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('My Nursery'), findsNothing);
  });

  testWidgets('shows My Nursery when the signed-in user has registered one',
      (tester) async {
    const userId = 'gardener@example.com';
    final nursery = Nursery(
      id: 'nursery_registered',
      ownerUserId: userId,
      nurseryName: 'Green Garden',
      ownerName: 'Gardener',
      phone: '03001234567',
      address: 'Garden Road',
      city: 'Lahore',
      latitude: 31.52,
      longitude: 74.35,
      description: '',
      openingHours: '8 AM - 5 PM',
      image: '',
      createdAt: DateTime(2026),
    );
    SharedPreferences.setMockInitialValues({
      'baghbani.nurseries': [jsonEncode(nursery.toJson())],
    });
    final controller = AuthController(AuthService())
      ..profile = const UserProfile(
        name: 'Gardener',
        email: userId,
        phone: '',
        location: 'Lahore',
      )
      ..isAuthenticated = true;

    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          controller: controller,
          child: const DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('My Nursery'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('My Nursery'), findsOneWidget);
    expect(find.text('Add your nursery'), findsNothing);
  });
}
