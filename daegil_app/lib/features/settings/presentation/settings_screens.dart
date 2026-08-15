import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('프로필'),
            onTap: () => context.go('/settings/profile'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_none),
            title: const Text('알림'),
            onTap: () => context.go('/settings/notification'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('개인정보 및 동의'),
            onTap: () => context.go('/settings/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined),
            title: const Text('계정'),
            onTap: () => context.go('/settings/account'),
          ),
        ],
      ),
    );
  }
}

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('개인정보 및 동의')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('동의 상태는 서버 기준으로 관리되며, 철회하면 새 AI 운세·광고·패스를 사용할 수 없다냥.'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('앱 개선과 오류 분석 허용'),
            value: state.analyticsEnabled,
            onChanged: (value) => ref
                .read(settingsControllerProvider.notifier)
                .setAnalyticsEnabled(value),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: state.aiPersonalizationAllowed
                ? () => _withdraw(context, ref)
                : null,
            child: const Text('AI 개인화 동의 철회'),
          ),
        ],
      ),
    );
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    await ref.read(settingsControllerProvider.notifier).withdrawAiConsent();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI 개인화 동의를 철회했다냥.')));
    }
  }
}

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('계정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ElevatedButton(
            onPressed: () async {
              await ref.read(settingsControllerProvider.notifier).logout();
              if (context.mounted) context.go('/auth');
            },
            child: const Text('로그아웃'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/settings/account/delete'),
            child: const Text('계정 삭제'),
          ),
        ],
      ),
    );
  }
}

class AccountDeletionScreen extends ConsumerWidget {
  const AccountDeletionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('계정 삭제')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('계정을 삭제하면 프로필과 관련 데이터가 복구되지 않는다냥.'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(settingsControllerProvider.notifier)
                    .deleteAccount();
                if (context.mounted) context.go('/auth');
              },
              child: const Text('계정 삭제 확정'),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: const Center(child: Text('이 설정은 다음 연결 단계에서 준비된다냥.')),
  );
}
