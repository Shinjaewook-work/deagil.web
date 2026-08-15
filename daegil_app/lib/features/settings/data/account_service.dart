import 'package:supabase_flutter/supabase_flutter.dart';

class PrivacyState {
  const PrivacyState({
    this.aiPersonalizationAllowed = true,
    this.analyticsEnabled = false,
  });

  final bool aiPersonalizationAllowed;
  final bool analyticsEnabled;
}

abstract interface class AccountService {
  Future<void> setAnalyticsEnabled(bool enabled);

  Future<void> withdrawAiConsent();

  Future<void> logout();

  Future<void> deleteAccount();
}

class FakeAccountService implements AccountService {
  PrivacyState privacyState = const PrivacyState();
  final List<String> events = [];
  bool isLoggedOut = false;
  bool isDeleted = false;

  @override
  Future<void> setAnalyticsEnabled(bool enabled) async {
    privacyState = PrivacyState(
      aiPersonalizationAllowed: privacyState.aiPersonalizationAllowed,
      analyticsEnabled: enabled,
    );
    events.add('analytics:${enabled ? 'enabled' : 'disabled'}');
  }

  @override
  Future<void> withdrawAiConsent() async {
    privacyState = PrivacyState(
      aiPersonalizationAllowed: false,
      analyticsEnabled: false,
    );
    events.add('ai_consent_withdrawn');
  }

  @override
  Future<void> logout() async {
    isLoggedOut = true;
    events.add('logout');
  }

  @override
  Future<void> deleteAccount() async {
    isDeleted = true;
    isLoggedOut = true;
    events.add('delete_account');
  }
}

class SupabaseAccountService implements AccountService {
  SupabaseAccountService({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  @override
  Future<void> setAnalyticsEnabled(bool enabled) async {
    await _client.rpc(
      'set_my_privacy_preferences',
      params: {'analytics_enabled_value': enabled},
    );
  }

  @override
  Future<void> withdrawAiConsent() async {
    await _client.rpc('withdraw_my_ai_consent');
  }

  @override
  Future<void> logout() => _client.auth.signOut(scope: SignOutScope.local);

  @override
  Future<void> deleteAccount() async {
    final response = await _client.functions.invoke('delete-account');
    if (response.status >= 400) throw StateError('ACCOUNT_DELETE_FAILED');
    await _client.auth.signOut(scope: SignOutScope.local);
  }
}
