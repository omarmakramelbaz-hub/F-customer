import 'package:faskhaninja/view/layout/home/model/draw_badge.dart';
import 'package:faskhaninja/view/layout/home/widgets/draw_badge_chip.dart';
import 'package:faskhaninja/view/layout/restaurants/widgets/menu_product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _draw = DrawBadge(
  label: 'يؤهلك للدخول في السحب بقيمة 5,000 جنيه',
  prizeAmount: 5000,
);

Future<void> _mountCard(
  WidgetTester tester, {
  DrawBadge? draw = _draw,
  double width = 225,
  double height = 322,
  double textScale = 1,
  bool rtl = true,
  bool reducedMotion = false,
  bool tickerEnabled = true,
  VoidCallback? onTap,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(fontFamily: 'Tajawal'),
    home: MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reducedMotion,
      ),
      child: Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          body: Center(
            child: TickerMode(
              enabled: tickerEnabled,
              child: SizedBox(
                width: width,
                height: height,
                child: MenuProductCard(
                  name: 'ساندوتش فسيخ دسوق مظبوط',
                  priceLabel: '130 ج',
                  image: const ColoredBox(
                    key: ValueKey('product-image'),
                    color: Colors.white,
                  ),
                  draw: draw,
                  onTap: onTap ?? () {},
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ));
}

double _prizeScale(WidgetTester tester) => tester
    .widget<Transform>(find.descendant(
      of: find.byType(DrawBadgeChip),
      matching: find.byType(Transform),
    ))
    .transform
    .entry(0, 0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Tajawal', 'Roboto']) {
      final loader = FontLoader(family);
      for (final weight in ['Regular', 'Bold', 'Black']) {
        loader.addFont(
            rootBundle.load('assets/font/$family/$family-$weight.ttf'));
      }
      await loader.load();
    }
  });

  testWidgets('one prize box stays at the top left in both layout directions',
      (tester) async {
    for (final rtl in [true, false]) {
      await _mountCard(tester, rtl: rtl);
      final card = tester.getRect(find.byType(MenuProductCard));
      final prize = tester.getRect(find.text('5,000'));
      final caption = tester.getRect(find.text('هذا المنتج يؤهلك للسحب'));

      expect(find.byType(DrawBadgeChip), findsOneWidget);
      expect(find.text('مؤهل للسحب'), findsNothing);
      expect(caption.bottom, lessThan(prize.top));
      expect(prize.center.dx, lessThan(card.center.dx));
      expect(caption.top, lessThan(card.top + 30));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('small cards show the complete real prize at enlarged text sizes',
      (tester) async {
    for (final width in [135.0, 155.0, 225.0]) {
      for (final scale in [1.0, 2.0]) {
        await _mountCard(
          tester,
          width: width,
          height: 250 + (scale - 1) * 70,
          textScale: scale,
          draw: const DrawBadge(
            label: 'يؤهلك للدخول في السحب بقيمة 1,000,000 جنيه',
            prizeAmount: 1000000,
          ),
        );
        final image =
            tester.getRect(find.byKey(const ValueKey('product-image')));
        final badge = tester.getRect(find.byType(DrawBadgeChip));
        expect(badge.bottom, lessThanOrEqualTo(image.bottom),
            reason: 'The complete badge must fit: width $width, scale $scale');
        expect(find.text('1,000,000'), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: 'width $width, scale $scale');
      }
    }
  });

  testWidgets(
      'plain products have no draw badge and preserve the product action',
      (tester) async {
    var taps = 0;
    await _mountCard(tester, draw: null, onTap: () => taps++);
    expect(find.byType(DrawBadgeChip), findsNothing);
    expect(find.text('هذا المنتج يؤهلك للسحب'), findsNothing);
    await tester.tap(find.text('130 ج'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'prize pulses without changing its value and honors reduced motion',
      (tester) async {
    await _mountCard(tester);
    final initialScale = _prizeScale(tester);
    await tester.pump(const Duration(milliseconds: 800));
    expect(_prizeScale(tester), greaterThan(initialScale));
    expect(find.text('5,000'), findsOneWidget);

    await _mountCard(tester, reducedMotion: true);
    final stillScale = _prizeScale(tester);
    await tester.pump(const Duration(milliseconds: 800));
    expect(_prizeScale(tester), stillScale);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await _mountCard(tester, tickerEnabled: false);
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.binding.hasScheduledFrame, isFalse);

    await _mountCard(
      tester,
      reducedMotion: true,
      draw: const DrawBadge(
        label: 'يؤهلك للدخول في السحب بقيمة 10,000 جنيه',
        prizeAmount: 10000,
      ),
    );
    expect(find.text('10,000'), findsOneWidget);
    expect(find.text('5,000'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
