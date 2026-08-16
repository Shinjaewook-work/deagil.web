import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ads/domain/rewarded_ad_service.dart';
import '../../ads/presentation/rewarded_ad_controller.dart';
import '../../fortune/data/fortune_repository.dart';
import '../../profile/presentation/birth_profile_controller.dart';
import '../../../shared/widgets/cat_video.dart';
import '../../../shared/widgets/luna_page_frame.dart';

class CatHomeScreen extends ConsumerWidget {
  const CatHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(rewardedAdControllerProvider, (previous, next) {
      if (next.status == RewardedAdFlowStatus.completed &&
          previous?.status != RewardedAdFlowStatus.completed) {
        context.go('/fortune/result');
      }
    });
    final hasBirthProfile = ref.watch(birthProfileProvider) != null;
    final appState = ref.watch(fortuneAppStateProvider);
    final currentAppState = appState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
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
              child: Chip(
                avatar: Icon(Icons.confirmation_num_outlined),
                label: Text(
                  appState.maybeWhen(
                    data: (value) => '광고 패스권 ${value.activePassCount} / 3',
                    orElse: () => '광고 패스권 확인 중',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: const Card(
                child: SizedBox(height: 280, child: CatVideo()),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.volunteer_activism_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('광고 수익 일부를 고양이 보호 활동에 보탠다냥.', softWrap: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isBusy
                  ? null
                  : () async {
                      if (!hasBirthProfile) {
                        context.go('/profile/setup');
                      } else if (currentAppState?.canUsePass == true) {
                        await ref
                            .read(fortuneRepositoryProvider)
                            .useFortunePass();
                        ref.invalidate(fortuneAppStateProvider);
                        if (context.mounted) context.go('/fortune/result');
                      } else {
                        await ref
                            .read(rewardedAdControllerProvider.notifier)
                            .start(fortuneDate: _todayFortuneDate());
                      }
                    },
              child: Text(
                currentAppState?.canUsePass == true
                    ? '패스권으로 열기냥!'
                    : _ctaLabel(adState.status),
              ),
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
    _ => '알려주겠다냥! 🐾',
  };

  String _todayFortuneDate() {
    final now = DateTime.now();
    final fortuneDate = now.subtract(const Duration(hours: 4));
    final month = fortuneDate.month.toString().padLeft(2, '0');
    final day = fortuneDate.day.toString().padLeft(2, '0');
    return '${fortuneDate.year}-$month-$day';
  }
}
