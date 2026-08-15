import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../profile/presentation/birth_profile_controller.dart';
import '../../../shared/widgets/cat_video.dart';

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
          const Card(
            child: SizedBox(
              height: 280,
              child: CatVideo(),
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
