import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import 'theme/luna_theme.dart';

class LunaApp extends StatelessWidget {
  const LunaApp({required this.config, this.router, super.key});

  final AppConfig config;
  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    final theme = buildLunaTheme();
    if (router != null) {
      return MaterialApp.router(
        title: config.appDisplayName,
        debugShowCheckedModeBanner: config.isDevelopment,
        theme: theme,
        routerConfig: router,
      );
    }
    return MaterialApp(
      title: config.appDisplayName,
      debugShowCheckedModeBanner: config.isDevelopment,
      theme: theme,
      home: const PlaceholderScreen(title: '오늘도 알려주겠다냥!'),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, this.detail, super.key});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(detail!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
