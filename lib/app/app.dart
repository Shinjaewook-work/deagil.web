import 'package:flutter/material.dart';

import '../core/config/app_config.dart';

class LunaApp extends StatelessWidget {
  const LunaApp({required this.config, super.key});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: config.appDisplayName,
      debugShowCheckedModeBanner: config.isDevelopment ? true : false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFA14B3F)),
        scaffoldBackgroundColor: const Color(0xFFF4EFE5),
        useMaterial3: true,
      ),
      home: const _BootstrapHome(),
    );
  }
}

class _BootstrapHome extends StatelessWidget {
  const _BootstrapHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          '오늘도 알려주겠다냥!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
