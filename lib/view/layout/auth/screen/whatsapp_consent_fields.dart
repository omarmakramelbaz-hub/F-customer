import 'package:flutter/material.dart';

import '../model/whatsapp_consent_selection.dart';

class WhatsAppConsentFields extends StatelessWidget {
  const WhatsAppConsentFields({
    super.key,
    required this.isArabic,
    required this.selection,
    required this.onChanged,
  });

  final bool isArabic;
  final WhatsAppConsentSelection selection;
  final ValueChanged<WhatsAppConsentSelection> onChanged;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'رسائل واتساب من فسخانستا (اختياري)'
                  : 'WhatsApp messages from Fasakhansta (optional)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            CheckboxListTile(
              key: const ValueKey('whatsapp-service-consent'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              value: selection.service,
              onChanged: (value) =>
                  onChanged(selection.copyWith(service: value == true)),
              title: Text(
                isArabic
                    ? 'أوافق على رسالة لمتابعة رأيي في الطلب والخدمة.'
                    : 'I agree to a message asking for feedback on my order and service.',
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
            CheckboxListTile(
              key: const ValueKey('whatsapp-marketing-consent'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              value: selection.marketing,
              onChanged: (value) =>
                  onChanged(selection.copyWith(marketing: value == true)),
              title: Text(
                isArabic
                    ? 'أوافق على استقبال عروض ورسائل ترويجية.'
                    : 'I agree to receive offers and promotional messages.',
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
            Text(
              isArabic
                  ? 'يمكنك إلغاء الاشتراك في أي وقت بإرسال «إلغاء» على واتساب.'
                  : 'You can unsubscribe at any time by sending STOP on WhatsApp.',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF727780),
                height: 1.4,
              ),
            ),
          ],
        ),
      );
}
