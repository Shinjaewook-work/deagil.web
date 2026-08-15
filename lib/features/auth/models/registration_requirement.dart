enum LegalInteraction {
  acceptanceRequired,
  consentRequired,
  noticeOnly,
  linkOnly
}

class RegistrationRequirement {
  const RegistrationRequirement({
    required this.id,
    required this.title,
    required this.interaction,
    required this.required,
  });

  final String id;
  final String title;
  final LegalInteraction interaction;
  final bool required;
}
