enum LegalInteraction {
  acceptanceRequired,
  consentRequired,
  noticeOnly,
  linkOnly,
}

class RegistrationRequirement {
  const RegistrationRequirement({
    required this.id,
    required this.title,
    required this.interaction,
    required this.required,
    this.documentType,
    this.version,
    this.publicUrl,
    this.requiredForAi = false,
    this.withdrawable = false,
  });

  factory RegistrationRequirement.fromJson(Map<String, dynamic> json) {
    final interaction = switch (json['interaction'] as String?) {
      'acceptance_required' => LegalInteraction.acceptanceRequired,
      'consent_required' => LegalInteraction.consentRequired,
      'notice_only' => LegalInteraction.noticeOnly,
      'link_only' => LegalInteraction.linkOnly,
      _ => throw const FormatException('INVALID_LEGAL_INTERACTION'),
    };
    final id = json['id']?.toString();
    final title = json['title']?.toString();
    if (id == null || id.isEmpty || title == null || title.isEmpty) {
      throw const FormatException('INVALID_REGISTRATION_DOCUMENT');
    }
    return RegistrationRequirement(
      id: id,
      title: title,
      interaction: interaction,
      required: json['required_for_registration'] == true,
      documentType: json['document_type']?.toString(),
      version: json['version']?.toString(),
      publicUrl: json['public_url']?.toString(),
      requiredForAi: json['required_for_ai'] == true,
      withdrawable: json['withdrawable'] == true,
    );
  }

  final String id;
  final String title;
  final LegalInteraction interaction;
  final bool required;
  final String? documentType;
  final String? version;
  final String? publicUrl;
  final bool requiredForAi;
  final bool withdrawable;
}
