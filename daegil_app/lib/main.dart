import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bootstrap.dart';
import 'core/config/app_config.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/fortune/data/fortune_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  SupabaseAuthRepository? productionAuthRepository;
  if (config.shouldInitializeSupabase) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
    );
    productionAuthRepository = SupabaseAuthRepository(
      client: Supabase.instance.client,
      redirectTo: config.authRedirectUrl,
    );
  }
  if (productionAuthRepository != null) {
    runApp(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(productionAuthRepository),
          fortuneRepositoryProvider.overrideWithValue(
            SupabaseFortuneRepository(client: Supabase.instance.client),
          ),
        ],
        child: const LunaBootstrap(),
      ),
    );
    return;
  }
  runApp(const ProviderScope(child: LunaBootstrap()));
}
