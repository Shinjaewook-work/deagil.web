import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';
import '../../../app/theme/luna_theme.dart';
import '../../../shared/widgets/luna_card.dart';
import '../../../shared/widgets/luna_page_frame.dart';
import '../../../shared/widgets/luna_primary_button.dart';
import '../../../shared/widgets/paper_blend_image.dart';
import 'auth_controller.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (previous, next) {
      if (next.isAuthenticated && previous?.isAuthenticated != true) {
        context.go('/today');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('대길')),
      body: ColoredBox(
        color: LunaColors.paper,
        child: LunaPageFrame(
          child: ListView(
            cacheExtent: 1200,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              const Center(child: _WelcomePill()),
              const SizedBox(height: 12),
              Text(
                '오늘의 흐름을 읽어볼까냥?',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ColoredBox(
                color: LunaColors.imageCanvas,
                child: SizedBox(
                  height: 230,
                  child: const PaperBlendImage(
                    assetName: 'assets/images/daegil_cat_wave.png',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const LunaCard(
                color: LunaColors.cream,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: LunaColors.seal),
                    SizedBox(width: 10),
                    Expanded(child: Text('안전한 이용을 위해 아래 내용을 확인해달라냥.')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ConsentTile(
                color: LunaColors.butter,
                value: state.age14PlusAttested,
                onChanged: state.isLoading
                    ? null
                    : (value) => ref
                          .read(authControllerProvider.notifier)
                          .setAgeAttestation(value ?? false),
                title: '만 14세 이상입니다.',
                subtitle: '안전한 서비스 이용을 위한 필수 확인이다냥.',
              ),
              _ConsentTile(
                color: LunaColors.peachSoft,
                value: state.aiProcessingConsent,
                onChanged: state.isLoading
                    ? null
                    : (value) => ref
                          .read(authControllerProvider.notifier)
                          .setAiProcessingConsent(value ?? false),
                title: 'AI 개인화 처리에 동의합니다.',
                subtitle: '운세 생성을 위해 AI 처리를 이용합니다.',
              ),
              _ConsentTile(
                color: LunaColors.jadeSoft,
                value: state.privacyUsageConsent,
                onChanged: state.isLoading
                    ? null
                    : (value) => ref
                          .read(authControllerProvider.notifier)
                          .setPrivacyUsageConsent(value ?? false),
                title: '개인정보 활용에 동의합니다.',
                subtitle: '서비스 제공과 안전한 운영을 위해 이용합니다.',
              ),
              for (final requirement in state.requirements.where(
                (item) =>
                    item.documentType != 'ai_processing' &&
                    item.documentType != 'privacy',
              ))
                _ConsentTile(
                  color: requirement.required
                      ? LunaColors.blush
                      : LunaColors.peachSoft,
                  value: state.acceptedDocumentIds.contains(requirement.id),
                  onChanged: state.isLoading
                      ? null
                      : (value) => ref
                            .read(authControllerProvider.notifier)
                            .toggleRequirement(requirement.id, value ?? false),
                  title: requirement.title,
                  subtitle: requirement.required ? '필수' : '선택',
                ),
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _errorMessage(state.errorMessage!),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (state.errorMessage == 'REGISTRATION_REQUIREMENTS_LOAD_FAILED')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton(
                    onPressed: state.isLoading
                        ? null
                        : () => ref
                              .read(authControllerProvider.notifier)
                              .retryRequirements(),
                    child: const Text('동의 내용 다시 불러오기'),
                  ),
                ),
              if (state.isAuthPending)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Google 인증을 완료하면 앱으로 돌아온다냥.'),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          decoration: const BoxDecoration(
            color: LunaColors.cream,
            border: Border(top: BorderSide(color: LunaColors.subtleBorder)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final provider in SocialProvider.values)
                LunaPrimaryButton(
                  onPressed:
                      state.canSignIn &&
                          !state.isLoading &&
                          !state.isAuthPending
                      ? () => ref
                            .read(authControllerProvider.notifier)
                            .signIn(provider)
                      : null,
                  label: state.hasAuthenticatedSession
                      ? '동의 완료하고 시작하기'
                      : '${_providerName(provider)}로 계속하기',
                  icon: Icons.login_rounded,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _providerName(SocialProvider provider) => switch (provider) {
    SocialProvider.google => 'Google',
  };

  String _errorMessage(String code) => switch (code) {
    'REGISTRATION_CONFIRMATION_REQUIRED' =>
      'Google 연결을 확인했다냥. 동의 항목을 다시 확인하고 시작 버튼을 눌러달라냥.',
    'REGISTRATION_SYNC_FAILED' => '회원정보를 저장하지 못했다냥. 잠시 후 다시 눌러달라냥.',
    'REGISTRATION_REQUIREMENTS_LOAD_FAILED' =>
      '필수 동의 내용을 불러오지 못했다냥. 네트워크를 확인하고 다시 불러와달라냥.',
    'AUTH_PROVIDER_FAILED' => 'Google 로그인을 완료하지 못했다냥. 다시 시도해달라냥.',
    'REGISTRATION_REQUIREMENTS_INCOMPLETE' => '필수 동의 항목을 모두 확인해달라냥.',
    _ => '로그인을 완료하지 못했다냥. 잠시 후 다시 시도해달라냥.',
  };
}

class _WelcomePill extends StatelessWidget {
  const _WelcomePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: LunaColors.jadeSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LunaColors.subtleBorder),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pets_rounded, size: 17, color: LunaColors.seal),
          SizedBox(width: 7),
          Text('한복 고양이 운세방', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.color,
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        color: LunaColors.cream,
        child: CheckboxListTile(
          contentPadding: const EdgeInsets.fromLTRB(12, 4, 10, 4),
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const Icon(
              Icons.pets_rounded,
              size: 19,
              color: LunaColors.seal,
            ),
          ),
          value: value,
          onChanged: onChanged,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(subtitle),
        ),
      ),
    );
  }
}
