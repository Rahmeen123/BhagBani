
import 'package:flutter/material.dart';

import '../screens/land/my_land_listings_screen.dart';
import '../models/land.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';  
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/farmer/become_farmer_screen.dart';
import '../screens/farmer/farmer_listing_screen.dart';
import '../screens/farmer/hire_farmer_landing_screen.dart';
import '../screens/help/help_guide_screen.dart';
import '../screens/land/offer_land_screen.dart';
import '../screens/land/land_marketplace_screens.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/nursery/browse_plants_screen.dart';
import '../screens/nursery/my_orders_screen.dart';
import '../screens/nursery/nearby_nurseries_screen.dart';
import '../screens/nursery/nursery_gate_screen.dart';
import '../screens/nursery/register_nursery_screen.dart';
import '../screens/nursery/wishlist_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/profile_screen.dart';

abstract final class AppRoutes {
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const dashboard = '/dashboard';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const help = '/help';
  static const notifications = '/notifications';

  static const hireFarmer = '/hire-farmer';
  static const farmerListing = '/farmer-listing';
  static const becomeFarmer = '/become-farmer';

  // Land routes
  static const offerLand = '/offer-land';
  static const findLand = '/find-land';
  static const myLandListings = '/my-land-listings';
  static const myApplications = '/my-applications';

  // Nursery routes
  static const browsePlants = '/browse-plants';
  static const nearbyNurseries = '/nearby-nurseries';
  static const wishlist = '/wishlist';
  static const myOrders = '/my-orders';
  static const myNursery = '/my-nursery';
  static const registerNursery = '/register-nursery';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final Widget? screen = switch (settings.name) {
      welcome => const WelcomeScreen(),
      onboarding => const OnboardingScreen(),
      login => const LoginScreen(),
      signup => const SignupScreen(),
      forgotPassword => const ForgotPasswordScreen(),
      dashboard => const DashboardScreen(),
      profile => const ProfileScreen(),
      editProfile => const EditProfileScreen(),
      help => const HelpGuideScreen(),
      notifications => const NotificationsScreen(),

      hireFarmer => const HireFarmerLandingScreen(),
      farmerListing => const FarmerListingScreen(),
      becomeFarmer => const BecomeFarmerScreen(),

      // Land
      offerLand => settings.arguments is Land
          ? OfferLandScreen(land: settings.arguments as Land)
          : const OfferLandLandingScreen(),
      findLand => const FindLandScreen(),
      myLandListings => MyLandListingsScreen(
          ownerUserId: settings.arguments as String? ?? '',
        ),
      myApplications => MyAppliedLandsScreen(
          farmerUserId: settings.arguments as String? ?? '',
        ),

      // Nursery
      browsePlants => const BrowsePlantsScreen(),
      nearbyNurseries => const NearbyNurseriesScreen(),
      wishlist => const WishlistScreen(),
      myOrders => const MyOrdersScreen(),
      myNursery => const NurseryGateScreen(),
      registerNursery => const RegisterNurseryScreen(),

      _ => null,
    };

    if (screen == null) return null;

    return MaterialPageRoute<void>(
      builder: (_) => screen,
      settings: settings,
    );
  }
}
