import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';

class LunaBootstrap extends StatelessWidget {
  const LunaBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return LunaApp(config: AppConfig.fromEnvironment());
  }
}
