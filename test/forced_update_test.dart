import 'package:faskhaninja/helpers/forced_update/forced_update.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an older version is told apart from the allowed one', () {
    expect(ForcedUpdatePolicy.isOlder('1.0.54', '1.0.55'), isTrue);
    expect(ForcedUpdatePolicy.isOlder('1.0.9', '1.0.10'), isTrue,
        reason: 'numbers, not text');
    expect(ForcedUpdatePolicy.isOlder('1.0.55', '1.0.55'), isFalse);
    expect(ForcedUpdatePolicy.isOlder('1.1', '1.0.55'), isFalse);
    expect(ForcedUpdatePolicy.isOlder('2.0.6+56', '2.0.7'), isTrue,
        reason: 'the build number is ignored');
    expect(ForcedUpdatePolicy.isOlder('1.0', '1.0.0'), isFalse);
  });

  test('the server answer per platform; nothing forced when no version is set',
      () {
    final data = {
      'android': {
        'min_version': '1.0.55',
        'store_url': 'https://play.google.com/store/apps/details?id=x'
      },
      'ios': {'min_version': null, 'store_url': null},
      'message': 'حدّث دلوقتي',
    };
    final android = ForcedUpdatePolicy.fromJson(data, TargetPlatform.android)!;
    expect(android.minVersion, '1.0.55');
    expect(android.storeUrl, 'https://play.google.com/store/apps/details?id=x');
    expect(android.message, 'حدّث دلوقتي');
    expect(ForcedUpdatePolicy.fromJson(data, TargetPlatform.iOS), isNull);
    expect(ForcedUpdatePolicy.fromJson(null, TargetPlatform.android), isNull,
        reason: 'an older server');
  });

  testWidgets(
      'the message is Fasakhansta\'s update design and cannot be closed with back',
      (tester) async {
    const policy = ForcedUpdatePolicy(
        minVersion: '1.0.55',
        storeUrl: 'https://play.google.com/store/apps/details?id=x',
        message: 'حدّث دلوقتي');
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Builder(
          builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const ForcedUpdateDialog(policy: policy)),
                  child: const Text('open'),
                ),
              )),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('حدّث دلوقتي'), findsOneWidget);
    expect(find.text('إصدار أحدث من فسخانستا'), findsOneWidget);
    expect(find.text('التحديث إجباري لمتابعة استخدام التطبيق'), findsOneWidget);
    // Back does not close it, nor a tap outside.
    await tester.binding.handlePopRoute();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('حدّث دلوقتي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
