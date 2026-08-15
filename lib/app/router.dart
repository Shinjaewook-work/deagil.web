import 'package:go_router/go_router.dart';

import 'app.dart';
import '../core/config/app_config.dart';

GoRouter buildLunaRouter(AppConfig config) {
  return GoRouter(
    initialLocation: '/auth',
    debugLogDiagnostics: config.isDevelopment,
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Luna에 오신 걸 환영한다냥!',
        ),
      ),
      GoRoute(
        path: '/today',
        builder: (context, state) => const PlaceholderScreen(
          title: '오늘의 운세를 준비하고 있다냥!',
        ),
      ),
      GoRoute(
        path: '/profile/setup',
        builder: (context, state) => const PlaceholderScreen(
          title: '출생정보를 알려달라냥!',
        ),
      ),
    ],
    errorBuilder: (context, state) => PlaceholderScreen(
      title: '페이지를 찾을 수 없다냥.',
      detail: state.error?.toString(),
    ),
  );
}
