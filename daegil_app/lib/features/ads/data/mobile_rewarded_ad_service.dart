import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/config/app_config.dart';
import '../domain/rewarded_ad_service.dart';
import 'rewarded_ad_gateway.dart';

/// Real Rewarded Ad implementation for Android and iOS.
///
/// Windows and web stay on [FakeRewardedAdService] because the Google Mobile
/// Ads Flutter plugin does not support desktop or web.
class MobileRewardedAdService implements RewardedAdService {
  MobileRewardedAdService({
    required this.rewardedUnitId,
    required this.securityMode,
    required RewardedAdGateway gateway,
  }) : _gateway = gateway;

  @override
  final String rewardedUnitId;
  @override
  final AdSecurityMode securityMode;
  final RewardedAdGateway _gateway;
  RewardedAd? _loadedAd;
  bool _sdkInitialized = false;

  @override
  bool get usesNativeSdk => true;

  @override
  Future<void> preload() async {
    if (_loadedAd != null) return;

    if (!_sdkInitialized) {
      await MobileAds.instance.initialize();
      _sdkInitialized = true;
    }

    final completer = Completer<void>();
    RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadedAd = ad;
          completer.complete();
        },
        onAdFailedToLoad: (_) {
          completer.completeError(StateError('ad_load_failed'));
        },
      ),
    );
    await completer.future;
  }

  @override
  Future<AdAttempt> prepareAdSession({required String fortuneDate}) async {
    if (_loadedAd == null) {
      throw StateError('ad_not_preloaded');
    }
    final attempt = await _gateway.prepare(fortuneDate: fortuneDate);
    final ad = _loadedAd!;
    await ad.setServerSideOptions(
      ServerSideVerificationOptions(customData: attempt.customData),
    );
    return attempt;
  }

  @override
  Future<RewardedAdShowResult> show(AdAttempt attempt) async {
    final ad = _loadedAd;
    if (ad == null) throw StateError('ad_not_preloaded');
    _loadedAd = null;

    var impressionRecorded = false;
    var rewardEarned = false;
    final completer = Completer<RewardedAdShowResult>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdImpression: (_) => impressionRecorded = true,
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(
            RewardedAdShowResult(
              impressionRecorded: impressionRecorded,
              rewardEarned: rewardEarned,
              dismissed: true,
            ),
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.completeError(StateError('ad_show_failed'));
        }
      },
    );
    ad.show(
      onUserEarnedReward: (ad, reward) {
        rewardEarned = true;
      },
    );
    return completer.future;
  }

  @override
  Future<void> reportAdImpression(AdAttempt attempt) =>
      _gateway.reportImpression(attempt);

  @override
  Future<void> claimAdReward(AdAttempt attempt) =>
      _gateway.claimReward(attempt);

  @override
  Future<void> reportAdDismissed(
    AdAttempt attempt, {
    String terminalReason = 'dismissed',
  }) => _gateway.reportDismissed(attempt, terminalReason: terminalReason);
}
