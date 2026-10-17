import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/view/layout/auth/model/whatsapp_consent_selection.dart';
import '../lib/view/layout/auth/screen/whatsapp_consent_fields.dart';

void main() {
  test('untouched choices do not submit or revoke an existing preference', () {
    const selection = WhatsAppConsentSelection();
    expect(selection.hasSelection, isFalse);
    expect(selection.grants, isEmpty);
  });

  test('each purpose grants only the explicit selection', () {
    const feedback = WhatsAppConsentSelection(service: true);
    expect(feedback.grants, {
      'whatsapp_consent_version': '2026-10-17.v1',
      'service_consent': true,
    });
    const offers = WhatsAppConsentSelection(marketing: true);
    expect(offers.grants, {
      'whatsapp_consent_version': '2026-10-17.v1',
      'marketing_consent': true,
    });
    expect(feedback.copyWith(service: false).grants, isEmpty);
    expect(feedback.copyWith(marketing: true).grants, {
      'whatsapp_consent_version': '2026-10-17.v1',
      'service_consent': true,
      'marketing_consent': true,
    });
  });

  for (final arabic in [true, false]) {
    testWidgets('optional independent choices; Arabic=$arabic', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var selection = const WhatsAppConsentSelection();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.6)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: StatefulBuilder(builder: (context, setState) {
                  return WhatsAppConsentFields(
                    isArabic: arabic,
                    selection: selection,
                    onChanged: (value) => setState(() => selection = value),
                  );
                }),
              ),
            );
          }),
        ),
      ));
      await tester.pumpAndSettle();

      final feedback = find.byKey(const ValueKey('whatsapp-service-consent'));
      final offers = find.byKey(const ValueKey('whatsapp-marketing-consent'));
      expect(tester.widget<CheckboxListTile>(feedback).value, isFalse);
      expect(tester.widget<CheckboxListTile>(offers).value, isFalse);
      expect(find.textContaining(arabic ? 'فسخانستا' : 'Fasakhansta'), findsOneWidget);
      expect(find.textContaining(arabic ? 'إلغاء الاشتراك' : 'unsubscribe'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(offers);
      await tester.tap(offers);
      await tester.pumpAndSettle();
      expect(selection.marketing, isTrue);
      expect(selection.service, isFalse);
      expect(selection.grants.containsKey('service_consent'), isFalse);

      await tester.ensureVisible(feedback);
      await tester.tap(feedback);
      await tester.pumpAndSettle();
      expect(selection.service, isTrue);
      expect(selection.marketing, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
