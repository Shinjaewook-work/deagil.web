import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';
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

    if (state.isLoading && state.requirements.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Luna')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '오늘의 흐름을 읽어볼까냥?',
            style: Theme.of(context).textTheme.displaySmall,
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
          for (final requirement in state.requirements)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
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
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          for (final provider in SocialProvider.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: state.canSignIn && !state.isLoading
                    ? () => ref
                          .read(authControllerProvider.notifier)
                          .signIn(provider)
                    : null,
                child: Text('${_providerName(provider)}로 계속하기'),
              ),
            ),
        ],
      ),
    );
  }

  String _providerName(SocialProvider provider) => switch (provider) {
    SocialProvider.google => 'Google',
  };
}
