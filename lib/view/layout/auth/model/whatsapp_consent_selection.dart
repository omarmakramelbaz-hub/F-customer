/// Optional choices made beside the phone field; entering a phone is not consent.
class WhatsAppConsentSelection {
  const WhatsAppConsentSelection({this.service = false, this.marketing = false});

  static const version = '2026-10-17.v1';

  final bool service;
  final bool marketing;

  bool get hasSelection => service || marketing;

  WhatsAppConsentSelection copyWith({bool? service, bool? marketing}) =>
      WhatsAppConsentSelection(
        service: service ?? this.service,
        marketing: marketing ?? this.marketing,
      );

  /// Unchecked fields are omitted, so signup never revokes an existing choice.
  Map<String, dynamic> get grants => {
        if (hasSelection) 'whatsapp_consent_version': version,
        if (service) 'service_consent': true,
        if (marketing) 'marketing_consent': true,
      };
}
