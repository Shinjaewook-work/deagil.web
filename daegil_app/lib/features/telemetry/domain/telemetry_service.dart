enum NormalizedEventName {
  appOpened,
  authSucceeded,
  fortuneUnlockStarted,
  fortuneUnlockCompleted,
  fortuneUnlockFailed,
  resultViewed,
  notificationPermissionResponse,
  consentUpdated,
}

extension NormalizedEventNameWire on NormalizedEventName {
  String get wireName => switch (this) {
    NormalizedEventName.appOpened => 'app_opened',
    NormalizedEventName.authSucceeded => 'auth_succeeded',
    NormalizedEventName.fortuneUnlockStarted => 'fortune_unlock_started',
    NormalizedEventName.fortuneUnlockCompleted => 'fortune_unlock_completed',
    NormalizedEventName.fortuneUnlockFailed => 'fortune_unlock_failed',
    NormalizedEventName.resultViewed => 'result_viewed',
    NormalizedEventName.notificationPermissionResponse =>
      'notification_permission_response',
    NormalizedEventName.consentUpdated => 'consent_updated',
  };
}

class NormalizedAnalyticsEvent {
  const NormalizedAnalyticsEvent({
    required this.name,
    this.parameters = const {},
  });

  final NormalizedEventName name;
  final Map<String, String> parameters;
}

abstract interface class AnalyticsService {
  bool get collectionEnabled;

  Future<void> setCollectionEnabled(bool enabled);

  Future<void> log(NormalizedAnalyticsEvent event);
}

abstract interface class CrashReporter {
  bool get collectionEnabled;

  Future<void> setCollectionEnabled(bool enabled);

  Future<void> deleteUnsentReports();

  Future<void> record({required String errorCode, required bool fatal});
}

class FakeAnalyticsService implements AnalyticsService {
  @override
  bool collectionEnabled = false;

  final List<NormalizedAnalyticsEvent> events = [];

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }

  @override
  Future<void> log(NormalizedAnalyticsEvent event) async {
    if (!collectionEnabled) return;
    if (event.parameters.keys.any(_isSensitiveKey)) {
      throw StateError('TELEMETRY_SENSITIVE_PARAMETER');
    }
    if (event.parameters.values.any((value) => value.length > 80)) {
      throw StateError('TELEMETRY_PARAMETER_TOO_LONG');
    }
    events.add(event);
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase();
    return normalized.contains('pii') ||
        normalized.contains('fortune') ||
        normalized.contains('prompt') ||
        normalized.contains('token') ||
        normalized.contains('user_id') ||
        normalized.contains('birth');
  }
}

class FakeCrashReporter implements CrashReporter {
  @override
  bool collectionEnabled = false;

  final List<String> recordedCodes = [];
  int deletedUnsentReports = 0;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }

  @override
  Future<void> deleteUnsentReports() async {
    deletedUnsentReports += 1;
  }

  @override
  Future<void> record({required String errorCode, required bool fatal}) async {
    if (!collectionEnabled) return;
    if (errorCode.trim().isEmpty || errorCode.length > 80) {
      throw StateError('CRASH_CODE_INVALID');
    }
    recordedCodes.add('${fatal ? 'fatal' : 'nonfatal'}:$errorCode');
  }
}
