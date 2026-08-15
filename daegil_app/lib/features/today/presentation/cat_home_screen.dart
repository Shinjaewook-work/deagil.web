import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ads/domain/rewarded_ad_service.dart';
import '../../ads/presentation/rewarded_ad_controller.dart';
import '../../profile/presentation/birth_profile_controller.dart';
import '../../../shared/widgets/cat_video.dart';

class CatHomeScreen extends ConsumerWidget {
  const CatHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBirthProfile = ref.watch(birthProfileProvider) != null;
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
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
            tooltip: '설정',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: Chip(
              avatar: Icon(Icons.confirmation_num_outlined),
              label: Text('광고 패스권 0 / 3'),
            ),
          ),
          const SizedBox(height: 16),
          const Card(child: SizedBox(height: 280, child: CatVideo())),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isBusy
                ? null
                : () => hasBirthProfile
                      ? ref
                            .read(rewardedAdControllerProvider.notifier)
                            .start(fortuneDate: _todayFortuneDate())
                      : context.go('/profile/setup'),
            child: Text(_ctaLabel(adState.status)),
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
