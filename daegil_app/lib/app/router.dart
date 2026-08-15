import 'package:go_router/go_router.dart';

import 'app.dart';
import '../core/config/app_config.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/fortune/presentation/fortune_result_screen.dart';
import '../features/profile/presentation/birth_profile_screen.dart';
import '../features/settings/presentation/settings_screens.dart';
import '../features/today/presentation/cat_home_screen.dart';

GoRouter buildLunaRouter(AppConfig config) {
  return GoRouter(
    initialLocation: '/auth',
    debugLogDiagnostics: config.isDevelopment,
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/today',
        builder: (context, state) => const CatHomeScreen(),
      ),
      GoRoute(
        path: '/profile/setup',
        builder: (context, state) => const BirthProfileScreen(),
      ),
      GoRoute(
        path: '/fortune/result',
        builder: (context, state) => FortuneResultScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/profile',
        builder: (context, state) => const BirthProfileScreen(),
      ),
      GoRoute(
        path: '/settings/notification',
        builder: (context, state) =>
            const SettingsPlaceholderScreen(title: '알림'),
      ),
      GoRoute(
        path: '/settings/privacy',
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: '/settings/account',
        builder: (context, state) => const AccountSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/account/delete',
        builder: (context, state) => const AccountDeletionScreen(),
      ),
    ],
    errorBuilder: (context, state) => PlaceholderScreen(
      title: '페이지를 찾을 수 없다냥.',
      detail: state.error?.toString(),
    ),
  );
}
