import 'package:flutter/foundation.dart';

enum AppEnvironment { dev, prod }

enum AdSecurityMode { fast, rewardGated, ssvStrict }

AdSecurityMode parseAdSecurityMode(String value) => switch (value) {
  'reward_gated' => AdSecurityMode.rewardGated,
  'ssv_strict' => AdSecurityMode.ssvStrict,
  _ => AdSecurityMode.fast,
};

extension AdSecurityModeLabel on AdSecurityMode {
  String get wireValue => switch (this) {
    AdSecurityMode.fast => 'fast',
    AdSecurityMode.rewardGated => 'reward_gated',
    AdSecurityMode.ssvStrict => 'ssv_strict',
  };
}

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.admobRewardedUnitId,
    this.adSecurityMode = AdSecurityMode.fast,
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
      adSecurityMode: parseAdSecurityMode(
        const String.fromEnvironment('AD_SECURITY_MODE', defaultValue: 'fast'),
      ),
    );
  }

  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final String admobRewardedUnitId;
  final AdSecurityMode adSecurityMode;

  bool get isDevelopment => environment == AppEnvironment.dev;
  String get appDisplayName => isDevelopment ? 'Luna Dev' : 'Luna';

  @visibleForTesting
  bool get hasClientConfiguration =>
      supabaseUrl.isNotEmpty &&
      supabasePublishableKey.isNotEmpty &&
      admobRewardedUnitId.isNotEmpty;

  bool get hasValidAdSecurityMode =>
      AdSecurityMode.values.contains(adSecurityMode);
}
