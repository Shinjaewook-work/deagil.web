import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bootstrap.dart';
import 'core/config/app_config.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/windows_oauth_callback_server.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/ads/data/rewarded_ad_gateway.dart';
import 'features/ads/presentation/rewarded_ad_controller.dart';
import 'features/fortune/data/fortune_repository.dart';
import 'features/settings/presentation/settings_controller.dart';
import 'features/settings/data/account_service.dart';
import 'features/notifications/data/notification_preference_repository.dart';
import 'features/notifications/presentation/notification_controller.dart';
import 'features/profile/data/birth_profile_repository.dart';
import 'features/profile/presentation/birth_profile_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  SupabaseAuthRepository? productionAuthRepository;
  if (config.shouldInitializeSupabase) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
    );
    final authRedirectUrl = Platform.isWindows
        ? 'http://${WindowsOAuthCallbackServer.host}:${WindowsOAuthCallbackServer.port}'
        : config.authRedirectUrl;
    if (Platform.isWindows) {
      await WindowsOAuthCallbackServer.start();
    }
    productionAuthRepository = SupabaseAuthRepository(
      client: Supabase.instance.client,
      redirectTo: authRedirectUrl,
    );
  }
  if (productionAuthRepository != null) {
    runApp(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(productionAuthRepository),
          rewardedAdGatewayProvider.overrideWithValue(
            SupabaseRewardedAdGateway(
              backend: SupabaseRewardedAdBackend(
                client: Supabase.instance.client,
              ),
              platform: Platform.isAndroid ? 'android' : 'ios',
            ),
          ),
          fortuneRepositoryProvider.overrideWithValue(
            SupabaseFortuneRepository(client: Supabase.instance.client),
          ),
          accountServiceProvider.overrideWithValue(
            SupabaseAccountService(client: Supabase.instance.client),
          ),
          notificationPreferenceRepositoryProvider.overrideWithValue(
            SupabaseNotificationPreferenceRepository(
              client: Supabase.instance.client,
            ),
          ),
          birthProfileRepositoryProvider.overrideWithValue(
            SupabaseBirthProfileRepository(client: Supabase.instance.client),
          ),
        ],
        child: const LunaBootstrap(),
      ),
    );
    return;
  }
  runApp(const ProviderScope(child: LunaBootstrap()));
}
