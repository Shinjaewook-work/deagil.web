import '../../../core/config/app_config.dart';

enum RewardedAdFlowStatus {
  idle,
  loading,
  ready,
  showing,
  rewardVerifying,
  completed,
  dismissed,
  pendingReward,
  failed,
}

class AdAttempt {
  const AdAttempt({
    required this.id,
    required this.fortuneDate,
    required this.customData,
  });

  final String id;
  final String fortuneDate;
  final String customData;
}

class RewardedAdShowResult {
  const RewardedAdShowResult({
    required this.impressionRecorded,
    required this.rewardEarned,
    required this.dismissed,
  });

  final bool impressionRecorded;
  final bool rewardEarned;
  final bool dismissed;
}

abstract interface class RewardedAdService {
  String get rewardedUnitId;

  bool get usesNativeSdk;

  AdSecurityMode get securityMode;

  Future<void> preload();

  Future<AdAttempt> prepareAdSession({required String fortuneDate});

  Future<RewardedAdShowResult> show(AdAttempt attempt);

  Future<void> reportAdImpression(AdAttempt attempt);

  Future<void> claimAdReward(AdAttempt attempt);

  Future<void> reportAdDismissed(
    AdAttempt attempt, {
    String terminalReason = 'dismissed',
  });
}

class FakeRewardedAdService implements RewardedAdService {
  FakeRewardedAdService({
    required this.rewardedUnitId,
    required this.securityMode,
    this.nextResult = const RewardedAdShowResult(
      impressionRecorded: true,
      rewardEarned: true,
      dismissed: true,
    ),
  });

  @override
  final String rewardedUnitId;

  @override
  bool get usesNativeSdk => false;

  @override
  final AdSecurityMode securityMode;

  RewardedAdShowResult nextResult;
  final List<String> events = [];
  bool _isPreloaded = false;
  int _attemptNumber = 0;

  @override
  Future<void> preload() async {
    events.add('preload');
    _isPreloaded = true;
  }

  @override
  Future<AdAttempt> prepareAdSession({required String fortuneDate}) async {
    if (!_isPreloaded) {
      throw StateError('ad_not_preloaded');
    }
    _isPreloaded = false;
    final id = 'dev-ad-attempt-${++_attemptNumber}';
    final customData = 'dev-opaque-token-$id';
    events.add('prepare:$id');
    return AdAttempt(id: id, fortuneDate: fortuneDate, customData: customData);
  }

  @override
  Future<RewardedAdShowResult> show(AdAttempt attempt) async {
    events.add('show:${attempt.id}');
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    return nextResult;
  }

  @override
  Future<void> reportAdImpression(AdAttempt attempt) async {
    events.add('impression:${attempt.id}');
  }

  @override
  Future<void> claimAdReward(AdAttempt attempt) async {
    events.add('claim:${attempt.id}');
  }

  @override
  Future<void> reportAdDismissed(
    AdAttempt attempt, {
    String terminalReason = 'dismissed',
  }) async {
    events.add('$terminalReason:${attempt.id}');
  }
}
