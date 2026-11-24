import 'package:flutter/material.dart';
import '../../../navigation/protected_feature_navigation.dart';
import '../../../providers/auth_scope.dart';
import '../../auth/login_screen.dart';
import '../../land/offer_land_screen.dart';

void openCommunityFeature(
  BuildContext context, {
  required WidgetBuilder destination,
}) {
  ProtectedFeatureNavigation.open(
    context,
    destination: destination,
    loginScreenBuilder: (next) => LoginScreen(onAuthenticated: next),
  );
}

Future<bool> requireCommunityLogin(
  BuildContext context, {
  required String actionName,
}) async {
  final auth = AuthScope.of(context);
  if (auth.isAuthenticated && !auth.isGuest) return true;
  if (actionName == 'offer your land') {
    openCommunityFeature(
      context,
      destination: (_) => const OfferLandScreen(),
    );
  }
  return false;
}
