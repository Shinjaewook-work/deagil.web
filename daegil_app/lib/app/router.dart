import 'package:go_router/go_router.dart';

import 'app.dart';
import '../core/config/app_config.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/profile/presentation/birth_profile_screen.dart';
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
    ],
    errorBuilder: (context, state) => PlaceholderScreen(
      title: '페이지를 찾을 수 없다냥.',
      detail: state.error?.toString(),
    ),
  );
}
