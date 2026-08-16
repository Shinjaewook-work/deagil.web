import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../data/auth_repository.dart';
import '../models/registration_requirement.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const FakeAuthRepository();
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthState {
  const AuthState({
    this.requirements = const [],
    this.acceptedDocumentIds = const {},
    this.age14PlusAttested = false,
    this.aiProcessingConsent = false,
    this.privacyUsageConsent = false,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.isAuthPending = false,
    this.errorMessage,
  });

  final List<RegistrationRequirement> requirements;
  final Set<String> acceptedDocumentIds;
  final bool age14PlusAttested;
  final bool aiProcessingConsent;
  final bool privacyUsageConsent;
  final bool isLoading;
  final bool isAuthenticated;
  final bool isAuthPending;
  final String? errorMessage;

  bool get canSignIn =>
      age14PlusAttested &&
      aiProcessingConsent &&
      privacyUsageConsent &&
      requirements
          .where((item) => item.required)
          .every((item) => acceptedDocumentIds.contains(item.id));

  AuthState copyWith({
    List<RegistrationRequirement>? requirements,
    Set<String>? acceptedDocumentIds,
    bool? age14PlusAttested,
    bool? aiProcessingConsent,
    bool? privacyUsageConsent,
    bool? isLoading,
    bool? isAuthenticated,
    bool? isAuthPending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      requirements: requirements ?? this.requirements,
      acceptedDocumentIds: acceptedDocumentIds ?? this.acceptedDocumentIds,
      age14PlusAttested: age14PlusAttested ?? this.age14PlusAttested,
      aiProcessingConsent: aiProcessingConsent ?? this.aiProcessingConsent,
      privacyUsageConsent: privacyUsageConsent ?? this.privacyUsageConsent,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isAuthPending: isAuthPending ?? this.isAuthPending,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final authSubscription = ref
        .read(authRepositoryProvider)
        .authenticationChanges
        .listen((isAuthenticated) {
          state = state.copyWith(
            isAuthenticated: isAuthenticated,
            isAuthPending: false,
          );
          if (isAuthenticated) unawaited(_completeRegistration());
        });
    ref.onDispose(authSubscription.cancel);
    _loadRequirements();
    return const AuthState(isLoading: true);
  }

  Future<void> _loadRequirements() async {
    final requirements = await ref
        .read(authRepositoryProvider)
        .getRegistrationRequirements();
    state = state.copyWith(requirements: requirements, isLoading: false);
  }

  void setAgeAttestation(bool value) {
    state = state.copyWith(age14PlusAttested: value, clearError: true);
  }

  void setAiProcessingConsent(bool value) {
    final accepted = {...state.acceptedDocumentIds};
    for (final requirement in state.requirements.where(
      (item) => item.title.contains('AI'),
    )) {
      if (value) {
        accepted.add(requirement.id);
      } else {
        accepted.remove(requirement.id);
      }
    }
    state = state.copyWith(
      aiProcessingConsent: value,
      acceptedDocumentIds: accepted,
      clearError: true,
    );
  }

  void setPrivacyUsageConsent(bool value) {
    state = state.copyWith(privacyUsageConsent: value, clearError: true);
  }

  void toggleRequirement(String id, bool value) {
    final accepted = {...state.acceptedDocumentIds};
    if (value) {
      accepted.add(id);
    } else {
      accepted.remove(id);
    }
    state = state.copyWith(acceptedDocumentIds: accepted, clearError: true);
  }

  Future<void> signIn(SocialProvider provider) async {
    if (!state.canSignIn) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .signIn(
            provider: provider,
            age14PlusAttested: state.age14PlusAttested,
            acceptedDocumentIds: state.acceptedDocumentIds,
          );
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: result.isAuthenticated,
        isAuthPending: result.isPending,
      );
      if (result.isAuthenticated) await _completeRegistration();
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } on AuthException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'AUTH_PROVIDER_FAILED',
      );
    }
  }

  Future<void> _completeRegistration() async {
    try {
      await ref
          .read(authRepositoryProvider)
          .completeRegistration(
            age14PlusAttested: state.age14PlusAttested,
            displayedDocumentIds: state.requirements
                .map((item) => item.id)
                .toSet(),
            acceptedDocumentIds: state.acceptedDocumentIds,
            analyticsEnabled: false,
          );
    } on StateError catch (error) {
      state = state.copyWith(errorMessage: error.message);
    } on AuthException {
      state = state.copyWith(errorMessage: 'REGISTRATION_SYNC_FAILED');
    }
  }
}
