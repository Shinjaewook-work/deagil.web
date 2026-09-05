import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../fortune/data/fortune_repository.dart';
import '../data/mobile_rewarded_ad_service.dart';
import '../data/rewarded_ad_gateway.dart';
import '../domain/rewarded_ad_service.dart';

final rewardedAdGatewayProvider = Provider<RewardedAdGateway>((ref) {
  return FakeRewardedAdGateway();
});

final rewardedAdServiceProvider = Provider<RewardedAdService>((ref) {
  final config = AppConfig.fromEnvironment();
  final isMobile =
      !const bool.fromEnvironment('dart.library.html') &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (isMobile) {
    return MobileRewardedAdService(
      rewardedUnitId: config.admobRewardedUnitId.isEmpty
          ? (defaultTargetPlatform == TargetPlatform.android
                ? 'ca-app-pub-2364733930147091/2018144858'
                : 'ca-app-pub-3940256099942544/1712485313')
          : config.admobRewardedUnitId,
      securityMode: config.adSecurityMode,
      gateway: ref.watch(rewardedAdGatewayProvider),
    );
  }
  return FakeRewardedAdService(
    rewardedUnitId: 'ca-app-pub-3940256099942544/5224354917',
    securityMode: AdSecurityMode.fast,
  );
});

final rewardedAdControllerProvider =
    NotifierProvider<RewardedAdController, RewardedAdFlowState>(
      RewardedAdController.new,
    );

final rewardVerificationPollIntervalProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 2);
});

class RewardedAdFlowState {
  const RewardedAdFlowState({
    this.status = RewardedAdFlowStatus.idle,
    this.attempt,
    this.errorCode,
  });

  final RewardedAdFlowStatus status;
  final AdAttempt? attempt;
  final String? errorCode;

  RewardedAdFlowState copyWith({
    RewardedAdFlowStatus? status,
    AdAttempt? attempt,
    String? errorCode,
    bool clearAttempt = false,
    bool clearError = false,
  }) {
    return RewardedAdFlowState(
      status: status ?? this.status,
      attempt: clearAttempt ? null : attempt ?? this.attempt,
      errorCode: clearError ? null : errorCode ?? this.errorCode,
    );
  }
}

class RewardedAdController extends Notifier<RewardedAdFlowState> {
  bool _startInProgress = false;

  @override
  RewardedAdFlowState build() => const RewardedAdFlowState();

  Future<void> preload() async {
    if (state.status == RewardedAdFlowStatus.loading ||
        state.status == RewardedAdFlowStatus.ready) {
      return;
    }
    state = const RewardedAdFlowState(status: RewardedAdFlowStatus.loading);
    try {
      await ref.read(rewardedAdServiceProvider).preload();
      state = const RewardedAdFlowState(status: RewardedAdFlowStatus.ready);
    } on StateError catch (error) {
      state = RewardedAdFlowState(
        status: RewardedAdFlowStatus.failed,
        errorCode: error.message,
      );
    }
  }

  Future<void> start({required String fortuneDate}) async {
    if (_startInProgress ||
        state.status == RewardedAdFlowStatus.rewardVerifying ||
        state.status == RewardedAdFlowStatus.pendingReward) {
      return;
    }
    _startInProgress = true;
    final service = ref.read(rewardedAdServiceProvider);
    AdAttempt? activeAttempt;
    try {
      if (state.status != RewardedAdFlowStatus.ready) {
        await preload();
      }
      if (state.status != RewardedAdFlowStatus.ready) return;
      state = state.copyWith(status: RewardedAdFlowStatus.loading);
      final attempt = await service.prepareAdSession(fortuneDate: fortuneDate);
      activeAttempt = attempt;
      state = state.copyWith(
        status: RewardedAdFlowStatus.showing,
        attempt: attempt,
        clearError: true,
      );

      final result = await service.show(attempt);
      if (result.impressionRecorded) {
        await service.reportAdImpression(attempt);
      }
      if (result.rewardEarned) {
        await service.claimAdReward(attempt);
        if (service.securityMode == AdSecurityMode.ssvStrict) {
          state = state.copyWith(status: RewardedAdFlowStatus.rewardVerifying);
          await _waitForVerifiedReward();
        } else {
          state = state.copyWith(status: RewardedAdFlowStatus.completed);
        }
      } else if (result.dismissed) {
        state = state.copyWith(status: RewardedAdFlowStatus.dismissed);
      }
      if (result.dismissed) {
        await service.reportAdDismissed(attempt);
      }
    } on StateError catch (error) {
      if (activeAttempt != null) {
        try {
          await service.reportAdDismissed(
            activeAttempt,
            terminalReason: 'show_failed',
          );
        } on StateError {
          // The original ad failure remains the user-facing error.
        }
      }
      state = RewardedAdFlowState(
        status: RewardedAdFlowStatus.failed,
        errorCode: error.message,
      );
    } finally {
      _startInProgress = false;
    }
  }

  Future<void> _waitForVerifiedReward() async {
    for (var attempt = 0; attempt < 15; attempt++) {
      await Future<void>.delayed(
        ref.read(rewardVerificationPollIntervalProvider),
      );
      try {
        final appState = await ref
            .read(fortuneRepositoryProvider)
            .loadAppState();
        if (appState.access == FortuneAccessState.unlocked) {
          ref.invalidate(fortuneAppStateProvider);
          state = state.copyWith(status: RewardedAdFlowStatus.completed);
          return;
        }
      } on StateError {
        // A transient poll failure is retried within the bounded window.
      } on PostgrestException {
        // A transient Supabase failure is retried within the bounded window.
      }
    }
    state = state.copyWith(status: RewardedAdFlowStatus.pendingReward);
  }

  void markRewardPending() {
    if (state.attempt != null && state.status == RewardedAdFlowStatus.showing) {
      state = state.copyWith(status: RewardedAdFlowStatus.pendingReward);
    }
  }

  Future<void> retryPendingReward() async {
    final attempt = state.attempt;
    if (attempt == null || state.status != RewardedAdFlowStatus.pendingReward) {
      return;
    }
    await ref.read(rewardedAdServiceProvider).claimAdReward(attempt);
    state = state.copyWith(status: RewardedAdFlowStatus.completed);
  }
}
