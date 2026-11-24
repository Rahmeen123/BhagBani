import 'package:baghbani/providers/auth_scope.dart';
import 'package:baghbani/screens/nursery/browse_plants_screen.dart';
import 'package:baghbani/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads the plant catalog when opened', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AuthController(AuthService());

    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          controller: controller,
          child: const BrowsePlantsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Browse Plants'), findsOneWidget);
    expect(find.textContaining('Plants Available'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
