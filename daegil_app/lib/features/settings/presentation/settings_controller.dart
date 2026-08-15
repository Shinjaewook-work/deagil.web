import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_service.dart';

final accountServiceProvider = Provider<AccountService>(
  (ref) => FakeAccountService(),
);

final settingsControllerProvider =
    NotifierProvider<SettingsController, PrivacyState>(SettingsController.new);

class SettingsController extends Notifier<PrivacyState> {
  @override
  PrivacyState build() => const PrivacyState();

  Future<void> setAnalyticsEnabled(bool enabled) async {
    await ref.read(accountServiceProvider).setAnalyticsEnabled(enabled);
    state = PrivacyState(
      aiPersonalizationAllowed: state.aiPersonalizationAllowed,
      analyticsEnabled: enabled,
    );
  }

  Future<void> withdrawAiConsent() async {
    await ref.read(accountServiceProvider).withdrawAiConsent();
    state = const PrivacyState(aiPersonalizationAllowed: false);
  }

  Future<void> logout() => ref.read(accountServiceProvider).logout();

  Future<void> deleteAccount() =>
      ref.read(accountServiceProvider).deleteAccount();
}
