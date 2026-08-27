import '../models/registration_requirement.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SocialProvider { google }

abstract interface class AuthRepository {
  Future<List<RegistrationRequirement>> getRegistrationRequirements();
  Future<bool> hasCompletedRegistration();
  Stream<bool> get authenticationChanges;
  Future<AuthSignInResult> signIn({
    required SocialProvider provider,
    required bool age14PlusAttested,
    required Set<String> acceptedDocumentIds,
  });
  Future<void> completeRegistration({
    required bool age14PlusAttested,
    required Set<String> displayedDocumentIds,
    required Set<String> acceptedDocumentIds,
    required bool analyticsEnabled,
  });
}

class AuthSignInResult {
  const AuthSignInResult({
    required this.isAuthenticated,
    required this.isPending,
  });

  const AuthSignInResult.authenticated()
    : isAuthenticated = true,
      isPending = false;

  const AuthSignInResult.pending() : isAuthenticated = false, isPending = true;

  final bool isAuthenticated;
  final bool isPending;
}

class FakeAuthRepository implements AuthRepository {
  const FakeAuthRepository();

  static const requirements = [
    RegistrationRequirement(
      id: 'terms-v1',
      title: '서비스 이용약관에 동의합니다.',
      documentType: 'terms',
      interaction: LegalInteraction.acceptanceRequired,
      required: true,
    ),
    RegistrationRequirement(
      id: 'ai-processing-v1',
      title: 'AI 개인화 처리에 동의합니다.',
      documentType: 'ai_processing',
      interaction: LegalInteraction.consentRequired,
      required: true,
    ),
    RegistrationRequirement(
      id: 'privacy-v1',
      title: '개인정보 활용에 동의합니다.',
      documentType: 'privacy',
      interaction: LegalInteraction.consentRequired,
      required: true,
    ),
    RegistrationRequirement(
      id: 'analytics-v1',
      title: '앱 개선과 오류 분석을 허용합니다.',
      documentType: 'analytics',
      interaction: LegalInteraction.consentRequired,
      required: false,
    ),
  ];

  @override
  Stream<bool> get authenticationChanges => const Stream<bool>.empty();

  @override
  Future<List<RegistrationRequirement>> getRegistrationRequirements() async {
    return requirements;
  }

  @override
  Future<bool> hasCompletedRegistration() async => false;

  @override
  Future<AuthSignInResult> signIn({
    required SocialProvider provider,
    required bool age14PlusAttested,
    required Set<String> acceptedDocumentIds,
  }) async {
    if (!age14PlusAttested ||
        !acceptedDocumentIds.contains('terms-v1') ||
        !acceptedDocumentIds.contains('ai-processing-v1') ||
        !acceptedDocumentIds.contains('privacy-v1')) {
      throw StateError('REGISTRATION_REQUIREMENTS_INCOMPLETE');
    }
    return const AuthSignInResult.authenticated();
  }

  @override
  Future<void> completeRegistration({
    required bool age14PlusAttested,
    required Set<String> displayedDocumentIds,
    required Set<String> acceptedDocumentIds,
    required bool analyticsEnabled,
  }) async {
    if (!age14PlusAttested ||
        !acceptedDocumentIds.every(displayedDocumentIds.contains)) {
      throw StateError('REGISTRATION_REQUIREMENTS_INCOMPLETE');
    }
  }
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required SupabaseClient client,
    required this.redirectTo,
  }) : _client = client;

  final SupabaseClient _client;
  final String redirectTo;

  @override
  Stream<bool> get authenticationChanges =>
      _client.auth.onAuthStateChange.map((event) => event.session != null);

  @override
  Future<List<RegistrationRequirement>> getRegistrationRequirements() async {
    final response = await _client.rpc('get_public_registration_requirements');
    final payload = response as Map<String, dynamic>;
    final documents = payload['documents'];
    if (documents is! List) {
      throw const FormatException('INVALID_LEGAL_RESPONSE');
    }
    return documents
        .map(
          (document) => RegistrationRequirement.fromJson(
            Map<String, dynamic>.from(document as Map),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<bool> hasCompletedRegistration() async {
    final response = await _client.rpc('get_my_app_state');
    final payload = Map<String, dynamic>.from(response as Map);
    return payload['gate'] == 'NONE';
  }

  @override
  Future<AuthSignInResult> signIn({
    required SocialProvider provider,
    required bool age14PlusAttested,
    required Set<String> acceptedDocumentIds,
  }) async {
    // Legal requirements are server-driven. Supabase returns active document
    // UUIDs, so the client must not enforce Mock fixture IDs here. The
    // completion RPC performs the authoritative active-document check.
    if (!age14PlusAttested) {
      throw StateError('REGISTRATION_REQUIREMENTS_INCOMPLETE');
    }
    final response = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
      // Google Workspace/consumer accounts may not return an email claim
      // unless the email userinfo scope is explicitly requested. Supabase
      // uses that claim to create the auth identity during callback.
      scopes: 'https://www.googleapis.com/auth/userinfo.email',
    );
    if (!response) throw StateError('OAUTH_FLOW_NOT_STARTED');
    return const AuthSignInResult.pending();
  }

  @override
  Future<void> completeRegistration({
    required bool age14PlusAttested,
    required Set<String> displayedDocumentIds,
    required Set<String> acceptedDocumentIds,
    required bool analyticsEnabled,
  }) async {
    await _client.rpc(
      'complete_my_registration',
      params: {
        'age_14_plus_attested': age14PlusAttested,
        'displayed_document_ids': displayedDocumentIds.toList(growable: false),
        'accepted_document_ids': acceptedDocumentIds.toList(growable: false),
        'analytics_enabled': analyticsEnabled,
      },
    );
  }
}
