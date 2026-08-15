import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/fortune_result.dart';

enum FortuneAccessState {
  loading,
  locked,
  generating,
  recoveryPending,
  failed,
  unlocked,
}

class FortuneAppState {
  const FortuneAppState({
    required this.access,
    this.result,
    this.availablePassCount = 0,
    this.activePassCount = 0,
    this.canUsePass = false,
    this.canPrepareRewardedAd = false,
    this.nextRetryAt,
  });

  final FortuneAccessState access;
  final FortuneResult? result;
  final int availablePassCount;
  final int activePassCount;
  final bool canUsePass;
  final bool canPrepareRewardedAd;
  final DateTime? nextRetryAt;

  factory FortuneAppState.fromJson(Map<String, dynamic> json) {
    final state = json['fortune_state'] as String? ?? 'LOCKED';
    final resultJson = json['fortune_payload'];
    final resultPayload = resultJson is Map
        ? <String, dynamic>{
            ...Map<String, dynamic>.from(resultJson),
            'fortune_date': json['fortune_date'],
          }
        : null;
    return FortuneAppState(
      access: switch (state) {
        'UNLOCKED' => FortuneAccessState.unlocked,
        'GENERATING' => FortuneAccessState.generating,
        'RECOVERY_PENDING' => FortuneAccessState.recoveryPending,
        'FAILED' => FortuneAccessState.failed,
        _ => FortuneAccessState.locked,
      },
      result: state == 'UNLOCKED' && resultPayload != null
          ? FortuneResult.fromBackendJson(resultPayload)
          : null,
      availablePassCount: (json['available_pass_count'] as num?)?.toInt() ?? 0,
      activePassCount: (json['active_pass_count'] as num?)?.toInt() ?? 0,
      canUsePass: json['can_use_pass'] == true,
      canPrepareRewardedAd: json['can_prepare_rewarded_ad'] == true,
      nextRetryAt: DateTime.tryParse(json['next_retry_at'] as String? ?? ''),
    );
  }
}

abstract interface class FortuneRepository {
  Future<FortuneAppState> loadAppState();
  Future<FortuneAppState> useFortunePass();
}

class SupabaseFortuneRepository implements FortuneRepository {
  SupabaseFortuneRepository({required SupabaseClient client})
    : _client = client;
  final SupabaseClient _client;

  @override
  Future<FortuneAppState> loadAppState() async {
    final response = await _client.rpc('get_my_app_state');
    return FortuneAppState.fromJson(Map<String, dynamic>.from(response as Map));
  }

  @override
  Future<FortuneAppState> useFortunePass() async {
    final response = await _client.functions.invoke(
      'use-fortune-pass',
      body: const <String, dynamic>{},
    );
    if (response.status >= 400) {
      throw StateError('USE_FORTUNE_PASS_FAILED');
    }
    return loadAppState();
  }
}

class FakeFortuneRepository implements FortuneRepository {
  @override
  Future<FortuneAppState> loadAppState() async => FortuneAppState(
    access: FortuneAccessState.unlocked,
    result: MockFortuneResult(),
  );

  @override
  Future<FortuneAppState> useFortunePass() => loadAppState();
}

final fortuneRepositoryProvider = Provider<FortuneRepository>(
  (ref) => FakeFortuneRepository(),
);

final fortuneAppStateProvider = FutureProvider.autoDispose<FortuneAppState>(
  (ref) => ref.read(fortuneRepositoryProvider).loadAppState(),
);
