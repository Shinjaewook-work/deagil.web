import '../models/registration_requirement.dart';

enum SocialProvider { kakao, google, apple }

abstract interface class AuthRepository {
  Future<List<RegistrationRequirement>> getRegistrationRequirements();
  Future<void> signIn({
    required SocialProvider provider,
    required bool age14PlusAttested,
    required Set<String> acceptedDocumentIds,
  });
}

class FakeAuthRepository implements AuthRepository {
  const FakeAuthRepository();

  static const requirements = [
    RegistrationRequirement(
      id: 'terms-v1',
      title: '서비스 이용약관에 동의합니다.',
      interaction: LegalInteraction.acceptanceRequired,
      required: true,
    ),
    RegistrationRequirement(
      id: 'ai-processing-v1',
      title: 'AI 개인화 처리에 동의합니다.',
      interaction: LegalInteraction.consentRequired,
      required: true,
    ),
    RegistrationRequirement(
      id: 'analytics-v1',
      title: '앱 개선과 오류 분석을 허용합니다.',
      interaction: LegalInteraction.consentRequired,
      required: false,
    ),
  ];

  @override
  Future<List<RegistrationRequirement>> getRegistrationRequirements() async {
    return requirements;
  }

  @override
  Future<void> signIn({
    required SocialProvider provider,
    required bool age14PlusAttested,
    required Set<String> acceptedDocumentIds,
  }) async {
    if (!age14PlusAttested ||
        !acceptedDocumentIds.contains('terms-v1') ||
        !acceptedDocumentIds.contains('ai-processing-v1')) {
      throw StateError('REGISTRATION_REQUIREMENTS_INCOMPLETE');
    }
  }
}
