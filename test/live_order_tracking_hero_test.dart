import 'package:faskhaninja/view/layout/orders/model/orders_model.dart';
import 'package:faskhaninja/view/layout/orders/widgets/live_order_tracking_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpHero(
  WidgetTester tester, {
  required String status,
  bool reduceMotion = true,
  bool tickerEnabled = true,
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(const Size(320, 740));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF092225),
        body: TickerMode(
          enabled: tickerEnabled,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LiveOrderTrackingHero(
                key: const ValueKey('real-tracking-hero'),
                order:
                    OrdersModel(id: 501, orderNo: 'TEST-501', status: status),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  final states = <String, (String, String?)>{
    'pending': ('استلمنا طلبك', 'تم الاستلام'),
    'accepted': ('طلبك بيتجهّز', 'قيد التجهيز'),
    'new_order': ('المندوب في طريقه للاستلام', 'قيد التجهيز'),
    'shipped': ('طلبك في الطريق', 'في الطريق'),
    ' out-for-delivery ': ('طلبك في الطريق', 'في الطريق'),
    'completed': ('طلبك وصل بالسلامة', 'تم التسليم'),
    'cancelled': ('تم إلغاء الطلب', null),
    'declined': ('تعذّر قبول الطلب', null),
    'unknown-status': ('جارٍ تحديث حالة الطلب', null),
  };

  for (final entry in states.entries) {
    testWidgets('confirmed ${entry.key} presents its correct current stage',
        (tester) async {
      await _pumpHero(tester, status: entry.key);

      expect(find.text(entry.value.$1), findsOneWidget);
      expect(find.text('طلب رقم TEST-501'), findsOneWidget);
      final currentStage = entry.value.$2;
      if (currentStage == null) {
        expect(find.bySemanticsLabel(RegExp('المرحلة الحالية')), findsNothing);
      } else {
        expect(
          find.bySemanticsLabel('$currentStage، المرحلة الحالية'),
          findsOneWidget,
        );
      }
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('large Arabic text stays readable on a 320px screen', (
    tester,
  ) async {
    await _pumpHero(tester, status: 'new_order', textScale: 2.5);
    await tester.pumpAndSettle();

    expect(find.text('المندوب في طريقه للاستلام'), findsOneWidget);
    expect(find.text('تم الاستلام'), findsOneWidget);
    expect(find.text('تم التسليم'), findsOneWidget);
    expect(find.textContaining('دقيقة'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active motion stops for reduced motion and muted tickers', (
    tester,
  ) async {
    await _pumpHero(tester, status: 'shipped', reduceMotion: false);
    expect(tester.hasRunningAnimations, isTrue);

    await _pumpHero(tester, status: 'shipped', reduceMotion: true);
    expect(tester.hasRunningAnimations, isFalse);

    await _pumpHero(
      tester,
      status: 'shipped',
      reduceMotion: false,
      tickerEnabled: false,
    );
    expect(tester.hasRunningAnimations, isFalse);

    await _pumpHero(tester, status: 'shipped', reduceMotion: false);
    expect(tester.hasRunningAnimations, isTrue);

    await _pumpHero(tester, status: 'completed', reduceMotion: false);
    expect(find.text('طلبك وصل بالسلامة'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('backgrounding pauses motion until the application resumes', (
    tester,
  ) async {
    await _pumpHero(tester, status: 'shipped', reduceMotion: false);
    expect(tester.hasRunningAnimations, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    expect(tester.takeException(), isNull);
  });
}
