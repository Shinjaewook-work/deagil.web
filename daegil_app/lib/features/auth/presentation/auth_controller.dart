import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    this.hasAuthenticatedSession = false,
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
  final bool hasAuthenticatedSession;
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
    bool? hasAuthenticatedSession,
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
      hasAuthenticatedSession:
          hasAuthenticatedSession ?? this.hasAuthenticatedSession,
      isAuthPending: isAuthPending ?? this.isAuthPending,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  bool _registrationSyncInProgress = false;
  bool _sessionRestoreInProgress = false;

  @override
  AuthState build() {
    final authSubscription = ref
        .read(authRepositoryProvider)
        .authenticationChanges
        .listen((hasAuthenticatedSession) {
          state = state.copyWith(
            hasAuthenticatedSession: hasAuthenticatedSession,
            isAuthenticated: false,
            isAuthPending: false,
          );
          if (hasAuthenticatedSession) {
            unawaited(_restoreAuthenticatedSession());
          }
        });
    ref.onDispose(authSubscription.cancel);
    _loadRequirements();
    return const AuthState(isLoading: true);
  }

  Future<void> _loadRequirements() async {
    try {
      final requirements = await ref
          .read(authRepositoryProvider)
          .getRegistrationRequirements();
      state = state.copyWith(
        requirements: requirements,
        isLoading: false,
        clearError: true,
      );
    } on FormatException catch (_) {
      _setRequirementsLoadFailure();
    } on AuthException catch (_) {
      _setRequirementsLoadFailure();
    } on PostgrestException catch (_) {
      _setRequirementsLoadFailure();
    }
  }

  void setAgeAttestation(bool value) {
    state = state.copyWith(age14PlusAttested: value, clearError: true);
  }

  Future<void> retryRequirements() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _loadRequirements();
  }

  void setAiProcessingConsent(bool value) {
    final accepted = {...state.acceptedDocumentIds};
    for (final requirement in _requirementsOfType('ai_processing')) {
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
    final accepted = {...state.acceptedDocumentIds};
    for (final requirement in _requirementsOfType('privacy')) {
      if (value) {
        accepted.add(requirement.id);
      } else {
        accepted.remove(requirement.id);
      }
    }
    state = state.copyWith(
      privacyUsageConsent: value,
      acceptedDocumentIds: accepted,
      clearError: true,
    );
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
    if (state.hasAuthenticatedSession) {
      await _completeRegistration();
      return;
    }
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
        hasAuthenticatedSession: result.isAuthenticated,
        isAuthenticated: false,
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
    if (_registrationSyncInProgress) return;
    _registrationSyncInProgress = true;
    state = state.copyWith(isLoading: true, clearError: true);
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
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        hasAuthenticatedSession: true,
        isAuthPending: false,
        clearError: true,
      );
    } on StateError catch (error) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: error.message,
      );
    } on AuthException catch (_) {
      _setRegistrationFailure();
    } on PostgrestException catch (_) {
      _setRegistrationFailure();
    } finally {
      _registrationSyncInProgress = false;
    }
  }

  Future<void> _restoreAuthenticatedSession() async {
    if (_sessionRestoreInProgress) return;
    _sessionRestoreInProgress = true;
    try {
      final completed = await ref
          .read(authRepositoryProvider)
          .hasCompletedRegistration();
      if (completed) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          hasAuthenticatedSession: true,
          isAuthPending: false,
          clearError: true,
        );
      } else if (state.canSignIn) {
        await _completeRegistration();
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'REGISTRATION_CONFIRMATION_REQUIRED',
        );
      }
    } on AuthException catch (_) {
      _setRegistrationFailure();
    } on PostgrestException catch (_) {
      _setRegistrationFailure();
    } finally {
      _sessionRestoreInProgress = false;
    }
  }

  void _setRegistrationFailure() {
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: false,
      errorMessage: 'REGISTRATION_SYNC_FAILED',
    );
  }

  Iterable<RegistrationRequirement> _requirementsOfType(String type) =>
      state.requirements.where((item) => item.documentType == type);

  void _setRequirementsLoadFailure() {
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'REGISTRATION_REQUIREMENTS_LOAD_FAILED',
    );
  }
}
