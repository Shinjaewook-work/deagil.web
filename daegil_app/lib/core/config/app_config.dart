import 'package:flutter/foundation.dart';

enum AppEnvironment { dev, prod }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.admobRewardedUnitId,
  });

  factory AppConfig.fromEnvironment() {
    final environment = switch (const String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'dev',
    )) {
      'prod' => AppEnvironment.prod,
      _ => AppEnvironment.dev,
    };

    return AppConfig(
      environment: environment,
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabasePublishableKey: const String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
      ),
      admobRewardedUnitId: const String.fromEnvironment(
        'ADMOB_REWARDED_UNIT_ID',
      ),
    );
  }

  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final String admobRewardedUnitId;

  bool get isDevelopment => environment == AppEnvironment.dev;
  String get appDisplayName => isDevelopment ? 'Luna Dev' : 'Luna';

  @visibleForTesting
  bool get hasClientConfiguration =>
      supabaseUrl.isNotEmpty &&
      supabasePublishableKey.isNotEmpty &&
      admobRewardedUnitId.isNotEmpty;
}
