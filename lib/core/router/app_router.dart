import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_signup_screen.dart';
import '../../features/map/presentation/screens/discover_map_screen.dart';
import '../../features/business_details/presentation/screens/business_details_screen.dart';
import '../../features/events/presentation/screens/events_screen.dart';
import '../../features/events/presentation/screens/event_details_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/change_password_screen.dart';
import '../../features/add_business/presentation/screens/add_business_screen.dart';
import '../../features/add_business/presentation/screens/edit_business_screen.dart';
import '../../features/add_event/presentation/screens/add_event_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/contact_us/presentation/screens/contact_us_screen.dart';
import '../../features/about_us/presentation/screens/about_us_screen.dart';
import '../../features/dashboard/presentation/screens/my_businesses_screen.dart';
import '../../features/dashboard/presentation/screens/business_dashboard_screen.dart';
import '../widgets/main_shell.dart';

/// Route path constants — reference these instead of hardcoding strings
/// throughout the app so renames only happen in one place.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String discoverMap = '/map';
  static const String businessDetails = '/business/:id';
  static const String events = '/events';
  static const String eventDetails = '/events/:id';
  static const String favorites = '/favorites';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String addBusiness = '/add-business';
  static const String addEvent = '/add-event';
  static const String settings = '/settings';
  static const String contactUs = '/contact-us';
  static const String aboutUs = '/about-us';
  static const String myBusinesses = '/my-businesses';
  static const String businessDashboard = '/dashboard/:id';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String editBusiness = '/edit-business/:id';

  static String businessDetailsPath(String id) => '/business/$id';
  static String eventDetailsPath(String id) => '/events/$id';
  static String businessDashboardPath(String id) => '/dashboard/$id';
  static String editBusinessPath(String id) => '/edit-business/$id';
}

/// A [Listenable] bridge so GoRouter's `refreshListenable` can react to
/// Riverpod auth-state changes and re-run redirects automatically.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authControllerProvider);
      final bool isSplash = state.matchedLocation == AppRoutes.splash;
      final bool isLoggingIn = state.matchedLocation == AppRoutes.login;

      if (authState.isLoading) return null; // wait for splash to decide

      final bool authenticated = authState.isAuthenticated;

      if (!authenticated && !isLoggingIn) return AppRoutes.login;
      if (authenticated && (isLoggingIn || isSplash)) return AppRoutes.discoverMap;

      // Guard business-user-only routes for guests.
      final bool isGuest = authState.user?.isGuest ?? true;
      // Profile is intentionally NOT in this list — guests can reach it,
      // ProfileScreen itself shows a "create an account" prompt instead of
      // the account menu when the current user is a guest. Without this,
      // a guest would have no in-app path back to registration at all.
      final List<String> businessOnlyRoutes = [
        AppRoutes.favorites,
        AppRoutes.addBusiness,
        AppRoutes.addEvent,
        AppRoutes.myBusinesses,
        AppRoutes.editProfile,
        AppRoutes.changePassword,
        '/edit-business', // prefix match for /edit-business/:id
        '/dashboard', // prefix match for /dashboard/:id — see businessDashboard route
      ];
      if (authenticated &&
          isGuest &&
          businessOnlyRoutes.any((r) => state.matchedLocation.startsWith(r))) {
        return AppRoutes.discoverMap;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginSignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.businessDetails,
        builder: (context, state) =>
            BusinessDetailsScreen(businessId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.eventDetails,
        builder: (context, state) =>
            EventDetailsScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.addBusiness,
        builder: (context, state) => const AddBusinessScreen(),
      ),
      GoRoute(
        path: AppRoutes.addEvent,
        builder: (context, state) => const AddEventScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.contactUs,
        builder: (context, state) => const ContactUsScreen(),
      ),
      GoRoute(
        path: AppRoutes.aboutUs,
        builder: (context, state) => const AboutUsScreen(),
      ),
      GoRoute(
        path: AppRoutes.myBusinesses,
        builder: (context, state) => const MyBusinessesScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.editBusiness,
        builder: (context, state) =>
            EditBusinessScreen(businessId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.businessDashboard,
        builder: (context, state) =>
            BusinessDashboardScreen(businessId: state.pathParameters['id']!),
      ),
      // Bottom-nav tabs share a persistent shell (state preserved across tabs).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.discoverMap, builder: (c, s) => const DiscoverMapScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.events, builder: (c, s) => const EventsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.favorites, builder: (c, s) => const FavoritesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.notifications,
              builder: (c, s) => const NotificationsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.profile, builder: (c, s) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});
