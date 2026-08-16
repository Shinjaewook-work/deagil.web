import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../data/mobile_rewarded_ad_service.dart';
import '../domain/rewarded_ad_service.dart';

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
    final service = ref.read(rewardedAdServiceProvider);
    try {
      if (state.status != RewardedAdFlowStatus.ready) {
        await preload();
      }
      state = state.copyWith(status: RewardedAdFlowStatus.loading);
      final attempt = await service.prepareAdSession(fortuneDate: fortuneDate);
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
        if (service.securityMode == AdSecurityMode.ssvStrict) {
          state = state.copyWith(status: RewardedAdFlowStatus.rewardVerifying);
        } else {
          await service.claimAdReward(attempt);
          state = state.copyWith(status: RewardedAdFlowStatus.completed);
        }
      } else if (result.dismissed) {
        state = state.copyWith(status: RewardedAdFlowStatus.dismissed);
      }
      if (result.dismissed) {
        await service.reportAdDismissed(attempt);
      }
    } on StateError catch (error) {
      state = RewardedAdFlowState(
        status: RewardedAdFlowStatus.failed,
        errorCode: error.message,
      );
    }
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
