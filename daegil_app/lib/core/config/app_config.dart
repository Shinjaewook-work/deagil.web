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
    this.adSecurityModeExplicit = false,
    this.appDisplayNameOverride = '',
    this.androidApplicationId = '',
    this.iosBundleId = '',
    this.publicWebDomain = '',
    this.privacyUrl = '',
    this.termsUrl = '',
    this.accountDeletionUrl = '',
    this.aiProviderRegistryStatus = '',
    this.firebaseProjectId = '',
    this.firebaseAndroidAppId = '',
    this.firebaseIosAppId = '',
    this.authRedirectUrl =
        'https://nbdgwssdikmzitebqwkq.supabase.co/functions/v1/oauth-mobile-redirect',
    this.enableSupabaseAuth = false,
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
      adSecurityMode: parseAdSecurityMode(rawSecurityMode),
      adSecurityModeExplicit: rawSecurityMode.isNotEmpty,
      appDisplayNameOverride: const String.fromEnvironment('APP_DISPLAY_NAME'),
      androidApplicationId: const String.fromEnvironment(
        'ANDROID_APPLICATION_ID',
      ),
      iosBundleId: const String.fromEnvironment('IOS_BUNDLE_ID'),
      publicWebDomain: const String.fromEnvironment('PUBLIC_WEB_DOMAIN'),
      privacyUrl: const String.fromEnvironment('PRIVACY_URL'),
      termsUrl: const String.fromEnvironment('TERMS_URL'),
      accountDeletionUrl: const String.fromEnvironment('ACCOUNT_DELETION_URL'),
      aiProviderRegistryStatus: const String.fromEnvironment(
        'AI_PROVIDER_REGISTRY_STATUS',
      ),
      firebaseProjectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
      firebaseAndroidAppId: const String.fromEnvironment(
        'FIREBASE_ANDROID_APP_ID',
      ),
      firebaseIosAppId: const String.fromEnvironment('FIREBASE_IOS_APP_ID'),
      authRedirectUrl: const String.fromEnvironment(
        'AUTH_REDIRECT_URL',
        defaultValue:
            'https://nbdgwssdikmzitebqwkq.supabase.co/functions/v1/oauth-mobile-redirect',
      ),
      enableSupabaseAuth: const bool.fromEnvironment(
        'ENABLE_SUPABASE_AUTH',
        defaultValue: false,
      ),
    );
  }

  static const rawSecurityMode = String.fromEnvironment('AD_SECURITY_MODE');

  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final String admobRewardedUnitId;
  final AdSecurityMode adSecurityMode;
  final bool adSecurityModeExplicit;
  final String appDisplayNameOverride;
  final String androidApplicationId;
  final String iosBundleId;
  final String publicWebDomain;
  final String privacyUrl;
  final String termsUrl;
  final String accountDeletionUrl;
  final String aiProviderRegistryStatus;
  final String firebaseProjectId;
  final String firebaseAndroidAppId;
  final String firebaseIosAppId;
  final String authRedirectUrl;
  final bool enableSupabaseAuth;

  bool get isDevelopment => environment == AppEnvironment.dev;
  String get appDisplayName => isDevelopment
      ? '대길'
      : appDisplayNameOverride.isEmpty
      ? 'Luna'
      : appDisplayNameOverride;

  @visibleForTesting
  bool get hasClientConfiguration =>
      supabaseUrl.isNotEmpty &&
      supabasePublishableKey.isNotEmpty &&
      admobRewardedUnitId.isNotEmpty;

  bool get hasValidAdSecurityMode =>
      AdSecurityMode.values.contains(adSecurityMode);

  List<String> get productionConfigurationErrors {
    if (isDevelopment) return const [];
    final errors = <String>[];
    if (appDisplayNameOverride.trim().isEmpty) {
      errors.add('APP_DISPLAY_NAME_MISSING');
    }
    if (!_isHttpsSupabaseUrl(supabaseUrl)) errors.add('SUPABASE_URL_INVALID');
    if (supabasePublishableKey.isEmpty) {
      errors.add('SUPABASE_PUBLISHABLE_KEY_MISSING');
    }
    if (admobRewardedUnitId.isEmpty ||
        admobRewardedUnitId.contains('3940256099942544')) {
      errors.add('ADMOB_PRODUCTION_UNIT_MISSING');
    }
    if (!adSecurityModeExplicit || !hasValidAdSecurityMode) {
      errors.add('AD_SECURITY_MODE_INVALID_OR_MISSING');
    }
    if (_isPlaceholderPackage(androidApplicationId)) {
      errors.add('ANDROID_APPLICATION_ID_INVALID');
    }
    if (_isPlaceholderPackage(iosBundleId)) errors.add('IOS_BUNDLE_ID_INVALID');
    if (!_isValidMobileRedirectUrl(authRedirectUrl)) {
      errors.add('AUTH_REDIRECT_URL_INVALID');
    }
    if (!_isHttpsUrl(privacyUrl)) errors.add('PRIVACY_URL_INVALID');
    if (!_isHttpsUrl(termsUrl)) errors.add('TERMS_URL_INVALID');
    if (!_isHttpsUrl(accountDeletionUrl)) {
      errors.add('ACCOUNT_DELETION_URL_INVALID');
    }
    if (aiProviderRegistryStatus != 'PROD_APPROVED') {
      errors.add('AI_PROVIDER_NOT_PROD_APPROVED');
    }
    if (firebaseProjectId.trim().isEmpty) {
      errors.add('FIREBASE_PROJECT_MISSING');
    }
    if (firebaseAndroidAppId.trim().isEmpty) {
      errors.add('FIREBASE_ANDROID_APP_ID_MISSING');
    }
    if (firebaseIosAppId.trim().isEmpty) {
      errors.add('FIREBASE_IOS_APP_ID_MISSING');
    }
    return List.unmodifiable(errors);
  }

  bool get isProductionReady => productionConfigurationErrors.isEmpty;

  bool get shouldInitializeSupabase =>
      (!isDevelopment && isProductionReady) ||
      (isDevelopment && enableSupabaseAuth && _hasValidSupabaseClientConfig);

  bool get _hasValidSupabaseClientConfig =>
      _isHttpsSupabaseUrl(supabaseUrl) && supabasePublishableKey.isNotEmpty;

  static bool _isHttpsSupabaseUrl(String value) =>
      _isHttpsUrl(value) && !value.contains('example');

  static bool _isHttpsUrl(String value) => value.startsWith('https://');

  static bool _isValidMobileRedirectUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.scheme.isNotEmpty &&
        ((uri.scheme != 'http' &&
                uri.scheme != 'https' &&
                uri.host == 'login-callback') ||
            (uri.scheme == 'https' &&
                uri.host.endsWith('.supabase.co') &&
                uri.path == '/functions/v1/oauth-mobile-redirect'));
  }

  static bool _isPlaceholderPackage(String value) =>
      value.isEmpty || value.startsWith('com.example') || value == 'TBD';
}
