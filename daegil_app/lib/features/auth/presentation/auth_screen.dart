import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';
import '../../../shared/widgets/luna_page_frame.dart';
import 'auth_controller.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  static const _catBackground = Color(0xFFFFF3DC);

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
        color: _catBackground,
        child: LunaPageFrame(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Text(
                '오늘의 흐름을 읽어볼까냥?',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                height: 230,
                decoration: BoxDecoration(
                  color: _catBackground,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Image.asset(
                  'assets/images/daegil_cat_wave.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              const Text('안전한 이용을 위해 아래 내용을 확인해달라냥.'),
              const SizedBox(height: 24),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: state.age14PlusAttested,
                onChanged: state.isLoading
                    ? null
                    : (value) => ref
                          .read(authControllerProvider.notifier)
                          .setAgeAttestation(value ?? false),
                title: const Text('만 14세 이상입니다.'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: state.aiProcessingConsent,
                onChanged: state.isLoading
                    ? null
                    : (value) => ref
                          .read(authControllerProvider.notifier)
                          .setAiProcessingConsent(value ?? false),
                title: const Text('AI 개인화 처리에 동의합니다.'),
                subtitle: const Text('운세 생성을 위해 AI 처리를 이용합니다.'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: state.privacyUsageConsent,
                onChanged: state.isLoading
                    ? null
                    : (value) => ref
                          .read(authControllerProvider.notifier)
                          .setPrivacyUsageConsent(value ?? false),
                title: const Text('개인정보 활용에 동의합니다.'),
                subtitle: const Text('서비스 제공과 안전한 운영을 위해 이용합니다.'),
              ),
              for (final requirement in state.requirements.where(
                (item) =>
                    !item.title.contains('AI') && !item.title.contains('개인정보'),
              ))
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.pets_outlined),
                  value: state.acceptedDocumentIds.contains(requirement.id),
                  onChanged: state.isLoading
                      ? null
                      : (value) => ref
                            .read(authControllerProvider.notifier)
                            .toggleRequirement(requirement.id, value ?? false),
                  title: Text(requirement.title),
                  subtitle: requirement.required
                      ? const Text('필수')
                      : const Text('선택'),
                ),
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (state.isAuthPending)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Google 인증을 완료하면 앱으로 돌아온다냥.'),
                ),
              const SizedBox(height: 24),
              for (final provider in SocialProvider.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton(
                    onPressed:
                        state.canSignIn &&
                            !state.isLoading &&
                            !state.isAuthPending
                        ? () => ref
                              .read(authControllerProvider.notifier)
                              .signIn(provider)
                        : null,
                    child: Text('${_providerName(provider)}로 계속하기'),
                  ),
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
}
