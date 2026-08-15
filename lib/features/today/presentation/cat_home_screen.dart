import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../profile/presentation/birth_profile_controller.dart';

class CatHomeScreen extends ConsumerWidget {
  const CatHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBirthProfile = ref.watch(birthProfileProvider) != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 운세'),
        actions: [
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings_outlined),
              tooltip: '설정')
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const Align(
              alignment: Alignment.centerRight,
              child: Chip(
                  avatar: Icon(Icons.confirmation_num_outlined),
                  label: Text('광고 패스권 0 / 3'))),
          const SizedBox(height: 16),
          Card(
            child: SizedBox(
              height: 280,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets_outlined,
                      size: 80, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  const Text('고양이 영상을 준비하고 있다냥.'),
                  const SizedBox(height: 4),
                  Text('영상이 없어도 운세 이용에는 문제가 없다냥.',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => hasBirthProfile
                ? _showRewardPlaceholder(context)
                : context.go('/profile/setup'),
            child: const Text('알려주겠다냥! 🐾'),
          ),
        ],
      ),
    );
  }

  void _showRewardPlaceholder(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const Padding(
        padding: EdgeInsets.all(24),
        child: Text('광고를 완료하면 오늘의 운세를 확인할 수 있다냥.'),
      ),
    );
  }
}
