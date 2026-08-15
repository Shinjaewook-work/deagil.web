import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'app/router.dart';

class LunaBootstrap extends StatelessWidget {
  const LunaBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.fromEnvironment();
    if (!config.isDevelopment && !config.isProductionReady) {
      return MaterialApp(
        title: 'Luna',
        home: const PlaceholderScreen(
          title: '서비스 설정을 확인할 수 없다냥.',
          detail: '운영 환경 설정이 완료되지 않았어요.',
        ),
      );
    }
    return LunaApp(config: config, router: buildLunaRouter(config));
  }
}
