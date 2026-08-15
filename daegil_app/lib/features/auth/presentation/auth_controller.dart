import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    this.isLoading = false,
    this.isAuthenticated = false,
    this.errorMessage,
  });

  final List<RegistrationRequirement> requirements;
  final Set<String> acceptedDocumentIds;
  final bool age14PlusAttested;
  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;

  bool get canSignIn =>
      age14PlusAttested &&
      requirements
          .where((item) => item.required)
          .every((item) => acceptedDocumentIds.contains(item.id));

  AuthState copyWith({
    List<RegistrationRequirement>? requirements,
    Set<String>? acceptedDocumentIds,
    bool? age14PlusAttested,
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      requirements: requirements ?? this.requirements,
      acceptedDocumentIds: acceptedDocumentIds ?? this.acceptedDocumentIds,
      age14PlusAttested: age14PlusAttested ?? this.age14PlusAttested,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
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
      await ref
          .read(authRepositoryProvider)
          .signIn(
            provider: provider,
            age14PlusAttested: state.age14PlusAttested,
            acceptedDocumentIds: state.acceptedDocumentIds,
          );
      state = state.copyWith(isLoading: false, isAuthenticated: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    }
  }
}
