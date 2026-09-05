import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ads/domain/rewarded_ad_service.dart';
import '../../ads/presentation/rewarded_ad_controller.dart';
import '../../fortune/data/fortune_repository.dart';
import '../../profile/presentation/birth_profile_controller.dart';
import '../../../app/theme/luna_theme.dart';
import '../../../shared/widgets/cat_video.dart';
import '../../../shared/widgets/luna_card.dart';
import '../../../shared/widgets/luna_page_frame.dart';
import '../../../shared/widgets/luna_primary_button.dart';

class CatHomeScreen extends ConsumerStatefulWidget {
  const CatHomeScreen({super.key});

  @override
  ConsumerState<CatHomeScreen> createState() => _CatHomeScreenState();
}

class _CatHomeScreenState extends ConsumerState<CatHomeScreen> {
  bool _choiceInProgress = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(rewardedAdControllerProvider, (previous, next) {
      if (next.status == RewardedAdFlowStatus.showing &&
          previous?.status != RewardedAdFlowStatus.showing &&
          !ref.read(rewardedAdServiceProvider).usesNativeSdk) {
        _showFakeRewardedAd(context);
      }
      if (next.status == RewardedAdFlowStatus.completed &&
          previous?.status != RewardedAdFlowStatus.completed) {
        context.go('/fortune/result');
      }
    });
    final localBirthProfileExists = ref.watch(birthProfileProvider) != null;
    final appState = ref.watch(fortuneAppStateProvider);
    final currentAppState = appState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final hasBirthProfile =
        localBirthProfileExists ||
        (currentAppState?.birthProfileExists ?? false);
    final adState = ref.watch(rewardedAdControllerProvider);
    final isBusy = {
      RewardedAdFlowStatus.loading,
      RewardedAdFlowStatus.showing,
      RewardedAdFlowStatus.rewardVerifying,
    }.contains(adState.status);
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 운세'),
        actions: [
          IconButton(
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: '설정',
          ),
        ],
      ),
      body: LunaPageFrame(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: LunaColors.jadeSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: LunaColors.subtleBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.confirmation_num_rounded,
                      size: 18,
                      color: LunaColors.seal,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        appState.maybeWhen(
                          data: (value) =>
                              '광고 패스권 ${value.activePassCount} / 3',
                          orElse: () => '광고 패스권 확인 중',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '오늘은 어떤 운을 잡아올까냥?',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Card(
              color: LunaColors.imageCanvas,
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(
                  children: [
                    const ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      child: ColoredBox(
                        color: LunaColors.imageCanvas,
                        child: SizedBox(height: 272, child: CatVideo()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '오늘의 작은 힌트를\n대길이 찾아주겠다냥.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const LunaCard(
              color: LunaColors.cream,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: LunaColors.cream,
                    child: Icon(
                      Icons.volunteer_activism_rounded,
                      color: LunaColors.seal,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('광고 수익 일부를 고양이 보호 활동에 보탠다냥.', softWrap: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            LunaPrimaryButton(
              onPressed: isBusy || _choiceInProgress || currentAppState == null
                  ? null
                  : () async {
                      setState(() => _choiceInProgress = true);
                      try {
                        if (!hasBirthProfile) {
                          context.go('/profile/setup');
                          return;
                        }
                        final choice =
                            await showModalBottomSheet<_FortuneChoice>(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              backgroundColor: LunaColors.paperRaised,
                              builder: (_) => _FortuneChoiceSheet(
                                canUsePass: currentAppState.canUsePass,
                                canWatchAd:
                                    currentAppState.canPrepareRewardedAd,
                                availablePassCount:
                                    currentAppState.availablePassCount,
                              ),
                            );
                        if (!context.mounted || choice == null) return;
                        if (choice == _FortuneChoice.pass) {
                          await ref
                              .read(fortuneRepositoryProvider)
                              .useFortunePass();
                          if (!mounted) return;
                          ref.invalidate(fortuneAppStateProvider);
                          if (context.mounted) context.go('/fortune/result');
                        } else if (choice == _FortuneChoice.ad) {
                          await ref
                              .read(rewardedAdControllerProvider.notifier)
                              .start(fortuneDate: _todayFortuneDate());
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('연결을 확인하고 다시 시도해달라냥.'),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _choiceInProgress = false);
                      }
                    },
              label: _ctaLabel(adState.status),
              icon: Icons.pets_rounded,
            ),
            if (adState.status == RewardedAdFlowStatus.failed) ...[
              const SizedBox(height: 12),
              Text(
                '광고를 준비하지 못했어요. 잠시 후 다시 시도해달라냥.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _ctaLabel(RewardedAdFlowStatus status) => switch (status) {
    RewardedAdFlowStatus.loading => '광고를 준비하는 중이다냥…',
    RewardedAdFlowStatus.showing => '광고가 진행 중이다냥…',
    RewardedAdFlowStatus.rewardVerifying => '보상을 확인하는 중이다냥…',
    RewardedAdFlowStatus.completed => '오늘의 운세를 준비했다냥!',
    _ => '오늘의 운세 알려달라냥!',
  };

  void _showFakeRewardedAd(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('광고를 보는 중이다냥'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('광고 수익 일부가 고양이 보호 활동에 보탬이 된다냥.'),
          ],
        ),
      ),
    );
  }

  String _todayFortuneDate() {
    final now = DateTime.now();
    final fortuneDate = now.subtract(const Duration(hours: 4));
    final month = fortuneDate.month.toString().padLeft(2, '0');
    final day = fortuneDate.day.toString().padLeft(2, '0');
    return '${fortuneDate.year}-$month-$day';
  }
}

enum _FortuneChoice { pass, ad }

class _FortuneChoiceSheet extends StatelessWidget {
  const _FortuneChoiceSheet({
    required this.canUsePass,
    required this.canWatchAd,
    required this.availablePassCount,
  });

  final bool canUsePass;
  final bool canWatchAd;
  final int availablePassCount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '오늘의 AI 운세를 알려줄까냥?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              '광고를 끝까지 보거나 패스권 1장을 사용하면\n오늘의 운세를 확인할 수 있다냥.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const LunaCard(
              padding: EdgeInsets.all(14),
              child: Text(
                '운세 생성이 잠시 늦어져도\n추가 광고 없이 다시 준비해주겠다냥.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            if (canUsePass) ...[
              LunaPrimaryButton(
                label: '패스권 1장 쓰겠다냥! ($availablePassCount장 보유)',
                icon: Icons.confirmation_num_rounded,
                onPressed: () => Navigator.pop(context, _FortuneChoice.pass),
              ),
              const SizedBox(height: 10),
            ],
            if (canWatchAd)
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, _FortuneChoice.ad),
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('광고 보고 알려달라냥!'),
              ),
            if (!canWatchAd && !canUsePass)
              const Text(
                '지금은 운세 준비 상태를 확인하고 있다냥. 잠시 후 다시 시도해달라냥.',
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('다음에 볼래냥'),
            ),
          ],
        ),
      ),
    );
  }
}
