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
