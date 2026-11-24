import 'package:baghbani/providers/auth_scope.dart';
import 'package:baghbani/screens/nursery/my_orders_screen.dart';
import 'package:baghbani/screens/nursery/wishlist_screen.dart';
import 'package:baghbani/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads wishlist after auth dependencies are available',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AuthController(AuthService());

    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          controller: controller,
          child: const WishlistScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Monstera Deliciosa'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('loads plant orders after auth dependencies are available',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AuthController(AuthService());

    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          controller: controller,
          child: const MyOrdersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ORD-98214'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
