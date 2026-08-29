import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'settings_controller.dart';
import '../../notifications/presentation/notification_controller.dart';
import '../../../app/theme/luna_theme.dart';
import '../../../shared/widgets/luna_page_frame.dart';
import '../../../shared/widgets/cat_page_banner.dart';
import '../../../shared/widgets/luna_primary_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: LunaPageFrame(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const CatPageBanner(
              assetName: 'assets/images/daegil_cat_stretch.png',
              title: '편안하게 정리해보자냥',
              message: '프로필과 알림, 동의 상태를 여기서 돌볼 수 있다냥.',
            ),
            const SizedBox(height: 16),
            _SettingsTile(
              icon: Icons.person_outline,
              color: LunaColors.peachSoft,
              title: '프로필',
              subtitle: '출생정보를 확인하고 고친다냥',
              onTap: () => context.go('/settings/profile'),
            ),
            _SettingsTile(
              icon: Icons.notifications_none,
              color: LunaColors.butter,
              title: '알림',
              subtitle: '운세를 잡아올 시간을 정한다냥',
              onTap: () => context.go('/settings/notification'),
            ),
            _SettingsTile(
              icon: Icons.lock_outline,
              color: LunaColors.jadeSoft,
              title: '개인정보 및 동의',
              subtitle: '내 동의 상태를 안전하게 관리한다냥',
              onTap: () => context.go('/settings/privacy'),
            ),
            _SettingsTile(
              icon: Icons.manage_accounts_outlined,
              color: LunaColors.blush,
              title: '계정',
              subtitle: '로그아웃과 계정 관리를 한다냥',
              onTap: () => context.go('/settings/account'),
            ),
          ],
        ),
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
      body: LunaPageFrame(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const CatPageBanner(
              assetName: 'assets/images/daegil_cat_butterfly.png',
              title: '내 정보는 소중하다냥',
              message: '동의 상태는 서버에서 안전하게 관리한다냥.',
            ),
            const SizedBox(height: 16),
            Card(
              color: LunaColors.cream,
              child: SwitchListTile(
                secondary: const CircleAvatar(
                  backgroundColor: LunaColors.cream,
                  child: Icon(
                    Icons.query_stats_rounded,
                    color: LunaColors.seal,
                  ),
                ),
                title: const Text('앱 개선과 오류 분석 허용'),
                subtitle: const Text('선택 동의이며 언제든 바꿀 수 있다냥.'),
                value: state.analyticsEnabled,
                onChanged: (value) => ref
                    .read(settingsControllerProvider.notifier)
                    .setAnalyticsEnabled(value),
              ),
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
      body: LunaPageFrame(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const CatPageBanner(
              assetName: 'assets/images/daegil_cat_yawn.png',
              title: '잠깐 쉬어가도 괜찮다냥',
              message: '로그아웃해도 저장된 정보는 그대로 남아 있다냥.',
            ),
            const SizedBox(height: 20),
            LunaPrimaryButton(
              onPressed: () async {
                await ref.read(settingsControllerProvider.notifier).logout();
                if (context.mounted) context.go('/auth');
              },
              label: '로그아웃',
              icon: Icons.logout_rounded,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/settings/account/delete'),
              child: const Text('계정 삭제'),
            ),
          ],
        ),
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
      body: LunaPageFrame(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const CatPageBanner(
              assetName: 'assets/images/daegil_cat_mascot.png',
              title: '정말 떠나려는 거냥?',
              message: '계정을 삭제하면 프로필과 관련 데이터는 복구되지 않는다냥.',
              imageHeight: 180,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                await ref
                    .read(settingsControllerProvider.notifier)
                    .deleteAccount();
                if (context.mounted) context.go('/auth');
              },
              icon: const Icon(Icons.heart_broken_rounded),
              label: const Text('계정 삭제 확정'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: LunaColors.danger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
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

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool enabled = false;
  TimeOfDay time = const TimeOfDay(hour: 8, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: LunaPageFrame(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const CatPageBanner(
              assetName: 'assets/images/daegil_cat_wave.png',
              title: '시간 맞춰 깨워주겠다냥',
              message: '오늘의 운세 알림은 기기 권한과 서버 설정을 함께 사용한다냥.',
            ),
            const SizedBox(height: 16),
            Card(
              color: LunaColors.cream,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const CircleAvatar(
                      backgroundColor: LunaColors.cream,
                      child: Icon(
                        Icons.notifications_active_rounded,
                        color: LunaColors.seal,
                      ),
                    ),
                    title: const Text('매일 운세 알림'),
                    value: enabled,
                    onChanged: (value) => _save(value, time),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    enabled: enabled,
                    title: const Text('알림 시간'),
                    trailing: Text(time.format(context)),
                    onTap: enabled ? _pickTime : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: time);
    if (picked != null) await _save(enabled, picked);
  }

  Future<void> _save(bool nextEnabled, TimeOfDay nextTime) async {
    final now = DateTime.now();
    await ref
        .read(notificationControllerProvider.notifier)
        .setEnabled(
          enabled: nextEnabled,
          time: DateTime(
            now.year,
            now.month,
            now.day,
            nextTime.hour,
            nextTime.minute,
          ),
        );
    if (!mounted) return;
    setState(() {
      enabled = nextEnabled;
      time = nextTime;
    });
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        minTileHeight: 72,
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: LunaColors.seal),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
