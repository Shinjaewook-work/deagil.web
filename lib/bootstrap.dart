import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'app/router.dart';

class LunaBootstrap extends StatelessWidget {
  const LunaBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.fromEnvironment();
    return LunaApp(config: config, router: buildLunaRouter(config));
  }
}
