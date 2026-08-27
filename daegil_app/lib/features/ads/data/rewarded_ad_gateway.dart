import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/rewarded_ad_service.dart';

abstract interface class RewardedAdBackend {
  Future<Map<String, dynamic>> invoke(
    String functionName,
    Map<String, dynamic> body,
  );
}

class SupabaseRewardedAdBackend implements RewardedAdBackend {
  SupabaseRewardedAdBackend({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> invoke(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.functions.invoke(functionName, body: body);
    if (response.status >= 400 || response.data is! Map) {
      throw StateError('AD_SERVER_REQUEST_FAILED');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }
}

abstract interface class RewardedAdGateway {
  Future<AdAttempt> prepare({required String fortuneDate});
  Future<void> reportImpression(AdAttempt attempt);
  Future<void> claimReward(AdAttempt attempt);
  Future<void> reportDismissed(
    AdAttempt attempt, {
    required String terminalReason,
  });
}

class SupabaseRewardedAdGateway implements RewardedAdGateway {
  SupabaseRewardedAdGateway({
    required RewardedAdBackend backend,
    required this.platform,
  }) : _backend = backend;

  final RewardedAdBackend _backend;
  final String platform;
  final Random _secureRandom = Random.secure();

  @override
  Future<AdAttempt> prepare({required String fortuneDate}) async {
    final payload = await _backend.invoke('prepare-ad-session', {
      'prepare_request_id': _newUuid(),
      'platform': platform,
    });
    final id = payload['ad_attempt_id'];
    final serverFortuneDate = payload['fortune_date'];
    final customData = payload['custom_data'];
    if (id is! String ||
        serverFortuneDate is! String ||
        customData is! String) {
      throw StateError('INVALID_AD_SERVER_RESPONSE');
    }
    if (serverFortuneDate != fortuneDate) {
      throw StateError('FORTUNE_DATE_MISMATCH');
    }
    return AdAttempt(
      id: id,
      fortuneDate: serverFortuneDate,
      customData: customData,
    );
  }

  @override
  Future<void> reportImpression(AdAttempt attempt) async {
    await _backend.invoke('report-ad-impression', {
      'ad_attempt_id': attempt.id,
    });
  }

  @override
  Future<void> claimReward(AdAttempt attempt) async {
    await _backend.invoke('claim-ad-reward', {'ad_attempt_id': attempt.id});
  }

  @override
  Future<void> reportDismissed(
    AdAttempt attempt, {
    required String terminalReason,
  }) async {
    await _backend.invoke('report-ad-dismissed', {
      'ad_attempt_id': attempt.id,
      'terminal_reason': terminalReason,
    });
  }

  String _newUuid() {
    final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

class FakeRewardedAdGateway implements RewardedAdGateway {
  int _attemptNumber = 0;

  @override
  Future<AdAttempt> prepare({required String fortuneDate}) async {
    final id = 'local-ad-attempt-${++_attemptNumber}';
    return AdAttempt(
      id: id,
      fortuneDate: fortuneDate,
      customData: 'local-opaque-token-$id',
    );
  }

  @override
  Future<void> reportImpression(AdAttempt attempt) async {}

  @override
  Future<void> claimReward(AdAttempt attempt) async {}

  @override
  Future<void> reportDismissed(
    AdAttempt attempt, {
    required String terminalReason,
  }) async {}
}
